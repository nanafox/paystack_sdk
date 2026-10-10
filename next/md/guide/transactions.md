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

## Verify a Transaction

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

## List Transactions

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

## Fetch a Transaction

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

## Get Transaction Totals

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

## Transaction Timeline, Export and Charging

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

## Checking a Payment

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

## Charging a Saved Card

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
