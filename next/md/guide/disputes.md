# Disputes

Disputes (chargebacks) are filed against your transactions by customers or their banks. Listing and fetching are read-only. `update`, `add_evidence` and `resolve` change a real dispute, so call them only when you mean to answer it.

## List and Fetch Disputes

```ruby
# List, with Paystack's page pagination; filter by status, transaction ID or date range.
# status is one of awaiting-merchant-feedback, awaiting-bank-feedback, pending, resolved
response = paystack.disputes.list(status: "awaiting-merchant-feedback", per_page: 20, from: "2025-01-01", to: "2025-04-30")
response.data.each { |dispute| puts "#{dispute.id}: #{dispute.status}" } if response.success?

# Fetch one dispute, or every dispute filed for a transaction
paystack.disputes.fetch(id: 2867)
paystack.disputes.list_transaction(id: 5991760)

# Export disputes. Paystack answers 404 "No disputes found" when there is nothing to export.
paystack.disputes.export(from: "2025-01-01", to: "2025-04-30")
```

## Answer a Dispute

```ruby
# 1. Get a signed URL, upload the evidence file to it, and keep the returned file name
upload = paystack.disputes.fetch_upload_url(id: 2867, upload_filename: "receipt.pdf")
upload.data.signedUrl   # upload your file to this URL
upload.data.fileName    # pass this as uploaded_filename

# 2. Add evidence
paystack.disputes.add_evidence(
  id: 2867,
  customer_email: "ama@example.com",
  customer_name: "Ama Mensah",
  customer_phone: "0802345167",
  service_details: "Tithe payment for March",
  delivery_date: "2025-03-31"
)

# 3. Accept (with a refund) or decline. refund_amount is in the smallest currency unit.
# It is `resolve` because `resolve` would shadow a method Ruby already has.
paystack.disputes.resolve(
  id: 2867,
  resolution: "merchant-accepted", # or "declined"
  message: "Refunded at the customer's request",
  refund_amount: 50_000,
  uploaded_filename: upload.data.fileName
)

# Or change the refund amount and attachment without resolving
paystack.disputes.update(id: 2867, refund_amount: 50_000, uploaded_filename: upload.data.fileName)
```
