# Pages

Page operations.

Use it as `client.pages`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
pages.list(per_page: nil, page: nil, from: nil, to: nil)
```

List Pages.

List all previously created payment pages

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/page/#list>

### `create`

```ruby
pages.create(
  name:,
  description: nil,
  amount: nil,
  currency: nil,
  slug: nil,
  type: nil,
  plan: nil,
  fixed_amount: nil,
  split_code: nil,
  metadata: nil,
  redirect_url: nil,
  success_message: nil,
  notification_email: nil,
  collect_phone: nil,
  custom_fields: nil
)
```

Create Page.

Create a webpage to receive payments

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | String | yes | Name of page |
| `description` | String |  | The description of the page |
| `amount` | Integer |  | Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR |
| `currency` | String |  | The transaction currency. One of: NGN, GHS, ZAR, KES, USD. |
| `slug` | String |  | URL slug you would like to be associated with this page. |
| `type` | String |  | The type of payment page to create. One of: payment, subscription, product, plan. |
| `plan` | String |  | The ID of the plan to subscribe customers on this payment page to when `type` is set to `subscription`. |
| `fixed_amount` | Boolean |  | Specifies whether to collect a fixed amount on the payment page. |
| `split_code` | String |  | The split code of the transaction split. |
| `metadata` | Hash |  | JSON object of custom data |
| `redirect_url` | String |  | If you would like Paystack to redirect to a URL upon successful payment, specify the URL here. |
| `success_message` | String |  | A success message to display to the customer after a successful transaction |
| `notification_email` | String |  | An email address that will receive transaction notifications for this payment page |
| `collect_phone` | Boolean |  | Specify whether to collect phone numbers on the payment page |
| `custom_fields` | Array |  | If you would like to accept custom fields, specify them here. |

Paystack docs: <https://paystack.com/docs/api/page/#create>

### `fetch`

```ruby
pages.fetch(id_or_slug:)
```

Fetch Page.

Get a previously created payment page

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_slug` | String | yes | The unique identifier of a payment page |

Paystack docs: <https://paystack.com/docs/api/page/#fetch>

### `update`

```ruby
pages.update(id_or_slug:, name: nil, description: nil, amount: nil, active: nil)
```

Update Page.

Update a previously created payment page

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_slug` | String | yes | The unique identifier of a payment page |
| `name` | String |  | Name of page |
| `description` | String |  | The description of the page |
| `amount` | Integer |  | Amount should be in the subunit of the currency |
| `active` | Boolean |  | Set to false to deactivate page url |

Paystack docs: <https://paystack.com/docs/api/page/#update>

### `check_slug_availability`

```ruby
pages.check_slug_availability(slug:)
```

Check Slug Availability.

Check if a custom slug is available for use when creating a payment page

| Parameter | Type | Required | Description |
|---|---|---|---|
| `slug` | String | yes | The custom slug to check |

Paystack docs: <https://paystack.com/docs/api/page/#check-slug>

### `add_products`

```ruby
pages.add_products(id:, products:)
```

Add Products.

Add products to a previously created payment page.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes |  |
| `products` | Array | yes | A list of IDs of products to add to a page. |

Paystack docs: <https://paystack.com/docs/api/page/#add-products>


