---
name: paystack-sdk-overview
description: 'Use when writing or reviewing Ruby code that calls Paystack through the paystack_sdk gem: creating a client, picking a resource and method, reading a Response, handling errors, or deciding how far to trust a result. Load this first; it covers the conventions every other paystack-sdk skill assumes.'
---

# paystack_sdk: overview and conventions

`paystack_sdk` is a Ruby client for Paystack's API. It mirrors Paystack's endpoints, does not reshape Paystack's field names, and validates input before sending. This skill was installed from a specific gem version (see `metadata.gem_version` above). If `Gemfile.lock` pins a different version, run `paystack_sdk skills install` (or `rails g paystack_sdk:skills`) again so the skills match the code.

## Set up the client

```ruby
client = PaystackSdk::Client.new(secret_key: ENV.fetch("PAYSTACK_SECRET_KEY"))

# Staging and CI: refuse anything but a test key, at construction, before any request
client = PaystackSdk::Client.new(secret_key: ENV.fetch("PAYSTACK_SECRET_KEY"), sandbox_only: true)

client.live? # => true only for a live key (sk_live_...)
```

- With no `secret_key:` the client reads `PAYSTACK_SECRET_KEY`.
- `sandbox_only: true` raises `ArgumentError` unless the key starts with `sk_test_`. It checks the key's prefix only. It cannot stop a call that reaches live mode from a test key (publishing a storefront does).
- Connection options: `timeout` (default 30 s), `open_timeout` (5 s), `max_retries` (2), `retry_interval` (0.5 s). Leave `retry_non_idempotent` off; see "Retries".

## Pick the resource

Each Paystack resource is a method on the client: `transactions`, `charges`, `customers`, `refunds`, `transfers`, `transfer_recipients`, `banks`, `miscellaneous`, `subaccounts`, `splits`, `settlements`, `disputes`, `balances`, `plans`, `subscriptions`, `payment_requests`, `pages`, `products`, `orders`, `storefronts`, `bulk_charges`, `dedicated_virtual_accounts`, `apple_pay`, `integrations`, `virtual_terminals`, `direct_debits`, `terminals`, `webhook_events` (the log of webhooks Paystack sent you; not in Paystack's OpenAPI spec). The signature and a `@see` link to Paystack's docs are in each method's YARD comment in the gem; read them rather than guessing keywords.

## Conventions

- **Keyword arguments, never a payload hash.** `client.transactions.initiate(email: "ama@example.com", amount: 5000)`. To pass a hash you hold, splat it: `initiate(**params)`.
- **Ruby names are snake_case; Paystack's names go on the wire.** `per_page:` is sent as `perPage`, `next_cursor:` as `next`. Never write Paystack's camelCase names in Ruby calls.
- **Amounts are integers in the currency's smallest unit** (pesewas, kobo, cents). `5000` is GHS 50.00. Never send a Float.
- **Path values are escaped.** A blank value raises `PaystackSdk::MissingParamError`, and `.` or `..` raises `PaystackSdk::InvalidValueError`, so a caller cannot redirect a request to another endpoint.
- **Identifier keywords follow Paystack's docs**: `id_or_code:`, `email_or_code:`, `reference:`. The numeric ID and the string code are not always interchangeable; the method's docs and its topic skill say which.

## Read a Response

Every call returns a `PaystackSdk::Response`.

```ruby
response = client.transactions.verify(reference: "order-1042")

response.success?          # the call succeeded
response.status            # a field of Paystack's data, by dot access (raises NoMethodError if the key is absent)
response.customer.email    # nested fields too
response[:amount]          # hash-style works with strings or symbols
response.paid?(amount: 5000, currency: "GHS") # success + status "success" + amount and currency match
response.status?(:send_pin)                   # compare the "status" field with any value
response.meta              # pagination: total, page, pageCount, perPage
response.dig(:authorization, :authorization_code) # nil if any key is missing: use it for optional fields
response.original_response # the raw body, for anything not wrapped
response.error_message     # Paystack's message when the call did not succeed
```

Lists: `response.each` and `first`/`last` give you wrapped rows with dot access (`row.reference`). Enumerable calls such as `map` and `select` pass your block plain **string-keyed Hashes** and return a wrapped result, not an Array. For a plain Array of rows, use `response.original_response["data"]`.

## What raises and what returns

| Situation | What you get |
|---|---|
| A required keyword is missing | `ArgumentError` |
| A value fails validation before sending | a `PaystackSdk::ValidationError` (`MissingParamError`, `InvalidFormatError`, `InvalidValueError`) |
| 401, bad or missing key | raises `PaystackSdk::AuthenticationError` |
| 429, rate limited | raises `PaystackSdk::RateLimitError` (`retry_after` when Paystack gives it) |
| 5xx | raises `PaystackSdk::ServerError` |
| Any other 4xx (400, 404, 422...) | **returns an unsuccessful `Response`; nothing is raised.** Check `success?` and read `error_message` |
| Timeout or no connection | raises `PaystackSdk::TimeoutError` or `PaystackSdk::ConnectionError` |

All of these inherit from `PaystackSdk::Error`. The classic bug is calling `.data` on a 400 and treating the result as success. Always branch on `success?`.

## Retries

Reads (GET) retry on network errors and on 429/502/503/504. **Writes retry only on 429**, because a timeout or 5xx on a write may mean Paystack processed it. So after a `TimeoutError` or `ServerError` on a write, do not call it again blindly: look the thing up first (for a payment, `transactions.verify(reference:)`).

## Rules that prevent most bugs

1. **Never give value because of a redirect, a callback or a webhook alone.** Verify by reference: `client.transactions.verify(reference: ref).paid?(amount: expected_amount, currency: "GHS")`. Compare against what you expected to charge, not against what the response says.
2. **Create and store your own `reference` before you call Paystack**, so you can verify the outcome after a timeout or a crash.
3. **Branch on `success?` for every call** (see the table above).
4. **Keep secret keys out of code and logs**, and use `sandbox_only: true` outside production.

## Topic skills: load the one that matches the task

| You are... | Load |
|---|---|
| Taking a payment through Paystack's hosted checkout (initiate, redirect, verify) | [paystack-sdk-payments](paystack-sdk-payments.md) |
| Reacting to what a Charge API call returns (`send_pin`, `send_otp`, `pay_offline`, `failed`...) | [paystack-sdk-charge-statuses](paystack-sdk-charge-statuses.md) |
| Charging a mobile money wallet (Ghana: MTN, Telecel, AT Money) | [paystack-sdk-mobile-money](paystack-sdk-mobile-money.md) |
| Charging a customer's saved card again (renewals, recurring giving) | [paystack-sdk-saved-card-renewals](paystack-sdk-saved-card-renewals.md) |
| Receiving Paystack webhooks | [paystack-sdk-webhooks](paystack-sdk-webhooks.md) |
| Refunding a payment | [paystack-sdk-refunds](paystack-sdk-refunds.md) |
| Writing tests for code that calls Paystack | [paystack-sdk-testing](paystack-sdk-testing.md) |
| Reviewing or writing anything that handles money or keys (apply it before merging payment code) | [paystack-sdk-money-safety](paystack-sdk-money-safety.md) |

## What the gem's maintainers have not verified

Nothing has been exercised with a live key. Some operations could not be exercised against Paystack's test API either, and the README marks them "unverified": terminals, dedicated virtual accounts, and the state-changing calls on Apple Pay, integrations, virtual terminals and direct debits. Do not tell a user such a call works; say it follows Paystack's documentation and has not been confirmed. Test mode also does not model everything live mode does (for example, a mobile money charge answers `success` at once in test mode).
