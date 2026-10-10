# frozen_string_literal: true

# Hand-written from Paystack's docs (https://paystack.com/docs/api/webhook-events/). These operations are not in
# Paystack's OpenAPI spec, so the scaffold cannot generate them; they are recorded, with what was and was not
# observed, in spec/fixtures/docs_only_operations.yml.

require_relative "base"

module PaystackSdk
  module Resources
    # Webhook Events API: the log of webhooks Paystack has sent to your integration's webhook URL, with their
    # delivery status, the payload that was sent and what your endpoint answered, and a way to send them
    # again. Use it to find out whether a webhook was delivered, to see exactly what Paystack sent, and to
    # recover events your endpoint missed.
    #
    # `list`, `lookup` and `fetch` only read. `resend` and `resend_matching` make Paystack deliver webhooks
    # to your endpoint again, and have **not** been called against the Paystack test API.
    class WebhookEvents < PaystackSdk::Resources::Base
      # Delivery statuses the API accepts for the `status` filter (anything else is a 400).
      STATUSES = %w[Delivered Pending Failed].freeze

      # The filters List Events takes, which Resend Matching Events accepts too.
      FILTERS = %w[category event_type status category_row_id from to].freeze

      # The most event ids Paystack accepts in one resend.
      MAX_RESEND_IDS = 100

      # Ruby keyword => the parameter name Paystack documents.
      WIRE_NAMES = {next_cursor: "next", id: "reference"}.freeze

      # List Events.
      #
      # Fetches a page of the webhook events sent to your integration, newest first. The response `meta` holds
      # `next` and `previous` cursors: pass `meta.next` back as `next_cursor:` for the next page.
      #
      # Observed on the Paystack test API (2026-10-09), where the docs differ: a page holds 50 events by
      # default (the docs say 20), `limit` is capped at 50, and a `limit` that is not a number is ignored.
      #
      # @param category [String] Filter by category, for example "transactions" or "refund".
      # @param event_type [String] Filter by event name, for example "charge.success".
      # @param status [String] Filter by delivery status: Delivered, Pending or Failed.
      # @param category_row_id [String, Integer] Filter by the ID of the resource the event is about, such as a
      #   transaction ID.
      # @param from [String, Time, Date] Only events from this time on, for example 2016-09-24T00:00:05.000Z or 2016-09-21.
      # @param to [String, Time, Date] Only events up to this time.
      # @param limit [Integer] How many events to return per page.
      # @param next_cursor [String] The `meta.next` cursor of a previous response (sent as `next`). Not together with `previous`.
      # @param previous [String] The `meta.previous` cursor of a previous response. Not together with `next_cursor`.
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If a parameter is invalid or the API request fails.
      # @see https://paystack.com/docs/api/webhook-events/#list
      def list(category: nil, event_type: nil, status: nil, category_row_id: nil, from: nil, to: nil, limit: nil,
        next_cursor: nil, previous: nil)
        validate_allowed_values!(value: status, allowed_values: STATUSES, name: "status")
        validate_positive_integer!(value: limit, name: "limit")
        reject_both_cursors!(next_cursor, previous)

        wire_query = to_wire(
          {
            category:, event_type:, status:, category_row_id:,
            from: format_datetime(from, name: "from"),
            to: format_datetime(to, name: "to"),
            limit:, next_cursor:, previous:
          },
          WIRE_NAMES
        )

        handle_response(@connection.get("/integration/webhooks/events", wire_query))
      end

      # Look Up an Event.
      #
      # Finds a webhook event by its own ID, or by the ID of the resource it is about (a transaction ID, not
      # the transaction's reference). Observed on the test API: an event's `_id` and a `category_row_id`
      # both match; a value that matches nothing is a 404 "Webhook not found" (an unsuccessful Response).
      #
      # @param id [String, Integer] An event `_id`, or the ID of the resource it is about. Sent as `reference`, the name
      #   Paystack's docs give it, although it is not a reference.
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If a parameter is invalid or the API request fails.
      # @see https://paystack.com/docs/api/webhook-events/#lookup
      def lookup(id:)
        validate_presence!(value: id, name: "id")

        handle_response(@connection.get("/integration/webhooks/events/lookup", to_wire({id:}, WIRE_NAMES)))
      end

      # Fetch Event.
      #
      # Gets one event in full: `event_payload` (the body Paystack sent), `webhook_url`, `status`,
      # `status_detail`, `response_code`, `merchant_response_body` (what your endpoint answered), `trial_count`
      # and `trials`. Observed on the test API, where `event_payload` is a Hash with the keys `event` and
      # `data`. Read the payload's own `data` with brackets, `response.event_payload[:data]`: dot access
      # `event_payload.data` returns the Response itself, because `Response#data` is a method.
      #
      # @param id [String] The event's `_id`, from an item of {#list}.
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If a parameter is invalid or the API request fails.
      # @see https://paystack.com/docs/api/webhook-events/#fetch
      def fetch(id:)
        validate_presence!(value: id, name: "id")

        handle_response(@connection.get("/integration/webhooks/events/#{escape_path(id, name: "id")}"))
      end

      # Resend Events.
      #
      # Asks Paystack to deliver a specific set of events to your current webhook URL again.
      #
      # @note This makes Paystack send webhooks to your endpoint. The docs say resending is not idempotent:
      #   sending the same event ID twice delivers it twice, so your endpoint must dedupe. It has not been
      #   called against the Paystack test API; the method follows the docs.
      #
      # @param ids [Array<String>] The `_id`s of the events to resend: not empty, at most 100.
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If a parameter is invalid or the API request fails.
      # @see https://paystack.com/docs/api/webhook-events/#resend
      def resend(ids:)
        unless ids.is_a?(Array) && !ids.empty? && ids.size <= MAX_RESEND_IDS && ids.all? { |id| id.is_a?(String) && !id.strip.empty? }
          raise PaystackSdk::InvalidValueError.new("ids", "must be a non-empty Array of event _id strings, at most #{MAX_RESEND_IDS}")
        end

        handle_response(@connection.post("/integration/webhooks/events/resend", {ids: ids}))
      end

      # Resend Matching Events.
      #
      # Asks Paystack to deliver every event that matches the filters to your current webhook URL again.
      # With `preview: true` it only counts the matching events.
      #
      # `preview:` has no default here, although the docs make it optional: with no filters this resends
      # every event, so you have to say which you mean. Call it with `preview: true` first.
      #
      # @note This can make Paystack send a lot of webhooks to your endpoint, which must dedupe. It has not
      #   been called against the Paystack test API, including with `preview: true`; the method follows
      #   the docs.
      #
      # @param preview [Boolean] true to return the matching count without resending anything; false to resend.
      # @param filters [Hash, nil] Any of the {#list} filters: category, event_type, status, category_row_id, from, to.
      # @return [PaystackSdk::Response] The response from the Paystack API.
      # @raise [PaystackSdk::Error] If a parameter is invalid or the API request fails.
      # @see https://paystack.com/docs/api/webhook-events/#resend-matching
      def resend_matching(preview:, filters: nil)
        unless [true, false].include?(preview)
          raise PaystackSdk::InvalidValueError.new("preview", "must be true (count only) or false (resend)")
        end

        body = filters.nil? ? {} : {filters: checked_filters(filters)}
        handle_response(@connection.post("/integration/webhooks/events/resend-matching?preview=#{preview}", body))
      end

      private

      # `next` and `previous` together are a 400 from the API ("must be one of next or previous").
      def reject_both_cursors!(next_cursor, previous)
        return unless next_cursor && previous

        raise PaystackSdk::InvalidValueError.new("next_cursor", "cannot be used together with previous")
      end

      def checked_filters(filters)
        validate_hash!(input: filters, name: "filters")
        stringified = filters.transform_keys(&:to_s)
        unknown = stringified.keys - FILTERS
        raise PaystackSdk::InvalidValueError.new("filters", "unknown filter(s) #{unknown.join(", ")}; allowed: #{FILTERS.join(", ")}") unless unknown.empty?

        validate_allowed_values!(value: stringified["status"], allowed_values: STATUSES, name: "filters status")
        stringified["from"] = format_datetime(stringified["from"], name: "filters from") if stringified.key?("from")
        stringified["to"] = format_datetime(stringified["to"], name: "filters to") if stringified.key?("to")
        compact_params(stringified)
      end
    end
  end
end
