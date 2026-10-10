# Transfers

Transfer operations: send money from your balance to transfer recipients, and manage the OTP
requirement that guards them.

Use it as `client.transfers`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
transfers.list(
  use_cursor: nil,
  next_cursor: nil,
  previous: nil,
  per_page: nil,
  page: nil,
  from: nil,
  to: nil,
  recipient: nil,
  status: nil
)
```

List Transfers.

List the transfers made on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `use_cursor` | Boolean |  | Set to true to use cursor-based pagination (the response meta then carries `next` and `previous`) |
| `next_cursor` | String |  | The `next` cursor from a previous cursor-based response |
| `previous` | String |  | The `previous` cursor from a previous cursor-based response |
| `per_page` | Integer |  | How many records to retrieve per page (Paystack defaults to 50) |
| `page` | Integer |  | The page to retrieve (Paystack defaults to 1) |
| `from` | String, Date, Time |  | A timestamp from which to start listing transfers |
| `to` | String, Date, Time |  | A timestamp at which to stop listing transfers |
| `recipient` | Integer |  | Filter by the recipient ID |
| `status` | String |  | Filter by status. One of: pending, success, failed, otp, abandoned, reversed, blocked, rejected, received. |

Paystack docs: <https://paystack.com/docs/api/transfer/#list>

### `create`

```ruby
transfers.create(amount:, recipient:, reference:, source:, reason: nil, currency: nil)
```

Initiate Transfer.

Send money to your customers. The transfer's status is `pending` when the OTP requirement is
disabled, and `otp` when an OTP is required (complete it with `#finalize`).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `amount` | Integer | yes | Amount to transfer in the currency's subunit (kobo for NGN, pesewas for GHS) |
| `recipient` | String | yes | Code for the transfer recipient (RCP_...) |
| `reference` | String | yes | A unique identifier for the transfer, so retrying it cannot create a second transfer. Paystack documents 16 to 50 characters of lowercase letters, digits, `-` and `_`. |
| `source` | String | yes | Where to transfer from. Only "balance" for now. |
| `reason` | String |  | The reason for the transfer; it also shows up in the narration of the recipient's credit notification |
| `currency` | String |  | The currency of the transfer; Paystack defaults to NGN. One of: NGN, ZAR, KES, GHS. |

Paystack docs: <https://paystack.com/docs/api/transfer/#initiate>

### `finalize`

```ruby
transfers.finalize(transfer_code:, otp:)
```

Finalize Transfer.

Finalize an initiated transfer that is waiting for an OTP.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `transfer_code` | String | yes | The transfer code you want to finalize |
| `otp` | String | yes | OTP sent to the business phone to verify the transfer |

Paystack docs: <https://paystack.com/docs/api/transfer/#finalize>

### `bulk_create`

```ruby
transfers.bulk_create(source:, transfers:, currency: nil)
```

Initiate Bulk Transfer.

Batch multiple transfers in a single request. You need to disable the Transfers OTP
requirement to use this endpoint.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `source` | String | yes | Where to transfer from. Only "balance" for now. |
| `transfers` | Array&lt;Hash> | yes | The transfers, each with `amount`, `recipient`, `reference` and optionally `reason`, named as Paystack names them |
| `currency` | String |  | The currency of the transfers. One of: NGN, ZAR, KES, GHS. |

Paystack docs: <https://paystack.com/docs/api/transfer/#bulk>

### `fetch`

```ruby
transfers.fetch(id_or_code:)
```

Fetch Transfer.

Get details of a transfer on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String, Integer | yes | The transfer ID or code you want to fetch |

Paystack docs: <https://paystack.com/docs/api/transfer/#fetch>

### `verify`

```ruby
transfers.verify(reference:)
```

Verify Transfer.

Verify the status of a transfer on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `reference` | String | yes | Transfer reference |

Paystack docs: <https://paystack.com/docs/api/transfer/#verify>

### `export`

```ruby
transfers.export(recipient: nil, status: nil, from: nil, to: nil)
```

Export Transfers.

Export a list of transfers carried out on your integration. This operation is in Paystack's
OpenAPI spec but not on its docs page; the API answers it (404 "Transfers not found" when
nothing matches).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `recipient` | String |  | Export transfers by the recipient code |
| `status` | String |  | Export transfers by status. One of: pending, success, failed, otp, abandoned, reversed, blocked, rejected, received. |
| `from` | String, Date, Time |  | The start date |
| `to` | String, Date, Time |  | The end date |

Paystack docs: <https://paystack.com/docs/api/transfer/>

### `resend_otp`

```ruby
transfers.resend_otp(transfer_code:, reason:)
```

Resend OTP for Transfer.

Generates a new OTP and sends it to the business phone, for when it has trouble receiving one.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `transfer_code` | String | yes | The transfer code that requires an OTP validation |
| `reason` | String | yes | The purpose of the OTP. The docs list "resend_otp" and "transfer"; the spec also allows "disable_otp". |

Paystack docs: <https://paystack.com/docs/api/transfer-control/#resend-otp>

### `disable_otp`

```ruby
transfers.disable_otp
```

Disable OTP for Transfers.

Start turning off the OTP requirement so transfers can be completed programmatically.
Paystack sends an OTP to the business phone; confirm with {#finalize_disable_otp}.

**Raises** `PaystackSdk::Error` If the API request fails.

Paystack docs: <https://paystack.com/docs/api/transfer-control/#disable-otp>

### `finalize_disable_otp`

```ruby
transfers.finalize_disable_otp(otp:)
```

Finalize Disabling OTP for Transfers.

Finalize the request to disable OTP on your transfers.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `otp` | String | yes | OTP sent to the business phone to verify disabling the OTP requirement |

Paystack docs: <https://paystack.com/docs/api/transfer-control/#finalize-disable-otp>

### `enable_otp`

```ruby
transfers.enable_otp
```

Enable OTP requirement for Transfers.

Turn the OTP requirement for transfers back on.

**Raises** `PaystackSdk::Error` If the API request fails.

Paystack docs: <https://paystack.com/docs/api/transfer-control/#enable-otp>


