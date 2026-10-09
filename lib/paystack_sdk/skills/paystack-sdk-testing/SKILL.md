---
name: paystack-sdk-testing
description: 'Use when writing or running tests for an app that calls Paystack through the paystack_sdk gem: choosing keys for test, staging and CI, stubbing Paystack HTTP with WebMock (success, 400, 401, 429, 500 and timeout bodies), writing an opt-in test-API suite, using Paystacks published test cards and test mobile money number, testing a webhook endpoint, or deciding what test mode can never prove.'
---

# Testing an app that uses paystack_sdk

Three layers, cheapest first: (1) **HTTP stubs** in your normal suite (fast, offline, cover every error path); (2) an **opt-in test-API suite** that talks to Paystack with an `sk_test_` key; (3) a **manual live check** for what test mode cannot prove (last section). Conventions the other skills assume are in [[paystack-sdk-overview]].

## Keys

| Where | Key | Client |
|---|---|---|
| Unit tests | none needed; a dummy `sk_test_dummy` | `Client.new(secret_key: "sk_test_dummy")`, requests stubbed |
| Test-API suite, CI, staging, development | your Paystack **test** secret key (`sk_test_...`) | `Client.new(secret_key: key, sandbox_only: true)` |
| Production | the live key (`sk_live_...`) | no `sandbox_only` |

```ruby
client = PaystackSdk::Client.new(secret_key: ENV.fetch("PAYSTACK_SECRET_KEY"), sandbox_only: true)
client.live? # => false for sk_test_ keys; true only for sk_live_ keys
```

- `sandbox_only: true` raises `ArgumentError` at construction unless the key starts with `sk_test_`. It is a **prefix check**. It stops a live key from being used by mistake. It cannot stop a test-key call that Paystack itself routes to live mode (publishing a storefront copies it to the live integration even with a test key), so keep tests off calls that publish, register, activate, notify or pay out.
- `client.live?` is true only for a key starting `sk_live_`. Assert `expect(client).not_to be_live` in the test-API suite as a tripwire.
- Test and live are separate worlds: customers, transactions, saved cards (authorization codes), plans and references made with a test key do not exist in live, and the reverse. Never copy a test authorization code into a live flow.
- Never commit a key or put it in a log. Read it from the environment (CI secret).

## Stub Paystack at the HTTP edge (WebMock)

Stub the request to `https://api.paystack.co/...` and let `PaystackSdk::Client` run for real. Do not replace `client.transactions` or `Client` with a double: the SDK validates keywords before sending, builds the request, and wraps the body in `Response` (`success?`, `paid?`, `error_message`, dot access). A double skips all of that, so the test passes on code the SDK would reject, with a response shape the SDK never returns.

Copy this into `spec/support/paystack_stubs.rb` (it needs `webmock/rspec`):

```ruby
module PaystackStubs
  PAYSTACK_API = "https://api.paystack.co"

  # Paystack's success envelope: {status: true, message:, data: {...}}
  def paystack_ok(data = {}, message: "OK", meta: nil)
    body = {status: true, message: message, data: data}
    body[:meta] = meta if meta
    body
  end

  # Paystack's error envelope: {status: false, message:, meta: {nextStep:}, type:, code:}
  def paystack_error(message, code: nil, type: "validation_error", next_step: nil)
    body = {status: false, message: message}
    body[:meta] = {nextStep: next_step} if next_step
    body[:type] = type
    body[:code] = code if code
    body
  end

  # A transaction as `transactions.verify` returns it. Override any field.
  def paystack_transaction(overrides = {})
    {
      id: 1, reference: "order-1042", status: "success", amount: 5000, currency: "GHS",
      channel: "card", paid_at: "2026-01-01T10:00:00.000Z",
      customer: {email: "ama@example.com"},
      authorization: {authorization_code: "AUTH_abc123", reusable: true}
    }.merge(overrides)
  end

  # A stubbed response. `path` includes the query string if the request has one.
  def stub_paystack(verb, path, body, status: 200, headers: {})
    stub_request(verb, "#{PAYSTACK_API}#{path}").to_return(
      status: status, body: body.to_json,
      headers: {"Content-Type" => "application/json"}.merge(headers)
    )
  end

  def stub_paystack_timeout(verb, path)
    stub_request(verb, "#{PAYSTACK_API}#{path}").to_timeout
  end
end
```

