# Direct Debits

Direct Debit operations.

Use it as `client.direct_debits`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `trigger_activation_charge`

```ruby
direct_debits.trigger_activation_charge(customer_ids:)
```

Trigger Activation Charge.

Trigger activation charge for specified customers

| Parameter | Type | Required | Description |
|---|---|---|---|
| `customer_ids` | Array | yes | Array of customer IDs to trigger activation charge for |

::: warning Note
Charges the bank accounts behind the given customers' pending mandates to activate them; in live mode this moves real money. It was not called against the test API while this method was built, so its behaviour is documented, not verified. For one customer's inactive mandate, `customers.direct_debit_activation_charge` takes an `authorization_id` instead.
:::

Paystack docs: <https://paystack.com/docs/api/directdebit/#activation-charge>

### `list_mandate_authorizations`

```ruby
direct_debits.list_mandate_authorizations(cursor: nil, status: nil, per_page: nil)
```

List Mandate Authorizations.

Get a list of all the direct debit mandates on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `cursor` | String |  | The cursor value of the next set of authorizations to fetch. |
| `status` | String |  | Filter by the authorization status One of: pending, active, revoked. |
| `per_page` | Integer |  | The number of authorizations to fetch per request |

Paystack docs: <https://paystack.com/docs/api/directdebit/#mandate-authorizations>


