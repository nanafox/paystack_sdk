# Products

A product is something you sell through Paystack (a good, with stock if you track it). Prices are integers in the subunit of the currency: pesewas for GHS, kobo for NGN, cents for ZAR or USD. Only the currencies enabled on your integration are accepted.

## Create a Product

```ruby
response = paystack.products.create(
  name: "Church anniversary t-shirt",
  price: 5000,        # GHS 50.00, in pesewas
  currency: "GHS",
  description: "Cotton, sizes S to XL",
  quantity: 100,      # stock on hand; use unlimited: true instead if you do not track stock
  metadata: {branch: "Osu"} # a Hash; Paystack stores a JSON string as an object of its characters
)

if response.success?
  puts "Created #{response.data.product_code} (ID #{response.data.id})"
else
  puts "Error: #{response.error_message}"
end
```

`name`, `price` and `currency` are required by Paystack. Its docs and spec also list `description` as required, but the test API creates a product without one.

## List, Fetch, Update and Delete Products

```ruby
paystack.products.list(per_page: 20, page: 1, active: true)

# Products are fetched, updated and deleted by their numeric ID (not the PROD_ code)
paystack.products.fetch(id: 2782723)

# Send only what changes
paystack.products.update(id: 2782723, price: 6000, quantity: 80)

paystack.products.delete(id: 2782723)
```

`delete` calls `DELETE /product/{id}`, which is in Paystack's OpenAPI spec but on no docs page; the test API deletes the product and answers `404 Product not found` afterwards.
