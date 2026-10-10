# Subscriptions

Subscription operations.

Use it as `client.subscriptions`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
subscriptions.list(per_page: nil, page: nil, plan_id: nil, customer_id: nil, from: nil, to: nil)
```

List Subscriptions.

List all subscriptions available on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `plan_id` | Integer |  | Plan ID |
| `customer_id` | Integer |  | Customer ID |
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/subscription/#list>

### `create`

```ruby
subscriptions.create(customer:, plan:, authorization: nil, start_date: nil)
```

Create Subscription.

Create a subscription a customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `customer` | String | yes | Customer's email address or customer code |
| `plan` | String | yes | Plan code |
| `authorization` | String |  | If customer has multiple authorizations, you can set the desired authorization you wish to use for this subscription here. |
| `start_date` | String |  | Set the date for the first debit. |

Paystack docs: <https://paystack.com/docs/api/subscription/#create>

### `fetch`

```ruby
subscriptions.fetch(id_or_code:)
```

Fetch Subscription.

Get details of a customer's subscription

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The subscription code for the subscription you want to fetch |

Paystack docs: <https://paystack.com/docs/api/subscription/#fetch>

### `disable`

```ruby
subscriptions.disable(code:, token:)
```

Disable Subscription.

Disable a subscription on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Subscription code |
| `token` | String | yes | Email token |

Paystack docs: <https://paystack.com/docs/api/subscription/#disable>

### `enable`

```ruby
subscriptions.enable(code:, token:)
```

Enable Subscription.

Enable a subscription on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Subscription code |
| `token` | String | yes | Email token |

Paystack docs: <https://paystack.com/docs/api/subscription/#enable>

### `generate_update_link`

```ruby
subscriptions.generate_update_link(code:)
```

Generate Update Subscription Link.

Generate a link for updating the card on a subscription

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Subscription code |

Paystack docs: <https://paystack.com/docs/api/subscription/#manage-link>

### `send_update_link`

```ruby
subscriptions.send_update_link(code:)
```

Send Update Subscription Link.

Email a customer a link for updating the card on their subscription

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Subscription code |

Paystack docs: <https://paystack.com/docs/api/subscription/#manage-email>


