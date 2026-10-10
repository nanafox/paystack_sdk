# Charges

The Charge API lets you pick the payment channel yourself instead of sending the customer to Checkout: a saved card authorization, a bank account, USSD, mobile money, QR, EFT, Pay with Transfer or Capitec Pay. Many charges need one more step from the customer (a PIN, OTP, phone number, birthday or address) before they complete. See the Paystack docs: [Charge API](https://paystack.com/docs/api/charge/) and [Payment Channels](https://paystack.com/docs/payments/payment-channels/).

## Mobile Money in Ghana: Which Networks

Paystack lists three Ghana mobile-money providers (`banks.list(country: "ghana", type: "mobile_money")`): `MTN`, `VOD` (shown as Vodafone, now Telecel) and `ATL` (AirtelTigo). The bank list uses uppercase codes; `charges.mobile_money` takes the provider in any case and sends it in lowercase (`mtn`, `vod`, `atl`).

What was checked, against Paystack's test API only: a merchant-started charge of 100 pesewas (GHS) for each of the three providers on Paystack's test number was accepted, came back with `status: "success"` and `gateway_response: "Approved"` immediately, and `check_pending(reference:)` returned the same. **Test mode does not model the payer approving the prompt on their phone, so this does not show which live networks accept a charge you start yourself.** Treat each network as unverified in live mode: start the charge, read `response.status` (`status?(:pay_offline)`, `status?(:send_otp)`, `status?(:pending)` and so on, as Paystack returns them), show `response.display_text` to the payer when there is one, and poll `charges.check_pending(reference:)` or wait for the `charge.success` webhook. Confirm with `transactions.verify(reference:)` before giving value. If a network refuses a merchant-started prompt, fall back to a payment link for that network.

## Create a Mobile Money Charge

Mobile money is available to businesses in Ghana, Kenya and Côte d'Ivoire. `mobile_money` checks the `mobile_money` object (phone or till account, and a known provider) and sends it with `create`.

Supported providers (case-insensitive): `mtn`, `atl` (ATMoney/Airtel Money), `vod` (Telecel, formerly Vodafone), `mpesa`, `mpesa_offline`, `mptill` (M-PESA Till: send `account:`, the till number, instead of `phone:`), `orange`, `wave`.

```ruby
paystack = PaystackSdk::Client.new(secret_key: "sk_test_xxx")

response = paystack.charges.mobile_money(
  email: "customer@email.com",
  amount: 100,             # smallest unit (pesewas/cent)
  currency: "GHS",         # optional; Paystack uses your integration's currency without it
  mobile_money: {
    phone: "0551234987",
    provider: "mtn"        # mtn | atl | vod | mpesa | mpesa_offline | mptill | orange | wave
  }
)

if response.success?
  case response.status
  when "pay_offline"
    # Show instruction text and wait for webhook or verify later
    puts response.display_text
  when "send_otp"
    # For Vodafone, collect voucher/OTP and submit below
    puts response.display_text
  when "success"
    puts "Charge completed: #{response.reference}"
  else
    puts "Status: #{response.status}"
  end
else
  puts "Charge failed: #{response.error_message}"
end
```

## Create a Charge on Another Channel

`create` takes one channel object (or an `authorization_code`) as a keyword hash and sends it as Paystack documents it.

```ruby
# A returning customer's saved card
paystack.charges.create(email: "customer@email.com", amount: 10000, authorization_code: "AUTH_xxxx")

# A bank account (Paystack may then ask for the customer's birthday or an OTP)
paystack.charges.create(
  email: "customer@email.com",
  amount: 10000,
  bank: {code: "057", account_number: "0000000000"},
  birthday: Date.new(1995, 12, 23) # or "1995-12-23"
)

# USSD (Nigeria), Pay with Transfer, and QR or EFT (South Africa)
paystack.charges.create(email: "customer@email.com", amount: 10000, ussd: {type: "737"})
paystack.charges.create(email: "customer@email.com", amount: 10000, bank_transfer: {account_expires_at: "2026-10-10T12:00:00Z"})
paystack.charges.create(email: "customer@email.com", amount: 10000, currency: "ZAR", qr: {provider: "scan-to-pay"})
paystack.charges.create(email: "customer@email.com", amount: 10000, currency: "ZAR", eft: {provider: "ozow"})

# Send the payment through a split or to a subaccount
paystack.charges.create(email: "customer@email.com", amount: 10000, authorization_code: "AUTH_xxxx", split_code: "SPL_xxxx")
```

## Complete a Charge

When the response asks for more from the customer (read `response.status` and `response.display_text`), send it with the charge's `reference`:

```ruby
paystack.charges.submit_pin(pin: "1234", reference: "5bwib5v6anhe9xa")
paystack.charges.submit_otp(otp: "123456", reference: "5bwib5v6anhe9xa") # e.g. a Vodafone voucher
paystack.charges.submit_phone(phone: "08012345678", reference: "5bwib5v6anhe9xa")
paystack.charges.submit_birthday(birthday: "1961-09-21", reference: "5bwib5v6anhe9xa")
paystack.charges.submit_address(
  address: "140 N 2ND ST",
  city: "Stroudsburg",
  state: "PA",
  zip_code: "18360",
  reference: "7c7rpkqpc0tijs8"
)
```

## Check a Pending Charge

If a charge comes back `pending`, or a `/charge` call failed with an exception, wait at least 10 seconds, then check it (Paystack warns that checking too early returns more `pending` results):

```ruby
response = paystack.charges.check_pending(reference: "5bwib5v6anhe9xa")
puts response.status
```

For offline flows such as mobile money, listen for the `charge.success` webhook, and confirm it with `transactions.verify(reference:)` before giving value:

```ruby
verify = paystack.transactions.verify(reference: "r13havfcdt7btcm")
puts verify.status # "success", "failed", or current state
```
