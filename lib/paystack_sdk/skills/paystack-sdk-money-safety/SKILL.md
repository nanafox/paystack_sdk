---
name: paystack-sdk-money-safety
description: 'Use before writing, reviewing or merging any code that moves or records money with the paystack_sdk gem: starting or confirming a payment, granting value after a webhook or return URL, charging a saved card, handling a timeout on a write, storing card or authorization data, logging or reporting errors that touch a Paystack client, choosing keys per environment, or reconciling payments. A checklist of rules, each checked against the gem and the Paystack test API, ending in a pre-merge table.'
---

# Money safety checklist

Apply every rule below before you write payment code, and run the table at the end before you merge it. The gem's conventions (client, `Response`, errors) are in [[paystack-sdk-overview]].

## 1. Amounts are integers in the minor unit

`5000` is GHS 50.00 (pesewas). Convert once, at the edge, from a decimal you trust: `(BigDecimal(price) * 100).to_i`. Never use a Float for money anywhere in your app.

What happens to a bad amount on `transactions.initiate`:

| Amount | The SDK | Paystack, if it got it (observed on the test API 2026-10-09) |
|---|---|---|
| `100.5` | raises `PaystackSdk::InvalidValueError`, nothing sent | HTTP 400 `"amount" must be an integer` |
| `100.0` | raises `InvalidValueError` | **accepted**, stored as 100 |
| `"100"` | raises `InvalidValueError` | **accepted**, stored as 100 |
| `"100.50"` | raises `InvalidValueError` | HTTP 400 `"amount" must be an integer` |
| `0` or `-100` | raises `InvalidValueError` | HTTP 400 `Invalid Amount Sent` |

So do not bypass the SDK's check (for example through `client.connection.post`): Paystack itself silently accepts a whole Float or a numeric String.

## 2. Never grant value from a webhook or a return URL alone

A webhook, a callback or the payer landing on your return URL is a hint. Value is granted only after you verify **by your own reference** and compare with what **you** expected to charge, stored on your own record before the call. Never compare with the amount in the response, the webhook or the URL.

```ruby
# `payment` is your record: reference, amount (minor units), currency and email, saved before calling Paystack.
def payment_outcome(client, payment)
  response = client.transactions.verify(reference: payment.reference)
  return :not_found unless response.success?
  return :not_paid unless response.status?(:success)
  return :mismatch unless response.paid?(amount: payment.amount, currency: payment.currency) &&
    response.customer.email.to_s.casecmp?(payment.email)

  :paid
end
```

- `:paid`: grant value, once (see rule 8).
- `:mismatch`: Paystack took a payment, but not the one you asked for (amount, currency or email differ). Do not grant; alert a person.
- `:not_paid`: not (yet) paid. An initialized but unpaid transaction verified as `abandoned` on the test API. Check again later or wait for the webhook.
- `:not_found`: the reference is unknown. Observed: HTTP 400, `success?` false, message "Transaction reference not found."; the SDK returns it, it does not raise.

`paid?` with no arguments only checks the status: always pass `amount:` and `currency:`.

## 3. Never retry a write after a timeout

The SDK sends a write (POST, PUT, DELETE) once: a timeout or 5xx raises `PaystackSdk::TimeoutError` / `ConnectionError` / `ServerError` and is **not** repeated, because Paystack may have processed it. Writes are retried only on 429. Reads (GET, such as `verify`) are retried on network errors and 429/502/503/504.

Do this instead: treat the outcome as unknown and verify the reference.

```ruby
def charge_saved_card(client, payment, authorization_code)
  client.transactions.charge_authorization(email: payment.email, amount: payment.amount,
    currency: payment.currency, authorization_code: authorization_code, reference: payment.reference)
  payment_outcome(client, payment)
rescue PaystackSdk::ConnectionError, PaystackSdk::ServerError
  :unknown # Paystack may have charged. Do not send it again: verify payment.reference later (a job).
end
```

Do not pass `retry_non_idempotent: true` to `PaystackSdk::Client.new`. It makes the SDK resend writes after a timeout or 5xx (default 2 more times), which can charge twice.

## 4. Reference discipline

- Create the reference and save it on your record **before** the call, so a crash or timeout leaves something to verify.
- One reference per payment attempt. A failed charge cannot be resumed; the next attempt gets a new reference.
- Paystack rejects a reference it has already seen: `initiate` and `charge_authorization` with a used reference returned HTTP 400 "Duplicate Transaction Reference" (observed on the test API 2026-10-09). That is a safety net, not a plan: verify first.

## 5. Store the authorization code, never card data

