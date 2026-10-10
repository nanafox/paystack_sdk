# Dedicated Virtual Accounts

Dedicated Virtual Account operations.

Use it as `client.dedicated_virtual_accounts`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
dedicated_virtual_accounts.list(
  active: nil,
  customer: nil,
  currency: nil,
  provider_slug: nil,
  bank_id: nil,
  per_page: nil,
  page: nil
)
```

List Dedicated Accounts.

List dedicated virtual accounts available on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `active` | Boolean |  | Status of the dedicated virtual account |
| `customer` | Integer |  | The customer's ID |
| `currency` | String |  | The currency of the dedicated virtual account One of: NGN, GHS. |
| `provider_slug` | String |  | The bank's slug in lowercase, without spaces |
| `bank_id` | String |  | The bank's ID |
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#list>

### `create`

```ruby
dedicated_virtual_accounts.create(customer:, preferred_bank: nil, subaccount: nil, split_code: nil)
```

Create Dedicated Account.

Create a dedicated virtual account for an existing customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `customer` | String | yes | The code for the previously created customer |
| `preferred_bank` | String |  | The bank slug for preferred bank. |
| `subaccount` | String |  | Subaccount code of the account you want to split the transaction with |
| `split_code` | String |  | Split code consisting of the lists of accounts you want to split the transaction with |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#create>

### `assign`

```ruby
dedicated_virtual_accounts.assign(
  email:,
  first_name:,
  last_name:,
  phone:,
  preferred_bank:,
  country:,
  account_number: nil,
  bvn: nil,
  bank_code: nil,
  subaccount: nil,
  split_code: nil
)
```

Assign Dedicated Account.

With this endpoint, you can create a customer, validate the customer, and assign a DVA to the customer.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `first_name` | String | yes | Customer's first name |
| `last_name` | String | yes | Customer's last name |
| `phone` | String | yes | Customer's phone name |
| `preferred_bank` | String | yes | The bank slug for preferred bank. |
| `country` | String | yes | The two letter code country One of: NG, GH. |
| `account_number` | String |  | Customer's account number |
| `bvn` | String |  | Customer's Bank Verification Number |
| `bank_code` | String |  | Customer's bank code |
| `subaccount` | String |  | Subaccount code of the account you want to split the transaction with |
| `split_code` | String |  | Split code consisting of the lists of accounts you want to split the transaction with |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#assign>

### `fetch`

```ruby
dedicated_virtual_accounts.fetch(dedicated_account_id:)
```

Fetch Dedicated Account.

Get details of a dedicated virtual account on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `dedicated_account_id` | String | yes | ID of dedicated virtual account |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#fetch>

### `deactivate`

```ruby
dedicated_virtual_accounts.deactivate(dedicated_account_id:)
```

Deactivate Dedicated Account.

Deactivate a dedicated virtual account on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `dedicated_account_id` | String | yes | ID of dedicated virtual account |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#deactivate>

### `requery`

```ruby
dedicated_virtual_accounts.requery(account_number: nil, provider_slug: nil, date: nil)
```

Requery Dedicated Account.

Requery Dedicated Virtual Account for new transactions

| Parameter | Type | Required | Description |
|---|---|---|---|
| `account_number` | String |  | Virtual account number to requery |
| `provider_slug` | String |  | The bank's slug in lowercase, without spaces. |
| `date` | String |  | The day the transfer was made |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#requery>

### `add_split`

```ruby
dedicated_virtual_accounts.add_split(account_number:, subaccount: nil, split_code: nil)
```

Split Dedicated Account Transaction.

Split a dedicated virtual account transaction with one or more accounts

| Parameter | Type | Required | Description |
|---|---|---|---|
| `account_number` | String | yes | Valid Dedicated virtual account |
| `subaccount` | String |  | Subaccount code of the account you want to split the transaction with |
| `split_code` | String |  | Split code consisting of the lists of accounts you want to split the transaction with |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#add-split>

### `remove_split`

```ruby
dedicated_virtual_accounts.remove_split(account_number:)
```

Remove Split from Dedicated Account.

If you've previously set up split payment for transactions on a dedicated virtual account, you can remove it with this endpoint

| Parameter | Type | Required | Description |
|---|---|---|---|
| `account_number` | String | yes | Valid Dedicated virtual account |

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#remove-split>

### `fetch_bank_providers`

```ruby
dedicated_virtual_accounts.fetch_bank_providers
```

Fetch Bank Providers.

Get available bank providers for a dedicated virtual account

Paystack docs: <https://paystack.com/docs/api/dedicated-virtual-account/#providers>


