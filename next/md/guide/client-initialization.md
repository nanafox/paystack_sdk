# Client Initialization

```ruby
# Initialize with your Paystack secret key
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

# Or set the PAYSTACK_SECRET_KEY in your environment and do this instead
paystack = PaystackSdk::Client.new # => This will dynamically fetch the secret key

# You can access the connection directly if needed
connection = paystack.connection
```
