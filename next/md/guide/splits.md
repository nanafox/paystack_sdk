# Splits

A transaction split shares the settlement for a payment between your payout account and one or more subaccounts (`ACCT_...`). Create the split once, then pass its `split_code` when you initialize a transaction or create a charge.

## Create a Split

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

## List, Fetch and Update Splits

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

## Add, Update or Remove a Subaccount

```ruby
# Adds the subaccount, or changes its share if it is already in the split (numeric split ID)
paystack.splits.add_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb", share: 20)

paystack.splits.remove_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb")
```
