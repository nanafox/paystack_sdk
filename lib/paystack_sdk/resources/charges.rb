# frozen_string_literal: true

require_relative "base"

module PaystackSdk
  module Resources
    # The `Charges` resource exposes helpers for initiating and managing charges
    # through alternative payment channels such as Mobile Money.
    #
    # At the moment the SDK focuses on supporting the Mobile Money channel which
    # requires posting to the `/charge` endpoint with the customer's email,
    # amount, currency, and the provider specific `mobile_money` payload.
    class Charges < PaystackSdk::Resources::Base
      MOBILE_MONEY_PROVIDERS = %w[mtn atl vod mpesa orange wave].freeze

      # Initiates a Mobile Money payment.
      #
      # @param payload [Hash] The payload containing charge details.
      # @option payload [String] :email Customer's email address (required)
      # @option payload [Integer] :amount Amount in the lowest currency unit (required)
      # @option payload [String] :currency ISO currency code (default: GHS)
      # @option payload [String] :reference Optional reference supplied by the merchant
      # @option payload [String] :callback_url Optional callback URL for Paystack to redirect to
      # @option payload [Hash] :metadata Optional metadata to attach to the transaction
      # @option payload [Hash] :mobile_money The mobile money details (required)
      #   - :phone [String] Customer's mobile money phone number (required)
      #   - :provider [String] Mobile money provider code (required)
      #
      # @return [PaystackSdk::Response] The wrapped API response.
      # @raise [PaystackSdk::ValidationError] If the payload is invalid.
      def mobile_money(payload)
        validate_mobile_money_payload!(payload)

        response = @connection.post("/charge", payload)
        handle_response(response)
      end

      # Submits an OTP for authorising a pending Mobile Money charge (e.g. Vodafone).
      #
      # @param payload [Hash] Payload containing the OTP and charge reference.
      # @option payload [String] :otp The OTP supplied by the customer (required)
      # @option payload [String] :reference The charge reference returned from initiation (required)
      #
      # @return [PaystackSdk::Response] The wrapped API response.
      # @raise [PaystackSdk::ValidationError] If the payload is invalid.
      def submit_otp(payload)
        validate_fields!(
          payload: payload,
          validations: {
            otp: {type: :string, required: true},
            reference: {type: :reference, required: true}
          }
        )

        response = @connection.post("/charge/submit_otp", payload)
        handle_response(response)
      end

      private

      def validate_mobile_money_payload!(payload)
        validate_fields!(
          payload: payload,
          validations: {
            email: {type: :email, required: true},
            amount: {type: :positive_integer, required: true},
            currency: {type: :currency, required: false},
            reference: {type: :reference, required: false},
            callback_url: {required: false},
            metadata: {required: false},
            mobile_money: {required: true}
          }
        )

        mobile_money = payload[:mobile_money] || payload["mobile_money"]
        validate_hash!(input: mobile_money, name: "mobile_money")

        phone = mobile_money[:phone] || mobile_money["phone"]
        validate_presence!(value: phone, name: "mobile_money phone")

        provider = mobile_money[:provider] || mobile_money["provider"]
        validate_mobile_money_provider!(provider)
      end

      def validate_mobile_money_provider!(provider)
        validate_allowed_values!(
          value: provider&.downcase,
          allowed_values: MOBILE_MONEY_PROVIDERS,
          name: "mobile_money provider",
          allow_nil: false
        )
      end
    end
  end
end
