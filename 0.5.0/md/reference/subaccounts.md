# Subaccounts

Subaccount operations.

Use it as `client.subaccounts`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
subaccounts.list(per_page: nil, page: nil, active: nil)
```

List Subaccounts.

List subaccounts available on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | Number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |
| `active` | Integer |  | Filter by the state of the subaccounts |

Paystack docs: <https://paystack.com/docs/api/subaccount/#list>

### `create`

```ruby
subaccounts.create(
  business_name:,
  bank_code:,
  account_number:,
  percentage_charge:,
  description: nil,
  primary_contact_email: nil,
  primary_contact_name: nil,
  primary_contact_phone: nil,
  metadata: nil
)
```

Create Subaccount.

Create a subacount for a partner

| Parameter | Type | Required | Description |
|---|---|---|---|
| `business_name` | String | yes | Name of business for subaccount |
| `bank_code` | String | yes | Bank code for the bank, from the List Banks endpoint. |
| `account_number` | String | yes | Bank account number |
| `percentage_charge` | Numeric | yes | The percentage the main account receives from each payment made to the subaccount. |
| `description` | String |  | A description for this subaccount |
| `primary_contact_email` | String |  | A contact email for the subaccount |
| `primary_contact_name` | String |  | The name of the contact person for this subaccount |
| `primary_contact_phone` | String |  | A phone number to call for this subaccount |
| `metadata` | String |  | Stringified JSON object of custom data |

Paystack docs: <https://paystack.com/docs/api/subaccount/#create>

### `fetch`

```ruby
subaccounts.fetch(id_or_code:)
```

Fetch Subaccount.

Get details of a subaccount on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The subaccount code you want to fetch |

Paystack docs: <https://paystack.com/docs/api/subaccount/#fetch>

### `update`

```ruby
subaccounts.update(
  id_or_code:,
  business_name: nil,
  bank_code: nil,
  account_number: nil,
  active: nil,
  percentage_charge: nil,
  description: nil,
  primary_contact_email: nil,
  primary_contact_name: nil,
  primary_contact_phone: nil,
  metadata: nil
)
```

Update Subaccount.

Update a subaccount details on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id_or_code` | String | yes | The subaccount code you want to fetch |
| `business_name` | String |  | Name of business for subaccount |
| `bank_code` | String |  | Bank code for the bank, from the List Banks endpoint. |
| `account_number` | String |  | Bank account number |
| `active` | Boolean |  | Activate or deactivate a subaccount |
| `percentage_charge` | Numeric |  | The default percentage charged when receiving on behalf of this subaccount. |
| `description` | String |  | A description for this subaccount |
| `primary_contact_email` | String |  | A contact email for the subaccount |
| `primary_contact_name` | String |  | The name of the contact person for this subaccount |
| `primary_contact_phone` | String |  | A phone number to call for this subaccount |
| `metadata` | String |  | Stringified JSON object of custom data |

Paystack docs: <https://paystack.com/docs/api/subaccount/#update>


