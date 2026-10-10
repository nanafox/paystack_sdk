# What a result means

Most mistakes with a payment API come from reading one flag as another. This page is the short version of what each signal in `paystack_sdk` does and does not tell you.

## `success?` is not "the payment worked"

`response.success?` is true when Paystack accepted the call and answered with a success HTTP status. `transactions.verify` succeeds for any reference Paystack knows, paid or not. The outcome of the payment is in `data.status`.

| You want to know | Look at | Not at |
|---|---|---|
| Was the call accepted? | `success?` | |
| Was the customer charged the right amount? | `paid?(amount:, currency:)` | `success?` |
| What state is the transaction in? | `status?(:success)`, or `data.status` | the HTTP status |
| Why did a charge stop? | `data.status` and `gateway_response` | `success?` |

## Three kinds of failure, three behaviours

- **A call that cannot be valid** (a malformed email, an amount of `50.0`) raises `PaystackSdk::InvalidValueError` before anything is sent.
- **A 400 or 404 from Paystack** comes back as a `Response` with `success?` false and an `error_message`. It does not raise.
- **A bad key, a rate limit or a server error** (401, 429, 5xx) raises, so it cannot be mistaken for a result.

## Trust your own record, not the browser

Verify by `reference`, check the amount and currency with `paid?`, and compare the customer email before giving value. A redirect to your `callback_url` and a webhook body are both prompts to check, not proof.

## Retries are conservative on purpose

Reads retry on network errors and on 429, 502, 503 and 504. Writes retry only on 429, and never after a timeout, because a write that timed out may have succeeded. Retrying it could charge a customer twice.

See the [Response reference](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), [Errors](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/errors.md) and the [money-safety skill](https://nanafox.github.io/paystack_sdk/0.5.0/skills/paystack-sdk-money-safety.md).
