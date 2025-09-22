# frozen_string_literal: true

require_relative "base"

module PaystackSdk
  module Resources
    # The `Transactions` class provides methods for interacting with the Paystack
    #  Transactions API.
    # It allows you to initialize transactions, verify payments, list transactions, and fetch transaction details.
    # The Transactions class provides methods to interact with the Paystack API for managing transactions.
    # It includes functionalities for initializing, verifying, listing, fetching, and retrieving transaction totals.
    #
    # Example usage:
    # ```ruby
    #   transactions = PaystackSdk::Resources::Transactions.new(secret_key:)
    #
    #   # Initialize a transaction
    #   payload = { email: "customer@email.com", amount: 10000, currency: "GHS" }
    #   response = transactions.initiate(payload)
    #   if response.success?
    #     puts "Transaction initialized successfully."
    #     puts "Authorization URL: #{response.authorization_url}"
    #   else
    #     puts "Error initializing transaction: #{response.error_message}"
    #   end
    #
    #   # Verify a transaction
    #   response = transactions.verify(reference: "transaction_reference")
    #   if response.status == "success"
    #     puts "The payment with reference '#{response.reference}' is verified"
    #   else
    #     puts "Current status: #{response.status}"
    #   end
    #
    #   # List transactions
    #   response = transactions.list(per_page: 50, page: 1)
    #
    #   # Fetch a single transaction
    #   response = transactions.fetch(transaction_id: 12345)
    #
    #   # Get transaction totals
    #   response = transactions.totals
    # ```
    class Transactions < PaystackSdk::Resources::Base
      # Initializes a new transaction.
      #
      # @param payload [Hash] The payload containing transaction details (e.g., email, amount, currency).
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the payload is invalid or the API request fails.
      #
      # @example
      # ```ruby
      #   payload = { email: "customer@email.com", amount: 10000, currency: "GHS" }
      #   response = transactions.initiate(payload)
      # ```
      def initiate(payload)
        validate_fields!(
          payload: payload,
          validations: {
            email: {type: :email, required: true},
            amount: {type: :positive_integer, required: true},
            currency: {type: :currency, required: false},
            reference: {type: :reference, required: false},
            callback_url: {required: false}
          }
        )

        response = @connection.post("/transaction/initialize", payload)
        handle_response(response)
      end

      # Verifies a transaction using its reference.
      #
      # @param reference [String] The unique reference for the transaction.
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.verify(reference: "transaction_reference")
      def verify(reference:)
        validate_presence!(value: reference, name: "Reference")

        response = @connection.get("/transaction/verify/#{reference}")
        handle_response(response)
      end

      # Lists all transactions.
      #
      # @param per_page [Integer] Number of records per page (default: 50)
      # @param page [Integer] Page number to retrieve (default: 1)
      # @param from [String] A timestamp from which to start listing transactions e.g. 2016-09-24T00:00:05.000Z, 2016-09-21
      # @param to [String] A timestamp at which to stop listing transactions e.g. 2016-09-24T00:00:05.000Z, 2016-09-21
      # @param status [String] Filter transactions by status ('failed', 'success', 'abandoned')
      # @param customer [Integer] Specify an ID for the customer whose transactions you want to retrieve
      # @param currency [String] Specify the transaction currency to filter
      # @param amount [Integer] Filter by transaction amount
      # @return [PaystackSdk::Response] The response from the Paystack API containing a
      # list of transactions.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.list(per_page: 20, page: 2)
      #   # With filters
      #   response = transactions.list(per_page: 10, from: "2023-01-01", to: "2023-12-31", status: "success")
      def list(per_page: 50, page: 1, **params)
        # Create a combined parameter hash for validation
        all_params = {per_page: per_page, page: page}.merge(params)

        # Validate parameters
        validate_fields!(
          payload: all_params,
          validations: {
            per_page: {type: :positive_integer, required: false},
            page: {type: :positive_integer, required: false},
            from: {type: :date, required: false},
            to: {type: :date, required: false},
            status: {type: :inclusion, allowed_values: %w[failed success abandoned], required: false},
            customer: {type: :positive_integer, required: false},
            amount: {type: :positive_integer, required: false},
            currency: {type: :currency, required: false}
          }
        )

        # Prepare request parameters
        request_params = {perPage: per_page, page: page}.merge(params)
        response = @connection.get("/transaction", request_params)
        handle_response(response)
      end

      # Fetches details of a single transaction by its ID.
      #
      # @param transaction_id [String, Integer] The ID of the transaction to fetch.
      # @return [PaystackSdk::Response] The response from the Paystack API containing transaction details.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.fetch("12345")
      def fetch(transaction_id)
        validate_presence!(value: transaction_id, name: "Transaction ID")

        response = @connection.get("/transaction/#{transaction_id}")
        handle_response(response)
      end

      # Fetches the totals of all transactions.
      #
      # @param from [String] A timestamp from which to start listing transaction totals e.g. 2016-09-24T00:00:05.000Z, 2016-09-21
      # @param to [String] A timestamp at which to stop listing transaction totals e.g. 2016-09-24T00:00:05.000Z, 2016-09-21
      # @return [PaystackSdk::Response] The response from the Paystack API containing transaction totals.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.totals
      #   # With date filters
      #   response = transactions.totals(from: "2023-01-01", to: "2023-12-31")
      def totals(**params)
        validate_fields!(
          payload: params,
          validations: {
            from: {type: :date, required: false},
            to: {type: :date, required: false}
          }
        )

        response = @connection.get("/transaction/totals", params)
        handle_response(response)
      end

      # Exports transactions as a downloadable file.
      #
      # @param from [String] A timestamp from which to start the export e.g. 2016-09-24T00:00:05.000Z, 2016-09-21
      # @param to [String] A timestamp at which to stop the export e.g. 2016-09-24T00:00:05.000Z, 2016-09-21
      # @param status [String] Export only transactions with a specific status ('failed', 'success', 'abandoned')
      # @param currency [String] Specify the transaction currency to export
      # @param amount [Integer] Filter by transaction amount
      # @param settled [Boolean] Set to true to export only settled transactions
      # @param payment_page [Integer] Specify a payment page ID to export only transactions conducted through the page
      # @param customer [Integer] Specify an ID for the customer whose transactions you want to export
      # @param settlement [Integer] Specify a settlement ID to export only transactions in the settlement
      # @return [PaystackSdk::Response] The response from the Paystack API containing the export details.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.export
      #   # With filters
      #   response = transactions.export(from: "2023-01-01", to: "2023-12-31", status: "success", currency: "NGN")
      def export(**params)
        validate_fields!(
          payload: params,
          validations: {
            from: {type: :date, required: false},
            to: {type: :date, required: false},
            status: {type: :inclusion, allowed_values: %w[failed success abandoned], required: false},
            currency: {type: :currency, required: false},
            amount: {type: :positive_integer, required: false},
            payment_page: {type: :positive_integer, required: false},
            customer: {type: :positive_integer, required: false},
            settlement: {type: :positive_integer, required: false}
          }
        )

        response = @connection.get("/transaction/export", params)
        handle_response(response)
      end

      # Charges an authorization code for subsequent payments.
      #
      # @param payload [Hash] The payload containing charge details.
      # @option payload [String] :authorization_code Authorization code for the transaction (required)
      # @option payload [String] :email Customer's email address (required)
      # @option payload [Integer] :amount Amount in kobo, pesewas, or cents to charge (required)
      # @option payload [String] :reference Unique transaction reference. Only -, ., = and alphanumeric characters allowed
      # @option payload [String] :currency Currency in which amount should be charged (default: NGN)
      # @option payload [Hash] :metadata Additional transaction information
      # @option payload [Array<Hash>] :split_code Split payment among multiple accounts
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the payload is invalid or the API request fails.
      #
      # @example
      #   payload = {
      #     authorization_code: "AUTH_72btv547",
      #     email: "customer@email.com",
      #     amount: 10000
      #   }
      #   response = transactions.charge_authorization(payload)
      def charge_authorization(payload)
        validate_fields!(
          payload: payload,
          validations: {
            authorization_code: {required: true},
            email: {type: :email, required: true},
            amount: {type: :positive_integer, required: true},
            reference: {type: :reference, required: false},
            currency: {type: :currency, required: false}
          }
        )

        response = @connection.post("/transaction/charge_authorization", payload)
        handle_response(response)
      end

      # Performs a partial debit on a customer's account.
      #
      # @param payload [Hash] The payload containing partial debit details.
      # @option payload [String] :authorization_code Authorization code for the transaction (required)
      # @option payload [String] :currency Currency in which amount should be charged (required)
      # @option payload [Integer] :amount Amount in kobo, pesewas, or cents to charge (required)
      # @option payload [String] :email Customer's email address (required)
      # @option payload [String] :reference Unique transaction reference. Only -, ., = and alphanumeric characters allowed
      # @option payload [Hash] :metadata Additional transaction information
      # @option payload [Array<Hash>] :split_code Split payment among multiple accounts
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If the payload is invalid or the API request fails.
      #
      # @example
      #   payload = {
      #     authorization_code: "AUTH_72btv547",
      #     currency: "NGN",
      #     amount: 10000,
      #     email: "customer@email.com"
      #   }
      #   response = transactions.partial_debit(payload)
      def partial_debit(payload)
        validate_fields!(
          payload: payload,
          validations: {
            authorization_code: {required: true},
            currency: {type: :currency, required: true},
            amount: {type: :positive_integer, required: true},
            email: {type: :email, required: true},
            reference: {type: :reference, required: false}
          }
        )

        response = @connection.post("/transaction/partial_debit", payload)
        handle_response(response)
      end

      # View the timeline of a transaction
      #
      # @param id_or_reference [String] The ID or reference of the transaction
      # @return [PaystackSdk::Response] The response from the Paystack API containing timeline details.
      # @raise [PaystackSdk::Error] If the API request fails.
      #
      # @example
      #   response = transactions.timeline("12345")
      #   # OR
      #   response = transactions.timeline("ref_123456789")
      def timeline(id_or_reference)
        validate_presence!(value: id_or_reference, name: "Transaction ID or Reference")

        response = @connection.get("/transaction/timeline/#{id_or_reference}")
        handle_response(response)
      end
    end
  end
end
