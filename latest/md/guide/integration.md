# Integration

Settings of your Paystack integration (the account). Currently the payment session timeout.

## Payment Session Timeout

```ruby
# Seconds before a transaction becomes invalid. The test API returned 0 for an account that never set one.
response = paystack.integrations.fetch_payment_session_timeout
puts response.data.payment_session_timeout

paystack.integrations.update_payment_session_timeout(timeout: 30)
```

`update_payment_session_timeout` changes a setting of the whole integration, which may be shared with live mode even when you use a test key, so treat it as a live change. It is **unverified**: it was not called against the Paystack API while building the SDK for that reason. It is generated from the OpenAPI spec and the docs page (`PUT /integration/payment_session_timeout`, body `timeout`, an integer in seconds). Only `fetch_payment_session_timeout` was checked against the API.
