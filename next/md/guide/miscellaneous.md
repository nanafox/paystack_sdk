# Miscellaneous

```ruby
# Details of a card BIN (6 or 8 digits, as a string)
response = paystack.miscellaneous.resolve_card_bin(bin: "539983")
puts response.data["bank"] if response.success?

# Supported countries
paystack.miscellaneous.list_countries

# States for address verification (country is required)
paystack.miscellaneous.list_states(country: "CA")
```
