# Customers

Customer operations.

Use it as `client.customers`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
customers.list(
  use_cursor: nil,
  next_cursor: nil,
  previous: nil,
  from: nil,
  to: nil,
  per_page: nil,
  page: nil
)
```

List Customers.

List customers on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `use_cursor` | Boolean |  | A flag to indicate if cursor based pagination should be used |
| `next_cursor` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data |
| `previous` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data |
| `from` | String |  | The start date |
| `to` | String |  | The end date |
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |

Paystack docs: <https://paystack.com/docs/api/customer/#list>

### `create`

```ruby
customers.create(email:, first_name: nil, last_name: nil, phone: nil, metadata: nil)
```

Create Customer.

Create a customer on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `first_name` | String |  | Customer's first name |
| `last_name` | String |  | Customer's last name |
| `phone` | String |  | Customer's phone number |
| `metadata` | Hash |  | A set of key/value pairs that you can attach to the customer. |

Paystack docs: <https://paystack.com/docs/api/customer/#create>

### `fetch`

```ruby
customers.fetch(email_or_code:)
```

Fetch Customer.

Get details of a customer on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email_or_code` | String | yes | The code for the customer gotten from the response of the customer creation |

Paystack docs: <https://paystack.com/docs/api/customer/#fetch>

### `update`

```ruby
customers.update(code:, first_name: nil, last_name: nil, phone: nil, metadata: nil)
```

Update Customer.

Update a customer's details on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | The code for the customer gotten from the response of the customer creation |
| `first_name` | String |  | Customer's first name |
| `last_name` | String |  | Customer's last name |
| `phone` | String |  | Customer's phone number |
| `metadata` | Hash |  | A set of key/value pairs that you can attach to the customer. |

Paystack docs: <https://paystack.com/docs/api/customer/#update>

### `set_risk_action`

```ruby
customers.set_risk_action(customer:, risk_action: nil)
```

Set Risk Action.

Set customer's risk action by whitelisting or blacklisting the customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `customer` | String | yes | The customer code from the response of the customer creation |
| `risk_action` | String |  | This determines the fraud rules that should be applied to the customer One of: allow, deny, default. |

Paystack docs: <https://paystack.com/docs/api/customer/#whitelist-blacklist>

### `validate`

```ruby
customers.validate(
  code:,
  first_name:,
  last_name:,
  type:,
  country:,
  bvn:,
  bank_code:,
  account_number:,
  middle_name: nil,
  value: nil
)
```

Validate Customer.

Validate a customer's identity

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | The code for the customer gotten from the response of the customer creation |
| `first_name` | String | yes | Customer's first name |
| `last_name` | String | yes | Customer's last name |
| `type` | String | yes | Predefined types of identification. |
| `country` | String | yes | Two-letter country code of identification issuer |
| `bvn` | String | yes | Customer's Bank Verification Number |
| `bank_code` | String | yes | You can get the list of bank codes by calling the List Banks endpoint (https://api.paystack.co/bank). |
| `account_number` | String | yes | Customer's bank account number. |
| `middle_name` | String |  | Customer's middle name |
| `value` | String |  | Customer's identification number. |

Paystack docs: <https://paystack.com/docs/api/customer/#validate>

### `initialize_authorization`

```ruby
customers.initialize_authorization(email:, channel:, callback_url: nil, account: nil, address: nil)
```

Initialize Authorization.

Initiate a request to create a reusable authorization code for recurring transactions

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `channel` | String | yes | direct_debit is the only supported option for now One of: direct_debit. |
| `callback_url` | String |  | Fully qualified url (e.g. |
| `account` | Hash |  |  |
| `address` | Hash |  |  |

Paystack docs: <https://paystack.com/docs/api/customer/#initialize-authorization>

### `verify_authorization`

```ruby
customers.verify_authorization(reference:)
```

Verify Authorization.

Check the status of an authorization request

| Parameter | Type | Required | Description |
|---|---|---|---|
| `reference` | String | yes | The reference returned in the initialization response |

Paystack docs: <https://paystack.com/docs/api/customer/#verify-authorization>

### `deactivate_authorization`

```ruby
customers.deactivate_authorization(authorization_code:)
```

Deactivate Authorization.

Deactivate an authorization for any payment channel.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `authorization_code` | String | yes | Authorization code to be deactivated |

Paystack docs: <https://paystack.com/docs/api/customer/#deactivate-authorization>

### `initialize_direct_debit`

```ruby
customers.initialize_direct_debit(id:, account:, address:)
```

Initialize Direct Debit.

Initialize the process of linking an account to a customer for Direct Debit transactions

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The ID of the customer to initialize the direct debit for |
| `account` | Hash | yes |  |
| `address` | Hash | yes |  |

Paystack docs: <https://paystack.com/docs/api/customer/#initialize-direct-debit>

### `direct_debit_activation_charge`

```ruby
customers.direct_debit_activation_charge(id:, authorization_id:)
```

Direct Debit Activation Charge.

Trigger an activation charge on an inactive mandate on behalf of your customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The customer ID attached to the authorization |
| `authorization_id` | Integer | yes | The authorization ID gotten from the initiation response |

Paystack docs: <https://paystack.com/docs/api/customer/#directdebit-activation-charge>

### `fetch_mandate_authorizations`

```ruby
customers.fetch_mandate_authorizations(id:)
```

Fetch Mandate Authorizations.

Get the list of direct debit mandates associated with a customer

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | Integer | yes | The customer ID for the authorizations to fetch |

Paystack docs: <https://paystack.com/docs/api/customer/#directdebit-mandate-authorizations>


