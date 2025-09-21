# frozen_string_literal: true

module PaystackSdk
  # The Validations module provides shared validation methods for Paystack SDK resources.
  # It includes methods for validating common parameters like references, amounts, dates, etc.
  #
  # This module is intended to be included in resource classes to provide consistent
  # parameter validation before making API calls. All validation methods raise specific
  # error types to enable proper error handling in client applications.
  #
  # @example Usage in a resource class
  # ```ruby
  #   class MyResource < PaystackSdk::Resources::Base
  #     include PaystackSdk::Validations
  #
  #     def create(payload)
  #       validate_fields!(
  #         payload: payload,
  #         validations: {
  #           email: { type: :email, required: true },
  #           amount: { type: :positive_integer, required: true },
  #           currency: { type: :currency, required: true }
  #         }
  #       )
  #       # Make API call...
  #     end
  #   end
  # ```
  #
  # @see PaystackSdk::MissingParamError
  # @see PaystackSdk::InvalidFormatError
  # @see PaystackSdk::InvalidValueError
  module Validations
    # Validates that input is a hash.
    #
    # @param input [Object] The input to validate
    # @param name [String] Name of the parameter for error messages
    # @raise [PaystackSdk::InvalidFormatError] If input is not a hash
    def validate_hash!(input:, name: 'Payload')
      return if input.is_a?(Hash)

      raise PaystackSdk::InvalidFormatError.new(name, 'Hash')
    end

    # Validates that required parameters are present in a payload.
    #
    # @param payload [Hash] The payload to validate
    # @param required_params [Array<Symbol>] List of required parameter keys
    # @param operation_name [String] Name of the operation for error messages
    # @raise [PaystackSdk::MissingParamError] If any required parameters are missing
    def validate_required_params!(payload:, required_params:, operation_name: 'Operation')
      missing_params = required_params.select do |param|
        !payload.key?(param) && !payload.key?(param.to_s)
      end

      return if missing_params.empty?

      param = missing_params.first
      raise PaystackSdk::MissingParamError.new(param)
    end

    # Validates that a value is present (not nil or empty).
    #
    # @param value [Object] The value to validate
    # @param name [String] Name of the parameter for error messages
    # @raise [PaystackSdk::MissingParamError] If value is nil or empty
    def validate_presence!(value:, name: 'Parameter')
      return unless value.nil? || (value.respond_to?(:empty?) && value.empty?)

      raise PaystackSdk::MissingParamError.new(name)
    end

    # Validates that a number is a positive integer.
    #
    # @param value [Object] The value to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::InvalidValueError] If value is not a positive integer
    # @raise [PaystackSdk::MissingParamError] If value is nil and not allowed
    def validate_positive_integer!(value:, name: 'Parameter', allow_nil: true)
      if value.nil?
        raise PaystackSdk::MissingParamError.new(name) unless allow_nil
      elsif !value.is_a?(Integer) || value < 1
        raise PaystackSdk::InvalidValueError.new(name, 'must be a positive integer')
      end
    end

    # Validates a transaction reference format.
    #
    # @param reference [String] The reference to validate
    # @param name [String] Name of the parameter for error messages
    # @raise [PaystackSdk::InvalidFormatError] If reference format is invalid
    def validate_reference_format!(reference:, name: 'Reference')
      return if reference.to_s.match?(/^[a-zA-Z0-9._=-]+$/)

      raise PaystackSdk::InvalidFormatError.new(name, 'alphanumeric characters and the following: -, ., =')
    end

    # Validates a date string format.
    #
    # @param date_str [String] The date string to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::InvalidFormatError] If date format is invalid
    # @raise [PaystackSdk::MissingParamError] If date is nil and not allowed
    def validate_date_format!(date_str:, name: 'Date', allow_nil: true)
      if date_str.nil?
        raise PaystackSdk::MissingParamError.new(name) unless allow_nil

        return
      end

      begin
        Date.parse(date_str.to_s)
      rescue Date::Error
        raise PaystackSdk::InvalidFormatError.new(name, 'YYYY-MM-DD or ISO8601')
      end
    end

    # Validates that a value is within an allowed set of values.
    #
    # @param value [Object] The value to validate
    # @param allowed_values [Array] List of allowed values
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::InvalidValueError] If value is not in allowed_values
    # @raise [PaystackSdk::MissingParamError] If value is nil and not allowed
    #
    # @example
    # ```ruby
    #   validate_allowed_values!(
    #     value: "allow",
    #     allowed_values: %w[default allow deny],
    #     name: "risk_action"
    #   )
    # ```
    def validate_allowed_values!(value:, allowed_values:, name: 'Parameter', allow_nil: true)
      if value.nil?
        raise PaystackSdk::MissingParamError.new(name) unless allow_nil

        return
      end

      return if allowed_values.include?(value)

      allowed_list = allowed_values.join(', ')
      raise PaystackSdk::InvalidValueError.new(name, "must be one of: #{allowed_list}")
    end

    # Validates an email format.
    #
    # @param email [String] The email to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::Error] If email format is invalid
    def validate_email!(email:, name: 'Email', allow_nil: false)
      if email.nil?
        raise PaystackSdk::MissingParamError.new(name) unless allow_nil

        return
      end

      return if email.to_s.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)

      raise PaystackSdk::InvalidFormatError.new(name, 'valid email address')
    end

    # Validates a currency code format.
    #
    # @param currency [String] The currency code to validate
    # @param name [String] Name of the parameter for error messages
    # @param allow_nil [Boolean] Whether nil values are allowed
    # @raise [PaystackSdk::Error] If currency format is invalid
    def validate_currency!(currency:, name: 'Currency', allow_nil: true)
      if currency.nil?
        raise PaystackSdk::MissingParamError.new(name) unless allow_nil

        return
      end

      return if currency.to_s.match?(/\A[A-Z]{3}\z/)

      raise PaystackSdk::InvalidFormatError.new(name, '3-letter ISO code (e.g., NGN, USD, GHS)')
    end

    # Validates multiple fields at once.
    #
    # @param payload [Hash] The payload containing fields to validate
    # @param validations [Hash] Mapping of field names to validation options
    # @raise [PaystackSdk::Error] If any validation fails
    #
    # @example
    # ```ruby
    #   validate_fields!(
    #     payload: params,
    #     validations: {
    #       email: { type: :email, required: true },
    #       amount: { type: :positive_integer, required: true },
    #       currency: { type: :currency, required: false },
    #       reference: { type: :reference, required: false }
    #     }
    #   )
    # ```
    def validate_fields!(payload:, validations:)
      validate_hash!(input: payload, name: 'Payload')

      # First check required fields
      required_fields = validations.select { |_, opts| opts[:required] }.keys
      validate_required_params!(payload: payload, required_params: required_fields) unless required_fields.empty?

      # Then validate each field
      validations.each do |field, options|
        value = payload[field] || payload[field.to_s]
        next if value.nil? && !options[:required]

        case options[:type]
        when :email
          validate_email!(email: value, name: field.to_s.capitalize, allow_nil: !options[:required])
        when :positive_integer
          validate_positive_integer!(value: value, name: field.to_s, allow_nil: !options[:required])
        when :reference
          validate_reference_format!(reference: value, name: field.to_s) if value
        when :date
          validate_date_format!(date_str: value, name: field.to_s, allow_nil: !options[:required])
        when :currency
          validate_currency!(currency: value, name: field.to_s, allow_nil: !options[:required])
        when :inclusion
          if value
            validate_allowed_values!(
              value: value,
              allowed_values: options[:allowed_values],
              name: field.to_s,
              allow_nil: !options[:required]
            )
          end
        when :string
          validate_presence!(value: value, name: field.to_s) if !options[:allow_nil] && options[:required]
        end
      end
    end
  end
end
