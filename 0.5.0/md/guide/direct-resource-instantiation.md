# Direct Resource Instantiation

For more advanced usage, you can instantiate resource classes directly:

```ruby
# With a secret key
transactions = PaystackSdk::Resources::Transactions.new(secret_key: "sk_test_xxx")
customers = PaystackSdk::Resources::Customers.new(secret_key: "sk_test_xxx")

# With an existing Faraday connection
connection = Faraday.new(url: "https://api.paystack.co") do |conn|
  # Configure the connection
end

# The secret key can be omitted if set in an environment
transactions = PaystackSdk::Resources::Transactions.new(connection, secret_key:)
customers = PaystackSdk::Resources::Customers.new(connection, secret_key:)
```

For more detailed documentation on specific resources, please refer to the following guides:

- [Transactions](https://paystack.com/docs/api/transaction/)
- [Customers](https://paystack.com/docs/api/customer/)
- [Plans](https://paystack.com/docs/api/plan/)
- [Subscriptions](https://paystack.com/docs/api/subscription/)
- [Payment Channels: Mobile Money](https://paystack.com/docs/payments/payment-channels/#mobile-money)
