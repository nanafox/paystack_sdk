# Orders

Order operations.

Use it as `client.orders`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
orders.list(per_page: nil, page: nil, from: nil, to: nil)
```

List Orders.

List the previously created orders

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/order/#list>

### `create`

```ruby
orders.create(
  email:,
  first_name:,
  last_name:,
  phone:,
  currency:,
  items:,
  shipping:,
  is_gift: nil,
  pay_for_me: nil
)
```

Create Order.

Create an order for selected items

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | The email of the customer placing the order |
| `first_name` | String | yes | The customer's first name |
| `last_name` | String | yes | The customer's last name |
| `phone` | String | yes | The customer's mobile number |
| `currency` | String | yes | Currency in which amount is set One of: GHS, KES, NGN, USD, ZAR. |
| `items` | Array | yes |  |
| `shipping` | Hash | yes | The shipping details of the order |
| `is_gift` | Boolean |  | A flag to indicate if the order is for someone else |
| `pay_for_me` | Boolean |  | A flag to indicate if the someone else should pay for the order |

Paystack docs: <https://paystack.com/docs/api/order/#create>

### `fetch`

```ruby
orders.fetch(id:)
```

Fetch Order.

Fetch the details of a previously created order

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the order |

Paystack docs: <https://paystack.com/docs/api/order/#fetch>

### `fetch_product_orders`

```ruby
orders.fetch_product_orders(id:)
```

Fetch Product Orders.

Fetch all orders for a particular product

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the order |

Paystack docs: <https://paystack.com/docs/api/order/#fetch-product-orders>

### `validate`

```ruby
orders.validate(code:)
```

Validate Order.

Validate a pay for me order

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | The unique code of a previously created order |

Paystack docs: <https://paystack.com/docs/api/order/#validate>


