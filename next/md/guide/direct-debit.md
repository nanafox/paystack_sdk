# Direct Debit

`client.direct_debits` works across your whole integration: every customer's Direct Debit mandates at once, and activation charges for several customers in one call. To link a bank account, or to work with one customer's mandates by their customer ID, use the methods on `client.customers` (see [Authorizations and Direct Debit](https://nanafox.github.io/paystack_sdk/next/md/guide/customers.md#authorizations-and-direct-debit)):

| You want to | Integration-wide (`direct_debits`) | One customer (`customers`) |
|---|---|---|
| See mandates | `list_mandate_authorizations` (`GET /directdebit/mandate-authorizations`), filtered by `status`, paged by cursor | `fetch_mandate_authorizations(id:)` (`GET /customer/{id}/directdebit-mandate-authorizations`) |
| Trigger an activation charge | `trigger_activation_charge(customer_ids:)` (`PUT /directdebit/activation-charge`), for **pending** mandates | `direct_debit_activation_charge(id:, authorization_id:)` (`PUT /customer/{id}/directdebit-activation-charge`), for one **inactive** mandate |

## List Mandate Authorizations

```ruby
# All parameters are optional. status is pending, active or revoked
response = paystack.direct_debits.list_mandate_authorizations(status: "active", per_page: 10)

response.each do |mandate|
  puts "#{mandate.authorization_code} #{mandate.bank_name} #{mandate.status}"
end

# Cursor pagination: pass meta.next back as cursor (it is null on the last page)
next_cursor = response.meta.next
paystack.direct_debits.list_mandate_authorizations(status: "active", per_page: 10, cursor: next_cursor) if next_cursor
```

Paystack answers a cursor it cannot read with a 500, which the SDK raises as `PaystackSdk::ServerError`.

## Trigger Activation Charges

```ruby
# Numeric customer IDs of customers with pending mandates
response = paystack.direct_debits.trigger_activation_charge(customer_ids: [28958104, 983697220])
response.message # => "Mandate is queued for retry"
```

This charges the customers' bank accounts. It has not been verified against the test API: the method follows Paystack's docs and OpenAPI spec.
