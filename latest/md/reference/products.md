# Products

Product operations.

Use it as `client.products`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
products.list(per_page: nil, page: nil, active: nil, from: nil, to: nil)
```

List Products.

List all previously created products

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `active` | Boolean |  | The state of the product |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/product/#list>

### `create`

```ruby
products.create(
  name:,
  price:,
  currency:,
  description: nil,
  unlimited: nil,
  quantity: nil,
  split_code: nil,
  metadata: nil
)
```

Create Product.

Create a new product on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | String | yes | Name of product |
| `price` | Integer | yes | Price should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR |
| `currency` | String | yes | Currency in which price is set. |
| `description` | String |  | The description of the product. |
| `unlimited` | Boolean |  | Set to true if the product has unlimited stock. |
| `quantity` | Integer |  | Number of products in stock. |
| `split_code` | String |  | The split code if sharing the transaction with partners |
| `metadata` | Hash |  | A set of key/value pairs that you can attach to the product. |

Paystack docs: <https://paystack.com/docs/api/product/#create>

### `fetch`

```ruby
products.fetch(id:)
```

Fetch Product.

Fetch a previously created product

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the product |

Paystack docs: <https://paystack.com/docs/api/product/#fetch>

### `update`

```ruby
products.update(
  id:,
  name: nil,
  description: nil,
  price: nil,
  currency: nil,
  unlimited: nil,
  quantity: nil,
  split_code: nil,
  metadata: nil
)
```

Update product.

Update a previously created product

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the product |
| `name` | String |  | Name of product |
| `description` | String |  | The description of the product |
| `price` | Integer |  | Price should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR |
| `currency` | String |  | Currency in which price is set. |
| `unlimited` | Boolean |  | Set to true if the product has unlimited stock. |
| `quantity` | Integer |  | Number of products in stock. |
| `split_code` | String |  | The split code if sharing the transaction with partners |
| `metadata` | Hash |  | JSON object of custom data |

Paystack docs: <https://paystack.com/docs/api/product/#update>

### `delete`

```ruby
products.delete(id:)
```

Delete Product.

Delete a previously created product

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the product |

Paystack docs: <https://paystack.com/docs/api/product/#delete-product>


