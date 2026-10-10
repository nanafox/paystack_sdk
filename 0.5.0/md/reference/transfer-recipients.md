# Transfer Recipients

Transfer Recipient operations.

Use it as `client.transfer_recipients`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
transfer_recipients.list(use_cursor: nil, next_cursor: nil, previous: nil, per_page: nil, page: nil)
```

List Transfer Recipients.

List transfer recipients available on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `use_cursor` | Boolean |  | A flag to indicate if cursor based pagination should be used |
| `next_cursor` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data |
| `previous` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data |
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |

Paystack docs: <https://paystack.com/docs/api/transfer-recipient/#list>

### `create`

```ruby
transfer_recipients.create(
  type:,
  name:,
  account_number:,
  bank_code:,
  description: nil,
  currency: nil,
  authorization_code: nil,
  metadata: nil
)
```

Create Transfer Recipient.

Creates a new recipient. A duplicate account number will lead to the retrieval of the existing record.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `type` | String | yes | Recipient Type One of: nuban, ghipss, mobile_money, basa, authorization. |
| `name` | String | yes | The recipient's name according to their account registration. |
| `account_number` | String | yes | Recipient's bank account number |
| `bank_code` | String | yes | Recipient's bank code, from the List Banks endpoint. |
| `description` | String |  | A description for this recipient |
| `currency` | String |  | Currency for the account receiving the transfer |
| `authorization_code` | String |  | An authorization code from a previous transaction |
| `metadata` | Hash |  | JSON object of custom data |

Paystack docs: <https://paystack.com/docs/api/transfer-recipient/#create>

### `bulk_create`

```ruby
transfer_recipients.bulk_create(batch:)
```

Bulk Create Transfer Recipient.

Create multiple transfer recipients in batches. A duplicate account number will lead to the retrieval of the existing record.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `batch` | Array&lt;Hash> | yes | A list of transfer recipient objects, each with the fields accepted by `#create` |

Paystack docs: <https://paystack.com/docs/api/transfer-recipient/#bulk>

### `fetch`

```ruby
transfer_recipients.fetch(id_or_code:)
```

Fetch Transfer recipient.

Fetch the details of a transfer recipient

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The recipient code (RCP_...) or numeric ID |

Paystack docs: <https://paystack.com/docs/api/transfer-recipient/#fetch>

### `update`

```ruby
transfer_recipients.update(id_or_code:, name: nil, email: nil)
```

Update Transfer Recipient.

Update the details of a transfer recipient

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The recipient code (RCP_...) or numeric ID |
| `name` | String |  | Recipient's name |
| `email` | String |  | Recipient's email address |

Paystack docs: <https://paystack.com/docs/api/transfer-recipient/#update>

### `delete`

```ruby
transfer_recipients.delete(id_or_code:)
```

Delete Transfer Recipient.

Delete a transfer recipient (sets the transfer recipient to inactive)

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The recipient code (RCP_...) or numeric ID |

Paystack docs: <https://paystack.com/docs/api/transfer-recipient/#delete>


