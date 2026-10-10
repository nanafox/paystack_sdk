# Transactions

Transaction operations.

Use it as `client.transactions`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `initiate`

```ruby
transactions.initiate(
  email:,
  amount:,
  currency: nil,
  reference: nil,
  channels: nil,
  callback_url: nil,
  plan: nil,
  invoice_limit: nil,
  split_code: nil,
  split: nil,
  subaccount: nil,
  transaction_charge: nil,
  bearer: nil,
  label: nil,
  metadata: nil
)
```

Initialize Transaction.

Create a new transaction

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `amount` | Integer | yes | Amount should be in smallest denomination of the currency. |
| `currency` | String |  | List of all support currencies One of: GHS, KES, NGN, ZAR, USD. |
| `reference` | String |  | Unique transaction reference. |
| `channels` | Array |  | An array of payment channels to control what channels you want to make available to the user to make a payment with |
| `callback_url` | String |  | Fully qualified url, e.g. |
| `plan` | String |  | If transaction is to create a subscription to a predefined plan, provide plan code here. |
| `invoice_limit` | Integer |  | Number of times to charge customer during subscription to plan |
| `split_code` | String |  | The split code of the transaction split |
| `split` | Hash |  | Split configuration for transactions |
| `subaccount` | String |  | The code for the subaccount that owns the payment |
| `transaction_charge` | String |  | A flat fee to charge the subaccount for a transaction. |
| `bearer` | String |  | The bearer of the transaction charge One of: account, subaccount. |
| `label` | String |  | Used to replace the email address shown on the Checkout |
| `metadata` | String |  | Custom data as a JSON object (a Hash, or a JSON string). |

Paystack docs: <https://paystack.com/docs/api/transaction/#initialize>

### `charge_authorization`

```ruby
transactions.charge_authorization(
  email:,
  amount:,
  authorization_code:,
  reference: nil,
  currency: nil,
  split_code: nil,
  split: nil,
  subaccount: nil,
  transaction_charge: nil,
  bearer: nil,
  metadata: nil,
  queue: nil
)
```

Charge Authorization.

Charge all authorizations marked as reusable with this endpoint whenever you need to receive payments

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `amount` | Integer | yes | Amount in the lower denomination of your currency |
| `authorization_code` | String | yes | Valid authorization code to charge |
| `reference` | String |  | Unique transaction reference. |
| `currency` | String |  | List of all support currencies One of: GHS, KES, NGN, ZAR, USD. |
| `split_code` | String |  | The split code of the transaction split |
| `split` | Hash |  | Split configuration for transactions |
| `subaccount` | String |  | The code for the subaccount that owns the payment |
| `transaction_charge` | String |  | A flat fee to charge the subaccount for a transaction. |
| `bearer` | String |  | The bearer of the transaction charge One of: account, subaccount. |
| `metadata` | String |  | Stringified JSON object of custom data |
| `queue` | Boolean |  | If you are making a scheduled charge call, it is a good idea to queue them so the processing system does not get overloaded causing transaction processing errors. |

Paystack docs: <https://paystack.com/docs/api/transaction/#charge-authorization>

### `partial_debit`

```ruby
transactions.partial_debit(
  email:,
  amount:,
  authorization_code:,
  currency:,
  at_least: nil,
  reference: nil
)
```

Partial Debit.

Retrieve part of a payment from a customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `amount` | Integer | yes | Specified in the lowest denomination of your currency |
| `authorization_code` | String | yes | Valid authorization code to charge |
| `currency` | String | yes | List of all support currencies One of: GHS, KES, NGN, ZAR, USD. |
| `at_least` | String |  | Minimum amount to charge |
| `reference` | String |  | Unique transaction reference. |

Paystack docs: <https://paystack.com/docs/api/transaction/#partial-debit>

### `verify`

```ruby
transactions.verify(reference:)
```

Verify Transaction.

