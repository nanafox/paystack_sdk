# Storefronts

A storefront is a Paystack-hosted shop (`https://paystack.shop/<slug>`) that sells products you created with the Products API. Storefronts are identified by their numeric ID.

## Create a Storefront

```ruby
# Paystack requires name, slug and currency (its docs mark slug optional; the API does not).
# The slug must be 5 to 100 characters: lowercase letters, numbers, dashes or underscores.
response = paystack.storefronts.create(
  name: "Harvest stall",
  slug: "harvest-stall",
  currency: "GHS", # one your integration accepts; Paystack refuses others ("Currency not supported or allowed")
  description: "Sunday harvest sale"
)

puts response.data.id if response.success?
```

Check a slug first with `verify_slug`. Paystack answers with the storefront that holds it when it is taken (in test or live mode), and with a 404 "Storefront not found" when it is free:

```ruby
paystack.storefronts.verify_slug(slug: "harvest-stall").success? # => false: the slug is free
```

## List, Fetch, Update and Delete Storefronts

```ruby
paystack.storefronts.list(status: "active", per_page: 20) # status is active or inactive
paystack.storefronts.fetch(id: 1852308)

# Send only what changes; update returns a message, not the storefront
paystack.storefronts.update(id: 1852308, slug: "harvest-stall-2", description: "Harvest weekend")

# Paystack keeps a deleted storefront with status "deleted"; it drops out of list
paystack.storefronts.delete(id: 1852308)
```

## Products, Orders, Duplicate and Publish

```ruby
# products takes numeric product IDs (Paystack refuses PROD_ codes here)
paystack.storefronts.add_products(id: 1852308, products: [2782728])
paystack.storefronts.list_products(id: 1852308)
paystack.storefronts.fetch_orders(id: 1852308)

# A copy with its products, named "Copy of ..." and given a new slug
paystack.storefronts.duplicate(id: 1852308)

# Publish copies the storefront and its products to your live integration, even with a test key
paystack.storefronts.publish(id: 1852308)
```

`publish` makes a public, live storefront. On the test API it answered "Storefront published to live" and returned a new storefront with `domain: "live"` and a new ID, gave it the original slug, and renamed the test storefront (adding "-TEST" to the name and giving it a new slug). The live copy cannot be fetched or deleted with a test key: remove it from the dashboard in live mode.
