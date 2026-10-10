---
name: paystack-sdk-refunds
description: 'Use when code returns money to a customer for a Paystack payment with paystack_sdk (client.refunds): a full or partial refund, checking how much of a transaction is already refunded, reading a refund status (pending, processing, processed, failed, needs-attention), handling refund webhooks, recovering from a timeout on a refund request, or showing the payer what happened. Load it before writing any code that calls refunds.create.'
---

# Refunds (`client.refunds`)

A refund returns money from a successful transaction to the payer. It is **asynchronous**: `refunds.create` queues it, and the refund is `pending` until Paystack and the payer's bank or wallet provider finish. Treat "created" as "requested", never as "money returned". Basics (client, `Response`, errors) are in [[paystack-sdk-overview]]. Each claim below is marked **observed** (Paystack test API, 2026-10-09, `sk_test_` key), **documented** (Paystack docs, page named), or **design advice**.

## The calls

```ruby
# Full refund: leave amount out. `transaction:` takes the transaction reference or its numeric id.
client.refunds.create(transaction: "order-1042")

# Partial refund: amount in pesewas (integer), currency optional
client.refunds.create(
  transaction: "order-1042", amount: 200, currency: "GHS",
  customer_note: "Event cancelled", merchant_note: "Refund approved by treasurer, ticket 77"
)

client.refunds.fetch(id: 18_633_077)                  # one refund, by the refund id
client.refunds.list(transaction_id: 6_641_908_848)    # the refunds of one transaction: NUMERIC id
client.refunds.list(per_page: 20, page: 1, from: "2026-10-01", to: "2026-10-31")
```

Keywords: `create(transaction:, amount:, currency:, customer_note:, merchant_note:)`, `fetch(id:)`, `list(per_page:, page:, from:, to:, transaction_id:)`, `retry_with_customer_details(id:, refund_account_details:)`. `amount` must be a positive integer (the SDK checks before sending); `currency` must be one of GHS, KES, NGN, USD, ZAR.

## What was observed on the test API

| What I did | What came back |
|---|---|
| Refund by reference; refund by numeric id | Both accepted ("Refund has been queued for processing"). |
| `create` with a result | `data.status` is `pending`; `data.id` is the refund id; `data.amount`, `data.currency`; `refunded_by` was a short account name, not the email, so record your own requester. `customer_note`/`merchant_note` are echoed back; if you omit them Paystack fills them with "Refund for transaction <reference>" (and the account email in the merchant note). |
| Refund 50 pesewas of a 100-pesewa charge | **Rejected, HTTP 400: "The minimum amount you may send in a single refund at this time is: GHS1.00".** Over-refund of 60 gave the same minimum-amount message. After a full refund, 1 pesewa gave "Cannot refund less than GHS0.5". So a single refund below GHS 1.00 is refused in test mode (a limit "at this time"; check it for live). |
| 300-pesewa charge, refund 100 | Accepted, `pending`. |
| Then refund 250 (200 left), and `create` with `amount` omitted | **Both rejected: "Total refund amount cannot exceed original transaction amount".** With `amount` omitted Paystack asks for the whole original amount, not the remainder. After a partial refund, always pass the amount. |
| Then refund 100 (exactly part of the rest) | Accepted, `pending`. Two refunds on one transaction both appeared in `list(transaction_id:)`. |
| `currency: "USD"` on a GHS transaction | Rejected: "Transaction currency must match refund currency". |
| `list(transaction_id: <numeric id>)` | The transaction's refunds. Paystack answers a reference passed here with an empty list, not an error (observed on the test API), so the SDK refuses anything but a numeric ID (an Integer, or a string of digits) with `InvalidValueError` before sending. Find a refund by its transaction's numeric `data.id` from `verify`, not its reference. |
| `transactions.verify(reference:)` after a refund (full or partial) | `data.status` was `reversal-pending`, not `success`, so `paid?` returned `false`. A refunded payment no longer verifies as paid; do not re-verify an old payment and "un-grant" it because of that. |
| Refund status over the next minutes | Every refund stayed `pending` (`refunded_at` null). I did not see `processing`, `processed` or `failed`, nor `reversal-pending` change. |

Rejections are HTTP 400 and arrive as an unsuccessful `Response` (nothing raised): branch on `success?` and show `error_message` to staff.

## Statuses (documented, not observed beyond `pending`)

From Paystack's Refunds guide (docs.../payments/refunds) and the webhooks page:

