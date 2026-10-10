# Timeouts and Retries

Connections built by the SDK time out and retry transient failures by default:

```ruby
client = PaystackSdk::Client.new(
  secret_key: "sk_test_xxx",
  timeout: 30,        # seconds to wait for a response
  open_timeout: 5,    # seconds to wait for the connection to open
  max_retries: 2,     # retries after the first attempt (0 disables retrying)
  retry_interval: 0.5 # base backoff in seconds, doubled on each retry with jitter
)
```

- Read-only requests (`GET`) are retried on network failures and `429`/`502`/`503`/`504` responses.
- Anything that writes (`POST`, `PUT`, `DELETE`) is retried **only on `429`**, where Paystack rejected the
  request for exceeding the rate limit. A timeout or `5xx` on a write may mean Paystack processed it, so it is
  not retried. Pass `retry_non_idempotent: true` only if you deduplicate yourself (e.g. verify by reference first).
- On a `429` the SDK waits for Paystack's `x-ratelimit-reset` header (seconds) before retrying. If the wait
  exceeds 10 seconds it stops retrying and raises `PaystackSdk::RateLimitError` (`#retry_after` holds the value).
- Errors that survive all retries are raised as `PaystackSdk::RateLimitError`, `PaystackSdk::ServerError`,
  `PaystackSdk::TimeoutError` or `PaystackSdk::ConnectionError`, all of which inherit from `PaystackSdk::Error`.
- These options only apply to connections the SDK creates. Passing them together with your own `Faraday::Connection` raises `ArgumentError`; configure your connection yourself. Invalid values (e.g. a negative `max_retries`) also raise `ArgumentError`.
