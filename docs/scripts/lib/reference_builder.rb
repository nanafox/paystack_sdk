# frozen_string_literal: true

require "logger"
require "yard"
require_relative "markdown"
require_relative "readme_splitter"

module PaystackDocs
  # Builds the API reference pages from the YARD comments in lib/, so the reference cannot drift from the code:
  # one page per resource, plus the client, the response, the webhook helper and the errors.
  class ReferenceBuilder
    Page = ReadmeSplitter::Page

    STANDARD_RETURN = "The response from the Paystack API."
    STANDARD_RAISE = "If a parameter is invalid or the API request fails."

    # @param src [String] a checkout of the gem (its lib/ is parsed)
    def initialize(src)
      @src = src
    end

    # @return [Array<Page>]
    def pages
      load_registry
      [client_page, response_page, webhook_page, errors_page] + resource_pages
    end

    private

    def load_registry
      YARD::Registry.clear
      YARD::Logger.instance.level = ::Logger::ERROR
      files = Dir[File.join(@src, "lib", "**", "*.rb")].reject { |f| f.include?("/skills/") }
      YARD.parse(files)
    end

    def registry(path) = YARD::Registry.at(path)

    # --- resources

    def resource_classes
      YARD::Registry.all(:class)
        .select { |c| c.path.start_with?("PaystackSdk::Resources::") && !c.path.include?("Extensions") && c.path != "PaystackSdk::Resources::Base" }
        .sort_by(&:path)
    end

    def resource_pages
      resource_classes.map do |klass|
        name = klass.name.to_s
        accessor = snake(name)
        title = name.gsub(/([a-z])([A-Z])/, '\1 \2')
        Page.new(path: "reference/#{accessor.tr("_", "-")}", title: title, group: "Resources",
          body: resource_body(klass, title, accessor))
      end
    end

    def resource_body(klass, title, accessor)
      methods = public_methods_of(klass, :instance)
      klass.instance_mixins.each { |mixin| methods.concat(public_methods_of(mixin, :instance)) }
      out = ["# #{title}", ""]
      out << prose(klass.docstring.to_s) unless klass.docstring.to_s.strip.empty?
      out << ""
      out << "Use it as `client.#{accessor}`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](/reference/response), " \
        "and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack " \
        "(a 400 or 404) comes back as a Response with `success?` false."
      out << ""
      out << "## Methods"
      out << ""
      methods.sort_by { |m| [m.file.to_s, m.line.to_i] }.each { |m| out << render_method(m, "#{accessor}.") }
      out.join("\n").gsub(/\n{3,}/, "\n\n") + "\n"
    end

    def public_methods_of(klass, scope)
      klass.meths(scope: scope, visibility: [:public], inherited: false).reject { |m| m.name == :initialize || m.name.to_s.start_with?("_") }
    end

    # --- one method

    def render_method(meth, receiver)
      out = ["### `#{meth.name}`", ""]
      out << "```ruby"
      out << signature(meth, receiver)
      out << "```"
      out << ""
      text = meth.docstring.to_s.strip
      out << prose(text) << "" unless text.empty?
      out.concat(params_table(meth))
      out.concat(returns_and_raises(meth))
      out.concat(notes(meth))
      out.concat(examples(meth))
      out.concat(sees(meth))
      out << ""
      out.join("\n")
    end

    # How a parameter reads in a signature: `key: default` for keywords, `name = default` for positional ones.
    def argument(name, default)
      return name unless default

      name.end_with?(":") ? "#{name} #{default}" : "#{name} = #{default}"
    end

    def signature(meth, receiver)
      args = meth.parameters.map { |name, default| argument(name, default) }
      return "#{receiver}#{meth.name}" if args.empty?

      one_line = "#{receiver}#{meth.name}(#{args.join(", ")})"
      return one_line if one_line.size <= 100

      "#{receiver}#{meth.name}(\n#{args.map { |a| "  #{a}" }.join(",\n")}\n)"
    end

    def params_table(meth)
      tags = meth.tags(:param)
      return [] if tags.empty?

      required = meth.parameters.select { |name, default| name.end_with?(":") && default.nil? }.map { |name, _| name.chomp(":") }
      rows = tags.map do |tag|
        type = Array(tag.types).join(", ")
        need = required.include?(tag.name) ? "yes" : ""
        "| `#{tag.name}` | #{cell(type)} | #{need} | #{cell(tag.text.to_s.gsub(/\s+/, " ").strip)} |"
      end
      ["| Parameter | Type | Required | Description |", "|---|---|---|---|", *rows, ""]
    end

    def returns_and_raises(meth)
      out = []
      ret = meth.tag(:return)
      if ret && ret.text.to_s.strip != STANDARD_RETURN
        out << "**Returns** #{"`#{Array(ret.types).join(", ")}` " unless ret.types.nil?}#{inline(ret.text.to_s)}".strip << ""
      end
      meth.tags(:raise).each do |tag|
        next if tag.text.to_s.strip == STANDARD_RAISE

        out << "**Raises** #{"`#{Array(tag.types).join(", ")}` " unless tag.types.nil?}#{inline(tag.text.to_s)}".strip << ""
      end
      out
    end

    def notes(meth)
      meth.tags(:note).flat_map { |tag| ["::: warning Note", inline(tag.text.to_s.strip), ":::", ""] }
    end

    def examples(meth)
      meth.tags(:example).flat_map do |tag|
        code = tag.text.to_s.gsub(/^\s*#\s?/, "").strip
        next [] if code.empty?

        code = code.sub(/\A```ruby\n/, "").sub(/\n?```\z/, "")
        ["**Example#{": #{tag.name}" unless tag.name.to_s.empty?}**", "", "```ruby", code, "```", ""]
      end
    end

    def sees(meth)
      meth.tags(:see).map { |tag| "Paystack docs: <#{tag.name}>" if tag.name.to_s.start_with?("http") }.compact.flat_map { |line| [line, ""] }
    end

    # --- the client, response, webhook and errors

    def client_page
      klass = registry("PaystackSdk::Client")
      accessors = public_methods_of(klass, :instance).select { |m| m.parameters.empty? && !%i[live? inspect connection].include?(m.name) }
      known = resource_classes.map { |c| snake(c.name.to_s) }
      initialize = klass.meths(inherited: false).find { |m| m.name == :initialize }
      out = ["# Client", "", prose(klass.docstring.to_s), ""]
      if initialize
        out << "## Creating a client" << ""
        out << "```ruby" << "PaystackSdk::Client.new(#{initialize.parameters.map { |n, d| argument(n, d) }.join(", ")})" << "```" << ""
        out.concat(params_table(initialize))
      end
      out << "## Methods" << ""
      %i[live?].each do |name|
        meth = klass.meths(inherited: false).find { |m| m.name == name }
        out << render_method(meth, "client.") if meth
      end
      out << "## Resources" << "" << "| Accessor | Page |" << "|---|---|"
      accessors.map(&:name).select { |n| known.include?(n.to_s) }.sort.each do |name|
        out << "| `client.#{name}` | [#{name.to_s.tr("_", " ")}](/reference/#{name.to_s.tr("_", "-")}) |"
      end
      Page.new(path: "reference/client", title: "Client", group: "Core", body: out.join("\n").gsub(/\n{3,}/, "\n\n") + "\n")
    end

    def response_page
      klass = registry("PaystackSdk::Response")
      out = ["# Response", "", prose(klass.docstring.to_s), "", "## Methods", ""]
      public_methods_of(klass, :instance).reject { |m| %i[method_missing respond_to_missing? inspect].include?(m.name) }
        .sort_by { |m| m.line.to_i }.each { |m| out << render_method(m, "response.") }
      Page.new(path: "reference/response", title: "Response", group: "Core", body: out.join("\n").gsub(/\n{3,}/, "\n\n") + "\n")
    end

    def webhook_page
      mod = registry("PaystackSdk::Webhook")
      events = registry("PaystackSdk::Webhook::EVENTS")
      event = registry("PaystackSdk::Webhook::Event")
      out = ["# Webhook", "", prose(mod.docstring.to_s), ""]
      out << "## Module methods" << ""
      public_methods_of(mod, :class).sort_by { |m| m.line.to_i }.each { |m| out << render_method(m, "PaystackSdk::Webhook.") }
      if event
        out << "## Webhook::Event" << "" << prose(event.docstring.to_s) << ""
        public_methods_of(event, :instance).sort_by { |m| m.line.to_i }.each { |m| out << render_method(m, "event.") }
      end
      if events
        names = events.value.to_s[/%w\[(.*?)\]/m, 1].to_s.split
        out << "## EVENTS" << "" << prose(events.docstring.to_s) << "" << names.map { |n| "- `#{n}`" }.join("\n") << ""
      end
      Page.new(path: "reference/webhook", title: "Webhook", group: "Core", body: out.join("\n").gsub(/\n{3,}/, "\n\n") + "\n")
    end

    def errors_page
      classes = YARD::Registry.all(:class).select { |c| c.path.start_with?("PaystackSdk::") && c.superclass && error_class?(c) }.sort_by(&:path)
      out = ["# Errors", "", "Every error the SDK raises inherits from `PaystackSdk::Error`.", "", "| Class | Inherits from | When |", "|---|---|---|"]
      classes.each do |c|
        out << "| `#{c.path}` | `#{c.superclass.path}` | #{cell(c.docstring.to_s.gsub(/\s+/, " ").strip)} |"
      end
      Page.new(path: "reference/errors", title: "Errors", group: "Core", body: out.join("\n") + "\n")
    end

    def error_class?(klass)
      node = klass
      while node
        return true if node.path == "PaystackSdk::Error"

        node = node.superclass
        break unless node.respond_to?(:path) && node.path.start_with?("PaystackSdk")
      end
      false
    end

    # --- text

    def snake(name) = name.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase

    # Paragraph text for the page: YARD's `{Class}` references and inline markup made safe for Vue.
    def prose(text)
      Markdown.map_prose(text) { |line| Markdown.escape_for_vue(line.gsub(/\{([A-Za-z:#.]+)\}/, '`\1`')) }.strip
    end

    def inline(text) = Markdown.escape_for_vue(text.gsub(/\s+/, " ").strip.gsub(/\{([A-Za-z:#.]+)\}/, '`\1`'))

    # A table cell: no newlines, pipes escaped, tags made safe.
    def cell(text) = Markdown.escape_for_vue(text.to_s.gsub("|", "\\|").gsub(/\{([A-Za-z:#.]+)\}/, '`\1`'))
  end
end
