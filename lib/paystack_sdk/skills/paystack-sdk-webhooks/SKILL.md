---
name: paystack-sdk-webhooks
description: 'Use when building or reviewing the endpoint that receives Paystack webhooks (charge.success, refund.*, transfer.*, subscription.*, invoice.*, dispute.*) in a Rails or Rack app: verifying the x-paystack-signature header with PaystackSdk::Webhook, reading the raw request body, skipping CSRF, answering 200 fast and working in a background job, handling duplicate or out-of-order deliveries, and testing the endpoint with a signed request.'
---

# Receiving Paystack webhooks

A webhook is Paystack POSTing a JSON event to a URL you register on the Paystack dashboard. `PaystackSdk::Webhook` checks the signature and parses the event. It does not know your framework, your database or your jobs.

What is executed and what is not: every Ruby block marked "runs in the spec" is run by `spec/skills_webhooks_spec.rb`. The Rails blocks are not run (the gem has no Rails dependency); they use ordinary Rails methods and are marked. Facts from Paystack's Webhooks page (payments/webhooks) are labelled "documented". Nothing here was observed from a real Paystack delivery: the test API cannot be made to send one (see the end).

## The signature rule (documented)

Paystack sends the header `x-paystack-signature`: the HMAC SHA512, as lowercase hex, of the event payload signed with your secret key. Verify it **before** doing anything with the event, over the **raw request body, byte for byte**. A body that was parsed and re-serialised does not match.

| Call | Returns | Raises |
|---|---|---|
| `Webhook.valid_signature?(payload:, signature:, secret:)` | `true` / `false` (constant-time compare). A `nil`, empty, truncated or upper-case signature is `false` | `ArgumentError` if `payload` is not a String (a parsed Hash, for example) or `secret` is blank |
| `Webhook.verify!(payload:, signature:, secret:)` | `true` | `PaystackSdk::InvalidSignatureError`; also the `ArgumentError`s above |
| `Webhook.construct_event(payload:, signature:, secret:)` | a `Webhook::Event` (`event`, `payload`, `data`, `known?`) | `InvalidSignatureError` (nothing is parsed first), `InvalidPayloadError` if the signed body is not a JSON object with a non-empty string `"event"`; also the `ArgumentError`s |
| `Webhook.sign(payload, secret)` | the lowercase hex signature, for your own tests | |

`InvalidSignatureError` and `InvalidPayloadError` are both `PaystackSdk::WebhookError`, which is a `PaystackSdk::Error`. `event.data` is the event's `data` wrapped for dot access (`event.data.reference`, `event.data[:amount]`), or `nil` if the event carries none, or an array-like when `data` is an array (`subscription.expiring_cards`). `event.payload` is the string-keyed Hash.

Use `construct_event` unless you only need a yes/no. Rescue `PaystackSdk::WebhookError`, not `Error`, so a real SDK problem is not swallowed. The `ArgumentError`s are programming errors (blank secret): let them raise.

## Rails controller (not run in the spec; standard Rails methods)

```ruby
class PaystackWebhooksController < ApplicationController
  # The request comes from Paystack's servers: there is no session and no CSRF token.
  skip_before_action :verify_authenticity_token
  # Also skip any login filter your ApplicationController adds (authenticate_user! and the like).

  def create
    event = PaystackSdk::Webhook.construct_event(
      payload: request.raw_post, # the raw body, never params or request.body.read after parsing
      signature: request.headers["X-Paystack-Signature"],
      secret: Rails.application.credentials.paystack_secret_key
    )

    # Insert-or-ignore, then enqueue only the first time (see "Duplicates" below).
    if PaystackEvent.claim(event)
      HandlePaystackEventJob.perform_later(event.payload)
    end
    head :ok
  rescue PaystackSdk::WebhookError
    head :bad_request
  end
end
```

```ruby
# config/routes.rb
post "/paystack/webhook", to: "paystack_webhooks#create"
```

Rules for this action: read `request.raw_post`; never pass `params` or a re-generated JSON string; keep the secret key in credentials or ENV and out of logs; do not log the whole payload at info level (it holds customer emails and card metadata). Use the secret key of the same Paystack environment that is calling: a test key verifies test events, a live key live events (the signature is made with the key of the account and mode that sent it; documented as "signed using your secret key"; which of your keys signs which mode was not tested here).

## A framework-free receiver (runs in the spec)

This is the same logic with no Rails: a receiver returning an HTTP status, and a Rack app around it. `claim` is your idempotency store (next section); here it is any object whose `claim(key)` returns true the first time it sees a key.

