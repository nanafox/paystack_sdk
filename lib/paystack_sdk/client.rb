# frozen_string_literal: true

require_relative "resources/transactions"
require_relative "resources/customers"
require_relative "resources/transfer_recipients"
require_relative "resources/transfers"
require_relative "resources/banks"
require_relative "resources/charges"
require_relative "resources/miscellaneous"
require_relative "resources/refunds"
require_relative "resources/settlements"
require_relative "resources/splits"
require_relative "resources/disputes"
require_relative "resources/subaccounts"
require_relative "resources/balances"
require_relative "resources/plans"
require_relative "resources/subscriptions"
require_relative "resources/dedicated_virtual_accounts"
require_relative "resources/payment_requests"
require_relative "resources/pages"
require_relative "resources/products"
require_relative "resources/orders"
require_relative "resources/storefronts"
require_relative "resources/bulk_charges"
require_relative "resources/apple_pay"
require_relative "resources/integrations"
require_relative "resources/virtual_terminals"
require_relative "resources/direct_debits"
require_relative "utils/connection_utils"

module PaystackSdk
  # The `Client` class serves as the main entry point for interacting with the Paystack API.
  # It initializes a connection to the Paystack API and provides access to various resources.
  class Client
    # Include connection utilities
    include Utils::ConnectionUtils

    # Prefix of Paystack's test and live secret keys.
    TEST_KEY_PREFIX = "sk_test_"
    LIVE_KEY_PREFIX = "sk_live_"

    # @return [Faraday::Connection] The Faraday connection object used for API requests
    attr_reader :connection

    # Initializes a new `Client` instance.
    #
    # @param connection [Faraday::Connection, nil] The Faraday connection object used for API requests.
    #   If nil, a new connection will be created using the default API key.
    # @param secret_key [String, nil] Optional API key to use for creating a new connection.
    #   Only used if connection is nil.
    # @param sandbox_only [Boolean] Refuse to build a client unless the key is a test key
    #   (`sk_test_...`). Set this in staging and CI so they can never charge real money.
    # @raise [ArgumentError] If `sandbox_only` is true and the key is not a test key.
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
    # @example Refuse live keys (staging, CI)
    #   client = PaystackSdk::Client.new(secret_key: ENV["PAYSTACK_SECRET_KEY"], sandbox_only: true)
    def initialize(connection = nil, secret_key: nil, sandbox_only: false, **options)
      if sandbox_only
        key = connection ? key_from(connection) : (secret_key || ENV["PAYSTACK_SECRET_KEY"])
        unless key.to_s.start_with?(TEST_KEY_PREFIX)
          raise ArgumentError, "sandbox_only is set, but the secret key is not a test key (#{TEST_KEY_PREFIX}...)"
        end
      end

      @connection = initialize_connection(connection, secret_key: secret_key, **options)
    end

    # Whether this client is using a live key (`sk_live_...`), so requests move real money.
    # A test key, or a key in any other form, is not live.
    #
    # @return [Boolean]
    def live?
      key_from(@connection).to_s.start_with?(LIVE_KEY_PREFIX)
    end

    # Provides access to the `Transactions` resource.
    #
    # @return [PaystackSdk::Resources::Transactions] An instance of the
    #  `Transactions` resource.
    #
    # @example
    # ```ruby
    #   transactions = client.transactions
    #   response = transactions.initiate(email: "ama@example.com", amount: 10000)
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
    #   response = recipients.create(type: "nuban", name: "Ama Mensah", account_number: "0123456789", bank_code: "058")
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
    #   response = transfers.create(source: "balance", amount: 100_000, recipient: "RCP_xxx", reference: "payout-2025-0001-ama")
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
    #   response = banks.list(country: "nigeria")
    # ```
    def banks
      @banks ||= Resources::Banks.new(@connection)
    end

    # Provides access to the `Charges` resource.
    #
    # @return [PaystackSdk::Resources::Charges] An instance of the
    #  `Charges` resource.
    #
    # @example
    # ```ruby
    #   charges = client.charges
    #   response = charges.mobile_money(
    #     email: "ama@example.com",
    #     amount: 10000,
    #     mobile_money: {phone: "0551234987", provider: "mtn"}
    #   )
    # ```
    def charges
      @charges ||= Resources::Charges.new(@connection)
    end

    # Provides access to the `Miscellaneous` resource.
    #
    # @return [PaystackSdk::Resources::Miscellaneous] An instance of the
    #  `Miscellaneous` resource.
    #
    # @example
    # ```ruby
    #   response = client.miscellaneous.resolve_card_bin(bin: "539983")
    # ```
    def miscellaneous
      @miscellaneous ||= Resources::Miscellaneous.new(@connection)
    end

    # Provides access to the `Refunds` resource.
    #
    # @return [PaystackSdk::Resources::Refunds] An instance of the
    #  `Refunds` resource.
    def refunds
      @refunds ||= Resources::Refunds.new(@connection)
    end

    # Provides access to the `Settlements` resource.
    #
    # @return [PaystackSdk::Resources::Settlements] An instance of the
    #  `Settlements` resource.
    def settlements
      @settlements ||= Resources::Settlements.new(@connection)
    end

    # Provides access to the `Splits` resource.
    #
    # @return [PaystackSdk::Resources::Splits] An instance of the
    #  `Splits` resource.
    def splits
      @splits ||= Resources::Splits.new(@connection)
    end

    # Provides access to the `Disputes` resource.
    #
    # @return [PaystackSdk::Resources::Disputes] An instance of the
    #  `Disputes` resource.
    def disputes
      @disputes ||= Resources::Disputes.new(@connection)
    end

    # Provides access to the `Subaccounts` resource.
    #
    # @return [PaystackSdk::Resources::Subaccounts] An instance of the
    #  `Subaccounts` resource.
    def subaccounts
      @subaccounts ||= Resources::Subaccounts.new(@connection)
    end

    # Provides access to the `Balances` resource.
    #
    # @return [PaystackSdk::Resources::Balances] An instance of the
    #  `Balances` resource.
    def balances
      @balances ||= Resources::Balances.new(@connection)
    end

    # Provides access to the `Plans` resource.
    #
    # @return [PaystackSdk::Resources::Plans] An instance of the
    #  `Plans` resource.
    def plans
      @plans ||= Resources::Plans.new(@connection)
    end

    # Provides access to the `Subscriptions` resource.
    #
    # @return [PaystackSdk::Resources::Subscriptions] An instance of the
    #  `Subscriptions` resource.
    def subscriptions
      @subscriptions ||= Resources::Subscriptions.new(@connection)
    end

    # Provides access to the `DedicatedVirtualAccounts` resource.
    #
    # @return [PaystackSdk::Resources::DedicatedVirtualAccounts] An instance of the
    #  `DedicatedVirtualAccounts` resource.
    def dedicated_virtual_accounts
      @dedicated_virtual_accounts ||= Resources::DedicatedVirtualAccounts.new(@connection)
    end

    # Provides access to the `PaymentRequests` resource.
    #
    # @return [PaystackSdk::Resources::PaymentRequests] An instance of the
    #  `PaymentRequests` resource.
    def payment_requests
      @payment_requests ||= Resources::PaymentRequests.new(@connection)
    end

    # Provides access to the `Pages` resource.
    #
    # @return [PaystackSdk::Resources::Pages] An instance of the
    #  `Pages` resource.
    def pages
      @pages ||= Resources::Pages.new(@connection)
    end

    # Provides access to the `Products` resource.
    #
    # @return [PaystackSdk::Resources::Products] An instance of the
    #  `Products` resource.
    def products
      @products ||= Resources::Products.new(@connection)
    end

    # Provides access to the `Orders` resource.
    #
    # @return [PaystackSdk::Resources::Orders] An instance of the
    #  `Orders` resource.
    def orders
      @orders ||= Resources::Orders.new(@connection)
    end

    # Provides access to the `Storefronts` resource.
    #
    # @return [PaystackSdk::Resources::Storefronts] An instance of the
    #  `Storefronts` resource.
    def storefronts
      @storefronts ||= Resources::Storefronts.new(@connection)
    end

    # Provides access to the `BulkCharges` resource.
    #
    # @return [PaystackSdk::Resources::BulkCharges] An instance of the
    #  `BulkCharges` resource.
    def bulk_charges
      @bulk_charges ||= Resources::BulkCharges.new(@connection)
    end

    # Provides access to the `ApplePay` resource.
    #
    # @return [PaystackSdk::Resources::ApplePay] An instance of the
    #  `ApplePay` resource.
    def apple_pay
      @apple_pay ||= Resources::ApplePay.new(@connection)
    end

    # Provides access to the `Integrations` resource.
    #
    # @return [PaystackSdk::Resources::Integrations] An instance of the
    #  `Integrations` resource.
    def integrations
      @integrations ||= Resources::Integrations.new(@connection)
    end

    # Provides access to the `VirtualTerminals` resource.
    #
    # @return [PaystackSdk::Resources::VirtualTerminals] An instance of the
    #  `VirtualTerminals` resource.
    def virtual_terminals
      @virtual_terminals ||= Resources::VirtualTerminals.new(@connection)
    end

    # Provides access to the `DirectDebits` resource.
    #
    # @return [PaystackSdk::Resources::DirectDebits] An instance of the
    #  `DirectDebits` resource.
    def direct_debits
      @direct_debits ||= Resources::DirectDebits.new(@connection)
    end

    private

    # The secret key a connection sends, read from its Authorization header.
    def key_from(connection)
      connection.headers["Authorization"].to_s.delete_prefix("Bearer ")
    end
  end
end
