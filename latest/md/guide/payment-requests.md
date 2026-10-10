# Payment Requests

A payment request is an invoice Paystack sends to a customer, who pays it online. Amounts are in the subunit (pesewas, kobo, cents).

## Create a Payment Request

```ruby
# customer is a customer code (CUS_...) or ID. Give line_items and tax, each an Array of Hashes,
# and Paystack adds them up (2 x 2000 + 300 = 4300 here); give amount instead when you have none.
response = paystack.payment_requests.create(
  customer: "CUS_p6i0reogc8ulu1n",
  currency: "GHS",
  description: "Harvest thanksgiving pledge",
  line_items: [{name: "Pledge", amount: 2000, quantity: 2}],
  tax: [{name: "Levy", amount: 300}],
  due_date: Date.new(2026, 12, 31), # a Date, a Time or an ISO 8601 string
  metadata: {branch: "Osu"},        # a Hash; Paystack refuses a JSON string here
  draft: true                       # a draft is not sent; finalize it later
)

if response.success?
  puts "Created #{response.data.request_code} for #{response.data.amount}"
else
  puts "Error: #{response.error_message}"
end
```

Paystack's docs say it emails the customer when a request is created, unless you pass `draft: true` or `send_notification: false`. Without `amount`, `line_items` or `tax`, Paystack refuses anything but a draft ("Amount was not passed or could not be extrapolated from line items.").

## List, Fetch and Verify Payment Requests

```ruby
# customer_id is the numeric customer ID (Paystack ignores a CUS_ code here)
paystack.payment_requests.list(customer_id: 407172149, status: "pending", per_page: 20)

# Archived requests are left out unless you pass include_archive: true. Paystack includes them
# whenever the parameter is sent, even as false, so leave it out rather than passing false.
paystack.payment_requests.list(include_archive: true)

# Fetch by numeric ID or PRQ_ code
paystack.payment_requests.fetch(id_or_code: "PRQ_7w7dpecncnebg7e")

# Verify takes the PRQ_ code only, and only once the request is no longer a draft
paystack.payment_requests.verify(code: "PRQ_7w7dpecncnebg7e")

# Pending, successful and total amounts per currency
paystack.payment_requests.totals
```

## Update, Finalize, Notify and Archive

```ruby
# Send only what changes; new line_items and tax recompute the amount
paystack.payment_requests.update(id_or_code: "PRQ_7w7dpecncnebg7e", due_date: "2027-01-31")

# Finalize a draft. Paystack emails the customer unless send_notification is false.
paystack.payment_requests.finalize(id_or_code: "PRQ_7w7dpecncnebg7e", send_notification: false)

# Email the customer a reminder
paystack.payment_requests.notify(code: "PRQ_7w7dpecncnebg7e")

# Archive: it no longer shows up in list or verify
paystack.payment_requests.archive(id_or_code: "PRQ_7w7dpecncnebg7e")
```
