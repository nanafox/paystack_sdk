---
name: paystack-sdk-saved-card-renewals
description: 'Use when charging a returning customer saved card without checkout through paystack_sdk: renewals, dues or instalments your own app schedules, saving the reusable authorization from a first payment, calling transactions.charge_authorization or partial_debit, designing renewal references, handling a declined, rejected or timed-out renewal, dunning, or a lost authorization code. Not for Paystack Plans or Subscriptions.'
---

# Saved-card renewals (your app schedules the charge)

The payer pays once through checkout (or the Charge API). Paystack returns an `authorization`. If it is reusable, you store its code and later charge the card yourself with `transactions.charge_authorization`, without the payer present. Your job owns the schedule. Read [[paystack-sdk-overview]] first; it covers `success?`, `paid?` and retries.

Paystack Plans and Subscriptions (`client.plans`, `client.subscriptions`) are a different feature, in which Paystack does the scheduling. They have their own method docs in the gem and are not covered or verified here.

## 1. Get a reusable authorization from the first payment

After the first payment, verify it and read `data.authorization`. Save it only if `reusable` is true. Paystack's Recurring Charges guide says: "You should only attempt to use the authorization_code if this flag returns as true."

```ruby
def reusable_card_authorization(verify_response, amount:, currency:)
  return nil unless verify_response.paid?(amount: amount, currency: currency)

  auth = verify_response.original_response.dig("data", "authorization") || {}
  return nil unless auth["reusable"] == true && auth["channel"] == "card"

  {
    email: verify_response.original_response.dig("data", "customer", "email"), # the code belongs to THIS email
    authorization_code: auth["authorization_code"],                            # secret: store it encrypted
    signature: auth["signature"],                                              # the same card gives the same signature
    last4: auth["last4"], exp_month: auth["exp_month"], exp_year: auth["exp_year"],
    bank: auth["bank"], card_type: auth["card_type"].to_s.strip                 # Paystack sends "visa " with a space
  }
end
```

| Field | What it is | Store it? |
|---|---|---|
| `authorization_code` | What you charge (`AUTH_...`) | Yes, **encrypted** (for example with Active Record encryption). Never log it |
| `customer.email` of that payment | The only email that can charge this code | Yes, next to the code. Do not take it from the user record later |
| `signature` | Identifies the card, not the customer | Yes: dedupe saved cards on email + signature |
| `last4`, `exp_month`, `exp_year`, `bank`, `card_type` | For "Visa ending 4081, expires 09/27" | Yes, plain |
| `reusable` | Whether you may charge it later | Check it. Do not save a code that is not `true` |
| Card number, CVV, PIN, OTP | You never receive them from Paystack | Never store or log what a payer typed |

Observed on the test API 2026-10-09: the customers `kwes@email.com` and `jdoe@email.com` hold different codes (`AUTH_50w0d0f5xo`, `AUTH_f6sm3o0m7w`) with the **same** signature, because they used the same test card. So a signature on its own is not a customer key. Paystack's guide also says new authorization codes are created each time a card is used, while the signature stays the same: dedupe on email + signature and keep the newest code.

## 2. Charge a renewal

```ruby
response = client.transactions.charge_authorization(
  email: card.email,                           # the email the code was saved with
  amount: 5000,                                # pesewas, an Integer (100.0 raises InvalidValueError before sending)
  currency: "GHS",                             # always pass it
  authorization_code: card.authorization_code,
  reference: renewal_reference(membership.id, "2026-10", 1),
  metadata: {membership_id: membership.id, period: "2026-10"} # a Hash is sent as a JSON string; verify returns it as a Hash
)
```

