# Virtual Terminals

Virtual Terminal operations.

Use it as `client.virtual_terminals`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
virtual_terminals.list(per_page: nil, page: nil, status: nil)
```

List Virtual Terminals.

List Virtual Terminals on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `per_page` | Integer |  | The number of records to fetch per request |
| `page` | Integer |  | The offset to retrieve data from |
| `status` | String |  | Filter virtual terminals by status, active or inactive. |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#list>

### `create`

```ruby
virtual_terminals.create(name:, destinations:, split_code: nil, metadata: nil)
```

Create Virtual Terminal.

Create a Virtual Terminal on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | String | yes | The name of the virtual terminal |
| `destinations` | Array | yes | Array of objects containing recipients for payment notifications for the Virtual Terminal. |
| `split_code` | String |  | Split code to associate with the virtual terminal |
| `metadata` | Hash |  | Additional custom data as key-value pairs |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#create>

### `fetch`

```ruby
virtual_terminals.fetch(code:)
```

Fetch Virtual Terminal.

Fetch a Virtual Terminal on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Code of the Virtual Terminal |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#fetch>

### `update`

```ruby
virtual_terminals.update(code:, name:)
```

Update Virtual Terminal.

Update a Virtual Terminal on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Code of the Virtual Terminal |
| `name` | String | yes | Name of the virtual terminal |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#update>

### `deactivate`

```ruby
virtual_terminals.deactivate(code:)
```

Deactivate Virtual Terminal.

Deactivate a Virtual Terminal on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Code of the Virtual Terminal |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#deactivate>

### `assign_destination`

```ruby
virtual_terminals.assign_destination(code:, destinations:)
```

Assign Destination to Virtual Terminal.

Add a destination (WhatsApp number) to a Virtual Terminal on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Code of the Virtual Terminal |
| `destinations` | Array | yes | Array of objects containing recipients for payment notifications for the Virtual Terminal. |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#assign-destination>

### `unassign_destination`

```ruby
virtual_terminals.unassign_destination(code:, targets:)
```

Unassign Destination from Virtual Terminal.

Unassign a destination (WhatsApp Number) from a Virtual Terminal on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Code of the Virtual Terminal |
| `targets` | Array | yes | Array of destination targets to unassign |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#unassign-destination>

### `add_split_code`

```ruby
virtual_terminals.add_split_code(code:, split_code:)
```

Add Split Code to Virtual Terminal.

Add Split Code to Virtual Terminal

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Code of the Virtual Terminal |
| `split_code` | String | yes | The split code to assign to the virtual terminal |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#add-split-code>

### `remove_split_code`

```ruby
virtual_terminals.remove_split_code(code:, split_code:)
```

Remove Split Code from Virtual Terminal.

Remove Split Code from Virtual Terminal

| Parameter | Type | Required | Description |
|---|---|---|---|
| `code` | String | yes | Code of the Virtual Terminal |
| `split_code` | String | yes | The split code to assign to the virtual terminal |

Paystack docs: <https://paystack.com/docs/api/virtual-terminal/#remove-split-code>


