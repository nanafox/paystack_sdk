# frozen_string_literal: true

require "json"
require "openssl"
require_relative "response"

module PaystackSdk
  # Helpers for receiving Paystack webhooks, independent of any web framework.
  #
  # Paystack signs every event with the `x-paystack-signature` header: a
  # lowercase hex HMAC SHA512 of the raw request body, using your secret key.
  # Verify it before doing anything with the event, and return a `200 OK`
  # quickly (do long work in a background job): events that are not
  # acknowledged are retried for 72 hours in live mode.
  #
  # @see https://paystack.com/docs/payments/webhooks/
  #
  # @example In a Rails controller
  # ```ruby
  #   def create
  #     event = PaystackSdk::Webhook.construct_event(
  #       payload: request.raw_post,
  #       signature: request.headers["X-Paystack-Signature"],
  #       secret: ENV.fetch("PAYSTACK_SECRET_KEY")
  #     )
  #     HandlePaystackEventJob.perform_later(event.payload)
  #     head :ok
  #   rescue PaystackSdk::WebhookError
  #     head :bad_request
  #   end
  # ```
  module Webhook
    # Header Paystack puts the signature in. Rack and Rails expose it as
    # `HTTP_X_PAYSTACK_SIGNATURE` or `request.headers["X-Paystack-Signature"]`.
    SIGNATURE_HEADER = "x-paystack-signature"

    # The only addresses Paystack sends webhooks from, for both test and live.
    IP_ADDRESSES = %w[52.31.139.75 52.49.173.169 52.214.14.220].freeze

    # Events Paystack documents. Paystack adds events over time, so an event
    # outside this list is still returned by {Webhook.construct_event}.
    EVENTS = %w[
      charge.dispute.create charge.dispute.remind charge.dispute.resolve charge.success
      customeridentification.failed customeridentification.success
      dedicatedaccount.assign.failed dedicatedaccount.assign.success
      invoice.create invoice.payment_failed invoice.update
      paymentrequest.pending paymentrequest.success
      refund.failed refund.pending refund.processed refund.processing
      subscription.create subscription.disable subscription.expiring_cards subscription.not_renew
      transfer.failed transfer.reversed transfer.success
    ].freeze

    # A verified webhook event.
    class Event
      # @return [String] The event name, e.g. "charge.success"
      attr_reader :event

      # @return [Hash] The parsed JSON body, string-keyed
      attr_reader :payload

      def initialize(payload)
        @payload = payload
        @event = payload["event"]
      end

      # @return [PaystackSdk::Response, nil] The event's `data`, wrapped for dot and hash access
      def data
        return @data if defined?(@data)

        @data = payload.key?("data") ? Response.new(payload["data"]) : nil
      end

      # @return [Boolean] Whether Paystack documents this event name
      def known?
        EVENTS.include?(event)
      end
    end

    class << self
      # Computes the signature Paystack would send for a payload.
      # Mostly useful in your own tests.
      #
      # @param payload [String] The raw request body
      # @param secret [String] Your secret key
      # @return [String] Lowercase hex HMAC SHA512
      def sign(payload, secret)
        OpenSSL::HMAC.hexdigest("SHA512", secret, payload)
      end

      # Checks a webhook's signature in constant time.
      #
      # @param payload [String] The raw request body, byte for byte. Not a parsed
      #   or re-serialised version of it, which would not match.
      # @param signature [String, nil] The `x-paystack-signature` header value
      # @param secret [String] Your secret key
      # @return [Boolean]
      # @raise [ArgumentError] If the payload is not a String or the secret is blank
      def valid_signature?(payload:, signature:, secret:)
        unless payload.is_a?(String)
          raise ArgumentError, "payload must be the raw request body (a String), not a parsed or re-serialised copy"
        end
        raise ArgumentError, "secret must not be blank" if secret.nil? || secret.to_s.empty?

        expected = sign(payload, secret)
        return false unless signature.is_a?(String) && signature.bytesize == expected.bytesize

        OpenSSL.fixed_length_secure_compare(expected, signature)
      end

      # Like {valid_signature?} but raises when the signature is wrong.
      #
      # @return [true]
      # @raise [PaystackSdk::InvalidSignatureError]
      def verify!(payload:, signature:, secret:)
        raise InvalidSignatureError unless valid_signature?(payload: payload, signature: signature, secret: secret)

        true
      end

      # Verifies the signature, then parses the event. Nothing is parsed if the
      # signature is wrong.
      #
      # @return [PaystackSdk::Webhook::Event]
      # @raise [PaystackSdk::InvalidSignatureError] If the signature does not match
      # @raise [PaystackSdk::InvalidPayloadError] If the signed body is not a JSON event
      def construct_event(payload:, signature:, secret:)
        verify!(payload: payload, signature: signature, secret: secret)

        parsed = begin
          JSON.parse(payload)
        rescue JSON::ParserError
          raise InvalidPayloadError, "Webhook body is not valid JSON"
        end

        unless parsed.is_a?(Hash) && parsed["event"].is_a?(String) && !parsed["event"].empty?
          raise InvalidPayloadError, "Webhook body is not an event (missing \"event\")"
        end

        Event.new(parsed)
      end

      # Whether an address is one Paystack documents for webhooks. A second
      # check alongside the signature, not a replacement for it.
      #
      # @param ip [String, nil]
      # @return [Boolean]
      def trusted_ip?(ip)
        IP_ADDRESSES.include?(ip)
      end
    end
  end
end
