# Payment Requests

Payment Request operations.

Use it as `client.payment_requests`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
payment_requests.list(
  per_page: nil,
  page: nil,
  customer_id: nil,
  status: nil,
  currency: nil,
  from: nil,
  to: nil,
  include_archive: nil
)
```

List Payment Request.

List all previously created payment requests to your customers

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `customer_id` | Integer |  | Customer ID |
| `status` | String |  | Invoice status to filter One of: draft, pending, success, failed. |
| `currency` | String |  | If your integration supports more than one currency, choose the one to filter |
| `from` | String |  | The start date |
| `to` | String |  | The end date |
| `include_archive` | Boolean |  | Pass true to include archived payment requests. |

Paystack docs: <https://paystack.com/docs/api/payment-request/#list>

### `create`

```ruby
payment_requests.create(
  customer:,
  amount: nil,
  currency: nil,
  due_date: nil,
  description: nil,
  line_items: nil,
  tax: nil,
  send_notification: nil,
  draft: nil,
  has_invoice: nil,
  invoice_number: nil,
  split_code: nil,
  metadata: nil,
  redirect_url: nil
)
```

Create Payment Request.

Create a new payment request by issuing an invoice to a customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `customer` | String | yes | Customer id or code |
| `amount` | Integer |  | The amount in the subunit. |
| `currency` | String |  | Specify the currency of the invoice. |
| `due_date` | String |  | ISO 8601 date or date-time the request is due, for example 2026-12-31 or 2026-12-31T23:00:00Z. |
| `description` | String |  | A short description of the payment request |
| `line_items` | Array |  | Line items, each a Hash such as {name: "item 1", amount: 2000, quantity: 1} (amount in the subunit). |
| `tax` | Array |  | Taxes, each a Hash such as {name: "VAT", amount: 2000} (amount in the subunit). |
| `send_notification` | Boolean |  | Indicates whether Paystack sends an email notification to customer. |
| `draft` | Boolean |  | Indicate if request should be saved as draft. |
| `has_invoice` | Boolean |  | Set to true to create a draft invoice (adds an auto incrementing invoice number if none is provided) even if there are no line_items or tax passed |
| `invoice_number` | Integer |  | Numeric value of invoice. |
| `split_code` | String |  | The split code of the transaction split. |
| `metadata` | Hash |  | A Hash of custom data, stored on the payment request. |
| `redirect_url` | String |  | A URL for Paystack to redirect to after a successful payment. |

Paystack docs: <https://paystack.com/docs/api/payment-request/#create>

### `fetch`

```ruby
payment_requests.fetch(id_or_code:)
```

Fetch Payment Request.

Fetch a previously created payment request

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The unique identifier of a previously created payment request |

Paystack docs: <https://paystack.com/docs/api/payment-request/#fetch>

### `update`

```ruby
payment_requests.update(
  id_or_code:,
  customer: nil,
  amount: nil,
  currency: nil,
  due_date: nil,
  description: nil,
  line_items: nil,
  tax: nil,
  send_notification: nil,
  draft: nil,
  has_invoice: nil,
  invoice_number: nil,
  split_code: nil
)
```

Update Payment Request.

Update a previously created payment request

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The unique identifier of a previously created payment request |
| `customer` | String |  | Customer id or code |
| `amount` | Integer |  | Payment request amount. |
| `currency` | String |  | Specify the currency of the invoice. |
| `due_date` | String |  | ISO 8601 date or date-time the request is due, for example 2026-12-31 or 2026-12-31T23:00:00Z. |
| `description` | String |  | A short description of the payment request |
| `line_items` | Array |  | Line items, each a Hash such as {name: "item 1", amount: 2000, quantity: 1} (amount in the subunit). |
| `tax` | Array |  | Taxes, each a Hash such as {name: "VAT", amount: 2000} (amount in the subunit). |
| `send_notification` | Boolean |  | Indicates whether Paystack sends an email notification to customer. |
| `draft` | Boolean |  | Indicate if request should be saved as draft. |
| `has_invoice` | Boolean |  | Set to true to create a draft invoice (adds an auto incrementing invoice number if none is provided) even if there are no line_items or tax passed |
| `invoice_number` | Integer |  | Numeric value of invoice. |
| `split_code` | String |  | The split code of the transaction split. |

Paystack docs: <https://paystack.com/docs/api/payment-request/#update>

### `verify`

```ruby
payment_requests.verify(code:)
```

Verify Payment Request.

Verify the status of a previously created payment request

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | The unique identifier of a previously created payment request |

Paystack docs: <https://paystack.com/docs/api/payment-request/#verify>

### `notify`

```ruby
payment_requests.notify(code:)
```

Send Notification.

Trigger an email reminder to a customer for a previously created payment request

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | The unique identifier of a previously created payment request |

Paystack docs: <https://paystack.com/docs/api/payment-request/#send-notification>

### `totals`

```ruby
payment_requests.totals
```

Payment Request Total.

Get the metric of all pending and successful payment requests

Paystack docs: <https://paystack.com/docs/api/payment-request/#total>

### `finalize`

```ruby
payment_requests.finalize(id_or_code:, send_notification: nil)
```

Finalize Payment Request.

Finalise the creation of a draft payment request for a customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The unique identifier of a draft payment request |
| `send_notification` | Boolean |  | Whether Paystack emails the customer; defaults to true. |

Paystack docs: <https://paystack.com/docs/api/payment-request/#finalize>

### `archive`

```ruby
payment_requests.archive(id_or_code:)
```

Archive Payment Request.

Archive a payment request to clean up your records.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The unique identifier of a previously created payment request |

Paystack docs: <https://paystack.com/docs/api/payment-request/#archive>


