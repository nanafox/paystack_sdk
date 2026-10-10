---
name: paystack-sdk-payments
description: 'Use when building or reviewing the hosted checkout flow with paystack_sdk: starting a payment with client.transactions.initiate, redirecting the payer to authorization_url, handling the callback_url return, confirming with transactions.verify and paid?, reading a verify status such as success, abandoned or failed, making confirmation safe when the callback and the webhook arrive together, deciding which transaction fields to store, or looking transactions up with fetch and list.'
---

# Accepting a payment with the hosted checkout

The payer pays on Paystack's checkout page, not on yours. Your server starts the transaction, sends the payer to Paystack, and later asks Paystack what happened. Nothing the browser brings back counts as proof. Read [paystack-sdk-overview](paystack-sdk-overview.md) first for the client, `Response` and error conventions.

## The flow

1. Create your own payment row with a new `reference`, an `amount` in pesewas and a `currency`, status `pending`. Save it **before** calling Paystack.
2. `client.transactions.initiate(...)` with that reference. Redirect the payer to `response.authorization_url`.
3. The payer comes back to your `callback_url`. Treat that request as "please check", nothing more.
4. `client.transactions.verify(reference:)` and give value only if `paid?(amount: payment.amount, currency: payment.currency)` is true.
5. Do the same in the `charge.success` webhook handler. Steps 4 and 5 run the same idempotent code (see "Confirming twice is normal").

## Start the payment: `transactions.initiate`

| Keyword | What to pass |
|---|---|
| `email:` (required) | The payer's email. The SDK refuses a malformed one before sending |
| `amount:` (required) | A positive Integer in the subunit: `5000` is GHS 50.00. `0`, `50.0` and `"5000"` raise `PaystackSdk::InvalidValueError` before any request |
| `currency:` | Always pass it (`"GHS"`). The SDK accepts `GHS`, `KES`, `NGN`, `ZAR`, `USD`. Left out, Paystack uses the integration currency (docs); ours came back `GHS` |
| `reference:` | Yours, unique, stored first. The SDK accepts letters, digits and `-` `.` `=` `_`. Use letters, digits and `-` only: Paystack's docs list `-`, `.`, `=` and alphanumerics (an `_` was accepted on the test API, but it is not documented) |
| `callback_url:` | Where Paystack sends the payer after paying. It overrides the dashboard setting; with neither set, the payer is not sent back (docs) |
| `channels:` | An Array limiting the checkout, e.g. `["card", "mobile_money"]`. The docs list `card`, `bank`, `apple_pay`, `ussd`, `qr`, `mobile_money`, `bank_transfer`, `eft`, `capitec_pay`, `payattitude`. The SDK sends it unchecked |
| `metadata:` | A Hash (or a JSON string). The SDK sends it stringified, as Paystack documents it, so numbers keep their type (`{order_id: 42}` comes back from `verify` as `42`; sent as a plain object Paystack would store `"42"`: observed on the test API 2026-10-09). Look payments up by your reference, not by metadata |

The method also takes `plan:`, `invoice_limit:`, `split_code:`, `split:`, `subaccount:`, `transaction_charge:`, `bearer:` and `label:`. It has no `first_name:`, `last_name:` or `phone:` keyword.

A successful call returns `authorization_url`, `access_code` and your `reference`. `transactions.verify` does not return `authorization_url`, so if you lose it, you cannot get it back from verify.

```ruby
# app/controllers/payments_controller.rb
def create
  payment = Payment.create!(member: current_member, amount: 5000, currency: "GHS",
    reference: "pay-#{SecureRandom.uuid}", status: "pending")

  response = PaystackSdk::Client.new.transactions.initiate(
    email: current_member.email, amount: payment.amount, currency: payment.currency,
    reference: payment.reference, callback_url: payments_callback_url,
    channels: ["card", "mobile_money"], metadata: {payment_id: payment.id}
  )

  if response.success?
    redirect_to response.authorization_url, allow_other_host: true # else OpenRedirectError when raise_on_open_redirects is on
  else
    payment.update!(status: "failed", gateway_response: response.error_message)
    redirect_to new_payment_path, alert: "We could not start the payment. Please try again."
  end
end
```

**One reference, one transaction, ever.** Paystack answered HTTP 400 "Duplicate Transaction Reference" (an unsuccessful `Response`, not an exception) to every reuse we tried: `initiate` again with the same reference (same or different amount), a card charge with a reference that `initiate` had already used, and `initiate` with a reference that was already paid. So a new attempt always needs a new reference and a new payment row.

**If `initiate` raises `PaystackSdk::TimeoutError` or `ServerError`**, the SDK does not retry it, and it may have reached Paystack. Call `verify(reference:)`: "Transaction reference not found." means Paystack never created it; a found transaction means it exists but you have no `authorization_url` for it. Either way, start again with a new reference and mark the old row `failed`.