Verify a previously initiated transaction using it's reference

| Parameter | Type | Required | Description |
|---|---|---|---|
| `reference` | String | yes | The transaction reference to verify |

Paystack docs: <https://paystack.com/docs/api/transaction/#verify>

### `list`

```ruby
transactions.list(
  use_cursor: nil,
  next_cursor: nil,
  previous: nil,
  per_page: nil,
  page: nil,
  from: nil,
  to: nil,
  status: nil,
  source: nil,
  terminal_id: nil,
  virtual_account_number: nil,
  customer_id: nil,
  amount: nil,
  settlement: nil,
  channel: nil,
  subaccount_code: nil,
  split_code: nil
)
```

List Transactions.

List transactions that has occurred on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `use_cursor` | Boolean |  | A flag to indicate if cursor based pagination should be used |
| `next_cursor` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data |
| `previous` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data |
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |
| `from` | String |  | The start date |
| `to` | String |  | The end date |
| `status` | String |  | Filter transaction by status One of: success, failed, abandoned, reversed. |
| `source` | String |  | The origin of the payment One of: merchantApi, checkout, pos, virtualTerminal. |
| `terminal_id` | String |  | Filter transactions by a terminal ID |
| `virtual_account_number` | String |  | Filter transactions by a virtual account number |
| `customer_id` | Integer |  | Filter transactions by a customer code |
| `amount` | Integer |  | Filter transactions by a specific amount |
| `settlement` | Integer |  | The settlement ID to filter for settled transactions |
| `channel` | String |  | The payment method the customer used to complete the transaction One of: card, pos, bank, dedicated_nuban, ussd, bank_transfer. |
| `subaccount_code` | String |  | Filter transaction by subaccount code |
| `split_code` | String |  | Filter transaction by split code |

Paystack docs: <https://paystack.com/docs/api/transaction/#list>

### `fetch`

```ruby
transactions.fetch(id:)
```

Fetch Transaction.

Fetch a transaction to get its details

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The ID of the transaction to fetch |

Paystack docs: <https://paystack.com/docs/api/transaction/#fetch>

### `timeline`

```ruby
transactions.timeline(id:)
```

Fetch Transaction Timeline.

Fetch the steps taken from the initiation to the completion of a transaction

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The ID of the transaction to fetch |

Paystack docs: <https://paystack.com/docs/api/transaction/#view-timeline>

### `totals`

```ruby
transactions.totals(from: nil, to: nil)
```

Transaction Totals.

Get the total amount of all transactions

| Parameter | Type | Required | Description |
|---|---|---|---|
| `from` | String |  | The start date |
| `to` | String |  | The end date |

Paystack docs: <https://paystack.com/docs/api/transaction/#totals>

### `export`

```ruby
transactions.export(
  from: nil,
  to: nil,
  status: nil,
  customer_id: nil,
  subaccount_code: nil,
  settlement: nil,
  currency: nil,
  amount: nil,
  settled: nil,
  payment_page: nil
)
```

Export Transactions.

Download transactions that occurred on your integration for a specific timeframe

| Parameter | Type | Required | Description |
|---|---|---|---|
| `from` | String |  | The start date |
| `to` | String |  | The end date |
| `status` | String |  | Filter by the status of the transaction One of: success, failed, abandoned, reversed, all. |
| `customer_id` | Integer |  | Filter by customer ID |
| `subaccount_code` | String |  | Filter by subaccount code |
| `settlement` | Integer |  | Filter by the settlement ID |
| `currency` | String |  | Specify the transaction currency to export. |
| `amount` | Integer |  | Filter transactions by amount, using the supported currency subunit. |
| `settled` | Boolean |  | Set to true to export only settled transactions, false for pending transactions. |
| `payment_page` | Integer |  | Specify a payment page's id to export only transactions conducted on said page. |

Paystack docs: <https://paystack.com/docs/api/transaction/#export>


