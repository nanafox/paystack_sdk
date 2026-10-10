# Webhook Events

Webhook Events API: the log of webhooks Paystack has sent to your integration's webhook URL, with their
delivery status, the payload that was sent and what your endpoint answered, and a way to send them
again. Use it to find out whether a webhook was delivered, to see exactly what Paystack sent, and to
recover events your endpoint missed.

`list`, `lookup` and `fetch` only read. `resend` and `resend_matching` make Paystack deliver webhooks
to your endpoint again, and have **not** been called against the Paystack test API.

Use it as `client.webhook_events`. Every method takes keyword arguments, returns a [`PaystackSdk::Response`](https://nanafox.github.io/paystack_sdk/0.5.0/md/reference/response.md), and raises a `PaystackSdk::Error` if a parameter is invalid before anything is sent. An unsuccessful result from Paystack (a 400 or 404) comes back as a Response with `success?` false.

## Methods

### `list`

```ruby
webhook_events.list(
  category: nil,
  event_type: nil,
  status: nil,
  category_row_id: nil,
  from: nil,
  to: nil,
  limit: nil,
  next_cursor: nil,
  previous: nil
)
```

List Events.

Fetches a page of the webhook events sent to your integration, newest first. The response `meta` holds
`next` and `previous` cursors: pass `meta.next` back as `next_cursor:` for the next page.

Observed on the Paystack test API (2026-10-09), where the docs differ: a page holds 50 events by
default (the docs say 20), `limit` is capped at 50, and a `limit` that is not a number is ignored.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `category` | String |  | Filter by category, for example "transactions" or "refund". |
| `event_type` | String |  | Filter by event name, for example "charge.success". |
| `status` | String |  | Filter by delivery status: Delivered, Pending or Failed. |
| `category_row_id` | String, Integer |  | Filter by the ID of the resource the event is about, such as a transaction ID. |
| `from` | String, Time, Date |  | Only events from this time on, for example 2016-09-24T00:00:05.000Z or 2016-09-21. |
| `to` | String, Time, Date |  | Only events up to this time. |
| `limit` | Integer |  | How many events to return per page. |
| `next_cursor` | String |  | The `meta.next` cursor of a previous response (sent as `next`). Not together with `previous`. |
| `previous` | String |  | The `meta.previous` cursor of a previous response. Not together with `next_cursor`. |

Paystack docs: <https://paystack.com/docs/api/webhook-events/#list>

### `lookup`

```ruby
webhook_events.lookup(id:)
```

Look Up an Event.

Finds a webhook event by its own ID, or by the ID of the resource it is about (a transaction ID, not
the transaction's reference). Observed on the test API: an event's `_id` and a `category_row_id`
both match; a value that matches nothing is a 404 "Webhook not found" (an unsuccessful Response).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | String, Integer | yes | An event `_id`, or the ID of the resource it is about. Sent as `reference`, the name Paystack's docs give it, although it is not a reference. |

Paystack docs: <https://paystack.com/docs/api/webhook-events/#lookup>

### `fetch`

```ruby
webhook_events.fetch(id:)
```

Fetch Event.

Gets one event in full: `event_payload` (the body Paystack sent), `webhook_url`, `status`,
`status_detail`, `response_code`, `merchant_response_body` (what your endpoint answered), `trial_count`
and `trials`. Observed on the test API, where `event_payload` is a Hash with the keys `event` and
`data`. Read the payload's own `data` with brackets, `response.event_payload[:data]`: dot access
`event_payload.data` returns the Response itself, because `Response#data` is a method.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | String | yes | The event's `_id`, from an item of `#list`. |

Paystack docs: <https://paystack.com/docs/api/webhook-events/#fetch>

### `resend`

```ruby
webhook_events.resend(ids:)
```

Resend Events.

Asks Paystack to deliver a specific set of events to your current webhook URL again.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `ids` | Array&lt;String> | yes | The `_id`s of the events to resend: not empty, at most 100. |

::: warning Note
This makes Paystack send webhooks to your endpoint. The docs say resending is not idempotent: sending the same event ID twice delivers it twice, so your endpoint must dedupe. It has not been called against the Paystack test API; the method follows the docs.
:::

Paystack docs: <https://paystack.com/docs/api/webhook-events/#resend>

### `resend_matching`

```ruby
webhook_events.resend_matching(preview:, filters: nil)
```

Resend Matching Events.

Asks Paystack to deliver every event that matches the filters to your current webhook URL again.
With `preview: true` it only counts the matching events.

`preview:` has no default here, although the docs make it optional: with no filters this resends
every event, so you have to say which you mean. Call it with `preview: true` first.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `preview` | Boolean | yes | true to return the matching count without resending anything; false to resend. |
| `filters` | Hash, nil |  | Any of the `#list` filters: category, event_type, status, category_row_id, from, to. |

::: warning Note
This can make Paystack send a lot of webhooks to your endpoint, which must dedupe. It has not been called against the Paystack test API, including with `preview: true`; the method follows the docs.
:::

Paystack docs: <https://paystack.com/docs/api/webhook-events/#resend-matching>


