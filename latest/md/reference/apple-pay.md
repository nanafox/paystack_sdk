# Apple Pay

Apple Pay operations.

Use it as `client.apple_pay`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/latest/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list_domains`

```ruby
apple_pay.list_domains(use_cursor: nil, next_cursor: nil, previous: nil)
```

List Domains.

Lists all registered domains on your integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `use_cursor` | Boolean |  | A flag to indicate if cursor based pagination should be used |
| `next_cursor` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the next set of data |
| `previous` | String |  | An alphanumeric value returned for every cursor based retrieval, used to retrieve the previous set of data |

Paystack docs: <https://paystack.com/docs/api/apple-pay/#list-domains>

### `register_domain`

```ruby
apple_pay.register_domain(domain_name:)
```

Register Domain.

Register a top-level domain or subdomain for your Apple Pay integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `domain_name` | String | yes | The domain or subdomain for your application |

::: warning Note
Registers a domain for Apple Pay on the whole account. This changes Apple Pay configuration that may also affect live mode, even with a test key (sk_test_). Not verified against the live API by this SDK: do not call it to try the API out.
:::

Paystack docs: <https://paystack.com/docs/api/apple-pay/#register-domain>

### `unregister_domain`

```ruby
apple_pay.unregister_domain(domain_name:)
```

Unregister Domain.

Unregister a top-level domain or subdomain previously used for your Apple Pay integration.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `domain_name` | String | yes | The domain or subdomain for your application |

::: warning Note
Unregisters a domain from Apple Pay on the whole account. This changes Apple Pay configuration that may also affect live mode, even with a test key (sk_test_). Not verified against the live API by this SDK, including how Paystack reads the request body of a DELETE.
:::

Paystack docs: <https://paystack.com/docs/api/apple-pay/#unregister-domain>


