# Banks

Everything takes keyword arguments. Account numbers and bank codes are strings, so leading zeros survive.

```ruby
# List banks. Filters are optional: country (ghana, kenya, nigeria, "south africa"), currency,
# type, gateway, per_page, page, use_cursor, next_cursor, previous, ...
response = paystack.banks.list(country: "nigeria", per_page: 50)
response.data.each { |bank| puts "#{bank["name"]}: #{bank["code"]}" }

# Resolve an account number to the name on the account
response = paystack.banks.resolve_account_number(account_number: "0022728151", bank_code: "063")
puts response.data["account_name"] if response.success?

# Validate a South African bank account before sending money
response = paystack.banks.validate_account(
  account_name: "Ama Mensah",
  account_number: "0123456789",
  account_type: "personal",
  bank_code: "632005",
  country_code: "ZA",
  document_type: "identityNumber",
  document_number: "1234567890123" # optional
)
```
