# frozen_string_literal: true

require "json"
require "uri"
require "yaml"
require "json_schemer"

# Checks the HTTP requests the SDK actually sends against Paystack's OpenAPI spec
# (spec/fixtures/paystack_openapi.yaml, pinned from PaystackOSS/openapi).
#
# It sees the real request after the SDK has validated, mapped and serialised everything: the method,
# path, query string, headers and JSON body. It checks that
#
# * the operation exists for that method and path,
# * every query parameter and body field is one the spec knows, with the right type, enum and format,
# * the spec's required parameters and fields are present,
# * the request carries a bearer token and, with a body, a JSON content type.
#
# Wired into every example by spec_helper: a request to api.paystack.co that breaks the contract fails
# the example. Opt out with `contract: false` on specs that send deliberately odd requests.
# Known, confirmed differences from the spec live in paystack_contract_exceptions.yml.
module PaystackContract
  SPEC_PATH = File.expand_path("../fixtures/paystack_openapi.yaml", __dir__)
  EXCEPTIONS_PATH = File.expand_path("paystack_contract_exceptions.yml", __dir__)
  HOST = "api.paystack.co"
  VERBS = %w[get post put delete patch].freeze

  class << self
    def document
      @document ||= YAML.safe_load_file(SPEC_PATH, aliases: true)
    end

    # OpenAPI treats numeric formats as hints (`float` does not mean "must have a decimal point"), so
    # whole numbers are accepted. Formats that carry real meaning, like date-time, are still checked.
    NUMERIC_FORMATS = %w[float double int32 int64].to_h { |format| [format, proc { true }] }.freeze

    def openapi
      @openapi ||= JSONSchemer.openapi(document, formats: NUMERIC_FORMATS)
    end

    def reset
      Thread.current[:paystack_contract_violations] = []
    end

    def violations
      Thread.current[:paystack_contract_violations] ||= []
    end

    # Called by WebMock after every request. Only requests to Paystack are checked.
    def record(request)
      uri = URI(request.uri.to_s)
      return unless uri.host == HOST

      found = check(method: request.method, url: uri.to_s, body: request.body, headers: request.headers || {})
      violations.concat(found.map { |message| "#{request.method.to_s.upcase} #{uri.request_uri}: #{message}" })
    end

    # @return [Array<String>] What is wrong with the request, empty if it conforms to the spec.
    def check(method:, url:, body:, headers:)
      uri = URI(url)
      verb = method.to_s.downcase
      path, operation = find_operation(verb, uri.path)
      unless operation
        documented = find_documented_only(verb, uri.path)
        return check_documented_only(documented, uri.query, body, headers) if documented

        return ["no operation #{verb.upcase} #{uri.path} in the spec"]
      end

      key = "#{verb.upcase} #{path}"
      problems = []
      problems.concat(check_headers(headers, body))
      problems.concat(check_query(operation, path, key, uri.query))
      problems.concat(check_body(operation, path, verb, key, body))
      problems
    end

    private

    # Operations the docs describe and the spec lacks (spec/fixtures/docs_only_operations.yml). Their
    # requests still have to carry only the query and body parameters the docs list.
    def docs_only_operations
      @docs_only_operations ||= YAML.safe_load_file(File.expand_path("../fixtures/docs_only_operations.yml", __dir__))
    end

    def find_documented_only(verb, request_path)
      segments = request_path.chomp("/").split("/")
      candidates = docs_only_operations.select do |entry|
        entry_verb, path = entry["operation"].split(" ", 2)
        entry_verb.downcase == verb && matches?(path.split("/"), segments)
      end
      # a literal path beats a templated one: /events/lookup over /events/{id}
      candidates.min_by { |entry| entry["operation"].scan("{").size }
    end

    def check_documented_only(entry, query, body, headers)
      problems = check_headers(headers, body)
      given_query = URI.decode_www_form(query.to_s).map(&:first)
      (given_query - entry["query"]).each { |name| problems << "unknown query parameter `#{name}` (the docs list #{entry["query"].inspect})" }
      if body && !body.to_s.empty?
        sent = begin
          JSON.parse(body)
        rescue JSON::ParserError
          nil
        end
        problems << "the body is not JSON" unless sent.is_a?(Hash)
        (sent.keys - entry["body"]).each { |name| problems << "unknown body parameter `#{name}` (the docs list #{entry["body"].inspect})" } if sent.is_a?(Hash)
      end
      problems
    end

    def find_operation(verb, request_path)
      segments = request_path.chomp("/").split("/")
      candidates = document["paths"].select do |path, item|
        item.key?(verb) && matches?(path.split("/"), segments)
      end
      # a literal path beats a templated one: /transaction/totals over /transaction/{id}
      path, = candidates.min_by { |candidate, _| candidate.scan("{").size }
      path && [path, document["paths"][path][verb]]
    end

    def matches?(template, segments)
      template.size == segments.size &&
        template.zip(segments).all? { |t, s| t.start_with?("{") ? !s.empty? : t == s }
    end

    # --- headers

    def check_headers(headers, body)
      headers = headers.transform_keys { |name| name.to_s.downcase }
      problems = []
      problems << "missing Authorization: Bearer <secret key> header" unless headers["authorization"].to_s.match?(/\ABearer \S+\z/)
      if body && !body.to_s.empty? && !headers["content-type"].to_s.start_with?("application/json")
        problems << "a request body needs Content-Type: application/json"
      end
      problems
    end

    # --- query

    def check_query(operation, path, key, query)
      declared = parameters(operation, path).select { |param| param["in"] == "query" }
      given = URI.decode_www_form(query.to_s)
      problems = []

      given.each do |name, value|
        param, override = resolve_query_param(declared, key, name)
        if param.nil?
          problems << "unknown query parameter `#{name}`"
        else
          problems.concat(query_value_problems(name, value, param["schema"] || {}, override))
        end
      end

      declared.select { |param| param["required"] }.each do |param|
        known = given.map(&:first)
        names = [param["name"]] + exceptions_for(key, "query").select { |e| e["spec"] == param["name"] }.map { |e| e["wire"] }
        problems << "missing required query parameter `#{param["name"]}`" if (known & names).empty?
      end
      problems
    end

    def resolve_query_param(declared, key, name)
      exception = exceptions_for(key, "query").find { |e| e["wire"] == name }
      param = if exception && exception["spec"].nil?
        # documented by Paystack but absent from the spec: check against the type recorded in the exception
        {"name" => name, "schema" => {"type" => exception["type"]}}
      else
        declared.find { |p| p["name"] == (exception ? exception["spec"] : name) }
      end
      # an exception may correct the spec's list of allowed values
      if param && exception && exception["enum"]
        param = param.merge("schema" => resolve(param["schema"] || {}).merge("enum" => exception["enum"]))
      end
      [param, exception&.fetch("type", nil)]
    end

    def query_value_problems(name, value, schema, type_override)
      schema = resolve(schema)
      type = type_override || schema["type"]
      case type
      when "integer"
        return ["`#{name}` must be an integer, got #{value.inspect}"] unless value.match?(/\A-?\d+\z/)
      when "number"
        return ["`#{name}` must be a number, got #{value.inspect}"] unless value.match?(/\A-?\d+(\.\d+)?\z/)
      when "boolean"
        return ["`#{name}` must be true or false, got #{value.inspect}"] unless %w[true false].include?(value)
      end
      problems = []
      if schema["enum"] && !type_override && !schema["enum"].map(&:to_s).include?(value)
        problems << "`#{name}` is #{value.inspect}, not one of #{schema["enum"].inspect}"
      end
      problems << "`#{name}` must be a date-time, got #{value.inspect}" if schema["format"] == "date-time" && !date_time?(value)
      problems
    end

    def date_time?(value)
      Time.iso8601(value)
      true
    rescue ArgumentError
      begin
        Date.iso8601(value)
        true
      rescue ArgumentError
        false
      end
    end

    # --- body

    def check_body(operation, path, verb, key, body)
      has_body = !body.nil? && !body.to_s.empty?
      request_body = resolve(operation["requestBody"] || {})
      schema = request_body.dig("content", "application/json", "schema")

      if schema.nil?
        return [] if !has_body || docs_only_body?(body, key)

        return ["this operation takes no request body"]
      end
      unless has_body
        # the spec rarely marks the body itself required, so judge by the schema's required fields
        required = request_body["required"] || openapi.ref(schema_pointer(path, verb)).validate({}).any?
        return required ? ["this operation requires a request body"] : []
      end

      begin
        parsed = JSON.parse(body.to_s)
      rescue JSON::ParserError
        return ["the request body is not valid JSON"]
      end

      results = openapi.ref(schema_pointer(path, verb)).validate(with_spec_names(parsed, key)).reject { |e| optional_by_exception?(e, key) }
      errors = results.map { |e| e["error"] }.reject { |e| exception_error?(e, key) }
      errors + unknown_fields(schema, parsed, key)
    end

    # A body on an operation the spec gives none is fine when it holds only fields the docs list
    # (exception entries with no `spec`), for example send_notification on Finalize Payment Request.
    def docs_only_body?(body, key)
      parsed = JSON.parse(body.to_s)
      allowed = exceptions_for(key, "body").select { |e| e["spec"].nil? }.map { |e| e["wire"] }
      parsed.is_a?(Hash) && (parsed.empty? ? allowed.any? : (parsed.keys - allowed).empty?)
    rescue JSON::ParserError
      false
    end

    # A field the spec marks required but the API does not need (an exception with `required: false`).
    def optional_by_exception?(result, key)
      return false unless result["type"] == "required"

      optional = exceptions_for(key, "body").select { |e| e["required"] == false }.flat_map { |e| [e["wire"], e["spec"]] }
      (result.dig("details", "missing_keys") || []).all? { |name| optional.include?(name) }
    end

    def exception_error?(error, key)
      exceptions_for(key, "body").any? { |e| error.include?("`/#{e["wire"]}`") || (e["spec"] && error.include?("`/#{e["spec"]}`")) }
    end

    # A body field the docs name differently (bank_code for the spec's settlement_bank) also fills the
    # spec's name, so the spec's required check sees it. Its value is checked by the exception, not the spec.
    def with_spec_names(parsed, key)
      return parsed unless parsed.is_a?(Hash)

      exceptions_for(key, "body").each_with_object(parsed.dup) do |e, body|
        next if e["spec"].nil? || e["spec"] == e["wire"] || !body.key?(e["wire"]) || body.key?(e["spec"])

        body[e["spec"]] = body[e["wire"]]
      end
    end

    def unknown_fields(schema, value, key, prefix = nil)
      return [] unless value.is_a?(Hash)

      properties = flatten(schema)
      return [] if properties.empty?

      allowed = exceptions_for(key, "body").map { |e| e["wire"] }
      value.flat_map do |name, child|
        label = [prefix, name].compact.join(".")
        spec_prop = properties[name]
        if spec_prop.nil?
          allowed.include?(name) ? [] : ["unknown body field `#{label}`"]
        else
          unknown_fields(spec_prop, child, key, label)
        end
      end
    end

    # The properties of a schema, including those from allOf and $ref.
    def flatten(schema)
      schema = resolve(schema)
      return {} unless schema.is_a?(Hash)

      merged = (schema["allOf"] || []).map { |part| flatten(part) }.reduce({}, :merge)
      merged.merge(schema["properties"] || {})
    end

    # --- shared

    def parameters(operation, path)
      ((document["paths"][path]["parameters"] || []) + (operation["parameters"] || [])).map { |param| resolve(param) }
    end

    def resolve(node)
      while node.is_a?(Hash) && node["$ref"]
        node = node["$ref"].delete_prefix("#/").split("/").reduce(document) { |current, part| current.fetch(part.gsub("~1", "/").gsub("~0", "~")) }
      end
      node
    end

    def schema_pointer(path, verb)
      "#/paths/#{encode_pointer(path)}/#{verb}/requestBody/content/application~1json/schema"
    end

    def encode_pointer(path)
      path.gsub("~", "~0").gsub("/", "~1").gsub("{", "%7B").gsub("}", "%7D")
    end

    def exceptions_for(key, location)
      @exceptions ||= YAML.safe_load_file(EXCEPTIONS_PATH).group_by { |e| [e["operation"], e["in"]] }
      @exceptions.fetch([key, location], [])
    end
  end
end
