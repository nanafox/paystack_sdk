# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require_relative "paystack_sdk/version"
require_relative "paystack_sdk/client"
require_relative "paystack_sdk/webhook"

module PaystackSdk
  # Base error class for all Paystack SDK errors.
  # All SDK-specific exceptions inherit from this class.
  class Error < StandardError; end

  # Base class for all validation errors.
  # Raised when input parameters fail validation before API calls.
  class ValidationError < Error; end

  # Raised when a required parameter is missing.
  # Contains the parameter name for detailed error handling.
  class MissingParamError < ValidationError
    attr_reader :param_name

    def initialize(param_name)
      @param_name = param_name
      super("Missing required parameter: #{param_name}")
    end
  end

  # Raised when a parameter has an invalid format.
  # Contains both the parameter name and expected format for detailed error handling.
  class InvalidFormatError < ValidationError
    attr_reader :param_name, :expected_format

    def initialize(param_name, expected_format)
      @param_name = param_name
      @expected_format = expected_format
      super("Invalid format for #{param_name}. Expected format: #{expected_format}")
    end
  end

  # Raised when a parameter has an invalid value.
  # Contains both the parameter name and the reason for the invalid value.
  class InvalidValueError < ValidationError
    attr_reader :param_name, :reason

    def initialize(param_name, reason)
      @param_name = param_name
      @reason = reason
      super("Invalid value for #{param_name}: #{reason}")
    end
  end

  # Base class for API errors.
  # Raised when the Paystack API returns an error response.
  class APIError < Error; end

  # Raised when authentication fails
  class AuthenticationError < APIError
    def initialize(message = "Invalid API key or authentication failed")
      super
    end
  end

  # Raised when a resource is not found
  class ResourceNotFoundError < APIError
    attr_reader :resource_type

    def initialize(resource_type, message)
      @resource_type = resource_type
      super(message)
    end
  end

  # Raised when rate limiting is encountered
  class RateLimitError < APIError
    # @return [Integer, nil] Seconds until the rate-limit window ends, from the
    #   `x-ratelimit-reset` header, or nil if Paystack did not send it
    attr_reader :retry_after

    def initialize(retry_after = nil)
      @retry_after = retry_after
      super(retry_after ? "Rate limit exceeded. Retry after #{retry_after} seconds" : "Rate limit exceeded")
    end
  end

  # Raised when a request could not reach Paystack (DNS, refused, reset, ...)
  # after all retries were exhausted.
  class ConnectionError < Error; end

  # Raised when a request to Paystack timed out after all retries were exhausted.
  class TimeoutError < ConnectionError; end

  # Raised when the server returns a 5xx error
  class ServerError < APIError
    attr_reader :status_code

    def initialize(status_code, message = "An error occurred on the Paystack server")
      @status_code = status_code
      super("#{message} (Status: #{status_code})")
    end
  end

  # Base class for webhook errors.
  class WebhookError < Error; end

  # Raised when a webhook's signature does not match its payload.
  # Treat the request as not coming from Paystack.
  class InvalidSignatureError < WebhookError
    def initialize(message = "Webhook signature does not match the payload")
      super
    end
  end

  # Raised when a correctly signed webhook body is not a JSON event.
  class InvalidPayloadError < WebhookError; end
end
