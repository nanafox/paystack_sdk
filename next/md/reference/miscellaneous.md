# Miscellaneous

Miscellaneous operations.

Use it as `client.miscellaneous`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `resolve_card_bin`

```ruby
miscellaneous.resolve_card_bin(bin:)
```

Resolve Card BIN.

Get the details of a card BIN

| Parameter | Type | Required | Description |
|---|---|---|---|
| `bin` | String | yes | The card bank identification number |

Paystack docs: <https://paystack.com/docs/api/verification/#resolve-card>

### `list_countries`

```ruby
miscellaneous.list_countries
```

List Countries.

List all supported countries on Paystack

Paystack docs: <https://paystack.com/docs/api/miscellaneous/#country>

### `list_states`

```ruby
miscellaneous.list_states(country:)
```

List States (AVS).

Get a list of states for a country for address verification

| Parameter | Type | Required | Description |
|---|---|---|---|
| `country` | String | yes | The country code of the states to list. |

Paystack docs: <https://paystack.com/docs/api/miscellaneous/#avs-states>


