# Storefronts

Storefront operations.

Use it as `client.storefronts`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
storefronts.list(per_page: nil, page: nil, status: nil)
```

List Storefronts.

List the storefronts you previously created

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |
| `status` | String |  | One of: active, inactive. |

Paystack docs: <https://paystack.com/docs/api/storefront/#list>

### `create`

```ruby
storefronts.create(name:, slug:, currency:, description: nil)
```

Create Storefront.

Create a digital shop to manage and display your products

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | String | yes | Name of the storefront |
| `slug` | String | yes | A unique identifier to access your store. |
| `currency` | String | yes | Currency for prices of products in your storefront. One of: GHS, KES, NGN, USD, ZAR. |
| `description` | String |  | The description of the storefront |

Paystack docs: <https://paystack.com/docs/api/storefront/#create>

### `fetch`

```ruby
storefronts.fetch(id:)
```

Fetch Storefront.

Get the details of a previously created Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |

Paystack docs: <https://paystack.com/docs/api/storefront/#fetch>

### `update`

```ruby
storefronts.update(id:, name: nil, slug: nil, description: nil)
```

Update Storefront.

Update the details of a previously created Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |
| `name` | String |  | Name of the storefront |
| `slug` | String |  | A unique identifier to access your store. |
| `description` | String |  | The description of the storefront |

Paystack docs: <https://paystack.com/docs/api/storefront/#update>

### `delete`

```ruby
storefronts.delete(id:)
```

Delete Storefront.

Delete a previously created Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |

Paystack docs: <https://paystack.com/docs/api/storefront/#delete>

### `verify_slug`

```ruby
storefronts.verify_slug(slug:)
```

Verify Storefront Slug.

Verify the availability of a slug before using it for your Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `slug` | String | yes | The custom slug to check |

Paystack docs: <https://paystack.com/docs/api/storefront/#verify-slug>

### `fetch_orders`

```ruby
storefronts.fetch_orders(id:)
```

Fetch Storefront Orders.

Fetch all orders in your Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |

Paystack docs: <https://paystack.com/docs/api/storefront/#fetch-orders>

### `list_products`

```ruby
storefronts.list_products(id:)
```

List Storefront Products.

List the products in a Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |

Paystack docs: <https://paystack.com/docs/api/storefront/#list-products>

### `add_products`

```ruby
storefronts.add_products(id:, products:)
```

Add Products to Storefront.

Add previously created products to a Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |
| `products` | Array | yes | An array of product IDs |

Paystack docs: <https://paystack.com/docs/api/storefront/#add-products>

### `publish`

```ruby
storefronts.publish(id:)
```

Publish Storefront.

Make your Storefront publicly available

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |

::: warning Note
Publishing copies the storefront and its products into LIVE mode, even when you call it with a test key (sk_test_). The live copy is active, can be found by its slug, and cannot be read or deleted with a test key. Do not call this to try the API out; use `duplicate` instead.
:::

Paystack docs: <https://paystack.com/docs/api/storefront/#publish>

### `duplicate`

```ruby
storefronts.duplicate(id:)
```

Duplicate Storefront.

Duplicate a previously created Storefront

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the Storefront |

Paystack docs: <https://paystack.com/docs/api/storefront/#duplicate>


