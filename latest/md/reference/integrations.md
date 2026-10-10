# Integrations

Integration operations.

Use it as `client.integrations`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `fetch_payment_session_timeout`

```ruby
integrations.fetch_payment_session_timeout
```

Fetch Payment Session Timeout.

Fetch the session timeout of a transaction

Paystack docs: <https://paystack.com/docs/api/integration/#fetch-timeout>

### `update_payment_session_timeout`

```ruby
integrations.update_payment_session_timeout(timeout:)
```

Update Payment Session Timeout.

Update the session timeout of a transaction

| Parameter | Type | Required | Description |
|---|---|---|---|
| `timeout` | Integer | yes | Time in seconds before a transaction becomes invalid |

::: warning Note
Changes the payment session timeout of the whole integration (account-wide), and the setting may be shared with LIVE mode even when you call it with a test key (sk_test_). It has not been verified against the live API. Read the current value with `fetch_payment_session_timeout` first, and do not call this to try the API out.
:::

Paystack docs: <https://paystack.com/docs/api/integration/#update-timeout>