## When the payer comes back

Paystack's docs (Accept Payments, Redirect) say it appends the reference to your `callback_url` as `?reference=...`, and that a visit to the callback URL "doesn't prove that transaction was successful". So the callback only runs the confirmation:

```ruby
# GET /payments/callback?reference=...
def callback
  payment = ConfirmPayment.call(params[:reference].to_s)
  return head(:not_found) if payment.nil?

  redirect_to payment_path(payment) # shows paid, pending or failed from your own row
end
```

## What `verify` tells you

`verify` succeeds (`success?` true, HTTP 200) for any reference Paystack knows, paid or not. The payment outcome is in `data.status`, never in `success?`.

| `data.status` | What it means | What to do |
|---|---|---|
| `success` | Paid. `paid?(amount:, currency:)` also checks the amount and currency are the ones you asked for | Mark paid and give value once, if `paid?` is true. If the status is `success` but `paid?` is false, do not give value: flag it for a person |
| `abandoned` | Not paid (yet). Seen right after `initiate`, while a charge waited for a PIN, and after a card was declined at the first step (with the reason in `gateway_response`, e.g. "Transaction declined. Please use the test card.") | Keep the row `pending`. Do not call it failed: the docs define it as "the customer hasn't completed the transaction" |
| `failed` | The attempt failed. Seen after a wrong PIN, with `gateway_response` "Incorrect PIN" | Mark failed; a retry is a new reference |
| `ongoing`, `pending`, `processing`, `queued` | In progress (docs only, not seen here) | Keep `pending`, wait for the webhook or verify later |
| `reversed` | Refunded or charged back (docs only, not seen here) | Do not give value; if you already did, handle it as a reversal |
| anything else | Unknown | Keep `pending`, log the status and reference, do not guess |

A reference Paystack does not know: `verify` returns HTTP 400, `success?` false, `error_message` "Transaction reference not found." and no `data`. It does not raise. Never treat that as paid or as failed; it is not a Paystack transaction (or not one yet).

On a paid transaction, `verify` returned (test API): `id`, `status` `success`, `reference`, `amount` `100`, `currency` `GHS`, `paid_at`, `channel` `card`, `gateway_response` "Successful", your `metadata`, `customer` (`id`, `email`, `customer_code`) and `authorization` (`authorization_code`, `reusable` true, `channel`, plus card details: `bin`, `last4`, `exp_month`, `exp_year`, `brand`, `bank`, `signature`). On an unpaid one, `paid_at` was `null` and `authorization` was `{}`.

Dot access (`response.paid_at`) raises `NoMethodError` when Paystack leaves a key out. Read a field that may be missing with `response.dig(:paid_at)` (or `response.dig(:authorization, :authorization_code)`): it returns `nil` as soon as a key is missing.

## Confirming twice is normal (design advice)

The callback and the `charge.success` webhook confirm the same payment, possibly at the same moment. Paystack's Verify Payments guide warns to "confirm that you haven't already delivered value for that transaction to avoid double fulfillments". This is **our design advice, not Paystack behaviour**: a unique `reference` column, one service both paths call, a row lock and a state check inside it.

```ruby
# db/migrate/..._create_payments.rb
create_table :payments do |t|
  t.references :member, null: false
  t.string :reference, null: false
  t.integer :amount, null: false          # pesewas
  t.string :currency, null: false
  t.string :status, null: false           # yours: pending, paid, failed, needs_review
  t.string :paystack_status               # the last data.status verify returned
  t.bigint :paystack_id                   # data.id; the docs say treat it as an unsigned 64-bit integer
  t.datetime :paid_at
  t.string :gateway_response
  t.string :authorization_code            # only when reusable; `encrypts :authorization_code` in the model
  t.timestamps
end
add_index :payments, :reference, unique: true
```

```ruby
# app/services/confirm_payment.rb: the callback and the webhook both call this
class ConfirmPayment
  def self.call(reference, client: PaystackSdk::Client.new)
    payment = Payment.find_by(reference: reference)
    return nil if payment.nil?                  # not ours: never act on it
    return payment if payment.status == "paid"  # already done

    response = client.transactions.verify(reference: reference)
    return payment unless response.success?     # unknown to Paystack: leave it pending

    data = response.original_response["data"]   # a plain Hash: a missing key is nil, not an error
    payment.with_lock do                        # locks the row and reloads it
      if payment.status == "paid"
        # the other confirmation finished first: do nothing
      elsif response.paid?(amount: payment.amount, currency: payment.currency)
        authorization = data["authorization"] || {}
        payment.update!(status: "paid", paystack_status: data["status"], paystack_id: data["id"],
          paid_at: data["paid_at"], gateway_response: data["gateway_response"],
          authorization_code: (authorization["authorization_code"] if authorization["reusable"]))
        # record what the payment buys here, inside the lock, so it happens once
      elsif response.status?(:success)
        payment.update!(status: "needs_review", paystack_status: "success", gateway_response: data["gateway_response"])
      else
        payment.update!(status: response.status?(:failed) ? "failed" : "pending",
          paystack_status: data["status"], gateway_response: data["gateway_response"])
      end
    end
    payment
  end
end
```

