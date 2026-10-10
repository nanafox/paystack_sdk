# Balances

Balance operations.

Use it as `client.balances`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `fetch`

```ruby
balances.fetch
```

Fetch Balance.

Fetch the available balance on your integration

Paystack docs: <https://paystack.com/docs/api/transfer-control/#balance>

### `ledger`

```ruby
balances.ledger(per_page: nil, page: nil, from: nil, to: nil)
```

Balance Ledger.

Fetch all pay-ins and pay-outs that occured on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/transfer-control/#balance-ledger>