Add `config.include PaystackStubs` in `spec/spec_helper.rb` (or `rails_helper.rb`) and `WebMock.disable_net_connect!` (the default with `webmock/rspec`).

### Each case, as the SDK sees it

```ruby
let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_dummy", retry_interval: 0) }

# Success: initialize
stub_paystack(:post, "/transaction/initialize", paystack_ok(
  {authorization_url: "https://checkout.paystack.com/abc", access_code: "abc", reference: "order-1042"},
  message: "Authorization URL created"
))
response = client.transactions.initiate(email: "ama@example.com", amount: 5000, currency: "GHS", reference: "order-1042")
response.success?          # => true
response.authorization_url # => "https://checkout.paystack.com/abc"

# Success: verify, then the check your app must make
stub_paystack(:get, "/transaction/verify/order-1042", paystack_ok(paystack_transaction, message: "Verification successful"))
client.transactions.verify(reference: "order-1042").paid?(amount: 5000, currency: "GHS") # => true

# 400 (and 404, 422): NOT raised, an unsuccessful Response
stub_paystack(:post, "/transaction/initialize", paystack_error("Duplicate Transaction Reference", code: "duplicate_reference"), status: 400)
response = client.transactions.initiate(email: "ama@example.com", amount: 5000, reference: "order-1042")
response.success?       # => false
response.error_message  # => "Duplicate Transaction Reference"

# 401: raises PaystackSdk::AuthenticationError ("Invalid key")
stub_paystack(:get, "/transaction/verify/x", paystack_error("Invalid key", code: "invalid_Key"), status: 401)

# 429: raises PaystackSdk::RateLimitError; retry_after comes from the x-ratelimit-reset header
stub_paystack(:get, "/transaction/verify/x", paystack_error("Rate limit exceeded"), status: 429, headers: {"x-ratelimit-reset" => "30"})

# 500: raises PaystackSdk::ServerError (status_code 500)
stub_paystack(:post, "/transaction/initialize", paystack_error("Internal server error"), status: 500)

# Timeout: raises PaystackSdk::TimeoutError
stub_paystack_timeout(:post, "/transaction/initialize")
```

Assert what you send, not only what you get back:

```ruby
stub = stub_paystack(:post, "/transaction/initialize", paystack_ok({reference: "order-1042"}))
client.transactions.initiate(email: "ama@example.com", amount: 5000, currency: "GHS", reference: "order-1042")
expect(stub.with(body: hash_including("amount" => 5000, "currency" => "GHS"))).to have_been_requested
```

Shapes, and how they were established:

- **Observed on the test API 2026-10-09**: the 401, 400 and 404 bodies. 401 (bad key): `{"status":false,"message":"Invalid key","meta":{"nextStep":"Ensure that you provide the correct authorization key for the request"},"type":"validation_error","code":"invalid_Key"}`. 400 (`transaction/initialize` with email `not-an-email`): message `"Invalid Email Address Passed"`, `type` `"validation_error"`, `code` `"invalid_email_address"`. 404 (`transaction/verify` of an unknown reference): message `"Transaction reference not found."`, `code` `"transaction_not_found"`. The success shapes of initialize and verify were also observed; `paystack_transaction` is a trimmed version of the real verify `data`, not a full copy.
- **Not observed**: the real bodies of a 429 and a 500 (stubbed with the same envelope as the others, which is an assumption), and a real timeout. What the SDK does with them is checked by the gem's own specs; the status codes and the header are what matters.
- The SDK retries reads on network errors and 429/502/503/504, and writes only on 429. In tests pass `retry_interval: 0` (as above) so a stubbed 429 or timeout does not sleep. A 429 whose `x-ratelimit-reset` is more than 10 seconds is raised at once.

