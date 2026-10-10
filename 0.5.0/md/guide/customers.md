# Customers

The SDK provides comprehensive support for Paystack's Customer API, allowing you to manage customer records, their identity validation, risk actions and authorizations (including Direct Debit mandates).

## Create a Customer

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

## List Customers

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

## Fetch a Customer

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

## Update a Customer

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

## Validate a Customer

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

## Set Risk Action (Whitelist/Blacklist)

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

## Authorizations and Direct Debit

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

# The customer's Direct Debit mandates (every customer's: paystack.direct_debits.list_mandate_authorizations)
paystack.customers.fetch_mandate_authorizations(id: 12345)

# Trigger an activation charge on an inactive mandate (pending mandates of several customers:
# paystack.direct_debits.trigger_activation_charge, see Direct Debit below)
paystack.customers.direct_debit_activation_charge(id: 12345, authorization_id: 1069309917)

# Deactivate an authorization (any channel)
response = paystack.customers.deactivate_authorization(authorization_code: "AUTH_72btv547")

if response.success?
  puts "Authorization deactivated: #{response.message}"
else
  puts "Error: #{response.error_message}"
end
```
