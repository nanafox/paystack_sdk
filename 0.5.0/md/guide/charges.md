# Charges

The Charge API lets you pick the payment channel yourself instead of sending the customer to Checkout: a saved card authorization, a bank account, USSD, mobile money, QR, EFT, Pay with Transfer or Capitec Pay. Many charges need one more step from the customer (a PIN, OTP, phone number, birthday or address) before they complete. See the Paystack docs: [Charge API](https://paystack.com/docs/api/charge/) and [Payment Channels](https://paystack.com/docs/payments/payment-channels/).

## Mobile Money in Ghana: Which Networks

Paystack lists three Ghana mobile-money providers (`banks.list(country: "ghana", type: "mobile_money")`): `MTN`, `VOD` (shown as Vodafone, now Telecel) and `ATL` (AirtelTigo). The bank list uses uppercase codes; `charges.mobile_money` takes the provider in any case and sends it in lowercase (`mtn`, `vod`, `atl`).

What was checked, against Paystack's test API only: a merchant-started charge of 100 pesewas (GHS) for each of the three providers on Paystack's test number was accepted, came back with `status: "success"` and `gateway_response: "Approved"` immediately, and `check_pending(reference:)` returned the same. **Test mode does not model the payer approving the prompt on their phone, so this does not show which live networks accept a charge you start yourself.** Treat each network as unverified in live mode: start the charge, read `response.status` (`status?(:pay_offline)`, `status?(:send_otp)`, `status?(:pending)` and so on, as Paystack returns them), show `response.display_text` to the payer when there is one, and poll `charges.check_pending(reference:)` or wait for the `charge.success` webhook. Confirm with `transactions.verify(reference:)` before giving value. If a network refuses a merchant-started prompt, fall back to a payment link for that network.

## Create a Mobile Money Charge

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

## Create a Charge on Another Channel

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

## Complete a Charge

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

## Check a Pending Charge

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
