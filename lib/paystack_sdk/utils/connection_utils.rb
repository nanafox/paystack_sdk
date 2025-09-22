# frozen_string_literal: true

module PaystackSdk
  module Utils
    # The `ConnectionUtils` module provides shared functionality for creating
    # and initializing API connections. This is used by both the Client class
    # and resource classes.
    module ConnectionUtils
      # The base URL for the Paystack API.
      BASE_URL = "https://api.paystack.co"

      # Initializes a connection based on the provided parameters.
      #
      # @param connection [Faraday::Connection, nil] An existing connection object.
      # @param secret_key [String, nil] Optional API key to use for creating a new connection.
      # @return [Faraday::Connection] A connection object for API requests.
      # @raise [PaystackSdk::Error] If no connection or API key can be found.
      def initialize_connection(connection = nil, secret_key: nil)
        if connection
          connection
        elsif secret_key
          create_connection(secret_key:)
        else
          # Try to get API key from environment variable
          env_secret_key = ENV["PAYSTACK_SECRET_KEY"]
          raise AuthenticationError, "No connection or API key provided" unless env_secret_key

          create_connection(secret_key: env_secret_key)
        end
      end

      # Creates a new Faraday connection with the Paystack API.
      #
      # @param secret_key [String] The secret API key for authenticating with the Paystack API.
      # @return [Faraday::Connection] A configured Faraday connection.
      def create_connection(secret_key:)
        Faraday.new(url: BASE_URL) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.headers["Authorization"] = "Bearer #{secret_key}"
          conn.headers["Content-Type"] = "application/json"
          conn.headers["User-Agent"] = "paystack_sdk/#{PaystackSdk::VERSION}"
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
