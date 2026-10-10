# Dedicated Virtual Accounts

A dedicated virtual account is a bank account number Paystack issues to one of your customers, so they can pay you by bank transfer. Paystack's docs offer it to Nigerian and Ghanaian businesses (`NGN` and `GHS`), and it has to be enabled for your business first: until it is, every call returns an unsuccessful response with status 403 and the message "Dedicated NUBAN is not available for your business".

## Create or Assign an Account

```ruby
# Which banks can issue an account for your integration (e.g. "wema-bank", "titan-paystack")
paystack.dedicated_virtual_accounts.fetch_bank_providers

# For a customer you already created (their code or ID)
response = paystack.dedicated_virtual_accounts.create(customer: "CUS_xnxdt6s1zg1f4nx", preferred_bank: "wema-bank")

if response.success?
  puts "#{response.data.account_number} at #{response.data.bank.name}"
else
  puts "Error: #{response.error_message}"
end

# Or create the customer, validate them and assign an account in one call. Paystack's docs
# show the reply "Assign dedicated account in progress", with no account in it.
paystack.dedicated_virtual_accounts.assign(
  email: "ama@example.com",
  first_name: "Ama",
  last_name: "Mensah",
  phone: "+2348100000000",
  preferred_bank: "wema-bank",
  country: "NG"
)
```

## List, Fetch, Requery and Deactivate

```ruby
paystack.dedicated_virtual_accounts.list(active: true, currency: "NGN", provider_slug: "wema-bank")

# By the account's numeric ID
paystack.dedicated_virtual_accounts.fetch(dedicated_account_id: 1234553)

# Ask Paystack to check the account for transfers it has not recorded yet
paystack.dedicated_virtual_accounts.requery(account_number: "1234567890", provider_slug: "wema-bank", date: Date.new(2026, 10, 9))

paystack.dedicated_virtual_accounts.deactivate(dedicated_account_id: 1234553)
```

## Split Payments on an Account

```ruby
# Send payments into the account through a split (or a single subaccount:)
paystack.dedicated_virtual_accounts.add_split(account_number: "0033322211", split_code: "SPL_e7jnRLtzla")

# And stop splitting them
paystack.dedicated_virtual_accounts.remove_split(account_number: "0033322211")
```

`create` and `assign` also take `split_code:` or `subaccount:` to set a split when the account is made.
