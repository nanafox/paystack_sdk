# frozen_string_literal: true

module PaystackSdk
  module Resources
    module Extensions
      # Hand-written additions to {PaystackSdk::Resources::Charges}, which bin/paystack-scaffold
      # generates from Paystack's OpenAPI spec and includes this module into.
      module Charges
        # The provider codes Paystack documents for the `mobile_money` object.
        #
        # @see https://paystack.com/docs/api/charge/#create
        # @see https://paystack.com/docs/payments/payment-channels/#mobile-money
        MOBILE_MONEY_PROVIDERS = %w[mtn atl vod mpesa orange wave mpesa_offline mptill].freeze

        # Charges a mobile money wallet: a {#create} call with a checked `mobile_money` object.
        #
        # Mobile money is available to businesses in Ghana, Kenya and Côte d'Ivoire. The charge usually
        # comes back with status `pay_offline` (the customer approves it on their phone; show them
        # `display_text` and wait for the `charge.success` webhook) or `send_otp` (collect the OTP and
        # call {#submit_otp}).
        #
        # @param email [String] Customer's email address
        # @param amount [Integer] Amount in the subunit of the currency (pesewas, cents)
        # @param mobile_money [Hash] The wallet to charge, with symbol or string keys:
        #   `phone` (the customer's number) or, for M-PESA Till (`mptill`), `account` (the till number),
        #   and `provider`, one of {MOBILE_MONEY_PROVIDERS} in any case (sent in lowercase).
        # @param currency [String, nil] 3-letter currency code, e.g. GHS or KES; Paystack uses your
        #   integration's currency when it is left out.
        # @param reference [String, nil] Unique transaction reference
        # @param metadata [Hash, nil] Custom data for your post-payment processes
        # @return [PaystackSdk::Response] The response from the Paystack API.
        # @raise [PaystackSdk::Error] If a parameter is invalid or the API request fails.
        # @see https://paystack.com/docs/payments/payment-channels/#mobile-money
        def mobile_money(email:, amount:, mobile_money:, currency: nil, reference: nil, metadata: nil)
          wallet = checked_mobile_money(mobile_money)
          validate_currency!(currency: currency, name: "currency")

          create(email:, amount:, currency:, reference:, metadata:, mobile_money: wallet)
        end

        private

        # Checks the `mobile_money` object and returns a copy with symbol keys and a lowercase provider.
        # The caller's hash is never changed.
        def checked_mobile_money(details)
          validate_presence!(value: details, name: "mobile_money")
          validate_hash!(input: details, name: "mobile_money")

          wallet = details.transform_keys(&:to_sym)
          validate_presence!(value: wallet[:phone] || wallet[:account], name: "mobile_money phone (or account)")

          provider = wallet[:provider]&.to_s&.downcase
          validate_allowed_values!(
            value: provider,
            allowed_values: MOBILE_MONEY_PROVIDERS,
            name: "mobile_money provider",
            allow_nil: false
          )

          wallet.merge(provider: provider)
        end
      end
    end
  end
end