- Store `authorization.authorization_code` (encrypted at rest, for example Rails `encrypts`) and the customer email: `charge_authorization` needs both. Store it only when `authorization.reusable` is true.
- A verified card transaction returns `authorization_code`, `bin`, `last4`, `exp_month`, `exp_year`, `channel`, `card_type`, `bank`, `country_code`, `brand`, `reusable`, `signature` and `account_name` (observed). `last4`, `brand` and expiry are enough to show the payer which card is saved.
- Never store or log a card number, CVV, PIN or OTP. They go straight to Paystack.

## 6. Keep secret keys out of logs and error reports

- The SDK puts nothing of the key in its error messages (checked for timeouts, connection failures, 401, 429 and 5xx), nor in `Response#inspect`.
- **`inspect` and `pp` of a `PaystackSdk::Client`, of any resource (`client.transactions`) and of the connection the SDK builds do not include the secret key** (they print the class name; the connection's `Authorization` header shows `[REDACTED]`). **Versions before 0.4.1 printed the key in full**: on one of those, never log, `pp`, or send to an error reporter a client, a resource or a connection, and rotate the key if you may have. A connection you build yourself and pass to `Client.new(connection)` is yours: its own `inspect` is unchanged. Whatever the version, log the reference, the `Response#error_message` and the HTTP `status_code` instead of whole objects.
- Read the key from the environment or encrypted credentials; never commit it.

## 7. Key hygiene

- Use `PaystackSdk::Client.new(secret_key: ..., sandbox_only: true)` everywhere except production. It raises `ArgumentError` unless the key starts with `sk_test_`.
- `client.live?` is true only for an `sk_live_` key. Use it to guard anything that must never run live, and to label logs.
- `sandbox_only` is a prefix check, not a sandbox. A test key can still reach live mode: the gem documents that `storefronts.publish` copies the storefront and its products to the live integration even with a test key. Do not call such methods from tests or seeds.

## 8. Webhooks

The gem's `PaystackSdk::Webhook` checks the signature (`construct_event`, `valid_signature?`, `verify!`) and the documented sender addresses (`trusted_ip?`). The paystack-sdk-webhooks skill covers the handler in full. For money safety:

- Verify the signature on the raw body before anything else. The IP check is optional, a second check, never a replacement.
- Respond `200 OK` fast and do the work in a job. Paystack's webhooks page says unacknowledged events are retried (every 3 minutes for 4 tries, then hourly for 72 hours in live mode; hourly for 10 hours in test mode; 30 second timeout). Documented, not observed.
- Expect repeats and out-of-order delivery. Paystack documents no event id: dedupe on the event name plus `data.id` or `data.reference`, and in the job call `payment_outcome` (rule 2) instead of trusting the event body.
- Grant value at most once: make the "paid" transition idempotent (a unique constraint or a row lock on your payment record), because the webhook, the return URL and a verify job can all arrive at the same time.

## 9. Reconciliation

Run a daily job that compares your records with Paystack's. Calls the gem has for it (each answered on the test API; how to match rows is up to you):

| Call | Use it for |
|---|---|
| `transactions.list(status:, from:, to:, per_page:, page:)` | Transactions Paystack has, to find ones you never recorded or never granted |
| `settlements.list(from:, to:)`, `settlements.transactions(id:)` | Payouts to your bank account and the transactions in each |
| `balances.fetch`, `balances.ledger(from:, to:)` | Your Paystack balance per currency and the entries that moved it |

## Pre-merge checklist

| Check | Pass when |
|---|---|
| Amounts | Integers in minor units, converted from a decimal; no Float; no raw `client.connection` call that skips the SDK's check |
| Reference | Created and saved before the call; one per attempt |
| Granting value | Only after `transactions.verify` + `paid?(amount:, currency:)` with your stored amount and currency, and the customer email checked |
| Grant once | The paid transition is idempotent across webhook, return URL and jobs |
| Writes after timeout | `ConnectionError` / `ServerError` on a write leads to verify by reference, never to a resend |
| Retries | `retry_non_idempotent` is not set |
| Webhooks | Signature checked on the raw body; 200 fast; deduped; no value from the event body |
| Stored data | Only `authorization_code` (encrypted) and display fields; no card number, CVV, PIN or OTP anywhere, including logs |
| Secrets | Key only from the environment or credentials; `paystack_sdk` >= 0.4.1 (earlier versions printed the key in `inspect`); nothing logs a whole client, resource or connection anyway |
| Environments | `sandbox_only: true` outside production; nothing that reaches live mode (such as `storefronts.publish`) in tests or seeds |
| Reconciliation | A scheduled job compares your records with `transactions.list` |

## Not verified

Nothing here ran with a live key. Paystack's accepting `100.0` and `"100"` was seen in test mode only. Whether a resend with the same reference is rejected while the first request is still in flight was not tested. Webhook retry timing and ordering come from Paystack's webhooks page, not from observation. `settlements.list` returned no rows on the test account, so its row shape was not seen.
