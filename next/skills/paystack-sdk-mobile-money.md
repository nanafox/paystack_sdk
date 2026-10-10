---
name: paystack-sdk-mobile-money
description: 'Use when charging a mobile money wallet in Ghana (MTN, Telecel, AT Money/AirtelTigo) with paystack_sdk, or any provider that uses charges.mobile_money: choosing the provider code and the phone number format, what the payer sees, how long the payer has, how to learn the result, and what test mode does not prove.'
---

# Mobile money charges (Ghana first)

A mobile money charge is **merchant-started and payer-approved**: you ask Paystack to charge a wallet, the payer gets a prompt on their phone and approves it there, and the result arrives later. Your code must expect "not finished yet" as the normal answer. Statuses and next calls are in [paystack-sdk-charge-statuses](paystack-sdk-charge-statuses.md); this skill is the mobile money specifics.

## Start a charge

```ruby
response = client.charges.mobile_money(
  email: "ama@example.com",
  amount: 5000,              # pesewas: GHS 50.00
  currency: "GHS",
  reference: reference,      # create and store it first
  mobile_money: {phone: "0551234987", provider: "mtn"}
)
```

`charges.mobile_money` checks the `mobile_money` object (a phone, or an `account` for an M-PESA Till; a known provider in any case, sent in lowercase) and then calls `charges.create`. It does not change the hash you pass in.

## Provider codes

| Network (Ghana) | `provider` | Code in `banks.list(country: "ghana", type: "mobile_money")` |
|---|---|---|
| MTN | `mtn` | `MTN` |
| Telecel (formerly Vodafone) | `vod` | `VOD` (Paystack's list still names it "Vodafone") |
| AT Money / Airtel Money (AirtelTigo) | `atl` | `ATL` |

The charge takes the lowercase provider code; the bank list returns uppercase codes. The SDK accepts either case for `mobile_money:`. Network brand names change (Telecel Cash, AT Money); the codes above are what Paystack uses. Other providers `charges.mobile_money` accepts: `mpesa`, `mpesa_offline`, `mptill` (Kenya), `orange`, `wave` (Côte d'Ivoire).

## The phone number

Paystack's Ghana example uses the **local ten-digit form**, `0551234987`. If you store numbers in E.164 (`+233551234987`), convert before calling:

```ruby
def local_ghana_number(phone)
  digits = phone.to_s.gsub(/\D/, "")                       # drop +, spaces and dashes
  digits = digits.delete_prefix("233") if digits.size == 12  # +233 551234987 -> 551234987
  digits = "0#{digits}" if digits.size == 9                  # 551234987 -> 0551234987
  raise ArgumentError, "not a Ghana mobile number: #{phone.inspect}" unless digits.match?(/\A0\d{9}\z/)

  digits
end

local_ghana_number("+233551234987") # => "0551234987"
local_ghana_number("0551234987")    # => "0551234987"
```

What was checked, and what it does not prove: on Paystack's **test** API, `0551234987`, `+233551234987`, `233551234987`, `551234987` and `055 123 4987` were all accepted and all answered `success`; `0551234` (too short) answered `failed`. Test mode is lenient, so it cannot tell you which form live mode requires. The docs' example for Kenya recommends the country code (`+254...`); for Ghana the docs show only the local form. Use the local form for Ghana and confirm the first live charge.

## What happens next (live mode, per Paystack's docs)

1. The response has `data.status` `pay_offline` and `data.display_text`. Show the text to the payer.
2. The payer approves on their phone. **They have 180 seconds**; after that the charge fails (a network-provider limit).
3. Paystack sends the `charge.success` webhook when it succeeds. Verify by reference before giving value.
4. If no webhook arrives after 180 seconds, call `transactions.verify(reference:)` (or `charges.check_pending(reference:)`). The reason a charge failed is in `data.message`.

```ruby
case response.status
when "pay_offline", "pending"
  # show response.display_text, then wait for the webhook (or poll check_pending)
when "success"
  # test mode answers like this at once; still verify
when "failed"
  # response.original_response.dig("data", "message") says why; start a new charge, new reference
end
```

## What test mode does not prove

On the test API a mobile money charge for each of `mtn`, `vod` and `atl`, on Paystack's test number `0551234987`, returned `success` immediately and `check_pending` agreed. That means the call shapes work. It says **nothing** about live behaviour: whether a given network accepts a merchant-started prompt for a given wallet, whether `pay_offline` and its display text look as documented, or how long approval takes. Treat live mobile money as unverified until the first real charge, and keep a fallback (such as emailing a payment link) for a network that refuses.

## Rules

- **Never give value on `pay_offline` or on the response alone.** Wait for the webhook and verify by reference with `paid?(amount:, currency:)`.
- **Create the `reference` before the call and store it.** After a timeout the charge may exist: verify the reference first, and never repeat the call blindly (the SDK does not retry writes after a timeout).
- **A new attempt is a new reference.** A `failed` charge is finished.
- **Check `data.status`, not `success?`** (see [paystack-sdk-charge-statuses](paystack-sdk-charge-statuses.md)).
