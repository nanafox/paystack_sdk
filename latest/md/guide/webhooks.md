# Webhooks

Paystack tells you about changes (a charge succeeded, a refund was processed, a transfer failed) by POSTing events to your webhook URL. `PaystackSdk::Webhook` verifies and parses them, and works with any framework.

Paystack signs each event: the `x-paystack-signature` header is a lowercase hex HMAC SHA512 of the **raw request body**, using your secret key. Verify it before using the event.

```ruby
# Rails controller (skip CSRF protection for this action)
def create
  event = PaystackSdk::Webhook.construct_event(
    payload: request.raw_post,                          # raw body, not params
    signature: request.headers["X-Paystack-Signature"],
    secret: ENV.fetch("PAYSTACK_SECRET_KEY")
  )

  HandlePaystackEventJob.perform_later(event.payload)   # do the work in the background
  head :ok                                              # acknowledge quickly
rescue PaystackSdk::WebhookError
  head :bad_request
end
```

```ruby
event.event             # => "charge.success"
event.data.reference    # data is wrapped like any Response
event.data[:amount]
event.known?            # => true if Paystack documents this event name
event.payload           # the parsed JSON Hash (string keys), handy for queuing a job
```

- `Webhook.valid_signature?(payload:, signature:, secret:)` returns a boolean, and `Webhook.verify!` raises `PaystackSdk::InvalidSignatureError`. The comparison is constant-time.
- The payload must be the exact bytes received. A parsed or re-serialised body will not match, and a non-String payload raises `ArgumentError`. A blank secret also raises, rather than checking against nothing.
- `Webhook.construct_event` verifies first and parses only afterwards. A signed body that is not a JSON event raises `PaystackSdk::InvalidPayloadError`. Events Paystack adds later still come back, with `known?` false.
- `Webhook.trusted_ip?(ip)` checks the three addresses Paystack documents (`Webhook::IP_ADDRESSES`). Use it as an extra check, not instead of the signature.
- `Webhook.sign(payload, secret)` produces a valid signature, for testing your own endpoint.
- Paystack retries events your server does not acknowledge with a `200 OK`: in live mode every 3 minutes for 4 tries, then hourly for 72 hours. Return `200` fast, process in a background job, and make handlers safe to run more than once.
- Before giving value for a `charge.success`, confirm it with `transactions.verify(reference:)`, as Paystack recommends.