| Refund `status` | Meaning (Paystack's words, shortened) | Webhook event |
|---|---|---|
| `pending` | Initiated, waiting for the processor | `refund.pending` |
| `processing` | Received by the processor | `refund.processing` |
| `processed` | Successfully processed. The guide adds that customers may still wait up to 10 business days for the funds | `refund.processed` |
| `failed` | Could not be processed; the guide says your account reflects the credited amount again | `refund.failed` |
| `needs-attention` | You must provide the customer's bank details | the guide names `refund.needs-attention`, which is in `PaystackSdk::Webhook::EVENTS` (it is named in the Refunds guide but not on Paystack's Webhooks page) |

## What to record and how to treat a refund (design advice)

Store a `Refund` row per request before calling Paystack: your own id, the payment's `reference` and Paystack transaction id, `amount` and `currency` (pesewas, integer), who requested and who approved it, `customer_note`/`merchant_note`, then after the call the Paystack refund `id` and `status`. Mark it `pending` until Paystack says `processed`. Reasons: a created refund can still fail (then the money stays with you), "processed" can still take days to reach the payer, and you can only tell the payer "refunded" once. Update the row from `refund.*` webhooks (verified with `Webhook.construct_event`; dedupe on event plus the refund id and status, there is no documented event id) and from `refunds.fetch(id:)`. Do not mark the member's payment as refunded in your ledger as final until `processed`. Keep the original payment record; a refund is its own record.

## Never retry a create blindly

A timed-out `refunds.create` may have queued a refund (the SDK does not retry writes after a timeout). A second blind call could refund twice. First look:

```ruby
# Returns the refunds Paystack already has for this payment (nil if the payment cannot be verified).
def refunds_for_payment(client, reference)
  txn = client.transactions.verify(reference: reference)
  return nil unless txn.success?

  client.refunds.list(transaction_id: txn.data.id).original_response["data"]
end

# Pesewas already refunded or on their way (failed refunds do not count).
def refunded_amount(rows)
  rows.reject { |row| row["status"] == "failed" }.sum { |row| row["amount"] }
end

# Safe to ask for `wanted` more pesewas?
def can_refund?(rows, payment_amount, wanted)
  wanted >= 100 && refunded_amount(rows) + wanted <= payment_amount
end
```

If a refund for that amount is listed, adopt its id; if the list is empty (with the numeric id), then create it. Persist your own refund row first so a crash leaves a trace. `wanted >= 100` is the GHS 1.00 minimum seen on the test API, not a documented number.

## Webhooks

`refund.pending`, `refund.processing`, `refund.processed` and `refund.failed` are in `PaystackSdk::Webhook::EVENTS` (listed on Paystack's webhooks page). The refund webhook payload shape is **not** in the docs I had, and I did not receive one: read the fields you need from the event, and when it matters call `refunds.fetch(id:)` instead of trusting the payload. Return 200 quickly; Paystack retries unacknowledged events (documented).

## Mobile money and bank transfer payments

Paystack's refunds guide says nothing about mobile money, minimum amounts, or how a refund reaches a wallet; its only account rule is the `needs-attention` flow where you supply a customer bank account. The channels page says a transfer that arrives with the wrong amount is refunded automatically. So for a mobile money or bank transfer payment, **not verified**: whether `refunds.create` works, how long it takes, and whether you will land in `needs-attention`. I only refunded card payments. Plan for a manual fallback (pay the member back yourself and record it).

## `retry_with_customer_details` (documented only; never called)

```ruby
client.refunds.retry_with_customer_details(
  id: refund_id,
  refund_account_details: {currency: "GHS", account_number: "0123456789", bank_id: "9"}
)
```

Per the docs, use it only for a refund in `needs-attention` (after the `refund.needs-attention` event), with any valid bank account of the customer; `bank_id` comes from `banks.list`, `account_number` is a string, and `currency` must be the payment's. I did not call it.

## Rules

- **Amounts are integer pesewas.** After any earlier refund on the transaction, pass `amount:` explicitly; omitting it asks for the full original amount and fails (observed).
- **Check `success?` on every refund call**; 400s do not raise.
- **A refund is pending until `processed`.** Do not tell the payer or finalise the books earlier.
- **After a timeout, list by the numeric transaction id before creating again.**
- **Only authorised staff may refund**; log who asked. Each refund moves real money in live mode.

## Not verified

Any status beyond `pending`; how long a test refund stays pending; refund webhook payloads; the live minimum refund; mobile money and bank transfer refunds; `retry_with_customer_details`; whether a failed or reversed refund returns the transaction to `success`.
