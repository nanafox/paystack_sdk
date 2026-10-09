# Paystack Ruby SDK: Simplify Payments

The `paystack_sdk` gem provides a simple and intuitive interface for interacting with Paystack's payment gateway API. It allows developers to easily integrate Paystack's payment processing features into their Ruby applications. With support for various endpoints, this SDK simplifies tasks such as initiating transactions, verifying payments, managing customers, and more.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Client Initialization](#client-initialization)
  - [Test and Live Keys](#test-and-live-keys)
  - [Transactions](#transactions)
    - [Initialize a Transaction](#initialize-a-transaction)
    - [Verify a Transaction](#verify-a-transaction)
    - [List Transactions](#list-transactions)
    - [Fetch a Transaction](#fetch-a-transaction)
    - [Get Transaction Totals](#get-transaction-totals)
    - [Checking a Payment](#checking-a-payment)
    - [Charging a Saved Card](#charging-a-saved-card)
  - [Charges](#charges)
    - [Mobile Money in Ghana: Which Networks](#mobile-money-in-ghana-which-networks)
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
  - [Transfers](#transfers)
    - [Initiate a Transfer](#initiate-a-transfer)
    - [Verify, Fetch and List Transfers](#verify-fetch-and-list-transfers)
    - [Bulk Transfers and the OTP Requirement](#bulk-transfers-and-the-otp-requirement)
  - [Refunds](#refunds)
    - [Create a Refund](#create-a-refund)
    - [Fetch, List and Retry Refunds](#fetch-list-and-retry-refunds)
  - [Settlements](#settlements)
  - [Splits](#splits)
    - [Create a Split](#create-a-split)
    - [List, Fetch and Update Splits](#list-fetch-and-update-splits)
    - [Add, Update or Remove a Subaccount](#add-update-or-remove-a-subaccount)
  - [Disputes](#disputes)
    - [List and Fetch Disputes](#list-and-fetch-disputes)
    - [Answer a Dispute](#answer-a-dispute)
  - [Subaccounts](#subaccounts)
    - [Create a Subaccount](#create-a-subaccount)
    - [List and Fetch Subaccounts](#list-and-fetch-subaccounts)
    - [Update a Subaccount](#update-a-subaccount)
  - [Orders](#orders)
  - [Balances](#balances)
  - [Plans](#plans)
    - [Create a Plan](#create-a-plan)
    - [List and Fetch Plans](#list-and-fetch-plans)
    - [Update a Plan](#update-a-plan)
  - [Subscriptions](#subscriptions)
    - [Create a Subscription](#create-a-subscription)
    - [List and Fetch Subscriptions](#list-and-fetch-subscriptions)
    - [Enable or Disable a Subscription](#enable-or-disable-a-subscription)
    - [Let the Customer Update Their Card](#let-the-customer-update-their-card)
  - [Dedicated Virtual Accounts](#dedicated-virtual-accounts)
    - [Create or Assign an Account](#create-or-assign-an-account)
    - [List, Fetch, Requery and Deactivate](#list-fetch-requery-and-deactivate)
    - [Split Payments on an Account](#split-payments-on-an-account)
  - [Pages](#pages)
    - [List, Fetch and Update Pages](#list-fetch-and-update-pages)
  - [Payment Requests](#payment-requests)
    - [Create a Payment Request](#create-a-payment-request)
    - [List, Fetch and Verify Payment Requests](#list-fetch-and-verify-payment-requests)
    - [Update, Finalize, Notify and Archive](#update-finalize-notify-and-archive)
  - [Products](#products)
    - [Create a Product](#create-a-product)
    - [List, Fetch, Update and Delete Products](#list-fetch-update-and-delete-products)
  - [Storefronts](#storefronts)
    - [Create a Storefront](#create-a-storefront)
    - [List, Fetch, Update and Delete Storefronts](#list-fetch-update-and-delete-storefronts)
    - [Products, Orders, Duplicate and Publish](#products-orders-duplicate-and-publish)
  - [Bulk Charges](#bulk-charges)
    - [Initiate a Bulk Charge](#initiate-a-bulk-charge)
    - [List and Fetch Batches and Their Charges](#list-and-fetch-batches-and-their-charges)
    - [Pause and Resume a Batch](#pause-and-resume-a-batch)
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

### Test and Live Keys

A live key (`sk_live_...`) moves real money. `client.live?` tells you which kind a client holds, and `sandbox_only: true` makes the client refuse anything but a test key (`sk_test_...`) at construction, before any request is sent. Set it in staging and CI:

```ruby
client = PaystackSdk::Client.new(secret_key: ENV["PAYSTACK_SECRET_KEY"], sandbox_only: true)
# => ArgumentError if the key is a live key, or anything not recognisable as a test key

client.live? # => false
```

The error never includes the key. A pre-built Faraday connection is checked too (the key is read from its `Authorization` header).

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

#### Mobile Money in Ghana: Which Networks

Paystack lists three Ghana mobile-money providers (`banks.list(country: "ghana", type: "mobile_money")`): `MTN`, `VOD` (shown as Vodafone, now Telecel) and `ATL` (AirtelTigo). The bank list uses uppercase codes; `charges.mobile_money` takes the provider in any case and sends it in lowercase (`mtn`, `vod`, `atl`).

What was checked, against Paystack's test API only: a merchant-started charge of 100 pesewas (GHS) for each of the three providers on Paystack's test number was accepted, came back with `status: "success"` and `gateway_response: "Approved"` immediately, and `check_pending(reference:)` returned the same. **Test mode does not model the payer approving the prompt on their phone, so this does not show which live networks accept a charge you start yourself.** Treat each network as unverified in live mode: start the charge, read `response.status` (`status?(:pay_offline)`, `status?(:send_otp)`, `status?(:pending)` and so on, as Paystack returns them), show `response.display_text` to the payer when there is one, and poll `charges.check_pending(reference:)` or wait for the `charge.success` webhook. Confirm with `transactions.verify(reference:)` before giving value. If a network refuses a merchant-started prompt, fall back to a payment link for that network.

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

#### Checking a Payment

Confirm a payment by verifying it, then check the status, amount and currency. `paid?` does all three: it is true only when the call succeeded and the transaction's `status` is `"success"`, and, for the `amount` and `currency` you pass, they match what Paystack reports.

```ruby
response = paystack.transactions.verify(reference: reference)

if response.paid?(amount: 5000, currency: "GHS") # amount in the smallest unit, e.g. pesewas
  authorization = response.authorization
  authorization.authorization_code # keep this to charge the card again
  authorization.reusable           # true if it can be charged again
end
```

Fields keep Paystack's own names: `response.reference`, `amount`, `currency`, `status`, `paid_at`, `gateway_response`, `fees`, `customer.email`, `customer.customer_code`, and on `authorization`: `authorization_code`, `reusable`, `channel`, `last4`, `card_type`, `signature`, `exp_month`, `exp_year`, `bin`, `bank`, `account_name`, `country_code` and `brand`. `response.status?(:pending)` compares the `status` field with any value, which is how you read a charge that is waiting on the payer (`status?(:send_pin)`, `status?(:pay_offline)`); `response.display_text` is the prompt Paystack wants shown to them.

#### Charging a Saved Card

After a successful card payment, the `authorization_code` can be charged again with no checkout, for example for a renewal. Only an authorization with `reusable: true` can be charged again.

```ruby
charge = paystack.transactions.charge_authorization(
  email: "customer@example.com",   # the customer the authorization belongs to
  amount: 5000,
  currency: "GHS",
  authorization_code: "AUTH_xxxx",
  reference: "renewal-2025-06-ama"  # unique per attempt; reuse it if you retry so you cannot charge twice
)

paystack.transactions.verify(reference: "renewal-2025-06-ama").paid?(amount: 5000, currency: "GHS")
```

This was checked against Paystack's test API: a reusable card authorization charged successfully (`status: "success"`, `gateway_response: "Approved"`), and an unknown `authorization_code` came back as an unsuccessful response with `"Authorization code is invalid"`. Writes are never retried after a timeout, so if a `charge_authorization` call times out, verify the `reference` before charging again. Test mode does not prove live behaviour.

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
response = paystack.customers.fetch(email_or_code: "CUS_xr58yrr2ujlft9k")

# Or fetch by email (Paystack accepts either in the same place)
response = paystack.customers.fetch(email_or_code: "customer@example.com")

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

### Transfers

Transfers send money from your Paystack balance to a transfer recipient (`RCP_...`). They move real money in live mode, so the SDK never retries them except on `429` (see [Timeouts and Retries](#timeouts-and-retries)).

#### Initiate a Transfer

```ruby
# Amount is in the smallest currency unit (kobo, pesewas, cents).
# reference is required: generate it once and reuse it if you retry, so a retry cannot pay twice.
# Paystack documents 16 to 50 characters of lowercase letters, digits, - and _.
response = paystack.transfers.create(
  source: "balance",
  amount: 100_000,
  recipient: "RCP_gd9vgag7n5lr5ix",
  reference: "acv_9ee55786-2323-4760-98e2-6380c9cb3f68",
  reason: "Bonus for the week"
)

if response.success?
  case response.data.status
  when "otp"
    # Your integration requires an OTP: Paystack sent one to the business phone
    paystack.transfers.finalize(transfer_code: response.data.transfer_code, otp: "928783")
  else
    puts "Transfer #{response.data.transfer_code} is #{response.data.status}"
  end
else
  puts "Error: #{response.error_message}"
end
```

#### Verify, Fetch and List Transfers

```ruby
# Verify by your reference
paystack.transfers.verify(reference: "acv_9ee55786-2323-4760-98e2-6380c9cb3f68")

# Fetch by transfer ID or code
paystack.transfers.fetch(id_or_code: "TRF_v5tip3zx8nna9o78")

# List, with Paystack's page pagination (default 50 per page)...
paystack.transfers.list(per_page: 20, page: 2, from: "2025-01-01", to: "2025-04-30")

# ...filtered by the numeric recipient ID, or by status
paystack.transfers.list(recipient: 56824902, status: "success")

# ...or with cursor pagination: pass response.meta.next back as next_cursor
paystack.transfers.list(use_cursor: true, per_page: 20)

# Export transfers (in Paystack's OpenAPI spec, not on its docs page)
paystack.transfers.export(from: "2025-01-01", to: "2025-04-30", status: "success")
```

#### Bulk Transfers and the OTP Requirement

```ruby
# Bulk transfers need the OTP requirement disabled. Each transfer uses Paystack's field names.
paystack.transfers.bulk_create(
  source: "balance",
  currency: "NGN",
  transfers: [
    {amount: 20_000, recipient: "RCP_gd9vgag7n5lr5ix", reference: "acv_2627bbfe-1a2a-4a1a-8d0e-9d2ee6c31496", reason: "Bonus"},
    {amount: 35_000, recipient: "RCP_zpk2tgagu6lgb4g", reference: "acv_1bd0c1f8-78c2-463b-8bd4-ed9eeb36be50", reason: "Bonus"}
  ]
)

# Turn the OTP requirement off (Paystack sends an OTP to the business phone), then confirm it
paystack.transfers.disable_otp
paystack.transfers.finalize_disable_otp(otp: "928783")

# Turn it back on
paystack.transfers.enable_otp

# Resend the OTP for a transfer awaiting one
paystack.transfers.resend_otp(transfer_code: "TRF_vsyqdmlzble3uii", reason: "resend_otp")
```

### Refunds

Refunds return money from a successful transaction to the customer. They move real money in live mode, so the SDK never retries them except on `429` (see [Timeouts and Retries](#timeouts-and-retries)).

#### Create a Refund

```ruby
# transaction is the transaction's reference or its numeric ID.
# amount is in the smallest currency unit (kobo, pesewas, cents) and cannot exceed the transaction amount.
# Leave amount out to refund the whole transaction; pass less for a partial refund.
response = paystack.refunds.create(
  transaction: "T685312322670591",
  amount: 2_500,
  currency: "GHS",               # optional; Paystack refuses one that differs from the transaction's
  customer_note: "Duplicate payment",
  merchant_note: "Refunded by the finance team"
)

if response.success?
  puts "Refund #{response.data.id} is #{response.data.status}" # "pending" until Paystack processes it
else
  puts "Error: #{response.error_message}" # e.g. "Transaction not found"
end

# A full refund by transaction ID
paystack.refunds.create(transaction: 1_004_723_697)
```

#### Fetch, List and Retry Refunds

```ruby
paystack.refunds.fetch(id: 18_625_648)

# List, with page pagination (default 50 per page) and a date range...
paystack.refunds.list(per_page: 20, page: 1, from: "2025-01-01", to: "2025-04-30")

# ...or the refunds of one transaction, by its numeric ID (a reference returns none)
paystack.refunds.list(transaction_id: 1_004_723_697)

# Retry a refund with the needs-attention status by giving the customer's bank account
paystack.refunds.retry_with_customer_details(
  id: 18_625_648,
  refund_account_details: {currency: "GHS", account_number: "0123456789", bank_id: "9"}
)
```

Paystack's docs also list a `currency` filter on the list endpoint, but the test API returned the same refunds for every currency, so the SDK does not offer it.
### Settlements

Settlements are the payouts Paystack makes to your bank account. Use them to reconcile what was paid out against the transactions behind each payout.

```ruby
# List settlements (Paystack's defaults apply: 50 per page, page 1)
paystack.settlements.list
paystack.settlements.list(per_page: 20, page: 2)

# Only settlements within a date range (a date or an ISO 8601 timestamp)
paystack.settlements.list(from: "2025-01-01", to: "2025-01-31T23:59:59Z")

# The transactions that make up one settlement
paystack.settlements.transactions(id: 3090024)
```

Paystack's docs also list `status` and `subaccount` filters on the list endpoint, but they are not in its OpenAPI spec and the SDK does not offer them yet: the test account has no settlements, so whether they filter could not be checked. `transactions` takes no filters or pagination for the same reason.

### Splits

A transaction split shares the settlement for a payment between your payout account and one or more subaccounts (`ACCT_...`). Create the split once, then pass its `split_code` when you initialize a transaction or create a charge.

#### Create a Split

```ruby
# type is "percentage" (each share is a percentage) or "flat" (each share is an amount in the
# currency's subunit: kobo, pesewas, cents). currency must be enabled on your integration.
response = paystack.splits.create(
  name: "Halfsies",
  type: "percentage",
  currency: "GHS",
  subaccounts: [{subaccount: "ACCT_6uujpqtzmnufzkw", share: 50}],
  # Optional: who pays Paystack's fee. One of "account", "subaccount", "all-proportional" or "all"
  # (Paystack's default). "subaccount" also needs bearer_subaccount, a subaccount in the split.
  bearer_type: "all-proportional"
)

split_code = response.data.split_code if response.success? # e.g. "SPL_RcScyW5jp2"
```

#### List, Fetch and Update Splits

```ruby
# List, with Paystack's page pagination (default 50 per page) and filters
paystack.splits.list(per_page: 20, page: 1, active: true)
paystack.splits.list(name: "Halfsies", subaccount_code: "ACCT_6uujpqtzmnufzkw", from: "2025-01-01", to: "2025-04-30")

# Fetch by numeric ID or by split code
paystack.splits.fetch(id: 2703655)
paystack.splits.fetch(id: "SPL_RcScyW5jp2")

# Update (by numeric ID only: Paystack refuses a split code here)
paystack.splits.update(id: 2703655, active: false)
paystack.splits.update(id: 2703655, bearer_type: "subaccount", bearer_subaccount: "ACCT_6uujpqtzmnufzkw")
```

#### Add, Update or Remove a Subaccount

```ruby
# Adds the subaccount, or changes its share if it is already in the split (numeric split ID)
paystack.splits.add_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb", share: 20)

paystack.splits.remove_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb")
```

### Disputes

Disputes (chargebacks) are filed against your transactions by customers or their banks. Listing and fetching are read-only. `update`, `add_evidence` and `resolve` change a real dispute, so call them only when you mean to answer it.

#### List and Fetch Disputes

```ruby
# List, with Paystack's page pagination; filter by status, transaction ID or date range.
# status is one of awaiting-merchant-feedback, awaiting-bank-feedback, pending, resolved
response = paystack.disputes.list(status: "awaiting-merchant-feedback", per_page: 20, from: "2025-01-01", to: "2025-04-30")
response.data.each { |dispute| puts "#{dispute.id}: #{dispute.status}" } if response.success?

# Fetch one dispute, or every dispute filed for a transaction
paystack.disputes.fetch(id: 2867)
paystack.disputes.list_transaction(id: 5991760)

# Export disputes. Paystack answers 404 "No disputes found" when there is nothing to export.
paystack.disputes.export(from: "2025-01-01", to: "2025-04-30")
```

#### Answer a Dispute

```ruby
# 1. Get a signed URL, upload the evidence file to it, and keep the returned file name
upload = paystack.disputes.fetch_upload_url(id: 2867, upload_filename: "receipt.pdf")
upload.data.signedUrl   # upload your file to this URL
upload.data.fileName    # pass this as uploaded_filename

# 2. Add evidence
paystack.disputes.add_evidence(
  id: 2867,
  customer_email: "ama@example.com",
  customer_name: "Ama Mensah",
  customer_phone: "0802345167",
  service_details: "Tithe payment for March",
  delivery_date: "2025-03-31"
)

# 3. Accept (with a refund) or decline. refund_amount is in the smallest currency unit.
# It is `resolve` because `resolve` would shadow a method Ruby already has.
paystack.disputes.resolve(
  id: 2867,
  resolution: "merchant-accepted", # or "declined"
  message: "Refunded at the customer's request",
  refund_amount: 50_000,
  uploaded_filename: upload.data.fileName
)

# Or change the refund amount and attachment without resolving
paystack.disputes.update(id: 2867, refund_amount: 50_000, uploaded_filename: upload.data.fileName)
```

### Subaccounts

A subaccount is a settlement account that receives its share of the payments made to it, such as one per branch or partner. Pass its code (`ACCT_...`) as `subaccount` when you charge or initialize a transaction.

#### Create a Subaccount

```ruby
# bank_code comes from paystack.banks.list (country: "ghana" lists GHS banks and the
# MTN, VOD and ATL mobile money codes). account_number is a string: leading zeros matter.
# percentage_charge is the percentage the main account keeps from each payment (0 to 100).
response = paystack.subaccounts.create(
  business_name: "Grace Chapel Accra",
  bank_code: "MTN",
  account_number: "0551234987",
  percentage_charge: 2.5,
  description: "Giving for the Accra branch",
  primary_contact_name: "Ama Mensah",
  primary_contact_email: "finance@gracechapel.example",
  primary_contact_phone: "0551234987"
)

if response.success?
  puts "Created #{response.data.subaccount_code} for #{response.data.account_name}"
else
  puts "Error: #{response.error_message}" # e.g. "Account details are invalid"
end
```

Paystack's docs name the bank field `bank_code`; its OpenAPI spec calls it `settlement_bank`. The API reads both and prefers `bank_code`, so the SDK sends `bank_code`.

#### List and Fetch Subaccounts

```ruby
# Paystack's page pagination (default 50 per page)
paystack.subaccounts.list(per_page: 20, page: 2)

# Without active, the test API lists only active subaccounts. active: 0 lists the inactive
# ones. Paystack reads any value other than 1, true included, as inactive, so pass 1 or 0.
paystack.subaccounts.list(active: 0)

# Fetch by subaccount code or numeric ID
paystack.subaccounts.fetch(id_or_code: "ACCT_6uujpqtzmnufzkw")
```

#### Update a Subaccount

```ruby
# Send only what changes
paystack.subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", percentage_charge: 3)

# Deactivate (or reactivate with active: true)
paystack.subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", active: false)

# A new settlement account: Paystack needs bank_code and account_number together
paystack.subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", bank_code: "040100", account_number: "1234567890123")
```

### Orders

Orders record a customer's purchase of your products. `create` places an order for a customer, so it may notify the buyer: use test mode and a test email while you build.

```ruby
response = paystack.orders.create(
  email: "ama@example.com",
  first_name: "Ama",
  last_name: "Mensah",
  phone: "+233200000000",
  currency: "GHS",
  items: [{item: 2782725, type: "product", quantity: 2, amount: 20_000}], # product ID; amount in pesewas
  shipping: {street_line: "1 Road", city: "Accra", state: "Greater Accra", country: "Ghana", shipping_fee: 0}
)

order = paystack.orders.fetch(id: 12_345)               # numeric order ID
paystack.orders.list(per_page: 20, from: "2026-01-01")  # filters: per_page, page, from, to
paystack.orders.fetch_product_orders(id: 2782725)       # orders for one product (the product ID)
paystack.orders.validate(code: "ORD_abc123def456")      # GET, for a "pay for me" order
```

Paystack's docs page shows `create` taking `customer` and `line_items`, but the API follows the OpenAPI spec: the test API answers the docs' shape with "Customer email is required". The order total must be at least 2 units of the currency (GHS 2), and a new order has status `created` until it is paid. `pay_for_me: true` needs receiver details that neither the spec nor the docs describe ("Receiver data is required"), so it is not covered here.

### Balances

Read-only. Amounts are integers in the currency's subunit (pesewas for GHS, kobo for NGN), so `48400` is GHS 484.00. Paystack documents both operations on its Transfers Control page.

```ruby
# One entry per currency your integration holds
response = paystack.balances.fetch
response.data.first.currency # => "GHS"
response.data.first.balance  # => 48400
# Iterating (each, map) yields plain hashes with string keys
response.data.each { |balance| puts "#{balance["currency"]}: #{balance["balance"]}" }

# Every pay-in and pay-out, newest first. `difference` is the signed change in the subunit
# (-2500 for a refund), `balance` the running balance after it, and `model_responsible`
# says what caused it ("Transaction", "Refund", "Transfer", ...).
ledger = paystack.balances.ledger(per_page: 20, page: 1)
ledger.data.each { |entry| puts "#{entry["createdAt"]} #{entry["model_responsible"]} #{entry["difference"]}" }
ledger.meta # => total, skipped, perPage, page, pageCount (50 per page by default)

# Date filters work by calendar day (the time part is ignored). `to` includes that day;
# `from` does not, so from: Date.new(2026, 10, 8) returns entries after 8 October.
paystack.balances.ledger(from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 31))
```

### Plans

A plan is a recurring charge definition: an amount, an interval and a currency. Customers are subscribed to a plan to be charged on that schedule. Paystack does not let you delete a plan.

#### Create a Plan

```ruby
# amount is in the subunit of the currency (pesewas for GHS). Paystack's minimum is 2 GHS.
# interval is one of hourly, daily, weekly, monthly, quarterly, biannually (every 6 months)
# or annually, in lowercase. currency defaults to the integration's currency.
response = paystack.plans.create(
  name: "Monthly tithe",
  amount: 20_000,
  interval: "monthly",
  currency: "GHS",
  description: "Standing tithe",
  send_invoices: false,
  send_sms: false,
  invoice_limit: 12
)

if response.success?
  puts "Created #{response.data.plan_code}"
else
  puts "Error: #{response.error_message}" # e.g. "Invalid interval selected"
end
```

`send_invoices` and `send_sms` are booleans (Paystack's docs call `send_sms` a string; the API refuses anything that is not a boolean).

#### List and Fetch Plans

```ruby
paystack.plans.list(per_page: 20, page: 1)

# Filter by interval, amount (in the subunit) or a date range
paystack.plans.list(interval: "monthly", amount: 20_000)
paystack.plans.list(from: "2026-01-01", to: "2026-12-31")

# Fetch by plan code or numeric ID
paystack.plans.fetch(id_or_code: "PLN_gx2wn530m0i3w3m")
```

#### Update a Plan

```ruby
# Send only what changes
paystack.plans.update(id_or_code: "PLN_gx2wn530m0i3w3m", name: "Monthly tithe (renamed)")

# By default Paystack applies the change to the plan's existing subscriptions too. Pass
# update_existing_subscriptions: false so that only new subscriptions use the new values.
paystack.plans.update(id_or_code: "PLN_gx2wn530m0i3w3m", amount: 25_000, update_existing_subscriptions: false)
```

The response carries a message only, for example `"Plan updated. 1 subscription(s) affected"`.
### Subscriptions

A subscription charges a customer's saved card on a plan's schedule. The customer needs a reusable card authorization (from an earlier successful card payment), and the plan is created in your Paystack dashboard or through the Plans API.

#### Create a Subscription

```ruby
# customer: the customer's email or customer code. plan: the plan code (PLN_...).
# authorization: which of the customer's saved cards to charge (AUTH_...); without it Paystack
# uses the customer's most recent authorization. It must belong to this customer.
# start_date: the date of the first debit, a Time, Date or ISO 8601 string. On the test API it
# becomes next_payment_date (2027-01-15T10:00:00Z here), and the schedule follows the plan's interval.
response = paystack.subscriptions.create(
  customer: "CUS_xnxdt6s1zg1f4nx",
  plan: "PLN_gx2wn530m0i3w3m",
  authorization: "AUTH_6tmt288t0o",
  start_date: Time.utc(2027, 1, 15, 10)
)

if response.success?
  # Keep both: enable and disable need the code and the email token
  puts "#{response.data.subscription_code} #{response.data.email_token}"
else
  puts "Error: #{response.error_message}" # e.g. "This subscription is already in place."
end
```

A customer can hold one active subscription per plan. The SDK checks that `start_date` is ISO 8601 before sending it: on the test API, an invalid `start_date` is refused with a 400 but still leaves an active subscription with no payment date behind.

#### List and Fetch Subscriptions

```ruby
# Filters take numeric IDs: the plan and customer codes match nothing
paystack.subscriptions.list(plan_id: 4298026, customer_id: 406976740, per_page: 20, page: 1)

# Created within a window (Time, Date or ISO 8601 string)
paystack.subscriptions.list(from: Date.new(2026, 10, 1), to: Time.now)

# Fetch by subscription code or numeric ID
paystack.subscriptions.fetch(id_or_code: "SUB_vsyqdmlzble3uii")
```

#### Enable or Disable a Subscription

```ruby
# token is the subscription's email_token, returned by create, list and fetch
paystack.subscriptions.disable(code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7")
# => data.status "non-renewing"

paystack.subscriptions.enable(code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7")
```

Disabling answers with `data.status` `non-renewing`, and fetch shows the same status. On the test API a disabled subscription that had never been charged could not be enabled again ("Subscription has been cancelled, and cannot be reactivated").

#### Let the Customer Update Their Card

```ruby
# A link to a Paystack page where the customer changes the card on the subscription
paystack.subscriptions.generate_update_link(code: "SUB_vsyqdmlzble3uii").data.link

# Or have Paystack email the customer that link
paystack.subscriptions.send_update_link(code: "SUB_vsyqdmlzble3uii")
```

Both take the subscription code; the numeric ID is not found.
### Dedicated Virtual Accounts

A dedicated virtual account is a bank account number Paystack issues to one of your customers, so they can pay you by bank transfer. Paystack's docs offer it to Nigerian and Ghanaian businesses (`NGN` and `GHS`), and it has to be enabled for your business first: until it is, every call returns an unsuccessful response with status 403 and the message "Dedicated NUBAN is not available for your business".

#### Create or Assign an Account

```ruby
# Which banks can issue an account for your integration (e.g. "wema-bank", "titan-paystack")
paystack.dedicated_virtual_accounts.fetch_bank_providers

# For a customer you already created (their code or ID)
response = paystack.dedicated_virtual_accounts.create(customer: "CUS_xnxdt6s1zg1f4nx", preferred_bank: "wema-bank")

if response.success?
  puts "#{response.data.account_number} at #{response.data.bank.name}"
else
  puts "Error: #{response.error_message}"
end

# Or create the customer, validate them and assign an account in one call. Paystack's docs
# show the reply "Assign dedicated account in progress", with no account in it.
paystack.dedicated_virtual_accounts.assign(
  email: "ama@example.com",
  first_name: "Ama",
  last_name: "Mensah",
  phone: "+2348100000000",
  preferred_bank: "wema-bank",
  country: "NG"
)
```

#### List, Fetch, Requery and Deactivate

```ruby
paystack.dedicated_virtual_accounts.list(active: true, currency: "NGN", provider_slug: "wema-bank")

# By the account's numeric ID
paystack.dedicated_virtual_accounts.fetch(dedicated_account_id: 1234553)

# Ask Paystack to check the account for transfers it has not recorded yet
paystack.dedicated_virtual_accounts.requery(account_number: "1234567890", provider_slug: "wema-bank", date: Date.new(2026, 10, 9))

paystack.dedicated_virtual_accounts.deactivate(dedicated_account_id: 1234553)
```

#### Split Payments on an Account

```ruby
# Send payments into the account through a split (or a single subaccount:)
paystack.dedicated_virtual_accounts.add_split(account_number: "0033322211", split_code: "SPL_e7jnRLtzla")

# And stop splitting them
paystack.dedicated_virtual_accounts.remove_split(account_number: "0033322211")
```

`create` and `assign` also take `split_code:` or `subaccount:` to set a split when the account is made.

### Payment Requests

A payment request is an invoice Paystack sends to a customer, who pays it online. Amounts are in the subunit (pesewas, kobo, cents).

#### Create a Payment Request

```ruby
# customer is a customer code (CUS_...) or ID. Give line_items and tax, each an Array of Hashes,
# and Paystack adds them up (2 x 2000 + 300 = 4300 here); give amount instead when you have none.
response = paystack.payment_requests.create(
  customer: "CUS_p6i0reogc8ulu1n",
  currency: "GHS",
  description: "Harvest thanksgiving pledge",
  line_items: [{name: "Pledge", amount: 2000, quantity: 2}],
  tax: [{name: "Levy", amount: 300}],
  due_date: Date.new(2026, 12, 31), # a Date, a Time or an ISO 8601 string
  metadata: {branch: "Osu"},        # a Hash; Paystack refuses a JSON string here
  draft: true                       # a draft is not sent; finalize it later
)

if response.success?
  puts "Created #{response.data.request_code} for #{response.data.amount}"
else
  puts "Error: #{response.error_message}"
end
```

Paystack's docs say it emails the customer when a request is created, unless you pass `draft: true` or `send_notification: false`. Without `amount`, `line_items` or `tax`, Paystack refuses anything but a draft ("Amount was not passed or could not be extrapolated from line items.").

#### List, Fetch and Verify Payment Requests

```ruby
# customer_id is the numeric customer ID (Paystack ignores a CUS_ code here)
paystack.payment_requests.list(customer_id: 407172149, status: "pending", per_page: 20)

# Archived requests are left out unless you pass include_archive: true. Paystack includes them
# whenever the parameter is sent, even as false, so leave it out rather than passing false.
paystack.payment_requests.list(include_archive: true)

# Fetch by numeric ID or PRQ_ code
paystack.payment_requests.fetch(id_or_code: "PRQ_7w7dpecncnebg7e")

# Verify takes the PRQ_ code only, and only once the request is no longer a draft
paystack.payment_requests.verify(code: "PRQ_7w7dpecncnebg7e")

# Pending, successful and total amounts per currency
paystack.payment_requests.totals
```

#### Update, Finalize, Notify and Archive

```ruby
# Send only what changes; new line_items and tax recompute the amount
paystack.payment_requests.update(id_or_code: "PRQ_7w7dpecncnebg7e", due_date: "2027-01-31")

# Finalize a draft. Paystack emails the customer unless send_notification is false.
paystack.payment_requests.finalize(id_or_code: "PRQ_7w7dpecncnebg7e", send_notification: false)

# Email the customer a reminder
paystack.payment_requests.notify(code: "PRQ_7w7dpecncnebg7e")

# Archive: it no longer shows up in list or verify
paystack.payment_requests.archive(id_or_code: "PRQ_7w7dpecncnebg7e")
```

### Pages

A payment page is a public pay link at `https://paystack.com/pay/<slug>`, useful for donations or one-off payments. Amounts are integers in the currency's subunit (pesewas for GHS).

```ruby
# Without an amount the customer chooses what to pay (a donation page). Pass fixed_amount: true
# together with amount to fix it.
response = paystack.pages.create(
  name: "Sunday Offering",
  description: "Give to the work of the church",
  slug: "sunday-offering",
  collect_phone: true,
  custom_fields: [{display_name: "Branch", variable_name: "branch"}]
)
response.data.slug # => "sunday-offering"

# type is payment (default), subscription (with plan:), product or plan
paystack.pages.create(name: "Lite plan", type: "subscription", plan: "4288882")

# Is a slug free? An unsuccessful response ("Slug already in use") means it is taken.
paystack.pages.check_slug_availability(slug: "sunday-offering").success?
```

#### List, Fetch and Update Pages

```ruby
paystack.pages.list(per_page: 20, page: 1)

# Fetch and update take the numeric ID or the slug
paystack.pages.fetch(id_or_slug: "sunday-offering")
paystack.pages.update(id_or_slug: "sunday-offering", description: "New description")

# Deactivate the page URL
paystack.pages.update(id_or_slug: 2215275, active: false)

# Product pages only: add products by numeric ID (the page needs type: "product")
paystack.pages.add_products(id: 2215275, products: [473, 292])
```

### Products

A product is something you sell through Paystack (a good, with stock if you track it). Prices are integers in the subunit of the currency: pesewas for GHS, kobo for NGN, cents for ZAR or USD. Only the currencies enabled on your integration are accepted.

#### Create a Product

```ruby
response = paystack.products.create(
  name: "Church anniversary t-shirt",
  price: 5000,        # GHS 50.00, in pesewas
  currency: "GHS",
  description: "Cotton, sizes S to XL",
  quantity: 100,      # stock on hand; use unlimited: true instead if you do not track stock
  metadata: {branch: "Osu"} # a Hash; Paystack stores a JSON string as an object of its characters
)

if response.success?
  puts "Created #{response.data.product_code} (ID #{response.data.id})"
else
  puts "Error: #{response.error_message}"
end
```

`name`, `price` and `currency` are required by Paystack. Its docs and spec also list `description` as required, but the test API creates a product without one.

#### List, Fetch, Update and Delete Products

```ruby
paystack.products.list(per_page: 20, page: 1, active: true)

# Products are fetched, updated and deleted by their numeric ID (not the PROD_ code)
paystack.products.fetch(id: 2782723)

# Send only what changes
paystack.products.update(id: 2782723, price: 6000, quantity: 80)

paystack.products.delete(id: 2782723)
```

`delete` calls `DELETE /product/{id}`, which is in Paystack's OpenAPI spec but on no docs page; the test API deletes the product and answers `404 Product not found` afterwards.
### Storefronts

A storefront is a Paystack-hosted shop (`https://paystack.shop/<slug>`) that sells products you created with the Products API. Storefronts are identified by their numeric ID.

#### Create a Storefront

```ruby
# Paystack requires name, slug and currency (its docs mark slug optional; the API does not).
# The slug must be 5 to 100 characters: lowercase letters, numbers, dashes or underscores.
response = paystack.storefronts.create(
  name: "Harvest stall",
  slug: "harvest-stall",
  currency: "GHS", # one your integration accepts; Paystack refuses others ("Currency not supported or allowed")
  description: "Sunday harvest sale"
)

puts response.data.id if response.success?
```

Check a slug first with `verify_slug`. Paystack answers with the storefront that holds it when it is taken (in test or live mode), and with a 404 "Storefront not found" when it is free:

```ruby
paystack.storefronts.verify_slug(slug: "harvest-stall").success? # => false: the slug is free
```

#### List, Fetch, Update and Delete Storefronts

```ruby
paystack.storefronts.list(status: "active", per_page: 20) # status is active or inactive
paystack.storefronts.fetch(id: 1852308)

# Send only what changes; update returns a message, not the storefront
paystack.storefronts.update(id: 1852308, slug: "harvest-stall-2", description: "Harvest weekend")

# Paystack keeps a deleted storefront with status "deleted"; it drops out of list
paystack.storefronts.delete(id: 1852308)
```

#### Products, Orders, Duplicate and Publish

```ruby
# products takes numeric product IDs (Paystack refuses PROD_ codes here)
paystack.storefronts.add_products(id: 1852308, products: [2782728])
paystack.storefronts.list_products(id: 1852308)
paystack.storefronts.fetch_orders(id: 1852308)

# A copy with its products, named "Copy of ..." and given a new slug
paystack.storefronts.duplicate(id: 1852308)

# Publish copies the storefront and its products to your live integration, even with a test key
paystack.storefronts.publish(id: 1852308)
```

`publish` makes a public, live storefront. On the test API it answered "Storefront published to live" and returned a new storefront with `domain: "live"` and a new ID, gave it the original slug, and renamed the test storefront (adding "-TEST" to the name and giving it a new slug). The live copy cannot be fetched or deleted with a test key: remove it from the dashboard in live mode.

### Bulk Charges

A bulk charge charges many saved cards (reusable authorizations) in one batch, which Paystack queues and processes in the background. Amounts are in the subunit (pesewas, kobo, cents).

#### Initiate a Bulk Charge

```ruby
# The body is a JSON array: one Hash per charge, each with a reusable authorization code and an
# integer amount. Give each a reference you can find again: it becomes the charge's transaction
# reference (lowercase letters, digits, - and _, per the spec).
response = paystack.bulk_charges.initiate(
  charges: [
    {authorization: "AUTH_50w0d0f5xo", amount: 5000, reference: "tithe-2026-10-kwesi"},
    {authorization: "AUTH_xfuz7dy4b9", amount: 2000, reference: "tithe-2026-10-ama"}
  ]
)

if response.success?
  puts "Queued #{response.data.batch_code} with #{response.data.total_charges} charges"
else
  puts "Error: #{response.error_message}"
end
```

The SDK refuses an empty list but sends each Hash as given: Paystack, not the SDK, checks what is inside. A successful response means the charges were queued ("Charges have been queued"), not that they succeeded; read each charge's outcome with `fetch_charges` or from your webhooks. Like every write, `initiate` is not retried after a timeout, so check `list_batches` before sending the same charges again.

#### List and Fetch Batches and Their Charges

```ruby
# status is active, paused or complete. Paystack's docs also list from and to, but the API ignores them.
paystack.bulk_charges.list_batches(status: "active", per_page: 20, page: 1)

# Fetch by numeric ID or BCH_ code; total_charges and pending_charges show its progress
batch = paystack.bulk_charges.fetch_batch(id_or_code: "BCH_1uhxe0d181eu850")
puts "#{batch.data.pending_charges} of #{batch.data.total_charges} still pending"

# Each charge with its customer, authorization, reference and status
# (pending, success, failed, error or inactive_authorization)
paystack.bulk_charges.fetch_charges(id_or_code: "BCH_1uhxe0d181eu850", status: "failed")
```

#### Pause and Resume a Batch

```ruby
# Both are GET requests, as Paystack documents them, and take the BCH_ batch code
paystack.bulk_charges.pause_batch(batch_code: "BCH_1uhxe0d181eu850")  # "Bulk charge batch has been paused"
paystack.bulk_charges.resume_batch(batch_code: "BCH_1uhxe0d181eu850") # "Bulk charge batch has been resumed"
```

A paused batch keeps its pending charges until it is resumed.

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
