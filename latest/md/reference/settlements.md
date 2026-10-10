# Settlements

Settlement operations.

Use it as `client.settlements`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
settlements.list(per_page: nil, page: nil, from: nil, to: nil)
```

List Settlements.

List settlements made to your settlement accounts

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |
| `from` | String |  | A timestamp from which to start listing settlements, for example 2016-09-24T00:00:05.000Z or 2016-09-21. |
| `to` | String |  | A timestamp at which to stop listing settlements, for example 2016-09-24T00:00:05.000Z or 2016-09-21. |

Paystack docs: <https://paystack.com/docs/api/settlement/#list>

### `transactions`

```ruby
settlements.transactions(id:)
```

Fetch Settlement Transactions.

Get the transactions that make up a particular settlement

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The settlement ID in which you want to fetch its transactions |

Paystack docs: <https://paystack.com/docs/api/settlement/#transactions>


