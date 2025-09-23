# Paystack Ruby SDK: Simplify Payments

The `paystack_sdk` gem provides a simple and intuitive interface for interacting with Paystack's payment gateway API. It allows developers to easily integrate Paystack's payment processing features into their Ruby applications. With support for various endpoints, this SDK simplifies tasks such as initiating transactions, verifying payments, managing customers, and more.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Client Initialization](#client-initialization)
  - [Transactions](#transactions)
    - [Initialize a Transaction](#initialize-a-transaction)
    - [Verify a Transaction](#verify-a-transaction)
    - [List Transactions](#list-transactions)
    - [Fetch a Transaction](#fetch-a-transaction)
    - [Get Transaction Totals](#get-transaction-totals)
  - [Charges (Mobile Money)](#charges-mobile-money)
  - [Customers](#customers)
    - [Create a Customer](#create-a-customer)
    - [List Customers](#list-customers)
    - [Fetch a Customer](#fetch-a-customer)
    - [Update a Customer](#update-a-customer)
    - [Validate a Customer](#validate-a-customer)
    - [Set Risk Action](#set-risk-action)
    - [Deactivate Authorization](#deactivate-authorization)
  - [Response Handling](#response-handling)
    - [Working with Response Objects](#working-with-response-objects)
    - [Accessing the Original Response](#accessing-the-original-response)
    - [Error Handling](#error-handling)
- [Advanced Usage](#advanced-usage)
  - [Environment Variables](#environment-variables)
  - [Direct Resource Instantiation](#direct-resource-instantiation)
- [Development](#development)
  - [Style and Linting](#style-and-linting)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paystack_sdk'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install paystack_sdk
```

## Quick Start

```ruby
require 'paystack_sdk'

# Initialize the client with your secret key
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

# Initialize a transaction
params = {
  email: "customer@email.com",
  amount: 2300,  # Amount in the smallest currency unit (kobo for NGN)
  currency: "NGN"
}

begin
  response = paystack.transactions.initiate(params)

  if response.success?
    puts "Visit this URL to complete payment: #{response.authorization_url}"
    puts "Transaction reference: #{response.reference}"
  else
    puts "Error: #{response.error_message}"
  end
rescue PaystackSdk::MissingParamError => e
  puts "Missing required data: #{e.message}"
rescue PaystackSdk::InvalidFormatError => e
  puts "Invalid data format: #{e.message}"
end

# Create a customer
customer_params = {
  email: "customer@email.com",
  first_name: "John",
  last_name: "Doe"
}

begin
  customer_response = paystack.customers.create(customer_params)

  if customer_response.success?
    puts "Customer created: #{customer_response.data.customer_code}"
  else
    puts "Error: #{customer_response.error_message}"
  end
rescue PaystackSdk::ValidationError => e
  puts "Validation error: #{e.message}"
end
```

### Response Format

The SDK handles API responses that use string keys (as returned by Paystack) and provides seamless access through both string and symbol notation. All response data maintains the original string key format from the API while offering convenient dot notation access.

### Error Handling

The SDK uses a two-tier error handling approach:

1. **Validation Errors** (thrown as exceptions) - for missing or invalid input data
2. **API Response Errors** (returned as unsuccessful Response objects) - for API-level issues

#### Input Validation

The SDK validates your parameters **before** making API calls and throws exceptions immediately for data issues:

```ruby
begin
  # This will throw an exception before making any API call
  response = paystack.transactions.initiate({amount: 1000}) # Missing required email
rescue PaystackSdk::MissingParamError => e
  puts "Fix your data: #{e.message}"
end
```

#### API Response Handling

All successful API calls return a `Response` object that you can check for success:

```ruby
response = paystack.transactions.initiate(valid_params)

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
- **Rate limiting** (429) - requires retry logic
- **Server errors** (5xx) - Paystack infrastructure issues
- **Network errors** - connection failures

All other API errors (resource not found, business logic errors, etc.) are returned as unsuccessful Response objects.

## Usage

### Client Initialization

```ruby
# Initialize with your Paystack secret key
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

# Or set the PAYSTACK_SECRET_KEY in your environment and do this instead
paystack = PaystackSdk::Client.new # => This will dynamically fetch the secret key

# You can access the connection directly if needed
connection = paystack.connection
```

### Transactions

The SDK provides comprehensive support for Paystack's Transaction API.

#### Initialize a Transaction

```ruby
# Prepare transaction parameters
params = {
  email: "customer@example.com",
  amount: 10000,  # Amount in the smallest currency unit (e.g., kobo, pesewas, cents)
  currency: "GHS",
  callback_url: "https://example.com/callback"
}

# Initialize the transaction
response = paystack.transactions.initiate(params)

if response.success?
  puts "Transaction initialized successfully!"
  puts "Authorization URL: #{response.authorization_url}"
  puts "Access Code: #{response.access_code}"
  puts "Reference: #{response.reference}"
else
  puts "Error: #{response.error_message}"
end
```

### Charges (Mobile Money)

Initiate Mobile Money payments using the Charges API. This channel is available to businesses in Ghana, Kenya, and Côte d'Ivoire. See the Paystack guide: [Mobile Money](https://paystack.com/docs/payments/payment-channels/#mobile-money).

Supported providers (case-insensitive): `mtn`, `atl` (ATMoney/Airtel Money), `vod` (Vodafone), `mpesa`, `orange`, `wave`.

#### Create a Mobile Money Charge

```ruby
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

response = paystack.charges.mobile_money(
  email: "customer@email.com",
  amount: 100,             # smallest unit (pesewas/cent)
  currency: "GHS",        # e.g., GHS, KES, XOF
  mobile_money: {
    phone: "0551234987",
    provider: "mtn"       # mtn | atl | vod | mpesa | orange | wave
  }
)

if response.success?
  case response.status
  when "pay_offline"
    # Show instruction text and wait for webhook or verify later
    puts response.display_text
  when "send_otp"
    # For Vodafone, collect voucher/OTP and submit below
    puts response.display_text
  when "success"
    puts "Charge completed: #{response.reference}"
  else
    puts "Status: #{response.status}"
  end
else
  puts "Charge failed: #{response.error_message}"
end
```

#### Submit OTP (e.g., Vodafone voucher)

```ruby
otp_response = paystack.charges.submit_otp(
  reference: "r13havfcdt7btcm",
  otp: "123456"
)

puts otp_response.status # => "success" when authorized
```

#### Verify after timeout or via webhook

For offline flows, listen for `charge.success` webhooks. You may also verify after the provider timeout window. Note: `transactions.verify` expects a transaction reference (often the same `reference` you supplied when creating the charge once it converts to a transaction):

```ruby
verify = paystack.transactions.verify(reference: "r13havfcdt7btcm")
puts verify.status # "success", "failed", or current state
```

#### Verify a Transaction

```ruby
# Verify using transaction reference
response = paystack.transactions.verify(reference: "transaction_reference")

if response.success?
  transaction = response.data
  puts "Transaction verified successfully!"
  puts "Status: #{transaction.status}"
  puts "Amount: #{transaction.amount}"
  puts "Currency: #{transaction.currency}"
  puts "Customer Email: #{transaction.customer.email}"

  # Check specific transaction status
  case transaction.status
  when "success"
    puts "Payment successful!"
  when "pending"
    puts "Payment is pending."
  else
    puts "Current status: #{transaction.status}"
  end
else
  puts "Verification failed: #{response.error_message}"
end
```

#### List Transactions

```ruby
# Get all transactions (default pagination: 50 per page)
response = paystack.transactions.list

# With custom pagination
response = paystack.transactions.list(per_page: 20, page: 2)

# With additional filters
response = paystack.transactions.list(
  per_page: 10,
  page: 1,
  from: "2025-01-01",
  to: "2025-04-30",
  status: "success"
)

if response.success?
  puts "Total transactions: #{response.count}" # response.size is another way

  response.data.each do |transaction|
    puts "ID: #{transaction.id}"
    puts "Reference: #{transaction.reference}"
    puts "Amount: #{transaction.amount}"
    puts "----------------"
  end

  # Get the first transaction
  first_transaction = response.data.first
  puts "First transaction reference: #{first_transaction.reference}"

  # Get the last transaction
  last_transaction = response.data.last
  puts "Last transaction amount: #{last_transaction.amount}"
else
  puts "Error: #{response.error_message}"
end
```

#### Fetch a Transaction

```ruby
# Fetch a specific transaction by ID
transaction_id = "12345"
response = paystack.transactions.fetch(transaction_id)

if response.success?
  transaction = response.data
  puts "Transaction details:"
  puts "ID: #{transaction.id}"
  puts "Reference: #{transaction.reference}"
  puts "Amount: #{transaction.amount}"
  puts "Status: #{transaction.status}"

  # Access customer information
  puts "Customer Email: #{transaction.customer.email}"
  puts "Customer Name: #{transaction.customer.name}"
else
  puts "Error: #{response.error_message}"
end
```

#### Get Transaction Totals

```ruby
# Get transaction volume and success metrics
response = paystack.transactions.totals

if response.success?
  puts "Total Transactions: #{response.data.total_transactions}"
  puts "Total Volume: #{response.data.total_volume}"
  puts "Pending Transfers: #{response.data.pending_transfers}"
else
  puts "Error: #{response.error_message}"
end
```

### Customers

The SDK provides comprehensive support for Paystack's Customer API, allowing you to manage customer records and their associated data.

#### Create a Customer

```ruby
# Prepare customer parameters
params = {
  email: "customer@example.com",
  first_name: "John",
  last_name: "Doe",
  phone: "+2348123456789"
}

# Create the customer
response = paystack.customers.create(params)

if response.success?
  puts "Customer created successfully!"
  puts "Customer Code: #{response.data.customer_code}"
  puts "Email: #{response.data.email}"
  puts "Name: #{response.data.first_name} #{response.data.last_name}"
else
  puts "Error: #{response.error_message}"
end
```

#### List Customers

```ruby
# Get all customers (default pagination: 50 per page)
response = paystack.customers.list

# With custom pagination
response = paystack.customers.list(per_page: 20, page: 2)

# With date filters
response = paystack.customers.list(
  per_page: 10,
  page: 1,
  from: "2025-01-01",
  to: "2025-06-10"
)

if response.success?
  puts "Total customers: #{response.data.size}"

  response.data.each do |customer|
    puts "Code: #{customer.customer_code}"
    puts "Email: #{customer.email}"
    puts "Name: #{customer.first_name} #{customer.last_name}"
    puts "----------------"
  end
else
  puts "Error: #{response.error_message}"
end
```

#### Fetch a Customer

```ruby
# Fetch by customer code
customer_code = "CUS_xr58yrr2ujlft9k"
response = paystack.customers.fetch(customer_code)

# Or fetch by email
response = paystack.customers.fetch("customer@example.com")

if response.success?
  customer = response.data
  puts "Customer details:"
  puts "Code: #{customer.customer_code}"
  puts "Email: #{customer.email}"
  puts "Name: #{customer.first_name} #{customer.last_name}"
  puts "Phone: #{customer.phone}"
else
  puts "Error: #{response.error_message}"
end
```

#### Update a Customer

```ruby
customer_code = "CUS_xr58yrr2ujlft9k"
update_params = {
  first_name: "Jane",
  last_name: "Smith",
  phone: "+2348987654321"
}

response = paystack.customers.update(customer_code, update_params)

if response.success?
  puts "Customer updated successfully!"
  puts "Updated Name: #{response.data.first_name} #{response.data.last_name}"
else
  puts "Error: #{response.error_message}"
end
```

#### Validate a Customer

```ruby
customer_code = "CUS_xr58yrr2ujlft9k"
validation_params = {
  country: "NG",
  type: "bank_account",
  account_number: "0123456789",
  bvn: "20012345677",
  bank_code: "007",
  first_name: "John",
  last_name: "Doe"
}

response = paystack.customers.validate(customer_code, validation_params)

if response.success?
  puts "Customer validation initiated: #{response.message}"
else
  puts "Error: #{response.error_message}"
end
```

#### Set Risk Action

```ruby
params = {
  customer: "CUS_xr58yrr2ujlft9k",
  risk_action: "allow"  # Options: "default", "allow", "deny"
}

response = paystack.customers.set_risk_action(params)

if response.success?
  puts "Risk action set successfully!"
  puts "Customer: #{response.data.customer_code}"
  puts "Risk Action: #{response.data.risk_action}"
else
  puts "Error: #{response.error_message}"
end
```

#### Deactivate Authorization

```ruby
params = {
  authorization_code: "AUTH_72btv547"
}

response = paystack.customers.deactivate_authorization(params)

if response.success?
  puts "Authorization deactivated: #{response.message}"
else
  puts "Error: #{response.error_message}"
end
```

### Response Handling

#### Working with Response Objects

All API requests return a `PaystackSdk::Response` object that provides easy access to the response data.

```ruby
response = paystack.transactions.initiate(params)

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

# For arrays, use array methods
response.data.first  # First item in an array
response.data.last   # Last item in an array
response.data.size   # Size of the array

# Iterate through array data
response.data.each do |item|
  puts item.id
end
```

#### Accessing the Original Response

Sometimes you may need access to the original API response:

```ruby
response = paystack.transactions.list

# Access the original response body
original = response.original_response

# Access metadata from the original response
total_count = original.dig("meta", "total")
current_page = original.dig("meta", "page")
```

#### Exception Handling

The SDK provides specific error classes for different types of failures, making it easier to handle errors appropriately:

```ruby
begin
  response = paystack.transactions.verify(reference: "invalid_reference")
rescue PaystackSdk::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue PaystackSdk::RateLimitError => e
  puts "Rate limit exceeded. Retry after: #{e.retry_after} seconds"
rescue PaystackSdk::ServerError => e
  puts "Server error: #{e.message}"
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

##### Error Types

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

##### Validation Error Examples

The SDK validates your input data **before** making API calls and will throw exceptions immediately if required data is missing or incorrectly formatted:

```ruby
# Missing required parameter
begin
  paystack.transactions.initiate({amount: 1000}) # Missing email
rescue PaystackSdk::MissingParamError => e
  puts e.message # => "Missing required parameter: email"
end

# Invalid format
begin
  paystack.transactions.initiate({
    email: "invalid-email",  # Not a valid email format
    amount: 1000
  })
rescue PaystackSdk::InvalidFormatError => e
  puts e.message # => "Invalid format for Email. Expected format: valid email address"
end

# Invalid value
begin
  paystack.customers.set_risk_action({
    customer: "CUS_123",
    risk_action: "invalid_action"  # Not in allowed values
  })
rescue PaystackSdk::InvalidValueError => e
  puts e.message # => "Invalid value for risk_action: must be one of [default, allow, deny]"
end
```

These validation errors are thrown immediately and prevent the API call from being made, helping you catch data issues early in development.

## Advanced Usage

### Environment Variables

You can use environment variables to configure the SDK:

```ruby
# Set the PAYSTACK_SECRET_KEY environment variable
ENV["PAYSTACK_SECRET_KEY"] = "sk_test_xxx"

# Then initialize resources without specifying the key
transactions = PaystackSdk::Resources::Transactions.new
customers = PaystackSdk::Resources::Customers.new
```

### Direct Resource Instantiation

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Style and Linting

This project uses [StandardRB](https://github.com/standardrb/standard) for code style and linting.

Add to your Gemfile (if not already present):

```ruby
gem "standard"
```

- Lint: `bundle exec standardrb`
- Auto-fix: `bundle exec standardrb --fix`
- Via Rake: `bundle exec rake standard`
- Default task (runs specs + standard): `bundle exec rake`

If you encounter cache permission issues locally, you can disable caching: `bundle exec standardrb --no-cache`.

### Testing

The SDK includes comprehensive test coverage with consistent response format handling. All test specifications use string keys with hashrocket notation (`=>`) to match the actual format returned by the Paystack API:

```ruby
# Example test response format
.and_return(Faraday::Response.new(status: 200, body: {
  "status" => true,
  "message" => "Transaction initialized",
  "data" => {
    "authorization_url" => "https://checkout.paystack.com/abc123",
    "access_code" => "access_code_123",
    "reference" => "ref_123"
  }
}))
```

Tests also validate specific error types to ensure proper exception handling:

```ruby
# Testing specific error types
expect { customers.set_risk_action(invalid_params) }
  .to raise_error(PaystackSdk::InvalidValueError, /risk_action/i)
```

### Installation and Release

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

To release a new version, update the version number in `version.rb`, and then run:

```bash
bundle exec rake release
```

This will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/nanafox/paystack_sdk](https://github.com/nanafox/paystack_sdk). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nanafox/paystack_sdk/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PaystackSdk project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/nanafox/paystack_sdk/blob/main/CODE_OF_CONDUCT.md).
