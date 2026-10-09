# frozen_string_literal: true

require_relative "../middleware/transport_errors"

module PaystackSdk
  module Utils
    # The `ConnectionUtils` module provides shared functionality for creating
    # and initializing API connections. This is used by both the Client class
    # and resource classes.
    module ConnectionUtils
      # The base URL for the Paystack API.
      BASE_URL = "https://api.paystack.co"

      # Seconds to wait for the connection to open.
      DEFAULT_OPEN_TIMEOUT = 5

      # Seconds to wait for a response.
      DEFAULT_TIMEOUT = 30

      # Retries performed after the initial attempt.
      DEFAULT_MAX_RETRIES = 2

      # Base delay in seconds before the first retry (doubles each attempt).
      DEFAULT_RETRY_INTERVAL = 0.5

      # HTTP methods that only read data and are always safe to repeat.
      SAFE_METHODS = %i[get head options].freeze

      # Statuses worth retrying. 500 is excluded because it usually means a
      # bug, not a transient fault.
      RETRY_STATUSES = [429, 502, 503, 504].freeze

      # Longest pause (seconds) between retries. If Paystack asks for a longer
      # wait via `x-ratelimit-reset`, the request is not retried and the
      # error is raised so the caller can decide.
      MAX_RETRY_WAIT = 10

      # Response header Paystack uses to say when the rate-limit window ends.
      # @see https://paystack.com/docs/api/rate-limits/
      RATE_LIMIT_RESET_HEADER = "x-ratelimit-reset"

      # Initializes a connection based on the provided parameters.
      #
      # @param connection [Faraday::Connection, nil] An existing connection object.
      # @param secret_key [String, nil] Optional API key to use for creating a new connection.
      # @param options [Hash] Connection options, see {#create_connection}.
      # @return [Faraday::Connection] A connection object for API requests.
      # @raise [PaystackSdk::Error] If no connection or API key can be found.
      def initialize_connection(connection = nil, secret_key: nil, **options)
        if connection
          unless options.empty?
            raise ArgumentError,
              "#{options.keys.join(", ")} cannot be used with a pre-built connection; configure the connection itself"
          end

          connection
        elsif secret_key
          create_connection(secret_key:, **options)
        else
          # Try to get API key from environment variable
          env_secret_key = ENV["PAYSTACK_SECRET_KEY"]
          raise AuthenticationError, "No connection or API key provided" unless env_secret_key

          create_connection(secret_key: env_secret_key, **options)
        end
      end

      # Creates a new Faraday connection with the Paystack API.
      #
      # Requests time out and are retried with exponential backoff on network
      # failures and on 429/502/503/504 responses. Because this SDK moves
      # money, retries are deliberately conservative:
      #
      # * Read-only requests (GET/HEAD/OPTIONS) are retried on any of the above.
      # * Every other request is retried only on 429, where Paystack has
      #   rejected it for exceeding the rate limit. A timeout or 5xx on a
      #   write could mean it was processed, so it is never retried unless you
      #   pass `retry_non_idempotent: true`.
      #
      # On a 429 the wait honours Paystack's `x-ratelimit-reset` header.
      #
      # @param secret_key [String] The secret API key for authenticating with the Paystack API.
      # @param timeout [Numeric] Seconds to wait for a response.
      # @param open_timeout [Numeric] Seconds to wait for the connection to open.
      # @param max_retries [Integer] Retries after the first attempt (0 disables retrying).
      # @param retry_interval [Numeric] Base delay in seconds before the first retry.
      # @param retry_non_idempotent [Boolean] Also retry writes on network failures and 5xx.
      #   Only enable this if you supply your own deduplication (e.g. verify by reference).
      # @return [Faraday::Connection] A configured Faraday connection.
      def create_connection(secret_key:, timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_OPEN_TIMEOUT,
        max_retries: DEFAULT_MAX_RETRIES, retry_interval: DEFAULT_RETRY_INTERVAL,
        retry_non_idempotent: false)
        validate_connection_options!(timeout:, open_timeout:, max_retries:, retry_interval:)

        connection = Faraday.new(url: BASE_URL, request: {timeout:, open_timeout:}) do |conn|
          conn.use Middleware::TransportErrors
          if max_retries > 0
            conn.request :retry, retry_options(max_retries, retry_interval, retry_non_idempotent)
          end
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.headers["Authorization"] = "Bearer #{secret_key}"
          conn.headers["Content-Type"] = "application/json"
          conn.headers["User-Agent"] = "paystack_sdk/#{PaystackSdk::VERSION}"
          conn.adapter Faraday.default_adapter
        end
        redact_secret_key(connection)
      end

      private

      # Faraday's default `inspect` prints the headers, and so the secret key. Replace it, on the
      # connection and on its headers, so logging or `pp` of either never writes the key out.
      def redact_secret_key(connection)
        connection.define_singleton_method(:inspect) { "#<#{self.class.name} #{url_prefix}>" }
        connection.headers.define_singleton_method(:inspect) do
          to_h.merge("Authorization" => "[REDACTED]").inspect
        end
        connection
      end

      def validate_connection_options!(timeout:, open_timeout:, max_retries:, retry_interval:)
        {timeout:, open_timeout:}.each do |name, value|
          raise ArgumentError, "#{name} must be a positive number" unless value.is_a?(Numeric) && value > 0
        end
        raise ArgumentError, "max_retries must be a non-negative Integer" unless max_retries.is_a?(Integer) && max_retries >= 0
        raise ArgumentError, "retry_interval must be a non-negative number" unless retry_interval.is_a?(Numeric) && retry_interval >= 0
      end

      def retry_options(max_retries, retry_interval, retry_non_idempotent)
        {
          max: max_retries,
          interval: retry_interval,
          interval_randomness: 0.5,
          backoff_factor: 2,
          max_interval: MAX_RETRY_WAIT,
          rate_limit_reset_header: RATE_LIMIT_RESET_HEADER,
          retry_statuses: RETRY_STATUSES,
          methods: [],
          exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed],
          retry_if: ->(env, exception) { retryable_request?(env, exception, retry_non_idempotent) }
        }
      end

      def retryable_request?(env, exception, retry_non_idempotent)
        return true if SAFE_METHODS.include?(env.method)
        return true if retry_non_idempotent

        # Writes: only when Paystack rejected the request for rate limiting.
        exception.is_a?(Faraday::RetriableResponse) && env.status == 429
      end
    end
  end
end
