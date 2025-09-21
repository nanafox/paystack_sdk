# frozen_string_literal: true

require_relative 'resources/transactions'
require_relative 'resources/customers'
require_relative 'resources/transfer_recipients'
require_relative 'resources/transfers'
require_relative 'resources/banks'
require_relative 'resources/verification'
require_relative 'resources/charges'
require_relative 'utils/connection_utils'

module PaystackSdk
  # The `Client` class serves as the main entry point for interacting with the Paystack API.
  # It initializes a connection to the Paystack API and provides access to various resources.
  class Client
    # Include connection utilities
    include Utils::ConnectionUtils

    # @return [Faraday::Connection] The Faraday connection object used for API requests
    attr_reader :connection

    # Initializes a new `Client` instance.
    #
    # @param connection [Faraday::Connection, nil] The Faraday connection object used for API requests.
    #   If nil, a new connection will be created using the default API key.
    # @param secret_key [String, nil] Optional API key to use for creating a new connection.
    #   Only used if connection is nil.
    #
    # @example With an existing connection
    #   connection = Faraday.new(...)
    #   client = PaystackSdk::Client.new(connection)
    #
    # @example With an API key
    #   client = PaystackSdk::Client.new(secret_key: "sk_test_xxx")
    #
    # @example With default connection (requires PAYSTACK_SECRET_KEY environment variable)
    #   client = PaystackSdk::Client.new
    def initialize(connection = nil, secret_key: nil)
      @connection = initialize_connection(connection, secret_key: secret_key)
    end

    # Provides access to the `Transactions` resource.
    #
    # @return [PaystackSdk::Resources::Transactions] An instance of the
    #  `Transactions` resource.
    #
    # @example
    # ```ruby
    #   transactions = client.transactions
    #   response = transactions.initiate(params)
    # ```
    def transactions
      @transactions ||= Resources::Transactions.new(@connection)
    end

    # Provides access to the `Customers` resource.
    #
    # @return [PaystackSdk::Resources::Customers] An instance of the
    #  `Customers` resource.
    #
    # @example
    # ```ruby
    #   customers = client.customers
    #   response = customers.list
    # ```
    def customers
      @customers ||= Resources::Customers.new(@connection)
    end

    # Provides access to the `TransferRecipients` resource.
    #
    # @return [PaystackSdk::Resources::TransferRecipients] An instance of the
    #  `TransferRecipients` resource.
    #
    # @example
    # ```ruby
    #   recipients = client.transfer_recipients
    #   response = recipients.create(params)
    # ```
    def transfer_recipients
      @transfer_recipients ||= Resources::TransferRecipients.new(@connection)
    end

    # Provides access to the `Transfers` resource.
    #
    # @return [PaystackSdk::Resources::Transfers] An instance of the
    #  `Transfers` resource.
    #
    # @example
    # ```ruby
    #   transfers = client.transfers
    #   response = transfers.create(params)
    # ```
    def transfers
      @transfers ||= Resources::Transfers.new(@connection)
    end

    # Provides access to the `Banks` resource.
    #
    # @return [PaystackSdk::Resources::Banks] An instance of the
    #  `Banks` resource.
    #
    # @example
    # ```ruby
    #   banks = client.banks
    #   response = banks.list
    # ```
    def banks
      @banks ||= Resources::Banks.new(@connection)
    end

    # Provides access to the `Verification` resource.
    #
    # @return [PaystackSdk::Resources::Verification] An instance of the
    #  `Verification` resource.
    #
    # @example
    # ```ruby
    #   verification = client.verification
    #   response = verification.resolve_account(account_number: ..., bank_code: ...)
    # ```
    def verification
      @verification ||= Resources::Verification.new(@connection)
    end

    # Provides access to the `Charges` resource.
    #
    # @return [PaystackSdk::Resources::Charges] An instance of the
    #  `Charges` resource.
    #
    # @example
    # ```ruby
    #   charges = client.charges
    #   response = charges.mobile_money(payload)
    # ```
    def charges
      @charges ||= Resources::Charges.new(@connection)
    end
  end
end
