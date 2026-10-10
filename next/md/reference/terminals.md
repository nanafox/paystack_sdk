# Terminals

Terminal operations.

Use it as `client.terminals`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/next/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `send_event`

```ruby
terminals.send_event(terminal_id:, type: nil, action: nil, data: nil)
```

Send Event.

Send an event from your application to the Paystack Terminal

| Parameter | Type | Required | Description |
|---|---|---|---|
| `terminal_id` | String | yes | The ID of the Terminal the event should be sent to. |
| `type` | String |  | The type of event to push One of: invoice, transaction. |
| `action` | String |  | The action the Terminal needs to perform. One of: process, view, print. |
| `data` | Hash |  | The parameters needed to perform the specified action |

::: warning Note
This pushes the event to a physical Paystack Terminal. Not verified against the Paystack API: the test account used to build this SDK has no Terminal access.
:::

Paystack docs: <https://paystack.com/docs/api/terminal/#send-event>

### `fetch_event_status`

```ruby
terminals.fetch_event_status(terminal_id:, event_id:)
```

Fetch Event Status.

Check the status of an event sent to the Terminal

| Parameter | Type | Required | Description |
|---|---|---|---|
| `terminal_id` | String | yes | The ID of the Terminal the event should be sent to. |
| `event_id` | String | yes | The ID of the event that was sent to the Terminal |

Paystack docs: <https://paystack.com/docs/api/terminal/#fetch-event-status>

### `fetch_status`

```ruby
terminals.fetch_status(terminal_id:)
```

Fetch Terminal Status.

Check the availiability of a Terminal before sending an event to it

| Parameter | Type | Required | Description |
|---|---|---|---|
| `terminal_id` | String | yes | The ID of the Terminal the event should be sent to. |

Paystack docs: <https://paystack.com/docs/api/terminal/#fetch-terminal-status>

### `list`

```ruby
terminals.list(next_cursor: nil, previous: nil, per_page: nil)
```

List Terminals.

List the Terminals available on your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `next_cursor` | String |  | A cursor that indicates your place in the list. |
| `previous` | String |  | A cursor that indicates your place in the list. |
| `per_page` | Integer |  | Specify how many records you want to retrieve per page |

Paystack docs: <https://paystack.com/docs/api/terminal/#list>

### `fetch`

```ruby
terminals.fetch(terminal_id:)
```

Fetch Terminal.

Get the details of a Terminal

| Parameter | Type | Required | Description |
|---|---|---|---|
| `terminal_id` | String | yes | The ID of the Terminal the event should be sent to. |

Paystack docs: <https://paystack.com/docs/api/terminal/#fetch>

### `update`

```ruby
terminals.update(terminal_id:, name: nil, address: nil)
```

Update Terminal.

Update the details of a Terminal

| Parameter | Type | Required | Description |
|---|---|---|---|
| `terminal_id` | String | yes | The ID of the Terminal the event should be sent to. |
| `name` | String |  | The new name for the Terminal |
| `address` | String |  | The new address for the Terminal |

Paystack docs: <https://paystack.com/docs/api/terminal/#update>

### `commission`

```ruby
terminals.commission(serial_number:)
```

Commission Terminal.

Activate your debug device by linking it to your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `serial_number` | String | yes | Device Serial Number |

::: warning Note
This links a physical device to your integration. Not verified against the Paystack API: the test account used to build this SDK has no Terminal access.
:::

Paystack docs: <https://paystack.com/docs/api/terminal/#commission>

### `decommission`

```ruby
terminals.decommission(serial_number:)
```

Decommission Terminal.

Unlink your debug device from your integration

| Parameter | Type | Required | Description |
|---|---|---|---|
| `serial_number` | String | yes | Device Serial Number |

::: warning Note
This unlinks a physical device from your integration. Not verified against the Paystack API: the test account used to build this SDK has no Terminal access.
:::

Paystack docs: <https://paystack.com/docs/api/terminal/#decommission>


