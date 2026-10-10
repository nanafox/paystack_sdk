# Transfers

Transfers send money from your Paystack balance to a transfer recipient (`RCP_...`). They move real money in live mode, so the SDK never retries them except on `429` (see [Timeouts and Retries](https://nanafox.github.io/paystack_sdk/latest/md/guide/timeouts-and-retries.md)).

## Initiate a Transfer

```ruby
# Amount is in the smallest currency unit (kobo, pesewas, cents).
# reference is required: generate it once and reuse it if you retry, so a retry cannot pay twice.
# Paystack documents 16 to 50 characters of lowercase letters, digits, - and _.
response = paystack.transfers.create(
  source: "balance",
  amount: 100_000,
  recipient: "RCP_gd9vgag7n5lr5ix",
  reference: "acv_9ee55786-2323-4760-98e2-6380c9cb3f68",
  reason: "Bonus for the week"
)

if response.success?
  case response.data.status
  when "otp"
    # Your integration requires an OTP: Paystack sent one to the business phone
    paystack.transfers.finalize(transfer_code: response.data.transfer_code, otp: "928783")
  else
    puts "Transfer #{response.data.transfer_code} is #{response.data.status}"
  end
else
  puts "Error: #{response.error_message}"
end
```

## Verify, Fetch and List Transfers

```ruby
# Verify by your reference
paystack.transfers.verify(reference: "acv_9ee55786-2323-4760-98e2-6380c9cb3f68")

# Fetch by transfer ID or code
paystack.transfers.fetch(id_or_code: "TRF_v5tip3zx8nna9o78")

# List, with Paystack's page pagination (default 50 per page)...
paystack.transfers.list(per_page: 20, page: 2, from: "2025-01-01", to: "2025-04-30")

# ...filtered by the numeric recipient ID, or by status
paystack.transfers.list(recipient: 56824902, status: "success")

# ...or with cursor pagination: pass response.meta.next back as next_cursor
paystack.transfers.list(use_cursor: true, per_page: 20)

# Export transfers (in Paystack's OpenAPI spec, not on its docs page)
paystack.transfers.export(from: "2025-01-01", to: "2025-04-30", status: "success")
```

## Bulk Transfers and the OTP Requirement

```ruby
# Bulk transfers need the OTP requirement disabled. Each transfer uses Paystack's field names.
paystack.transfers.bulk_create(
  source: "balance",
  currency: "NGN",
  transfers: [
    {amount: 20_000, recipient: "RCP_gd9vgag7n5lr5ix", reference: "acv_2627bbfe-1a2a-4a1a-8d0e-9d2ee6c31496", reason: "Bonus"},
    {amount: 35_000, recipient: "RCP_zpk2tgagu6lgb4g", reference: "acv_1bd0c1f8-78c2-463b-8bd4-ed9eeb36be50", reason: "Bonus"}
  ]
)

# Turn the OTP requirement off (Paystack sends an OTP to the business phone), then confirm it
paystack.transfers.disable_otp
paystack.transfers.finalize_disable_otp(otp: "928783")

# Turn it back on
paystack.transfers.enable_otp

# Resend the OTP for a transfer awaiting one
paystack.transfers.resend_otp(transfer_code: "TRF_vsyqdmlzble3uii", reason: "resend_otp")
```
