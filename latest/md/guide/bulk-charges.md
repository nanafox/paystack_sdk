# Bulk Charges

A bulk charge charges many saved cards (reusable authorizations) in one batch, which Paystack queues and processes in the background. Amounts are in the subunit (pesewas, kobo, cents).

## Initiate a Bulk Charge

```ruby
# The body is a JSON array: one Hash per charge, each with a reusable authorization code and an
# integer amount. Give each a reference you can find again: it becomes the charge's transaction
# reference (lowercase letters, digits, - and _, per the spec).
response = paystack.bulk_charges.initiate(
  charges: [
    {authorization: "AUTH_50w0d0f5xo", amount: 5000, reference: "tithe-2026-10-kwesi"},
    {authorization: "AUTH_xfuz7dy4b9", amount: 2000, reference: "tithe-2026-10-ama"}
  ]
)

if response.success?
  puts "Queued #{response.data.batch_code} with #{response.data.total_charges} charges"
else
  puts "Error: #{response.error_message}"
end
```

The SDK refuses an empty list but sends each Hash as given: Paystack, not the SDK, checks what is inside. A successful response means the charges were queued ("Charges have been queued"), not that they succeeded; read each charge's outcome with `fetch_charges` or from your webhooks. Like every write, `initiate` is not retried after a timeout, so check `list_batches` before sending the same charges again.

## List and Fetch Batches and Their Charges

```ruby
# status is active, paused or complete. Paystack's docs also list from and to, but the API ignores them.
paystack.bulk_charges.list_batches(status: "active", per_page: 20, page: 1)

# Fetch by numeric ID or BCH_ code; total_charges and pending_charges show its progress
batch = paystack.bulk_charges.fetch_batch(id_or_code: "BCH_1uhxe0d181eu850")
puts "#{batch.data.pending_charges} of #{batch.data.total_charges} still pending"

# Each charge with its customer, authorization, reference and status
# (pending, success, failed, error or inactive_authorization)
paystack.bulk_charges.fetch_charges(id_or_code: "BCH_1uhxe0d181eu850", status: "failed")
```

## Pause and Resume a Batch

```ruby
# Both are GET requests, as Paystack documents them, and take the BCH_ batch code
paystack.bulk_charges.pause_batch(batch_code: "BCH_1uhxe0d181eu850")  # "Bulk charge batch has been paused"
paystack.bulk_charges.resume_batch(batch_code: "BCH_1uhxe0d181eu850") # "Bulk charge batch has been resumed"
```

A paused batch keeps its pending charges until it is resumed.
