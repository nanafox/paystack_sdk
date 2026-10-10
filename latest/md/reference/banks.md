# Banks

Bank operations.

Use it as `client.banks`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
banks.list(
  country: nil,
  currency: nil,
  use_cursor: nil,
  per_page: nil,
  page: nil,
  next_cursor: nil,
  previous: nil,
  pay_with_bank_transfer: nil,
  pay_with_bank: nil,
  enabled_for_verification: nil,
  gateway: nil,
  type: nil,
  include_nip_sort_code: nil
)
```

List Banks.

List banks supported on Paystack

| Parameter | Type | Required | Description |
|---|---|---|---|
| `country` | String |  | The country from which to obtain the list of supported banks One of: ghana, kenya, nigeria, south africa. |
| `currency` | String |  | The currency of the banks to list. One of: GHS, KES, NGN, ZAR, USD. |
| `use_cursor` | Boolean |  | A flag to indicate if cursor based pagination should be used |
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |
| `next_cursor` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data |
| `previous` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data |
| `pay_with_bank_transfer` | Boolean |  | A flag to filter for available banks a customer can make a transfer to complete a payment |
| `pay_with_bank` | Boolean |  | A flag to filter for banks a customer can pay directly from |
| `enabled_for_verification` | Boolean |  | A flag to filter the banks that are supported for account verification in South Africa. |
| `gateway` | String |  | The type of gateway for a Nigerian bank One of: emandate, digitalbankmandate. |
| `type` | String |  | Type of financial channel One of: ghipss, mobile_money, nuban, kepss, basa. |
| `include_nip_sort_code` | Boolean |  | A flag that returns Nigerian banks with their NIP institution code. |

Paystack docs: <https://paystack.com/docs/api/miscellaneous/#bank>

### `resolve_account_number`

```ruby
banks.resolve_account_number(account_number:, bank_code:)
```

Resolve Account Number.

Resolve an account number to confirm the name associated with it

| Parameter | Type | Required | Description |
|---|---|---|---|
| `account_number` | String | yes | The account number of interest |
| `bank_code` | String | yes | The bank code associated with the account number |

Paystack docs: <https://paystack.com/docs/api/verification/#resolve-account>

### `validate_account`

```ruby
banks.validate_account(
  account_name:,
  account_number:,
  account_type:,
  bank_code:,
  country_code:,
  document_type:,
  document_number: nil
)
```

Validate Bank Account.

Confirm the authenticity of a customer's account number before sending money

| Parameter | Type | Required | Description |
|---|---|---|---|
| `account_name` | String | yes | Customer's first and last name registered with their bank |
| `account_number` | String | yes | Customer's account number |
| `account_type` | String | yes | The type of the customer's account number One of: personal, business. |
| `bank_code` | String | yes | The bank code of the customer’s bank. |
| `country_code` | String | yes | The two digit ISO code of the customer’s bank |
| `document_type` | String | yes | Customer’s mode of identity One of: identityNumber, passportNumber, businessRegistrationNumber. |
| `document_number` | String |  | Customer’s mode of identity number |

Paystack docs: <https://paystack.com/docs/api/verification/#validate-account>


