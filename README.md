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
  - [Charges](#charges)
    - [Create a Mobile Money Charge](#create-a-mobile-money-charge)
    - [Create a Charge on Another Channel](#create-a-charge-on-another-channel)
    - [Complete a Charge](#complete-a-charge)
    - [Check a Pending Charge](#check-a-pending-charge)
  - [Customers](#customers)
    - [Create a Customer](#create-a-customer)
    - [List Customers](#list-customers)
    - [Fetch a Customer](#fetch-a-customer)
    - [Update a Customer](#update-a-customer)
    - [Validate a Customer](#validate-a-customer)
    - [Set Risk Action](#set-risk-action)
    - [Deactivate Authorization](#deactivate-authorization)
  - [Banks](#banks)
  - [Miscellaneous](#miscellaneous)
  - [Transfer Recipients](#transfer-recipients)
  - [Response Handling](#response-handling)
    - [Working with Response Objects](#working-with-response-objects)
    - [Accessing the Original Response](#accessing-the-original-response)
    - [Error Handling](#error-handling)
- [Advanced Usage](#advanced-usage)
  - [Timeouts and Retries](#timeouts-and-retries)
  - [Webhooks](#webhooks)
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
- **Rate limiting** (429) - raised after automatic retries are exhausted, or immediately if Paystack asks for a long wait (see [Timeouts and Retries](#timeouts-and-retries))
- **Server errors** (5xx) - Paystack infrastructure issues
- **Network errors** - timeouts and connection failures, raised as `PaystackSdk::TimeoutError` / `PaystackSdk::ConnectionError`

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

### Charges

The Charge API lets you pick the payment channel yourself instead of sending the customer to Checkout: a saved card authorization, a bank account, USSD, mobile money, QR, EFT, Pay with Transfer or Capitec Pay. Many charges need one more step from the customer (a PIN, OTP, phone number, birthday or address) before they complete. See the Paystack docs: [Charge API](https://paystack.com/docs/api/charge/) and [Payment Channels](https://paystack.com/docs/payments/payment-channels/).

#### Create a Mobile Money Charge

Mobile money is available to businesses in Ghana, Kenya and Côte d'Ivoire. `mobile_money` checks the `mobile_money` object (phone or till account, and a known provider) and sends it with `create`.

Supported providers (case-insensitive): `mtn`, `atl` (ATMoney/Airtel Money), `vod` (Telecel, formerly Vodafone), `mpesa`, `mpesa_offline`, `mptill` (M-PESA Till: send `account:`, the till number, instead of `phone:`), `orange`, `wave`.

```ruby
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

response = paystack.charges.mobile_money(
  email: "customer@email.com",
  amount: 100,             # smallest unit (pesewas/cent)
  currency: "GHS",         # optional; Paystack uses your integration's currency without it
  mobile_money: {
    phone: "0551234987",
    provider: "mtn"        # mtn | atl | vod | mpesa | mpesa_offline | mptill | orange | wave
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

#### Create a Charge on Another Channel

`create` takes one channel object (or an `authorization_code`) as a keyword hash and sends it as Paystack documents it.

```ruby
# A returning customer's saved card
paystack.charges.create(email: "customer@email.com", amount: 10000, authorization_code: "AUTH_xxxx")

# A bank account (Paystack may then ask for the customer's birthday or an OTP)
paystack.charges.create(
  email: "customer@email.com",
  amount: 10000,
  bank: {code: "057", account_number: "0000000000"},
  birthday: Date.new(1995, 12, 23) # or "1995-12-23"
)

# USSD (Nigeria), Pay with Transfer, and QR or EFT (South Africa)
paystack.charges.create(email: "customer@email.com", amount: 10000, ussd: {type: "737"})
paystack.charges.create(email: "customer@email.com", amount: 10000, bank_transfer: {account_expires_at: "2026-10-10T12:00:00Z"})
paystack.charges.create(email: "customer@email.com", amount: 10000, currency: "ZAR", qr: {provider: "scan-to-pay"})
paystack.charges.create(email: "customer@email.com", amount: 10000, currency: "ZAR", eft: {provider: "ozow"})

# Send the payment through a split or to a subaccount
paystack.charges.create(email: "customer@email.com", amount: 10000, authorization_code: "AUTH_xxxx", split_code: "SPL_xxxx")
```

#### Complete a Charge

When the response asks for more from the customer (read `response.status` and `response.display_text`), send it with the charge's `reference`:

```ruby
paystack.charges.submit_pin(pin: "1234", reference: "5bwib5v6anhe9xa")
paystack.charges.submit_otp(otp: "123456", reference: "5bwib5v6anhe9xa") # e.g. a Vodafone voucher
paystack.charges.submit_phone(phone: "08012345678", reference: "5bwib5v6anhe9xa")
paystack.charges.submit_birthday(birthday: "1961-09-21", reference: "5bwib5v6anhe9xa")
paystack.charges.submit_address(
  address: "140 N 2ND ST",
  city: "Stroudsburg",
  state: "PA",
  zip_code: "18360",
  reference: "7c7rpkqpc0tijs8"
)
```

#### Check a Pending Charge

If a charge comes back `pending`, or a `/charge` call failed with an exception, wait at least 10 seconds, then check it (Paystack warns that checking too early returns more `pending` results):

```ruby
response = paystack.charges.check_pending(reference: "5bwib5v6anhe9xa")
puts response.status
```

For offline flows such as mobile money, listen for the `charge.success` webhook, and confirm it with `transactions.verify(reference:)` before giving value:

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
# Get all transactions (Paystack's default pagination: 50 per page)
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

# Filter by customer (the numeric customer ID, not the CUS_ code)
response = paystack.transactions.list(customer_id: 12345)

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
response = paystack.transactions.fetch(id: 12345)

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

# Within a date range
response = paystack.transactions.totals(from: "2025-01-01", to: "2025-04-30")

if response.success?
  puts "Total Transactions: #{response.data.total_transactions}"
  puts "Total Volume: #{response.data.total_volume}"
  puts "Pending Transfers: #{response.data.pending_transfers}"
else
  puts "Error: #{response.error_message}"
end
```

#### Transaction Timeline, Export and Charging

```ruby
# Timeline of a transaction, by ID or reference
paystack.transactions.timeline(id: "transaction_reference")

# Export transactions (Paystack returns a download link)
paystack.transactions.export(from: "2025-01-01", to: "2025-04-30", status: "success", settled: true)

# Charge a returning customer's saved authorization
paystack.transactions.charge_authorization(
  email: "customer@example.com",
  amount: 10000,
  authorization_code: "AUTH_xxxx"
)

# Debit part of an amount from a saved authorization
paystack.transactions.partial_debit(
  email: "customer@example.com",
  amount: 5000,
  authorization_code: "AUTH_xxxx",
  currency: "GHS"
)
```

### Customers

The SDK provides comprehensive support for Paystack's Customer API, allowing you to manage customer records, their identity validation, risk actions and authorizations (including Direct Debit mandates).

#### Create a Customer

```ruby
response = paystack.customers.create(
  email: "customer@example.com",
  first_name: "John",
  last_name: "Doe",
  phone: "+2348123456789",
  metadata: {plan: "gold"} # a Hash; Paystack rejects a JSON string here
)

if response.success?
  puts "Customer created successfully!"
  puts "Customer Code: #{response.data.customer_code}"
  puts "Email: #{response.data.email}"
  puts "Name: #{response.data.first_name} #{response.data.last_name}"
else
  puts "Error: #{response.error_message}"
end
```

`first_name`, `last_name` and `phone` are optional, except for customers you will assign a Dedicated Virtual Account to in some business categories (see Paystack's docs).

#### List Customers

```ruby
# Get all customers (Paystack's default pagination: 50 per page)
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

# Cursor pagination: the cursors come back in response.meta
response = paystack.customers.list(use_cursor: true, per_page: 20)
response = paystack.customers.list(use_cursor: true, per_page: 20, next_cursor: response.meta.next)

if response.success?
  puts "Customers on this page: #{response.data.size}"

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
response = paystack.customers.fetch(code: "CUS_xr58yrr2ujlft9k")

# Or fetch by email (Paystack accepts either in the same place)
response = paystack.customers.fetch(code: "customer@example.com")

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
response = paystack.customers.update(
  code: "CUS_xr58yrr2ujlft9k",
  first_name: "Jane",
  last_name: "Smith",
  phone: "+2348987654321"
)

if response.success?
  puts "Customer updated successfully!"
  puts "Updated Name: #{response.data.first_name} #{response.data.last_name}"
else
  puts "Error: #{response.error_message}"
end
```

#### Validate a Customer

Paystack only supports `type: "bank_account"` for now, and requires every keyword below; `middle_name` and `value` are optional. Paystack answers `202` and completes the validation asynchronously.

```ruby
response = paystack.customers.validate(
  code: "CUS_xr58yrr2ujlft9k",
  first_name: "John",
  last_name: "Doe",
  type: "bank_account",
  country: "NG",
  bvn: "20012345677",
  bank_code: "007",
  account_number: "0123456789"
)

if response.success?
  puts "Customer validation initiated: #{response.message}"
else
  puts "Error: #{response.error_message}"
end
```

#### Set Risk Action (Whitelist/Blacklist)

```ruby
# customer: the customer code or email address
response = paystack.customers.set_risk_action(
  customer: "CUS_xr58yrr2ujlft9k",
  risk_action: "allow" # "allow" to whitelist, "deny" to blacklist, "default" to reset
)

if response.success?
  puts "Risk action set successfully!"
  puts "Customer: #{response.data.customer_code}"
  puts "Risk Action: #{response.data.risk_action}"
else
  puts "Error: #{response.error_message}"
end
```

#### Authorizations and Direct Debit

```ruby
# Start creating a reusable authorization (direct_debit is the only channel for now)
response = paystack.customers.initialize_authorization(
  email: "customer@example.com",
  channel: "direct_debit",
  callback_url: "https://example.com/callback"
)
reference = response.data.reference # send the customer to response.data.redirect_url

# Check the authorization's status
paystack.customers.verify_authorization(reference: reference)

# Link a bank account to an existing customer for Direct Debit (id is the numeric customer ID)
paystack.customers.initialize_direct_debit(
  id: 12345,
  account: {number: "0123456789", bank_code: "058"},
  address: {street: "Some Where", city: "Ikeja", state: "Lagos"}
)

# The customer's Direct Debit mandates
paystack.customers.fetch_mandate_authorizations(id: 12345)

# Trigger an activation charge on an inactive mandate
paystack.customers.direct_debit_activation_charge(id: 12345, authorization_id: 1069309917)

# Deactivate an authorization (any channel)
response = paystack.customers.deactivate_authorization(authorization_code: "AUTH_72btv547")

if response.success?
  puts "Authorization deactivated: #{response.message}"
else
  puts "Error: #{response.error_message}"
end
```

### Banks

Everything takes keyword arguments. Account numbers and bank codes are strings, so leading zeros survive.

```ruby
# List banks. Filters are optional: country (ghana, kenya, nigeria, "south africa"), currency,
# type, gateway, per_page, page, use_cursor, next_cursor, previous, ...
response = paystack.banks.list(country: "nigeria", per_page: 50)
response.data.each { |bank| puts "#{bank["name"]}: #{bank["code"]}" }

# Resolve an account number to the name on the account
response = paystack.banks.resolve_account_number(account_number: "0022728151", bank_code: "063")
puts response.data["account_name"] if response.success?

# Validate a South African bank account before sending money
response = paystack.banks.validate_account(
  account_name: "Ama Mensah",
  account_number: "0123456789",
  account_type: "personal",
  bank_code: "632005",
  country_code: "ZA",
  document_type: "identityNumber",
  document_number: "1234567890123" # optional
)
```

### Miscellaneous

```ruby
# Details of a card BIN (6 or 8 digits, as a string)
response = paystack.miscellaneous.resolve_card_bin(bin: "539983")
puts response.data["bank"] if response.success?

# Supported countries
paystack.miscellaneous.list_countries

# States for address verification (country is required)
paystack.miscellaneous.list_states(country: "CA")
```

### Transfer Recipients

Every method takes keyword arguments. A recipient is who you send a transfer to.

#### Create a Transfer Recipient

```ruby
response = paystack.transfer_recipients.create(
  type: "nuban", # nuban, ghipss, mobile_money, basa or authorization
  name: "Ama Mensah",
  account_number: "0123456789",
  bank_code: "058",
  currency: "NGN",
  metadata: {job: "Baker"}
)

puts response.data.recipient_code if response.success?
```

A duplicate account number returns the existing recipient. To create many at once, pass a list of recipient hashes:

```ruby
response = paystack.transfer_recipients.bulk_create(
  batch: [
    {type: "nuban", name: "Ama Mensah", account_number: "0123456789", bank_code: "058"},
    {type: "nuban", name: "Kofi Boateng", account_number: "0987654321", bank_code: "058"}
  ]
)

response.data.success # recipients that were created
response.data.errors  # records Paystack rejected, with the reason
```

#### List, Fetch, Update and Delete

```ruby
paystack.transfer_recipients.list(per_page: 20, page: 2)

# fetch, update and delete take the recipient code or the numeric ID
paystack.transfer_recipients.fetch(id_or_code: "RCP_2x5j67tnnw1t98k")
paystack.transfer_recipients.update(id_or_code: "RCP_2x5j67tnnw1t98k", name: "Ama K. Mensah", email: "ama@example.com")
paystack.transfer_recipients.delete(id_or_code: "RCP_2x5j67tnnw1t98k") # Paystack sets the recipient to inactive
```

Paystack's docs list `from` and `to` filters on the list endpoint, but the API ignores them (checked against the test API), so the SDK does not offer them. Cursor pagination is available with `use_cursor: true`, `next_cursor:` and `previous:`.

### Response Handling

#### Working with Response Objects

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

#### Pagination Metadata

List responses carry Paystack's pagination details in `meta`:

```ruby
response = paystack.transactions.list(per_page: 20)

response.meta.total      # => 40
response.meta.page       # => 1
response.meta.pageCount  # => 2
response.meta.perPage    # => 20
```

`response.meta` is `nil` when the response has no `meta`.

#### Accessing the Original Response

Sometimes you may need access to the original API response:

```ruby
response = paystack.transactions.list

# Access the original response body
original = response.original_response

# Anything else in the body is still reachable
original.dig("meta", "total")
```

#### Exception Handling

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

- **`PaystackSdk::ConnectionError`** - Could not reach Paystack (DNS, refused connection, TLS) after retries
  - **`PaystackSdk::TimeoutError`** - The request timed out after retries

##### Validation Error Examples

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

## Advanced Usage

### Timeouts and Retries

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

### Webhooks

Paystack tells you about changes (a charge succeeded, a refund was processed, a transfer failed) by POSTing events to your webhook URL. `PaystackSdk::Webhook` verifies and parses them, and works with any framework.

Paystack signs each event: the `x-paystack-signature` header is a lowercase hex HMAC SHA512 of the **raw request body**, using your secret key. Verify it before using the event.

```ruby
# Rails controller (skip CSRF protection for this action)
def create
  event = PaystackSdk::Webhook.construct_event(
    payload: request.raw_post,                          # raw body, not params
    signature: request.headers["X-Paystack-Signature"],
    secret: ENV.fetch("PAYSTACK_SECRET_KEY")
  )

  HandlePaystackEventJob.perform_later(event.payload)   # do the work in the background
  head :ok                                              # acknowledge quickly
rescue PaystackSdk::WebhookError
  head :bad_request
end
```

```ruby
event.event             # => "charge.success"
event.data.reference    # data is wrapped like any Response
event.data[:amount]
event.known?            # => true if Paystack documents this event name
event.payload           # the parsed JSON Hash (string keys), handy for queuing a job
```

- `Webhook.valid_signature?(payload:, signature:, secret:)` returns a boolean, and `Webhook.verify!` raises `PaystackSdk::InvalidSignatureError`. The comparison is constant-time.
- The payload must be the exact bytes received. A parsed or re-serialised body will not match, and a non-String payload raises `ArgumentError`. A blank secret also raises, rather than checking against nothing.
- `Webhook.construct_event` verifies first and parses only afterwards. A signed body that is not a JSON event raises `PaystackSdk::InvalidPayloadError`. Events Paystack adds later still come back, with `known?` false.
- `Webhook.trusted_ip?(ip)` checks the three addresses Paystack documents (`Webhook::IP_ADDRESSES`). Use it as an extra check, not instead of the signature.
- `Webhook.sign(payload, secret)` produces a valid signature, for testing your own endpoint.
- Paystack retries events your server does not acknowledge with a `200 OK`: in live mode every 3 minutes for 4 tries, then hourly for 72 hours. Return `200` fast, process in a background job, and make handlers safe to run more than once.
- Before giving value for a `charge.success`, confirm it with `transactions.verify(reference:)`, as Paystack recommends.

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
expect { customers.set_risk_action(customer: "CUS_123", risk_action: "block") }
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