The SDK validates input before sending, so a stub cannot make it send a bad email or a missing field: `initiate(email: "x", ...)` raises `PaystackSdk::InvalidFormatError` and never reaches your stub. Stub a 400 for something only Paystack can know (a duplicate reference, an unknown customer).

### What to test in your own code

For each Paystack call your app makes, one spec per branch the app must handle: success; unsuccessful (`success?` false, 400); `AuthenticationError` (alert, do not retry); `RateLimitError`; `ServerError` and `TimeoutError` **on a write** (the app must verify by reference before retrying, never re-send); and "verify says not paid" (amount or currency mismatch: build it with `paystack_transaction(amount: 4000)`).

## An opt-in test-API suite

The gem's own `spec/sandbox/transactions_spec.rb` runs against Paystack's real test API only when `PAYSTACK_TEST_SECRET_KEY` is set, and is skipped otherwise. Do the same:

```ruby
RSpec.describe "Paystack test API", :paystack_sandbox do
  key = ENV["PAYSTACK_TEST_SECRET_KEY"].to_s

  before do
    skip "set PAYSTACK_TEST_SECRET_KEY to an sk_test_ key" unless key.start_with?("sk_test_")
    WebMock.allow_net_connect!
  end

  after { WebMock.disable_net_connect! }

  let(:client) { PaystackSdk::Client.new(secret_key: key, sandbox_only: true) }

  it "initializes and verifies a 100 pesewa payment" do
    reference = "myapp-test-#{Time.now.to_i}-#{rand(100_000)}"

    init = client.transactions.initiate(email: "test@example.com", amount: 100, currency: "GHS", reference: reference)
    expect(init).to be_success
    expect(init.reference).to eq(reference)

    verified = client.transactions.verify(reference: reference)
    expect(verified.status).to eq("abandoned") # nobody paid it
    expect(verified.paid?(amount: 100, currency: "GHS")).to be(false)
  end
end
```

- Skip when the key is unset or is not `sk_test_`; never fall back to `PAYSTACK_SECRET_KEY`, which on a developer machine may be live.
- Amounts of 100 pesewas (GHS 1.00). A **unique reference** per run: observed on the test API 2026-10-09, initializing a reference twice returns an unsuccessful Response, `Duplicate Transaction Reference` (`duplicate_reference`), the second time.
- Keep it out of the default run (tag it and exclude the tag, or run only `rspec spec/paystack_sandbox`). Each run leaves a test-mode transaction on the account (an abandoned one, in the example above).
- Do not call endpoints that publish, register, activate, notify or pay out from the suite (see Keys).

## Paystack's published test data

Documented on Paystack's Test Payments page (https://paystack.com/docs/payments/test-payments/), not observed by this gem except where marked. Expiry can be any future date (the page shows 09/27).

| Card | Number | CVV | Extra steps |
|---|---|---|---|
| No validation, reusable | 4084 0840 8408 4081 | 408 | none |
| PIN | 5078 5078 5078 5078 12 | 081 | PIN 1111 |
| PIN + OTP | 5060 6666 6666 6666 666 | 123 | PIN 1234, OTP 123456 |
| PIN + phone + OTP | 5078 5078 5078 5078 04 | 884 | PIN 0000, OTP 123456 |

The page also lists a declined card (4084 0800 0000 5408, CVV 001), a card where no token is generated (5078 5078 5078 5078 53, CVV 082, PIN 0000), and cards that decide how a **refund** ends (failed 4084 0800 0067 1803 CVV 180; needs attention 4084 0800 0067 1902 CVV 190). Not exercised by this gem.

