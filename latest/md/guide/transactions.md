# Transactions

The SDK provides comprehensive support for Paystack's Transaction API.

## Initialize a Transaction

```ruby
# Amount is in the smallest currency unit (e.g., kobo, pesewas, cents)
response = paystack.transactions.initiate(
  email: "customer@example.com",
  amount: 10000,
  currency: "GHS",
  callback_url: "https://example.com/callback"
)

if response.success?
  puts "Transaction initialized successfully!"
  puts "Authorization URL: #{response.authorization_url}"
  puts "Access Code: #{response.access_code}"
  puts "Reference: #{response.reference}"
else
  puts "Error: #{response.error_message}"
end
```
