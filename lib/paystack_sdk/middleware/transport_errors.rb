# frozen_string_literal: true

module PaystackSdk
  module Middleware
    # Translates low-level Faraday transport failures into SDK errors so that
    # `rescue PaystackSdk::Error` catches them. It sits outside the retry
    # middleware, so it only sees failures that survived all retries.
    class TransportErrors < Faraday::Middleware
      def call(env)
        @app.call(env)
      rescue Faraday::TimeoutError => e
        raise PaystackSdk::TimeoutError, "Request to Paystack timed out: #{e.message}"
      rescue Faraday::ConnectionFailed, Faraday::SSLError => e
        # Connect-phase timeouts (Net::OpenTimeout) surface as ConnectionFailed.
        if e.cause.is_a?(::Timeout::Error)
          raise PaystackSdk::TimeoutError, "Connecting to Paystack timed out: #{e.message}"
        end

        raise PaystackSdk::ConnectionError, "Could not connect to Paystack: #{e.message}"
      end
    end
  end
end
