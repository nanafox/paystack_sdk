# Settlements

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