The lock only serialises the two callers on a database with row locks (PostgreSQL, MySQL). The `status == "paid"` check inside the lock is what stops the second caller. Send emails and other side effects after the commit (for example from a job), not from inside the lock.

In the webhook, check the signature first, then call the same service with the event's reference:

```ruby
event = PaystackSdk::Webhook.construct_event(payload: request.raw_post,
  signature: request.headers["X-Paystack-Signature"], secret: ENV.fetch("PAYSTACK_SECRET_KEY"))
ConfirmPayment.call(event.data.reference) if event.event == "charge.success"
head :ok
```

## What to store

| Store | Why |
|---|---|
| `reference`, `amount`, `currency` | Yours, written before `initiate`; what `paid?` compares against |
| `status` (yours) and `paystack_status` | Your state machine, and what Paystack last said |
| `id` (as `paystack_id`, `bigint`) | `transactions.fetch(id:)` takes the numeric ID, not the reference |
| `paid_at`, `gateway_response` | Receipts and support ("Incorrect PIN", "Successful") |
| `authorization.authorization_code` | **Only when `authorization.reusable` is true**, encrypted, for later charges. Never overwrite a stored code with an empty one |

Never store card data: not `bin`, `last4`, `exp_month`, `exp_year`, `signature`, and never anything the payer typed. Keep the secret key out of logs.

## Looking transactions up

```ruby
client.transactions.fetch(id: payment.paystack_id)  # unknown ID: HTTP 404, success? false, "Transaction not found"

page = client.transactions.list(per_page: 50, page: 1, status: "success",
  from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 31), customer_id: 407293981)
page.each { |transaction| puts transaction.reference }
page.meta.total # also page.meta.pageCount, page.meta.perPage
```

- `per_page:` is sent as `perPage`; `customer_id:` is sent as `customer` and is Paystack's **numeric** customer ID (`data.customer.id` from verify). Paystack answers a `CUS_` code with `success?` true and no rows, which looks like "no payments", so the SDK refuses anything but a numeric ID (an Integer, or a string of digits) with `InvalidValueError` before sending.
- `status:` is checked by the SDK: `success`, `failed`, `abandoned` or `reversed`.
- `from:` and `to:` take a `Date`, a `Time` or an ISO 8601 String.

## Rules

- **Your reference, stored first, used once.** A new attempt is a new reference.
- **The callback URL proves nothing.** Verify by reference, then `paid?(amount:, currency:)` with *your* stored amount and currency.
- **`success?` on verify is not "paid".** Read `data.status`; only `success` with `paid?` true is paid.
- **`abandoned` is not failed.** Keep the row pending.
- **Confirmation is idempotent**: one service, called by the callback and the webhook, with a lock and a state check.
- **Never retry `initiate` after a timeout with the same reference.** Verify it, then start again with a new one.
- **Store the authorization code only when reusable, encrypted. Never card data.**

## Observed, and not verified

Observed on Paystack's test API on 2026-10-09 with `sandbox_only: true`: `initiate` with every keyword in the table (a 1-pesewa `initiate` and a 40-character `pay-<uuid>` reference were accepted too), `verify` of an unpaid, a paid, a declined, a wrong-PIN and an unknown reference, the duplicate-reference answers, `fetch` (known and unknown ID) and `list` with `per_page`, `status`, `from`, `to` and `customer_id`. The paid transaction was made with Paystack's no-validation test card through the Charge API (`4084 0840 8408 4081`, expiry `09/27`, CVV `408`) with our own reference, because the hosted checkout page cannot be driven from code.

Not verified: anything on the checkout page itself, including what the payer sees for each `channels` value, the exact query string Paystack adds to the `callback_url` (the docs show `reference`), and whether an `abandoned` transaction can still become `success` later. The statuses `ongoing`, `pending`, `processing`, `queued` and `reversed` come from Paystack's Verify Payments guide and were not produced here. The Rails code (the migration, the controller and `ConfirmPayment`) is design advice. The gem's specs run `ConfirmPayment` against a stand-in model; it was also run once with ActiveRecord 8.1 on SQLite against the test API (an abandoned payment stayed `pending`, a paid one confirmed from two threads ended `paid` once with its `AUTH_` code, an unknown reference returned `nil`). That run used SQLite, so the locking under real concurrent load on PostgreSQL or MySQL is not verified. Nothing here was run with a live key, and test mode does not model everything live mode does.
