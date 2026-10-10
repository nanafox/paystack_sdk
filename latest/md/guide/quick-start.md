# Quick Start

```ruby
require 'paystack_sdk'

# Initialize the client with your secret key
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

# Initialize a transaction
begin
  response = paystack.transactions.initiate(
    email: "customer@email.com",
    amount: 2300,  # Amount in the smallest currency unit (kobo for NGN)
    currency: "NGN"
  )

  if response.success?
    puts "Visit this URL to complete payment: #{response.authorization_url}"
    puts "Transaction reference: #{response.reference}"
  else
    puts "Error: #{response.error_message}"
  end
rescue ArgumentError => e
  puts "Missing required data: #{e.message}"
rescue PaystackSdk::InvalidFormatError => e
  puts "Invalid data format: #{e.message}"
end

# Create a customer
begin
  customer_response = paystack.customers.create(
    email: "customer@email.com",
    first_name: "John",
    last_name: "Doe"
  )

  if customer_response.success?
    puts "Customer created: #{customer_response.data.customer_code}"
  else
    puts "Error: #{customer_response.error_message}"
  end
rescue PaystackSdk::ValidationError => e
  puts "Validation error: #{e.message}"
end
```

## Response Format

The SDK handles API responses that use string keys (as returned by Paystack) and provides seamless access through both string and symbol notation. All response data maintains the original string key format from the API while offering convenient dot notation access.

## Error Handling

The SDK uses a two-tier error handling approach:

1. **Validation Errors** (thrown as exceptions) - for missing or invalid input data
2. **API Response Errors** (returned as unsuccessful Response objects) - for API-level issues

#### Input Validation

The SDK validates your parameters **before** making API calls and throws exceptions immediately for data issues:

```ruby
begin
  # Ruby raises ArgumentError for a missing required keyword, before any API call
  response = paystack.transactions.initiate(amount: 1000) # Missing required email
rescue ArgumentError => e
  puts "Fix your data: #{e.message}" # => "missing keyword: :email"
end
```

#### API Response Handling

All successful API calls return a `Response` object that you can check for success:

```ruby
response = paystack.transactions.initiate(**valid_params)

if response.success?
  puts "Transaction created: #{response.authorization_url}"
else
  puts "Transaction failed: #{response.error_message}"

  # Get detailed error information
  error_details = response.error_details
  puts "Status code: #{error_details[:status_code]}"
  puts "Error message: #{error_details[:message]}"
end
```

**Note**: The SDK raises exceptions for:

- **Validation errors** - when required parameters are missing or have invalid formats
- **Authentication errors** (401) - usually configuration issues
- **Rate limiting** (429) - raised after automatic retries are exhausted, or immediately if Paystack asks for a long wait (see [Timeouts and Retries](https://nanafox.github.io/paystack_sdk/latest/md/guide/timeouts-and-retries.md))
- **Server errors** (5xx) - Paystack infrastructure issues
- **Network errors** - timeouts and connection failures, raised as `PaystackSdk::TimeoutError` / `PaystackSdk::ConnectionError`

All other API errors (resource not found, business logic errors, etc.) are returned as unsuccessful Response objects.