```ruby
class PaystackReceiver
  def initialize(secret:, store:, enqueue:, allowed_ips: nil)
    @secret, @store, @enqueue, @allowed_ips = secret, store, enqueue, allowed_ips
  end

  def call(raw_body:, signature:, ip: nil)
    return 403 if @allowed_ips && !@allowed_ips.include?(ip)

    event = PaystackSdk::Webhook.construct_event(payload: raw_body, signature: signature, secret: @secret)
    @enqueue.call(event.payload) if @store.claim(self.class.key(event))
    200
  rescue PaystackSdk::WebhookError
    400
  end

  # event name + data.id, else event name + data.reference
  def self.key(event)
    data = event.payload["data"]
    data = data.first if data.is_a?(Array)
    id = data.is_a?(Hash) ? (data["id"] || data["reference"]) : nil
    [event.event, id].join(":")
  end
end

class PaystackWebhookApp
  def initialize(receiver)
    @receiver = receiver
  end

  def call(env)
    input = env["rack.input"]
    body = input.read
    input.rewind
    status = @receiver.call(raw_body: body, signature: env["HTTP_X_PAYSTACK_SIGNATURE"], ip: env["REMOTE_ADDR"])
    [status, {"content-type" => "text/plain"}, [""]]
  end
end
```

Pass `allowed_ips: PaystackSdk::Webhook::IP_ADDRESSES` to turn the IP check on. A bad signature gets 400 here (and in the gem's own example); 401 or 403 would also be reasonable, Paystack only needs a non-200 to know it was not accepted. Never answer 200 to an event you rejected.

## Answer fast, work later (documented)

Paystack: return `200 OK` immediately; long-running work in the webhook function leads to a timeout and an automatic error response, and without a 200 the event is retried. Documented retry policy: **live mode**, every 3 minutes for the first 4 tries, then hourly for the next 72 hours; **test mode**, hourly for 10 hours, with a 30 second timeout per attempt. A response that is not 200 (including a timeout) is "a failed attempt". So: verify the signature, store or enqueue, answer 200, and do the real work in a job (`HandlePaystackEventJob` above). Not observed here: the schedule was not seen in action.

Paystack also documents a Webhook Events API (list, look up and resend events to your webhook URL). `paystack_sdk` has no resource for it as of this version; call it through `client.connection` only after reading its docs page.

## Duplicates and out-of-order delivery (design advice, not Paystack behaviour)

Retries mean the same event can reach you more than once, and a retry of an old event can land after a newer one. The Webhooks page documents no event id. So:

- **Dedupe key**: event name + `data.id` (or `data.reference` when there is no id). Whether every event type carries an `id` or a `reference` is not verified; the receiver above falls back from one to the other, and an event with neither collapses to its name alone, so check the payload of each event type you handle before relying on this.
- **Store the key with a unique index** and insert before you act:

```ruby
# Rails migration and model: design advice, not run in the spec
class CreatePaystackEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :paystack_events do |t|
      t.string :key, null: false
      t.string :event, null: false
      t.datetime :processed_at
      t.timestamps
    end
    add_index :paystack_events, :key, unique: true
  end
end

class PaystackEvent < ApplicationRecord
  # true only for the delivery that created the row
  def self.claim(event)
    create!(key: PaystackReceiver.key(event), event: event.event)
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end
end
```

- **The job must be safe to run twice** anyway: it re-reads the current state, does its change in a transaction, and sets `processed_at`. A crash between claim and enqueue loses nothing if the claim and the enqueue share a transaction (a database-backed queue) or the job also checks `processed_at`; with a Redis queue, choose which failure you prefer (a lost event, or a duplicate job) and make the job idempotent.
- **Out of order**: do not apply an event as a state change from the payload alone ("set status to what the event says"). Fetch the current state from Paystack and apply that (below), so an old event cannot overwrite a newer one.

## Never grant value from the payload alone

A valid signature proves the event came from Paystack. It does not prove the amount, the currency or that the payment is still good. For anything that moves value (marking an invoice paid, giving a membership, crediting a wallet), the job does what a return URL would do: verify by reference and compare to what you expected.

```ruby
# inside HandlePaystackEventJob, for "charge.success"
reference = payload.dig("data", "reference")
response = client.transactions.verify(reference: reference)
if response.paid?(amount: expected_amount_in_pesewas, currency: "GHS")
  # grant value once; look the order up by reference, not by anything in the payload
end
```

`expected_amount_in_pesewas` comes from your own record of the order, not from the event. See [[paystack-sdk-payments]] (accepting a payment and verifying it), [[paystack-sdk-overview]] and [[paystack-sdk-charge-statuses]]. Unknown reference, `paid?` false, or a mismatched amount: log it and do not grant.

## Which events (documented list = `Webhook::EVENTS`)

`event.known?` is true for these 24. Paystack says it adds events over time, so an unknown name is still returned by `construct_event`: log it and answer 200.

| Group | Events |
|---|---|
| Payments | `charge.success` (a successful charge was made) |
| Refunds | `refund.pending` (initiated, waiting for the processor), `refund.processing` (received by the processor), `refund.processed` (done), `refund.failed` (cannot be processed; your account is credited with the refund amount) |
| Transfers | `transfer.success`, `transfer.failed`, `transfer.reversed` |
| Subscriptions | `subscription.create`, `subscription.disable`, `subscription.not_renew` (status changed to non-renewing; will not be charged on the next payment date), `subscription.expiring_cards` (all subscriptions with cards expiring that month; sent at the start of the month) |
| Invoices | `invoice.create` (usually 3 days before the subscription is due), `invoice.update` (usually means the customer was charged; inspect the invoice object), `invoice.payment_failed` |
| Disputes | `charge.dispute.create`, `charge.dispute.remind`, `charge.dispute.resolve` |
| Payment requests | `paymentrequest.pending`, `paymentrequest.success` |
| Customer identification | `customeridentification.success`, `customeridentification.failed` |
| Dedicated accounts | `dedicatedaccount.assign.success`, `dedicatedaccount.assign.failed` |

Payload shapes: the Webhooks page we read shows **one** sample body, for `customeridentification.failed` (`event`, then `data` with `customer_id`, `customer_code`, `email`, `identification{country,type,bvn,account_number,bank_code}`, `reason`). We saw no documented sample for `charge.success`, the refund, transfer, subscription, invoice or dispute events on that page, so fields such as `data.reference`, `data.amount`, `data.currency` and `data.status` are **not verified** as webhook payload fields. They are what the corresponding API objects carry, which is why the job verifies by reference instead of reading them. The spec uses invented bodies of the shape `{"event": ..., "data": {"id": ..., "reference": ...}}` only to exercise the code.

## Test your endpoint locally

Paystack cannot reach localhost (documented: "localhost URLs can't receive events"), and this skill's authors could not make the Paystack test API send a real webhook. So test the endpoint yourself by signing a body with the same secret and posting it. This is what the spec runs, against the Rack app above:

```ruby
secret = "sk_test_example" # a placeholder, never a real key
body = {event: "charge.success", data: {id: 302961, reference: "ref-1"}}.to_json
signature = PaystackSdk::Webhook.sign(body, secret)
# then POST `body` (exactly this string) with the header X-Paystack-Signature: signature
```

In a Rails request spec (not run here) post the string, not a Hash, so the bytes are what you signed:

```ruby
post "/paystack/webhook", params: body, headers: {"CONTENT_TYPE" => "application/json", "X-Paystack-Signature" => signature}
expect(response).to have_http_status(:ok)
```

Cases to cover: valid signature (200 and a job enqueued), body changed after signing (400, no job), missing header (400), signature made with another key (400), the same delivery twice (200 both times, one job).

To try a real delivery you need a public HTTPS URL (a tunnel, or a staging host) registered as the webhook URL on the dashboard, and an action that fires an event. That was not done for this skill.

## Behind a proxy: the IP allow-list (design advice)

`Webhook.trusted_ip?(ip)` is true only for the three addresses Paystack documents for both test and live (`52.31.139.75`, `52.49.173.169`, `52.214.14.220`). Paystack lists signature validation and IP allow-listing as the two ways to verify origin. Treat the IP check as a second layer next to the signature, never instead of it.

Behind a load balancer or CDN the socket address (`REMOTE_ADDR`) is the proxy, not Paystack. In Rails `request.remote_ip` resolves the client address through the proxies Rails is configured to trust; if the trusted-proxy setting is wrong, either everything is rejected or a spoofed `X-Forwarded-For` is believed. Not tested here. If you cannot get the client IP right, skip the IP check and rely on the signature, or enforce the allow-list at the firewall/load balancer instead of in Ruby.

## Rules

- **Verify the signature on the raw body first.** `request.raw_post` in Rails, `rack.input` in Rack. Never `params`.
- **Skip CSRF and login filters on this one action**, and nowhere else.
- **Respond 200 quickly**; do the work in a background job.
- **Reject with a non-2xx** (400) when the signature or payload is bad.
- **Dedupe** on event name + `data.id` / `data.reference` with a unique index, and make the job idempotent.
- **Verify by reference and check `paid?(amount:, currency:)`** against your own record before granting value.
- **Handle unknown events** by logging and answering 200.
- **Keep the secret key out of code, logs and the repo.**

## Not verified

No webhook was received from Paystack while writing this. Unverified: that the signature is made with the key of the mode that sent the event, the payload fields of every event except the one sample, which events carry an `id` and which only a `reference`, the live retry schedule in practice, and how your proxy reports the client IP. The retry schedule, header name, signature algorithm and IP list are as stated on Paystack's Webhooks documentation page.
