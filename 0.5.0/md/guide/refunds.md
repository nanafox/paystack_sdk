# Refunds

Refunds return money from a successful transaction to the customer. They move real money in live mode, so the SDK never retries them except on `429` (see [Timeouts and Retries](https://nanafox.github.io/paystack_sdk/0.5.0/md/guide/timeouts-and-retries.md)).

## Create a Refund

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

## Fetch, List and Retry Refunds

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
