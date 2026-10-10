# Orders

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
