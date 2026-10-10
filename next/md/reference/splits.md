# Splits

Split operations.

Use it as `client.splits`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
splits.list(
  subaccount_code: nil,
  name: nil,
  active: nil,
  per_page: nil,
  page: nil,
  from: nil,
  to: nil
)
```

List Splits.

List the transaction splits available on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `subaccount_code` | String |  | Filter by subaccount code |
| `name` | String |  | The name of the split |
| `active` | Boolean |  | The status of the split |
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/split/#list>

### `create`

```ruby
splits.create(name:, type:, subaccounts:, currency:, bearer_type: nil, bearer_subaccount: nil)
```

Create Split.

Create a split configuration for transactions

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | String | yes | Name of the transaction split |
| `type` | String | yes | The type of transaction split you want to create. One of: percentage, flat. |
| `subaccounts` | Array | yes | A list of object containing subaccount code and number of shares |
| `currency` | String | yes | The transaction currency One of: NGN, GHS, ZAR, USD. |
| `bearer_type` | String |  | This allows you specify how the transaction charge should be processed One of: subaccount, account, all-proportional, all. |
| `bearer_subaccount` | String |  | This is the subaccount code of the customer or partner that would bear the transaction charge if you specified subaccount as the bearer type |

Paystack docs: <https://paystack.com/docs/api/split/#create>

### `fetch`

```ruby
splits.fetch(id:)
```

Fetch Split.

Get details of a split configuration for a transaction

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | String | yes | The ID of the split configuration to fetch |

Paystack docs: <https://paystack.com/docs/api/split/#fetch>

### `update`

```ruby
splits.update(id:, name: nil, active: nil, bearer_type: nil, bearer_subaccount: nil)
```

Update Split.

Update a split configuration for transactions

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | String | yes |  |
| `name` | String |  | Name of the transaction split |
| `active` | Boolean |  | Toggle status of split. |
| `bearer_type` | String |  | This allows you specify how the transaction charge should be processed One of: subaccount, account, all-proportional, all. |
| `bearer_subaccount` | String |  | This is the subaccount code of the customer or partner that would bear the transaction charge if you specified subaccount as the bearer type |

Paystack docs: <https://paystack.com/docs/api/split/#update>

### `add_subaccount`

```ruby
splits.add_subaccount(id:, subaccount:, share:)
```

Add Subaccount to Split.

Add a subaccount to a split configuration, or update the share of an existing subaccount

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The ID of the split configuration to fetch |
| `subaccount` | String | yes | Subaccount code of the customer or partner |
| `share` | Integer | yes | The percentage or flat quota of the customer or partner |

Paystack docs: <https://paystack.com/docs/api/split/#add-subaccount>

### `remove_subaccount`

```ruby
splits.remove_subaccount(id:, subaccount:, share: nil)
```

Remove Subaccount from split.

Remove a subaccount from a split configuration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The ID of the split configuration to fetch |
| `subaccount` | String | yes | Subaccount code of the customer or partner |
| `share` | Integer |  | Not used when removing a subaccount; the docs do not list it, and Paystack removes the subaccount whatever share is sent. |

Paystack docs: <https://paystack.com/docs/api/split/#remove-subaccount>