Other keywords: `queue:` (Paystack's docs: for scheduled charges, so its processing system is not overloaded; with `queue: true` a test charge still answered `success` at once), `split_code:`, `split:`, `subaccount:`, `transaction_charge:`, `bearer:` (`"account"` or `"subaccount"`). Only `email`, `amount` and `authorization_code` are required by the method.

## 3. What comes back (observed on the test API 2026-10-09)

| Situation | HTTP | `success?` | Message | Transaction created? |
|---|---|---|---|---|
| Good code, its own email | 200 | true | "Charge attempted", `data.status` `success` | Yes |
| Code that does not exist | 400 | false | "Authorization code is invalid" | No |
| Another customer's code (email mismatch) | 400 | false | "Email does not match Authorization code. Authorization may be inactive or belong to a different email. Please confirm." | No |
| A code you deactivated (`customers.deactivate_authorization`) | 400 | false | Same "Email does not match..." message | No |
| A mobile money code (`reusable: false`), its own email | 400 | false | Same "Email does not match..." message | No |
| Currency the account does not take (USD) | 400 | false | "Currency not supported by merchant" | No |
| A reference already used | 400 | false | "Duplicate Transaction Reference" | No new one |
| `verify` of a reference Paystack never saw | 400 | false | "Transaction reference not found." | n/a |

None of these raise: read `response.error_message`. A 400 on `charge_authorization` did not create a transaction, so the same reference stayed free: a valid charge on it afterwards succeeded. Three different causes share one message, so do not try to tell "wrong email", "deactivated" and "not reusable" apart from the text.

**Not observed: a declined card.** No test card here declines a saved-card charge, so a 200 with `data.status` `failed` (insufficient funds, expired card) was not seen. Handle every status that is not `success` as not paid. Paystack's guide also documents a response with `data.paused` true and `data.authorization_url` when a card is challenged for two-factor authentication (Nigerian integrations, on request): the payer must open that URL, and you verify the reference afterwards.

## 4. References, lookup-first jobs and the timeout rule

One reference per **attempt**, built from your own record id and the billing period, and stored before the call. A retry of the same job (a crash, a timeout, a redeploy) reuses that reference and looks it up first. A deliberate new attempt after a decline gets the next attempt number.

```ruby
def renewal_reference(record_id, period, attempt)
  reference = "renewal-#{record_id}-#{period}-a#{attempt}"
  raise ArgumentError, "unusable reference #{reference.inspect}" unless reference.match?(/\A[a-zA-Z0-9._=-]+\z/)

  reference
end

# :paid, :failed, :pending (look again later), :check_amount (paid, but not what you asked for)
def renewal_outcome(response, amount:, currency:)
  return :paid if response.paid?(amount: amount, currency: currency)
  return :check_amount if response.status?(:success)
  return :failed if response.status?(:failed)

  :pending
end

# Returns [outcome, detail]. Outcomes: :paid, :failed, :pending, :check_amount,
# :rejected (400, nothing charged: detail is Paystack's message) and :unknown (verify this reference later).
def charge_renewal(client, card:, amount:, currency:, reference:)
  existing = client.transactions.verify(reference: reference)
  return [renewal_outcome(existing, amount: amount, currency: currency), nil] if existing.success?

  response = client.transactions.charge_authorization(email: card.email, amount: amount, currency: currency,
    authorization_code: card.authorization_code, reference: reference)
  return [:unknown, response.error_message] if response.error_message.to_s.include?("Duplicate")
  return [:rejected, response.error_message] unless response.success?

  [renewal_outcome(client.transactions.verify(reference: reference), amount: amount, currency: currency), nil]
rescue PaystackSdk::TimeoutError, PaystackSdk::ConnectionError, PaystackSdk::ServerError => e
  [:unknown, e.class.name] # the charge may have happened: never resend now, verify this reference on the next run
end
```

- **Never retry a charge after a timeout, connection error or 5xx.** The SDK does not (writes retry only on 429). The charge may have gone through: verify the reference first. `charge_renewal` returns `:unknown` and the next run starts with `verify`.
- If you do send a reference twice, Paystack refuses the second with "Duplicate Transaction Reference" (observed), so the lookup-first job cannot double charge one attempt.
- Grant the period only on `:paid`, which is `paid?(amount:, currency:)` on a `verify` by reference.
- Run on the test API 2026-10-09: the first `charge_renewal` charged and returned `[:paid, nil]`; a second call with the same reference returned `[:paid, nil]` from the lookup without charging; another customer's code returned `[:rejected, "Email does not match..."]`.

## 5. Partial debit

`transactions.partial_debit(email:, amount:, authorization_code:, currency:, at_least: nil, reference: nil)` charges a saved card for **whatever it can**, up to `amount`, when the full amount would fail for insufficient funds. Per Paystack's Partial Debits guide it is available only on request, only for Mastercard and Verve, and `verify` then returns `amount` (what was charged) and `requested_amount` (what you asked for). So `paid?(amount: requested, ...)` is false for a partial charge, and `renewal_outcome` returns `:check_amount`: record what was actually paid and bill the rest.

Observed on the test API 2026-10-09: `partial_debit` in GHS answered HTTP 400 "Currency GHS is not supported for Partial Debit", although the API reference lists NGN or GHS. **For a Ghana integration, treat partial debit as unavailable** unless Paystack enables it for you. No partial charge was observed.

## 6. Two confirmations racing (reported by a consumer, not reproduced)

An app reported that a webhook and a return-URL confirmation for the same first card payment ran at the same time and the reusable authorization was lost; they now re-verify by reference whenever the token is missing. What was observed (test API 2026-10-09): `transactions.verify` on a paid reference returned the same authorization (code, `reusable: true`, signature) on two calls in a row, for a saved-card charge and for a first card charge. So re-verifying is a sound recovery. Design advice: save the authorization in one place, idempotently (a unique index on email + signature, then insert-or-update), and have both confirmation paths call it.

Also observed: after `customers.deactivate_authorization`, `verify` of the old reference still said `reusable: true`, while `customers.fetch` listed no authorizations. `reusable` is a snapshot of the payment; it does not tell you the code still works.

## 7. Mobile money is not a saved card

A paid test mobile money charge (`0551234987`, `mtn`, observed 2026-10-09) returned an authorization with `reusable: false`, `signature: nil` and `channel: "mobile_money"`, and charging its code was refused (table above). There is no token to renew with: each mobile money renewal is a new payer-approved charge (see the `paystack-sdk-mobile-money` skill), or a payment link sent to the payer.

## 8. Dunning (design advice, not Paystack behaviour)

- `:failed`: retry a few times on later days with a new attempt number each time, then stop and ask the payer to pay through checkout (which can save a new card).
- `:rejected`: the code is unusable (invalid, inactive, another email, or not reusable). Do not retry it. Mark the card unusable and ask the payer to pay and save a card again.
- `:unknown` and `:pending`: verify the same reference later; do not charge again.
- `:check_amount`: record the partial payment and do not grant the full period.
- Warn payers before `exp_month`/`exp_year` passes. What Paystack returns for an expired saved card was not observed.

## Rules

- **Charge only codes saved with `reusable: true`, with the exact email they were saved with.**
- **Store the code encrypted and keyed to that email; never store card data or anything the payer typed.** Keep codes and keys out of logs.
- **One reference per attempt, stored before the call; a job retry looks it up first.**
- **Never resend after a timeout or 5xx; verify the reference.**
- **Grant the period only on `verify(reference:).paid?(amount:, currency:)`**, never on the charge response alone.
- **Amounts are Integers in pesewas, and always pass `currency: "GHS"`.**

## Not verified

A declined saved-card charge, an expired card, the `paused` two-factor flow, `queue: true` in live mode, a successful partial debit, and anything in live mode. Test mode is lenient. The consumer-reported race was not reproduced.
