# Subscriptions

A subscription charges a customer's saved card on a plan's schedule. The customer needs a reusable card authorization (from an earlier successful card payment), and the plan is created in your Paystack dashboard or through the Plans API.

## Create a Subscription

```ruby
# customer: the customer's email or customer code. plan: the plan code (PLN_...).
# authorization: which of the customer's saved cards to charge (AUTH_...); without it Paystack
# uses the customer's most recent authorization. It must belong to this customer.
# start_date: the date of the first debit, a Time, Date or ISO 8601 string. On the test API it
# becomes next_payment_date (2027-01-15T10:00:00Z here), and the schedule follows the plan's interval.
response = paystack.subscriptions.create(
  customer: "CUS_xnxdt6s1zg1f4nx",
  plan: "PLN_gx2wn530m0i3w3m",
  authorization: "AUTH_6tmt288t0o",
  start_date: Time.utc(2027, 1, 15, 10)
)

if response.success?
  # Keep both: enable and disable need the code and the email token
  puts "#{response.data.subscription_code} #{response.data.email_token}"
else
  puts "Error: #{response.error_message}" # e.g. "This subscription is already in place."
end
```

A customer can hold one active subscription per plan. The SDK checks that `start_date` is ISO 8601 before sending it: on the test API, an invalid `start_date` is refused with a 400 but still leaves an active subscription with no payment date behind.

## List and Fetch Subscriptions

```ruby
# Filters take numeric IDs: the plan and customer codes match nothing
paystack.subscriptions.list(plan_id: 4298026, customer_id: 406976740, per_page: 20, page: 1)

# Created within a window (Time, Date or ISO 8601 string)
paystack.subscriptions.list(from: Date.new(2026, 10, 1), to: Time.now)

# Fetch by subscription code or numeric ID
paystack.subscriptions.fetch(id_or_code: "SUB_vsyqdmlzble3uii")
```

## Enable or Disable a Subscription

```ruby
# token is the subscription's email_token, returned by create, list and fetch
paystack.subscriptions.disable(code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7")
# => data.status "non-renewing"

paystack.subscriptions.enable(code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7")
```

Disabling answers with `data.status` `non-renewing`, and fetch shows the same status. On the test API a disabled subscription that had never been charged could not be enabled again ("Subscription has been cancelled, and cannot be reactivated").

## Let the Customer Update Their Card

```ruby
# A link to a Paystack page where the customer changes the card on the subscription
paystack.subscriptions.generate_update_link(code: "SUB_vsyqdmlzble3uii").data.link

# Or have Paystack email the customer that link
paystack.subscriptions.send_update_link(code: "SUB_vsyqdmlzble3uii")
```

Both take the subscription code; the numeric ID is not found.
