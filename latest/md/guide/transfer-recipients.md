# Transfer Recipients

Every method takes keyword arguments. A recipient is who you send a transfer to.

## Create a Transfer Recipient

```ruby
response = paystack.transfer_recipients.create(
  type: "nuban", # nuban, ghipss, mobile_money, basa or authorization
  name: "Ama Mensah",
  account_number: "0123456789",
  bank_code: "058",
  currency: "NGN",
  metadata: {job: "Baker"}
)

puts response.data.recipient_code if response.success?
```

A duplicate account number returns the existing recipient. To create many at once, pass a list of recipient hashes:

```ruby
response = paystack.transfer_recipients.bulk_create(
  batch: [
    {type: "nuban", name: "Ama Mensah", account_number: "0123456789", bank_code: "058"},
    {type: "nuban", name: "Kofi Boateng", account_number: "0987654321", bank_code: "058"}
  ]
)

response.data.success # recipients that were created
response.data.errors  # records Paystack rejected, with the reason
```

## List, Fetch, Update and Delete

```ruby
paystack.transfer_recipients.list(per_page: 20, page: 2)

# fetch, update and delete take the recipient code or the numeric ID
paystack.transfer_recipients.fetch(id_or_code: "RCP_2x5j67tnnw1t98k")
paystack.transfer_recipients.update(id_or_code: "RCP_2x5j67tnnw1t98k", name: "Ama K. Mensah", email: "ama@example.com")
paystack.transfer_recipients.delete(id_or_code: "RCP_2x5j67tnnw1t98k") # Paystack sets the recipient to inactive
```

Paystack's docs list `from` and `to` filters on the list endpoint, but the API ignores them (checked against the test API), so the SDK does not offer them. Cursor pagination is available with `use_cursor: true`, `next_cursor:` and `previous:`.
