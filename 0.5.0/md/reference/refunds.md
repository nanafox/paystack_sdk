# Refunds

Refund operations.

Use it as `client.refunds`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
refunds.list(per_page: nil, page: nil, from: nil, to: nil, transaction_id: nil)
```

List Refunds.

List previously created refunds

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `from` | String |  | The start date |
| `to` | String |  | The end date |
| `transaction_id` | Integer |  | The ID of the refunded transaction. |

Paystack docs: <https://paystack.com/docs/api/refund/#list>

### `create`

```ruby
refunds.create(transaction:, amount: nil, currency: nil, customer_note: nil, merchant_note: nil)
```

Create Refund.

Initiate a refund for a previously completed transaction

| Parameter | Type | Required | Description |
|---|---|---|---|
| `transaction` | String | yes | The reference or ID of a previously completed transaction. |
| `amount` | Integer |  | Amount to be refunded to the customer. |
| `currency` | String |  | Three-letter ISO currency One of: GHS, KES, NGN, USD, ZAR. |
| `customer_note` | String |  | Customer reason |
| `merchant_note` | String |  | Merchant reason |

Paystack docs: <https://paystack.com/docs/api/refund/#create>

### `retry_with_customer_details`

```ruby
refunds.retry_with_customer_details(id:, refund_account_details:)
```

Retry Refund.

Retry a refund with a `needs-attention` status by providing the bank account details of a customer.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The identifier of the refund |
| `refund_account_details` | Hash | yes | An object that contains the customer’s account details for refund |

Paystack docs: <https://paystack.com/docs/api/refund/#retry>

### `fetch`

```ruby
refunds.fetch(id:)
```

Fetch Refund.

Get a previously created refund

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The identifier of the refund |

Paystack docs: <https://paystack.com/docs/api/refund/#fetch>


