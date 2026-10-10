# frozen_string_literal: true

require "date"
require "time"
require "erb"
require "json"

module PaystackSdk
  # Small helpers resource classes use to turn idiomatic Ruby arguments into exactly what Paystack
  # documents on the wire. They are private to the classes that include them.
  #
  # Ruby code uses snake_case keywords (`per_page:`, `terminal_id:`); the request carries Paystack's
  # names (`perPage`, `terminalid`). Each method names its mapping in one place, with {#to_wire}.
  module RequestHelpers
    private

    # Escapes a value for use as one segment of a URL path, so a reference or code containing `/`,
    # `?`, `#` or a space cannot change which endpoint is called.
    #
    # `.` and `..` are refused: the URL builder resolves them as relative path steps, so
    # `/customer/..` would call `/`. No Paystack identifier is ever one of them. An empty value is
    # refused too, since it would collapse the segment out of the path.
    #
    # @param segment [#to_s]
    # @param name [String] parameter name, for the error message
    # @return [String]
    # @raise [PaystackSdk::InvalidValueError] If the segment is empty, `.` or `..`
    def escape_path(segment, name: "path segment")
      value = segment.to_s
      raise InvalidValueError.new(name, "must not be empty") if value.empty?
      raise InvalidValueError.new(name, %(must not be "#{value}")) if %w[. ..].include?(value)

      ERB::Util.url_encode(value)
    end

    # Drops nil values, keeping `false`, `0` and empty strings, which are real values.
    #
    # @param params [Hash]
    # @return [Hash]
    def compact_params(params)
      params.compact
    end

    # Renames Ruby-style keys to the parameter names Paystack documents, drops nils and returns
    # string keys. Keys without a mapping are sent as given.
    #
    # @param params [Hash] e.g. `{per_page: 20, status: "success"}`
    # @param mapping [Hash{Symbol => String}] e.g. `{per_page: "perPage"}`
    # @return [Hash{String => Object}]
    def to_wire(params, mapping)
      compact_params(params).each_with_object({}) do |(key, value), wire|
        wire[(mapping[key] || key).to_s] = value
      end
    end

    # Formats a Date, Time or ISO 8601 String for a Paystack date-time parameter.
    #
    # @param value [Date, Time, String, nil]
    # @param name [String] parameter name, for the error message
    # @return [String, nil]
    # @raise [PaystackSdk::InvalidFormatError] If a String is not ISO 8601
    def format_datetime(value, name: "date")
      case value
      when nil then nil
      when Time, DateTime then value.getutc.strftime("%Y-%m-%dT%H:%M:%SZ")
      when Date then value.iso8601
      when String
        iso8601?(value) ? value : raise(InvalidFormatError.new(name, "ISO 8601 date or date-time (e.g. 2026-01-31 or 2026-01-31T09:00:00Z)"))
      else raise InvalidFormatError.new(name, "Date, Time or ISO 8601 String")
      end
    end

    # Formats a Date, Time or YYYY-MM-DD String for a Paystack date parameter.
    #
    # @param value [Date, Time, String, nil]
    # @param name [String] parameter name, for the error message
    # @return [String, nil]
    # @raise [PaystackSdk::InvalidFormatError] If a String is not a real YYYY-MM-DD date
    def format_date(value, name: "date")
      case value
      when nil then nil
      when Time, Date then value.strftime("%Y-%m-%d")
      when String
        valid = value.match?(/\A\d{4}-\d{2}-\d{2}\z/) && begin
          Date.strptime(value, "%Y-%m-%d")
        rescue
          nil
        end
        valid ? value : raise(InvalidFormatError.new(name, "YYYY-MM-DD"))
      else raise InvalidFormatError.new(name, "Date, Time or YYYY-MM-DD String")
      end
    end

    # For the few fields Paystack documents as "stringified JSON" (for example customer metadata):
    # accepts a Hash or Array and sends the JSON string. Strings pass through unchanged.
    #
    # @param value [Hash, Array, String, nil]
    # @return [String, nil]
    def stringify_json(value)
      case value
      when nil, String then value
      else JSON.generate(value)
      end
    end

    def iso8601?(value)
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
  end
end
