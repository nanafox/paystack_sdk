# Charges

Charge operations.

Use it as `client.charges`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `create`

```ruby
charges.create(
  email:,
  amount:,
  authorization_code: nil,
  pin: nil,
  reference: nil,
  birthday: nil,
  device_id: nil,
  metadata: nil,
  bank: nil,
  mobile_money: nil,
  ussd: nil,
  eft: nil,
  currency: nil,
  split_code: nil,
  subaccount: nil,
  bank_transfer: nil,
  qr: nil,
  capitec_pay: nil
)
```

Create Charge.

Initiate a payment by integrating the payment channel of your choice.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `amount` | Integer | yes | Amount should be in kobo if currency is NGN, pesewas, if currency is GHS, and cents, if currency is ZAR |
| `authorization_code` | String |  | An authorization code to charge. |
| `pin` | String |  | 4-digit PIN (send with a non-reusable authorization code) |
| `reference` | String |  | Unique transaction reference. |
| `birthday` | String |  | The customer's birthday in the format YYYY-MM-DD e.g 2017-05-16 |
| `device_id` | String |  | This is the unique identifier of the device a user uses in making payment. |
| `metadata` | Hash |  | JSON object of custom data |
| `bank` | Hash |  | The bank object if charging a bank account |
| `mobile_money` | Hash |  | Details of the mobile service provider |
| `ussd` | Hash |  | The USSD code for the provider to charge |
| `eft` | Hash |  | Details of the EFT provider |
| `currency` | String |  | The currency to charge in (GHS, KES and so on); Paystack uses your integration's currency when it is left out. |
| `split_code` | String |  | The split code (SPL_...) of a previously created split. |
| `subaccount` | String |  | The code (ACCT_...) of the subaccount that owns the payment. |
| `bank_transfer` | Hash |  | Settings for the Pay with Transfer and Pesalink channel (account_expires_at, the expiry time of the account). |
| `qr` | Hash |  | The QR provider details (provider, scan-to-pay being the only one); South Africa only. |
| `capitec_pay` | Hash |  | The Capitec Pay account holder (identifier_key, one of CELLPHONE, IDNUMBER or ACCOUNTNUMBER, and identifier_value); South Africa only. |

Paystack docs: <https://paystack.com/docs/api/charge/#create>

### `submit_pin`

```ruby
charges.submit_pin(pin:, reference:)
```

Submit PIN.

Submit PIN to continue a charge

| Parameter | Type | Required | Description |
|---|---|---|---|
| `pin` | String | yes | Customer's PIN for the ongoing transaction |
| `reference` | String | yes | Transaction reference that requires the PIN |

Paystack docs: <https://paystack.com/docs/api/charge/#submit-pin>

### `submit_otp`

```ruby
charges.submit_otp(otp:, reference:)
```

Submit OTP.

Submit OTP to complete a charge

| Parameter | Type | Required | Description |
|---|---|---|---|
| `otp` | String | yes | Customer's OTP for ongoing transaction |
| `reference` | String | yes | The reference of the ongoing transaction |

Paystack docs: <https://paystack.com/docs/api/charge/#submit-otp>

### `submit_phone`

```ruby
charges.submit_phone(phone:, reference:)
```

Submit Phone.

Submit phone number when requested

| Parameter | Type | Required | Description |
|---|---|---|---|
| `phone` | String | yes | Customer's mobile number |
| `reference` | String | yes | The reference of the ongoing transaction |

Paystack docs: <https://paystack.com/docs/api/charge/#submit-phone>

### `submit_birthday`

```ruby
charges.submit_birthday(birthday:, reference:)
```

Submit Birthday.

Submit the customer's birthday when requested

| Parameter | Type | Required | Description |
|---|---|---|---|
| `birthday` | String | yes | Customer's birthday in the format YYYY-MM-DD e.g 2016-09-21 |
| `reference` | String | yes | The reference of the ongoing transaction |

Paystack docs: <https://paystack.com/docs/api/charge/#submit-birthday>

### `submit_address`

```ruby
charges.submit_address(address:, city:, state:, zip_code:, reference:)
```

Submit Address.

Send the details of the customer's address for address verification

| Parameter | Type | Required | Description |
|---|---|---|---|
| `address` | String | yes | Customer's address |
| `city` | String | yes | Customer's city |
| `state` | String | yes | Customer's state |
| `zip_code` | String | yes | Customer's zipcode |
| `reference` | String | yes | The reference of the ongoing transaction |

Paystack docs: <https://paystack.com/docs/api/charge/#submit-address>

### `check_pending`

```ruby
charges.check_pending(reference:)
```

Check pending charge.

When you get `pending` as a charge status or if there was an exception when calling any of the `/charge` endpoints, wait 10 seconds or more, then make a check to see if its status has changed.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `reference` | String | yes | The reference of the ongoing transaction |

Paystack docs: <https://paystack.com/docs/api/charge/#check>

### `mobile_money`

```ruby
charges.mobile_money(email:, amount:, mobile_money:, currency: nil, reference: nil, metadata: nil)
```

Charges a mobile money wallet: a `#create` call with a checked `mobile_money` object.

Mobile money is available to businesses in Ghana, Kenya and Côte d'Ivoire. The charge usually
comes back with status `pay_offline` (the customer approves it on their phone; show them
`display_text` and wait for the `charge.success` webhook) or `send_otp` (collect the OTP and
call {#submit_otp}).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `amount` | Integer | yes | Amount in the subunit of the currency (pesewas, cents) |
| `mobile_money` | Hash | yes | The wallet to charge, with symbol or string keys: `phone` (the customer's number) or, for M-PESA Till (`mptill`), `account` (the till number), and `provider`, one of {MOBILE_MONEY_PROVIDERS} in any case (sent in lowercase). |
| `currency` | String, nil |  | 3-letter currency code, e.g. GHS or KES; Paystack uses your integration's currency when it is left out. |
| `reference` | String, nil |  | Unique transaction reference |
| `metadata` | Hash, nil |  | Custom data for your post-payment processes |

Paystack docs: <https://paystack.com/docs/payments/payment-channels/#mobile-money>

### `mobile_money`

```ruby
charges.mobile_money(email:, amount:, mobile_money:, currency: nil, reference: nil, metadata: nil)
```

Charges a mobile money wallet: a `#create` call with a checked `mobile_money` object.

Mobile money is available to businesses in Ghana, Kenya and Côte d'Ivoire. The charge usually
comes back with status `pay_offline` (the customer approves it on their phone; show them
`display_text` and wait for the `charge.success` webhook) or `send_otp` (collect the OTP and
call {#submit_otp}).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `email` | String | yes | Customer's email address |
| `amount` | Integer | yes | Amount in the subunit of the currency (pesewas, cents) |
| `mobile_money` | Hash | yes | The wallet to charge, with symbol or string keys: `phone` (the customer's number) or, for M-PESA Till (`mptill`), `account` (the till number), and `provider`, one of {MOBILE_MONEY_PROVIDERS} in any case (sent in lowercase). |
| `currency` | String, nil |  | 3-letter currency code, e.g. GHS or KES; Paystack uses your integration's currency when it is left out. |
| `reference` | String, nil |  | Unique transaction reference |
| `metadata` | Hash, nil |  | Custom data for your post-payment processes |

Paystack docs: <https://paystack.com/docs/payments/payment-channels/#mobile-money>


