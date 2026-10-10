# Response Handling

## Working with Response Objects

All API requests return a `PaystackSdk::Response` object that provides easy access to the response data.

```ruby
response = paystack.transactions.initiate(**params)

# Check if the request was successful
response.success?  # => true or false

# Access response message
response.api_message  # => "Authorization URL created"

# Access data using dot notation
response.data.authorization_url
response.data.access_code

# Access data directly from the response
response.authorization_url  # Same as response.data.authorization_url

# Access nested data
response.data.customer.email

# Hash-style access works with strings or symbols
response[:reference]
response["reference"]
response[:customer][:email]
response.key?(:reference)  # => true

# For arrays, use array methods
response.data.first  # First item in an array
response.data.last   # Last item in an array
response.data.size   # Size of the array

# Iterate through array data
response.data.each do |item|
  puts item.id
end
```

## Pagination Metadata

List responses carry Paystack's pagination details in `meta`:

```ruby
response = paystack.transactions.list(per_page: 20)

response.meta.total      # => 40
response.meta.page       # => 1
response.meta.pageCount  # => 2
response.meta.perPage    # => 20
```

`response.meta` is `nil` when the response has no `meta`.

## Optional Fields: `dig`

Dot access raises `NoMethodError` for a key that is not in the response. That is what you want for a typo, but not for a field Paystack only sometimes sends (`paid_at` on an unpaid transaction, `authorization` details on a payment without a card). Read those with `dig`: it returns `nil` as soon as a key along the path is missing, accepts strings or symbols (and an Integer to index an Array), and returns the value as it is, like `Hash#dig`.

```ruby
response = paystack.transactions.verify(reference: "order-1042")

response.dig(:paid_at)                              # => "2025-06-01T10:00:00.000Z" or nil
response.dig(:authorization, :authorization_code)   # => "AUTH_xxxx" or nil
response.dig(:customer, :email)                     # => "ama@example.com"
response.dig(:log, :history, 0, :message)           # an Integer indexes an Array
```

`response[:key]` also gives `nil` for a missing key, but wraps what it finds in a `Response`; `dig` gives you the plain value.

## Accessing the Original Response

Sometimes you may need access to the original API response:

```ruby
response = paystack.transactions.list

# Access the original response body
original = response.original_response

# Anything else in the body is still reachable
original.dig("meta", "total")
```

## Exception Handling

The SDK provides specific error classes for different types of failures, making it easier to handle errors appropriately:

```ruby
begin
  response = paystack.transactions.verify(reference: "invalid_reference")
rescue PaystackSdk::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue PaystackSdk::RateLimitError => e
  # retry_after is nil when Paystack did not send x-ratelimit-reset
  puts "Rate limit exceeded. Retry after: #{e.retry_after || "unknown"} seconds"
rescue PaystackSdk::ServerError => e
  puts "Server error: #{e.message}"
rescue PaystackSdk::TimeoutError, PaystackSdk::ConnectionError => e
  # For writes (e.g. creating a transfer) the request may still have been processed:
  # verify by your own reference before retrying
  puts "Could not complete the request: #{e.message}"
rescue PaystackSdk::APIError => e
  puts "API error: #{e.message}"
rescue PaystackSdk::Error => e
  puts "General error: #{e.message}"
end

# Alternatively, check response success without exceptions
response = paystack.transactions.verify(reference: "invalid_reference")

unless response.success?
  puts "Error: #{response.error_message}"

  # Take action based on the error
  if response.error_message.include?("not found")
    puts "The transaction reference was not found."
  elsif response.error_message.include?("Invalid key")
    puts "API authentication failed. Check your API key."
  end
end
```

### Error Types

The SDK includes several specific error classes:

- **`PaystackSdk::ValidationError`** - Base class for all validation errors

  - **`PaystackSdk::MissingParamError`** - Raised when required parameters are missing
  - **`PaystackSdk::InvalidFormatError`** - Raised when parameters have invalid format (e.g., invalid email)
  - **`PaystackSdk::InvalidValueError`** - Raised when parameters have invalid values (e.g., not in allowed list)

- **`PaystackSdk::APIError`** - Base class for API-related errors
  - **`PaystackSdk::AuthenticationError`** - Authentication failures
  - **`PaystackSdk::ResourceNotFoundError`** - Resource not found (404 errors)
  - **`PaystackSdk::RateLimitError`** - Rate limiting encountered
  - **`PaystackSdk::ServerError`** - Server errors (5xx responses)

- **`PaystackSdk::ConnectionError`** - Could not reach Paystack (DNS, refused connection, TLS) after retries
  - **`PaystackSdk::TimeoutError`** - The request timed out after retries

### Validation Error Examples

The SDK validates your input data **before** making API calls and will throw exceptions immediately if required data is missing or incorrectly formatted:

```ruby
# Missing required keyword
begin
  paystack.transactions.initiate(amount: 1000) # Missing email
rescue ArgumentError => e
  puts e.message # => "missing keyword: :email"
end

# Invalid format
begin
  paystack.transactions.initiate(
    email: "invalid-email",  # Not a valid email format
    amount: 1000
  )
rescue PaystackSdk::InvalidFormatError => e
  puts e.message # => "Invalid format for Email. Expected format: valid email address"
end

# Invalid value
begin
  paystack.customers.set_risk_action(
    customer: "CUS_123",
    risk_action: "invalid_action"  # Not in allowed values
  )
rescue PaystackSdk::InvalidValueError => e
  puts e.message # => "Invalid value for risk_action: must be one of: allow, deny, default"
end
```

These validation errors are thrown immediately and prevent the API call from being made, helping you catch data issues early in development.
