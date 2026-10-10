# Pages

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

## List, Fetch and Update Pages

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
