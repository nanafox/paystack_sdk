# Balances

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
