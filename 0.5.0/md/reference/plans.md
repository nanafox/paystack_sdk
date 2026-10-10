# Plans

Plan operations.

Use it as `client.plans`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
plans.list(per_page: nil, page: nil, interval: nil, amount: nil, from: nil, to: nil, status: nil)
```

List Plans.

List all recurring payment plans

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per page |
| `page` | Integer |  | The section to retrieve |
| `interval` | String |  | Specify interval of the plan One of: hourly, daily, weekly, monthly, quarterly, biannually, annually. |
| `amount` | Integer |  | The amount on the plans to retrieve |
| `from` | String |  | The start date |
| `to` | String |  | The end date |
| `status` | String |  | Filter list by plans with specified status. |

Paystack docs: <https://paystack.com/docs/api/plan/#list>

### `create`

```ruby
plans.create(
  name:,
  amount:,
  interval:,
  description: nil,
  send_invoices: nil,
  send_sms: nil,
  currency: nil,
  invoice_limit: nil
)
```

Create Plan.

Create a plan for recurring payments

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | String | yes | Name of plan |
| `amount` | Integer | yes | Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR |
| `interval` | String | yes | Payment interval One of: hourly, daily, weekly, monthly, quarterly, biannually, annually. |
| `description` | String |  | A description for this plan |
| `send_invoices` | Boolean |  | Set to false if you don't want invoices to be sent to your customers |
| `send_sms` | Boolean |  | Set to false if you don't want text messages to be sent to your customers |
| `currency` | String |  | Currency in which amount is set. |
| `invoice_limit` | Integer |  | Number of invoices to raise during subscription to this plan. |

Paystack docs: <https://paystack.com/docs/api/plan/#create>

### `fetch`

```ruby
plans.fetch(id_or_code:)
```

Fetch Plan.

Get the details of a payment plan

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The plan code you want to fetch |

Paystack docs: <https://paystack.com/docs/api/plan/#fetch>

### `update`

```ruby
plans.update(
  id_or_code:,
  name: nil,
  amount: nil,
  interval: nil,
  description: nil,
  send_invoices: nil,
  send_sms: nil,
  currency: nil,
  invoice_limit: nil,
  update_existing_subscriptions: nil
)
```

Update Plan.

Update a plan details on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The plan code you want to fetch |
| `name` | String |  | Name of plan |
| `amount` | Integer |  | Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR |
| `interval` | String |  | Payment interval One of: hourly, daily, weekly, monthly, quarterly, biannually, annually. |
| `description` | String |  | A description for this plan |
| `send_invoices` | Boolean |  | Set to false if you don't want invoices to be sent to your customers |
| `send_sms` | Boolean |  | Set to false if you don't want text messages to be sent to your customers |
| `currency` | String |  | Currency in which amount is set. |
| `invoice_limit` | Integer |  | Number of invoices to raise during subscription to this plan. |
| `update_existing_subscriptions` | Boolean |  | Set to true if you want the existing subscriptions to use the new changes. |

Paystack docs: <https://paystack.com/docs/api/plan/#update>


