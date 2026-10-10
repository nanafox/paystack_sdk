---
name: paystack-sdk-charge-statuses
description: 'Use when code starts a payment with the Charge API (card or mobile money) and must react to what comes back: a status such as send_pin, send_otp, send_phone, pay_offline, pending, failed or success, deciding what to show the payer, and which paystack_sdk call to make next. Also use when a charge call reports success? but the payment did not go through.'
---

# Charge statuses: what to show, what to call next

The Charge API (`client.charges`) does not finish in one call when the payer must prove something. Each response carries `data.status`, and that status tells you what the payer must do and which call comes next. Read it with `response.status` or `response.status?(:send_pin)`.

## The one trap: `success?` is not "the charge worked"

`response.success?` means Paystack accepted the *call*. It says nothing about whether the *charge* succeeded. Always look at `data.status`:

| What you did | `success?` | `data.status` |
|---|---|---|
| `charges.create`/`mobile_money` with a phone number that is too short | `true` (HTTP 200, message "Charge attempted") | `failed` |
| `charges.check_pending` on a charge that failed | `true` (HTTP 200) | `failed` |
| `charges.submit_pin` / `submit_otp` with a wrong PIN or OTP | `false` (HTTP 400) | `failed` |

So decide with the status, and give value only with `transactions.verify(reference:).paid?(amount:, currency:)` (see the rules in [paystack-sdk-overview](paystack-sdk-overview.md)).

## Status table

| `data.status` | Meaning | Show the payer | Next call |
|---|---|---|---|
| `success` | The charge went through | Confirmation | `transactions.verify(reference:)` then `paid?(amount:, currency:)` before giving value |
| `send_pin` | The card needs its PIN | A PIN field | `charges.submit_pin(pin:, reference:)` |
| `send_otp` | An OTP is needed | An OTP field, with `data.display_text` | `charges.submit_otp(otp:, reference:)` |
| `send_phone` | A mobile number is needed | A phone field, with `data.display_text` | `charges.submit_phone(phone:, reference:)` |
| `send_birthday` | A date of birth is needed (the bank flow; display text "Please enter your birthday") | A date field | `charges.submit_birthday(birthday:, reference:)` |
| `send_address` (name not confirmed) | A billing address is needed | Address, city, state and zip code | `charges.submit_address(address:, city:, state:, zip_code:, reference:)` |
| `pay_offline` | The payer approves on their phone or by USSD | `data.display_text` (and any USSD code in the response) | Nothing to submit. Wait for the `charge.success` webhook, then verify. If nothing arrives, poll `charges.check_pending(reference:)` or verify |
| `pending` (name not confirmed) | Paystack is still processing | "Processing" | `charges.check_pending(reference:)` until it is not `pending`, or wait for the webhook |
| `open_url` (EFT, South Africa) | The payer must finish on the provider's page | Redirect to `data.url` | Nothing to submit. Wait for the webhook, then verify |
| `failed` | The charge is dead | The reason, `data.message` | Start a **new** charge with a **new** `reference` |

Always pass the same `reference` you started the charge with to each follow-up call.

## What was observed on Paystack's test API (2026-10-09, test cards from Paystack's test-payments page)

These flows ran for real with `reference`s of our own, and each ended with `transactions.verify(...).paid?` true and a reusable authorization:

- Card `4084 0840 8408 4081`, expiry `09/27`, CVV `408` (no validation): `success` at once.
- Card `5078 5078 5078 5078 12`, CVV `081`, PIN `1111`: `send_pin` -> `submit_pin` -> `success`.
- Card `5060 6666 6666 6666 666`, CVV `123`, PIN `1234`, OTP `123456`: `send_pin` -> `submit_pin` -> `send_otp` (display text "Please enter OTP (none will be sent to your phone)") -> `submit_otp` -> `success`.
- Card `5078 5078 5078 5078 04`, CVV `884`, PIN `0000`, OTP `123456`: `send_pin` -> `send_phone` (display text "Kindly enter a mobile no (at least 10 digits)") -> `send_otp` -> `success`.
- A wrong PIN or OTP returned HTTP 400, `data.status` `failed`, `data.message` "Incorrect PIN" or "Token Authorization Not Successful...". **The charge is dead after one wrong entry**: entering the correct OTP afterwards still failed. Start over with a new reference.
- `submit_otp` with a reference Paystack does not know: HTTP 400, message "Transaction reference is invalid", no `data.status`.

Not reproduced here: `send_birthday`, `pay_offline` and `open_url` appear in Paystack's payment-channels guide (the bank flow, mobile money and EFT) but a test charge never produced them (a mobile money charge answers `success` at once in test mode). `send_address` and `pending` are not named in the docs we read: the SDK has `submit_address` and `check_pending`, so the statuses are expected, but their exact names are not confirmed. Treat all of these as unverified. The SDK's `charges.create` has no `card:` keyword; card details go through Paystack's card API, which is only for PCI-compliant businesses. The test cards above are for Paystack's test mode only.

## A loop that handles every status

```ruby
# `response` is the result of charges.create / charges.mobile_money, and `reference` is the one you chose.
response = client.charges.mobile_money(email: email, amount: 5000, currency: "GHS", reference: reference,
  mobile_money: {phone: "0551234987", provider: "mtn"})

case response.status
when "success"
  # still verify by reference before giving value
when "pay_offline", "pending"
  # show response.display_text (when present) and wait for the charge.success webhook
when "send_pin"
  response = client.charges.submit_pin(pin: pin_from_payer, reference: reference)
when "send_otp"
  response = client.charges.submit_otp(otp: otp_from_payer, reference: reference)
when "send_phone"
  response = client.charges.submit_phone(phone: phone_from_payer, reference: reference)
when "failed"
  reason = response.original_response.dig("data", "message") # never retry the same reference
else
  raise "unhandled charge status: #{response.status.inspect}" # fail loudly, do not guess
end
```

Collect the payer's input between steps; do not loop without them. The `else` branch matters: Paystack can return statuses this skill does not list.

## Rules

- **Branch on `data.status`, not on `success?`.**
- **One reference per charge attempt.** A `failed` charge cannot be resumed; the retry is a new charge with a new reference.
- **Never retry a charge call after a timeout** (the SDK does not either). First look it up: `client.transactions.verify(reference: reference)`.
- **Store nothing the payer typed.** PINs and OTPs go straight to Paystack and are never logged or saved.
- **Fail loudly on an unknown status**, and log the status and reference so it can be handled. The names `send_address` and `pending` are the likeliest to differ from the table.
