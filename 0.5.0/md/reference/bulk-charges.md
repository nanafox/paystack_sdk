# Bulk Charges

Bulk Charge operations.

Use it as `client.bulk_charges`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list_batches`

```ruby
bulk_charges.list_batches(per_page: nil, page: nil, status: nil)
```

List Bulk Charge Batches.

List all bulk charge batches.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The offset to retrieve data from |
| `status` | String |  | Filter by the status of the charges One of: active, paused, complete. |

Paystack docs: <https://paystack.com/docs/api/bulk-charge/#list>

### `initiate`

```ruby
bulk_charges.initiate(charges:)
```

Initiate Bulk Charge.

Charge multiple customers in batches

| Parameter | Type | Required | Description |
|---|---|---|---|
| `charges` | Array | yes | The request body: an array of hashes, each with authorization, amount, and optionally reference, attempt_partial_debit, at_least, metadata |

Paystack docs: <https://paystack.com/docs/api/bulk-charge/#initiate>

### `fetch_batch`

```ruby
bulk_charges.fetch_batch(id_or_code:)
```

Fetch Bulk Charge Batch.

This endpoint retrieves a specific batch code.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The code for the charge whose batches you want to retrieve |

Paystack docs: <https://paystack.com/docs/api/bulk-charge/#fetch-batch>

### `fetch_charges`

```ruby
bulk_charges.fetch_charges(id_or_code:, per_page: nil, page: nil, status: nil)
```

List Charges in a Batch.

This endpoint retrieves the charges associated with a specified batch code

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | An code for the batch whose charges you want to retrieve |
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The offset to retrieve data from |
| `status` | String |  | Filter by the status of the charges One of: success, failed, pending, error, inactive_authorization. |

Paystack docs: <https://paystack.com/docs/api/bulk-charge/#fetch-charge>

### `pause_batch`

```ruby
bulk_charges.pause_batch(batch_code:)
```

Pause Bulk Charge Batch.

Pause the processing of a charge batch

| Parameter | Type | Required | Description |
|---|---|---|---|
| `batch_code` | String | yes | The batch code for the bulk charge you want to pause |

Paystack docs: <https://paystack.com/docs/api/bulk-charge/#pause>

### `resume_batch`

```ruby
bulk_charges.resume_batch(batch_code:)
```

Resume Bulk Charge Batch.

Resume the processing of a previously paused charge batch

| Parameter | Type | Required | Description |
|---|---|---|---|
| `batch_code` | String | yes | The batch code for the bulk charge you want to pause |

Paystack docs: <https://paystack.com/docs/api/bulk-charge/#resume>