- Cards are entered on Paystack's checkout page (from `initiate`'s `authorization_url`). Through the API a card goes through the raw connection (`client.connection.post("/charge", ...)` with a `card` object) because `charges.create` has no card keyword. A real person's card number never belongs in your app's servers or logs; test numbers are the only card numbers in tests.
- **Mobile money**: MTN test number `0551234987` (documented as "No PIN/OTP"). Observed on the test API 2026-10-09: `charges.mobile_money(... phone: "0551234987", provider: "mtn", currency: "GHS", amount: 100)` answered `Charge attempted` with status `success` at once, and `verify` then showed `success` and `paid?` true. This proves your code handles the happy path. **It proves nothing about live mobile money**, where the payer gets a prompt and the status is `pay_offline`/`send_pin`/`send_otp` for a while. See the `paystack-sdk-mobile-money` and `paystack-sdk-charge-statuses` skills, and drive those statuses with stubs.
- The page's bank accounts (Zenith, Kuda), EFT accounts, M-PESA and Orange numbers are for Nigeria, Kenya or Cote d'Ivoire; skip them for Ghana.

## Testing a webhook endpoint

Paystack signs the raw body with HMAC SHA512 of your secret key in `x-paystack-signature`. In a test, build a body, sign it with `PaystackSdk::Webhook.sign`, and post it to your endpoint with that header:

```ruby
secret = "sk_test_dummy"
body = {event: "charge.success", data: {id: 1, reference: "order-1042", status: "success", amount: 5000, currency: "GHS"}}.to_json
signature = PaystackSdk::Webhook.sign(body, secret)

event = PaystackSdk::Webhook.construct_event(payload: body, signature: signature, secret: secret)
event.event            # => "charge.success"
event.data.reference   # => "order-1042"

PaystackSdk::Webhook.valid_signature?(payload: body + " ", signature: signature, secret: secret) # => false: one changed byte
```

Send exactly the string you signed (do not post a hash that the test framework re-serialises), assert a wrong or missing signature is rejected, and assert that the same event posted twice grants value once (Paystack retries events your server does not acknowledge, so the same event can arrive again; Paystack documents no event id, so dedupe on the event name plus `data.id` or `data.reference`). The endpoint should still **verify by reference** with the API rather than trust the body (stub `verify` with `stub_paystack`).

## What test mode cannot prove

| Not proven by test mode | What to do instead |
|---|---|
| Live mobile money: the prompt, the wait, the payer declining or timing out | Stub every non-final status; then one supervised live payment of the smallest real amount, with a refund |
| Webhooks actually arriving at your server (public URL, TLS, firewall, the three Paystack IPs, your response time) | Set the test webhook URL on the dashboard and make a test payment; or POST a signed body to your own endpoint |
| Settlements and payouts to a bank or wallet | Check the first live settlement by hand |
| Real declines, insufficient funds, fraud checks, bank 3DS | Stub the failure bodies; the docs list a declined test card, which is only a simulation |
| Live-only configuration (live key, live webhook URL, live callback URL, account activation) | Review by hand before launch; `sandbox_only: true` cannot catch a wrong key in production |

Not verified by this gem: any behaviour with a live key (it has never been exercised with one), the real 429 and 500 bodies, and the test-card flows through checkout. Say so rather than asserting them.

## Rules

1. Test and CI use `sk_test_` keys and `sandbox_only: true`; a live key never goes in a test environment.
2. Stub at HTTP with WebMock; do not mock `PaystackSdk::Client` or its resources.
3. Test the unhappy branches of every call: unsuccessful `Response`, 401, 429, 5xx, timeout, and "verify says not paid".
4. After a write times out or returns 5xx, the test expects a verify by reference, not a second write.
5. Test-API runs: opt in by environment variable, `sk_test_` only, 100 pesewas, unique references, nothing that publishes or pays out.
6. Passing test mode is not a launch check for mobile money, webhooks or settlements.
