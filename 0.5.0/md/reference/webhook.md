# Webhook

Helpers for receiving Paystack webhooks, independent of any web framework.

Paystack signs every event with the `x-paystack-signature` header: a
lowercase hex HMAC SHA512 of the raw request body, using your secret key.
Verify it before doing anything with the event, and return a `200 OK`
quickly (do long work in a background job): events that are not
acknowledged are retried for 72 hours in live mode.

```ruby
  def create
    event = PaystackSdk::Webhook.construct_event(
      payload: request.raw_post,
      signature: request.headers["X-Paystack-Signature"],
      secret: ENV.fetch("PAYSTACK_SECRET_KEY")
    )
    HandlePaystackEventJob.perform_later(event.payload)
    head :ok
  rescue PaystackSdk::WebhookError
    head :bad_request
  end
```

## Module methods

### `sign`

```ruby
PaystackSdk::Webhook.sign(payload, secret)
```

Computes the signature Paystack would send for a payload.
Mostly useful in your own tests.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `payload` | String |  | The raw request body |
| `secret` | String |  | Your secret key |

**Returns** `String` Lowercase hex HMAC SHA512

### `valid_signature?`

```ruby
PaystackSdk::Webhook.valid_signature?(payload:, signature:, secret:)
```

Checks a webhook's signature in constant time.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `payload` | String | yes | The raw request body, byte for byte. Not a parsed or re-serialised version of it, which would not match. |
| `signature` | String, nil | yes | The `x-paystack-signature` header value |
| `secret` | String | yes | Your secret key |

**Returns** `Boolean`

**Raises** `ArgumentError` If the payload is not a String or the secret is blank

### `verify!`

```ruby
PaystackSdk::Webhook.verify!(payload:, signature:, secret:)
```

Like {valid_signature?} but raises when the signature is wrong.

**Returns** `true`

**Raises** `PaystackSdk::InvalidSignatureError`

### `construct_event`

```ruby
PaystackSdk::Webhook.construct_event(payload:, signature:, secret:)
```

Verifies the signature, then parses the event. Nothing is parsed if the
signature is wrong.

**Returns** `PaystackSdk::Webhook::Event`

**Raises** `PaystackSdk::InvalidSignatureError` If the signature does not match

**Raises** `PaystackSdk::InvalidPayloadError` If the signed body is not a JSON event

### `trusted_ip?`

```ruby
PaystackSdk::Webhook.trusted_ip?(ip)
```

Whether an address is one Paystack documents for webhooks. A second
check alongside the signature, not a replacement for it.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `ip` | String, nil |  |  |

**Returns** `Boolean`

## Webhook::Event

A verified webhook event.

### `event`

```ruby
event.event
```

**Returns** `String` The event name, e.g. "charge.success"

### `payload`

```ruby
event.payload
```

**Returns** `Hash` The parsed JSON body, string-keyed

### `data`

```ruby
event.data
```

**Returns** `PaystackSdk::Response, nil` The event's `data`, wrapped for dot and hash access

### `known?`

```ruby
event.known?
```

**Returns** `Boolean` Whether this event name is in `EVENTS` (documented, or seen sent by Paystack)

## EVENTS

Events Paystack documents, plus ones Paystack was seen sending that its Webhooks page does not list.
Paystack adds events over time, so an event outside this list is still returned by
{Webhook.construct_event}.

Documented on the Webhooks page, except `refund.needs-attention`, which only the Refunds guide
names. Seen in the event log of a test integration (Webhook Events API) and not on the Webhooks
page: `paymentrequest.draft`, `product.create`, `product.update` and `product.delete`.

- `charge.dispute.create`
- `charge.dispute.remind`
- `charge.dispute.resolve`
- `charge.success`
- `customeridentification.failed`
- `customeridentification.success`
- `dedicatedaccount.assign.failed`
- `dedicatedaccount.assign.success`
- `invoice.create`
- `invoice.payment_failed`
- `invoice.update`
- `paymentrequest.draft`
- `paymentrequest.pending`
- `paymentrequest.success`
- `product.create`
- `product.delete`
- `product.update`
- `refund.failed`
- `refund.needs-attention`
- `refund.pending`
- `refund.processed`
- `refund.processing`
- `subscription.create`
- `subscription.disable`
- `subscription.expiring_cards`
- `subscription.not_renew`
- `transfer.failed`
- `transfer.reversed`
- `transfer.success`

