# Plans

A plan is a recurring charge definition: an amount, an interval and a currency. Customers are subscribed to a plan to be charged on that schedule. Paystack does not let you delete a plan.

## Create a Plan

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

## List and Fetch Plans

```ruby
paystack.plans.list(per_page: 20, page: 1)

# Filter by interval, amount (in the subunit) or a date range
paystack.plans.list(interval: "monthly", amount: 20_000)
paystack.plans.list(from: "2026-01-01", to: "2026-12-31")

# Fetch by plan code or numeric ID
paystack.plans.fetch(id_or_code: "PLN_gx2wn530m0i3w3m")
```

## Update a Plan

```ruby
# Send only what changes
paystack.plans.update(id_or_code: "PLN_gx2wn530m0i3w3m", name: "Monthly tithe (renamed)")

# By default Paystack applies the change to the plan's existing subscriptions too. Pass
# update_existing_subscriptions: false so that only new subscriptions use the new values.
paystack.plans.update(id_or_code: "PLN_gx2wn530m0i3w3m", amount: 25_000, update_existing_subscriptions: false)
```

The response carries a message only, for example `"Plan updated. 1 subscription(s) affected"`.
