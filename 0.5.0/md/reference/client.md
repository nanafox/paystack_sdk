# Client

The `Client` class serves as the main entry point for interacting with the Paystack API.
It initializes a connection to the Paystack API and provides access to various resources.

## Creating a client

```ruby
PaystackSdk::Client.new(connection = nil, secret_key: nil, sandbox_only: false, **options)
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `connection` | Faraday::Connection, nil |  | The Faraday connection object used for API requests. If nil, a new connection will be created using the default API key. |
| `secret_key` | String, nil |  | Optional API key to use for creating a new connection. Only used if connection is nil. |
| `sandbox_only` | Boolean |  | Refuse to build a client unless the key is a test key (`sk_test_...`). Set this in staging and CI so they can never charge real money. |

## Methods

### `live?`

```ruby
client.live?
```

Whether this client is using a live key (`sk_live_...`), so requests move real money.
A test key, or a key in any other form, is not live.

**Returns** `Boolean`

## Resources

| Accessor | Page |
|---|---|
| `client.apple_pay` | [apple pay](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/apple-pay.md) |
| `client.balances` | [balances](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/balances.md) |
| `client.banks` | [banks](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/banks.md) |
| `client.bulk_charges` | [bulk charges](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/bulk-charges.md) |
| `client.charges` | [charges](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/charges.md) |
| `client.customers` | [customers](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/customers.md) |
| `client.dedicated_virtual_accounts` | [dedicated virtual accounts](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/dedicated-virtual-accounts.md) |
| `client.direct_debits` | [direct debits](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/direct-debits.md) |
| `client.disputes` | [disputes](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/disputes.md) |
| `client.integrations` | [integrations](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/integrations.md) |
| `client.miscellaneous` | [miscellaneous](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/miscellaneous.md) |
| `client.orders` | [orders](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/orders.md) |
| `client.pages` | [pages](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/pages.md) |
| `client.payment_requests` | [payment requests](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/payment-requests.md) |
| `client.plans` | [plans](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/plans.md) |
| `client.products` | [products](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/products.md) |
| `client.refunds` | [refunds](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/refunds.md) |
| `client.settlements` | [settlements](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/settlements.md) |
| `client.splits` | [splits](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/splits.md) |
| `client.storefronts` | [storefronts](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/storefronts.md) |
| `client.subaccounts` | [subaccounts](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/subaccounts.md) |
| `client.subscriptions` | [subscriptions](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/subscriptions.md) |
| `client.terminals` | [terminals](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/terminals.md) |
| `client.transactions` | [transactions](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/transactions.md) |
| `client.transfer_recipients` | [transfer recipients](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/transfer-recipients.md) |
| `client.transfers` | [transfers](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/transfers.md) |
| `client.virtual_terminals` | [virtual terminals](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/virtual-terminals.md) |
| `client.webhook_events` | [webhook events](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/webhook-events.md) |
