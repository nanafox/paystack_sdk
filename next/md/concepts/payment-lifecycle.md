# How a payment works

The payer pays on Paystack's checkout page, not on yours. Your server starts the transaction, sends the payer to Paystack, and later asks Paystack what happened. Nothing the browser brings back counts as proof.

## The five steps

1. **Record it first.** Create your own payment row with a new `reference`, an `amount` in the currency's smallest unit (`5000` is GHS 50.00), a `currency` and the status `pending`. Save it before you call Paystack.
2. **Start it.** `client.transactions.initiate(...)` with that reference. Redirect the payer to `response.authorization_url`.
3. **The payer comes back** to your `callback_url`. Treat that request as "please check", nothing more: Paystack's own docs say a visit to the callback URL does not prove the transaction succeeded.
4. **Ask Paystack.** `client.transactions.verify(reference:)`, and give value only if `paid?(amount:, currency:)` is true.
5. **Do the same from the webhook.** The `charge.success` handler runs the same confirmation code as the callback.

```ruby
res = client.transactions.initiate(email: member.email, amount: 5000, currency: "GHS", reference: payment.reference)
redirect_to res.authorization_url, allow_other_host: true

# later, from the callback and from the webhook
res = client.transactions.verify(reference: payment.reference)
grant_access(payment) if res.paid?(amount: payment.amount, currency: payment.currency)
```

## Why steps 4 and 5 are the same code

The callback and the webhook can arrive at the same moment, so confirming twice is normal. Write one confirmation that is safe to run twice: a unique `reference` column, a row lock, and a check of your own status inside the lock. Record what the payment buys in that same locked block, so it happens once. This is design advice, not Paystack behaviour; the [payments skill](https://nanafox.github.io/paystack_sdk/next/skills/paystack-sdk-payments.md) has a complete example.

## When something goes wrong

- **A timeout or a server error on `initiate`.** The SDK does not retry a write, and the request may have reached Paystack. Call `verify(reference:)`: "Transaction reference not found." means Paystack never created it. Either way, start again with a new reference and mark the old row failed.
- **A reference used twice.** Paystack answers 400 "Duplicate Transaction Reference". One reference is one transaction, ever.
- **A status you do not recognise.** Keep the row `pending`, log the status and reference, and do not guess.

Next: [what a result means](https://nanafox.github.io/paystack_sdk/next/md/concepts/results-and-trust.md), and the [Transactions guide](https://nanafox.github.io/paystack_sdk/next/md/guide/transactions.md).
