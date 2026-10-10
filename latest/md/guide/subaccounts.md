# Subaccounts

A subaccount is a settlement account that receives its share of the payments made to it, such as one per branch or partner. Pass its code (`ACCT_...`) as `subaccount` when you charge or initialize a transaction.

## Create a Subaccount

```ruby
# bank_code comes from paystack.banks.list (country: "ghana" lists GHS banks and the
# MTN, VOD and ATL mobile money codes). account_number is a string: leading zeros matter.
# percentage_charge is the percentage the main account keeps from each payment (0 to 100).
response = paystack.subaccounts.create(
  business_name: "Grace Chapel Accra",
  bank_code: "MTN",
  account_number: "0551234987",
  percentage_charge: 2.5,
  description: "Giving for the Accra branch",
  primary_contact_name: "Ama Mensah",
  primary_contact_email: "finance@gracechapel.example",
  primary_contact_phone: "0551234987"
)

if response.success?
  puts "Created #{response.data.subaccount_code} for #{response.data.account_name}"
else
  puts "Error: #{response.error_message}" # e.g. "Account details are invalid"
end
```

Paystack's docs name the bank field `bank_code`; its OpenAPI spec calls it `settlement_bank`. The API reads both and prefers `bank_code`, so the SDK sends `bank_code`.

## List and Fetch Subaccounts

```ruby
# Paystack's page pagination (default 50 per page)
paystack.subaccounts.list(per_page: 20, page: 2)

# Without active, the test API lists only active subaccounts. active: 0 lists the inactive
# ones. Paystack reads any value other than 1, true included, as inactive, so pass 1 or 0.
paystack.subaccounts.list(active: 0)

# Fetch by subaccount code or numeric ID
paystack.subaccounts.fetch(id_or_code: "ACCT_6uujpqtzmnufzkw")
```

## Update a Subaccount

```ruby
# Send only what changes
paystack.subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", percentage_charge: 3)

# Deactivate (or reactivate with active: true)
paystack.subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", active: false)

# A new settlement account: Paystack needs bank_code and account_number together
paystack.subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", bank_code: "040100", account_number: "1234567890123")
```
