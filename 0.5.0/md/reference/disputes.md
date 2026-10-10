# Disputes

Dispute operations.

Use it as `client.disputes`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
disputes.list(per_page: nil, page: nil, status: nil, transaction: nil, from: nil, to: nil)
```

List Disputes.

List transaction disputes filed by customers

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `status` | String |  | Dispute status One of: awaiting-merchant-feedback, awaiting-bank-feedback, pending, resolved. |
| `transaction` | String |  | Transaction ID |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/dispute/#list>

### `fetch`

```ruby
disputes.fetch(id:)
```

Fetch Dispute.

Fetch a transaction dispute

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the dispute |

Paystack docs: <https://paystack.com/docs/api/dispute/#fetch>

### `update`

```ruby
disputes.update(id:, refund_amount:, uploaded_filename: nil)
```

Update Dispute.

Update a transaction dispute

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the dispute |
| `refund_amount` | Integer | yes | The amount to refund, in the subunit of your currency |
| `uploaded_filename` | String |  | Filename of attachment returned via response from the Dispute upload URL |

Paystack docs: <https://paystack.com/docs/api/dispute/#update>

### `fetch_upload_url`

```ruby
disputes.fetch_upload_url(id:, upload_filename: nil)
```

Fetch Upload URL.

Get the URL to upload a dispute evidence

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the dispute |
| `upload_filename` | String |  | The file name, with its extension, that you want to upload (for example filename.pdf). |

Paystack docs: <https://paystack.com/docs/api/dispute/#upload-url>

### `export`

```ruby
disputes.export(per_page: nil, page: nil, status: nil, from: nil, to: nil)
```

Export Disputes.

Export the disputes available on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `status` | String |  | One of: awaiting-merchant-feedback, awaiting-bank-feedback, pending, resolved. |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/dispute/#export>

### `list_transaction`

```ruby
disputes.list_transaction(id:)
```

List Transaction Disputes.

List all disputes filed for a transaction

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the transaction |

Paystack docs: <https://paystack.com/docs/api/dispute/#transaction>

### `resolve`

```ruby
disputes.resolve(id:, resolution:, message:, refund_amount:, uploaded_filename:, evidence: nil)
```

Resolve Dispute.

Resolve a transaction dispute

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the dispute |
| `resolution` | String | yes | Dispute resolution. |
| `message` | String | yes | Reason for resolving |
| `refund_amount` | Integer | yes | The amount to refund, in the subunit of your integration currency |
| `uploaded_filename` | String | yes | Filename of attachment returned via response from the Dispute upload URL |
| `evidence` | Integer |  | Evidence Id for fraud claims |

Paystack docs: <https://paystack.com/docs/api/dispute/#resolve>

### `add_evidence`

```ruby
disputes.add_evidence(
  id:,
  customer_email:,
  customer_name:,
  customer_phone:,
  service_details:,
  delivery_address: nil,
  delivery_date: nil
)
```

Add Evidence.

Provide evidence for a dispute

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The unique identifier of the dispute |
| `customer_email` | String | yes | Customer email |
| `customer_name` | String | yes | Customer name |
| `customer_phone` | String | yes | Customer mobile number |
| `service_details` | String | yes | Details of service offered |
| `delivery_address` | String |  | Delivery address |
| `delivery_date` | String |  | ISO 8601 representation of delivery date (YYYY-MM-DD) |

Paystack docs: <https://paystack.com/docs/api/dispute/#evidence>


