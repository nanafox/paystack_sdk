# Webhook Events

The Webhook Events API is the log of every webhook Paystack tried to send to your integration's webhook URL: whether it was delivered, what Paystack sent, and what your endpoint answered. It is documented by Paystack but is not in its OpenAPI spec, so `client.webhook_events` is written from the docs (the entry in `spec/fixtures/docs_only_operations.yml` records what was checked). Use it to find out why a webhook never arrived, to see the exact payload, and to replay events your endpoint missed.

```ruby
# Events Paystack could not deliver (status is Delivered, Pending or Failed)
response = paystack.webhook_events.list(status: "Failed", limit: 20)

response.each do |event|
  puts "#{event.event_name} #{event.status} (#{event.status_detail}) answered #{event.response_code}"
end

# The next page: pass meta.next back as next_cursor (not together with previous)
paystack.webhook_events.list(next_cursor: response.original_response.dig("meta", "next"))

# Filters: category, event_type, status, category_row_id, from, to
paystack.webhook_events.list(event_type: "charge.success", from: Date.new(2025, 6, 1))

# One event in full: the payload Paystack sent, and your endpoint's answer
event = paystack.webhook_events.fetch(id: "6ac94b47fdad55440ef2066a")
event.event_payload[:data] # brackets: a key named data is not reachable with dot access
event.merchant_response_body

# Find an event by its own id, or by the id of the resource it is about (a transaction id)
paystack.webhook_events.lookup(id: 6_641_907_106)
```

Checked against Paystack's test API: `list`, `lookup` and `fetch` (read-only). A page holds 50 events by default (the docs say 20) and `limit` is capped at 50. Every event has a `_id`; the payloads Paystack records are `{"event": ..., "data": {...}}` with no event id inside, and `data.id` was present in every payload seen.

**Resending is unverified and makes Paystack deliver webhooks to your endpoint.** `resend(ids:)` and `resend_matching(preview:, filters:)` were never called: the docs say resending is not idempotent, so your endpoint must dedupe. `resend_matching` makes you choose `preview:` (the docs make it optional) because with no filters it resends everything. Call it with `preview: true` first.
