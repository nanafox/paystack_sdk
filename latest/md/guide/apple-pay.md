# Apple Pay

Apple Pay on Paystack needs each domain (or subdomain) that shows the Apple Pay button to be registered on your integration. The accessor is `paystack.apple_pay`.

## List Registered Domains

```ruby
response = paystack.apple_pay.list_domains

# An account with no domains answers "Apple Pay registered domains retrieved" with an empty list
puts response.data.domainNames.inspect # => []
```

`list_domains` was checked against the Paystack test API. Paystack's docs mark `use_cursor` required, but the API answers without it (and with `use_cursor=true`), so the SDK keeps it optional. Cursor pagination (`next_cursor:`, sent as `next`, and `previous:`) could not be exercised, because the test account has no domains.

## Register and Unregister a Domain (unverified)

```ruby
paystack.apple_pay.register_domain(domain_name: "pay.example.com")
paystack.apple_pay.unregister_domain(domain_name: "pay.example.com")
```

**These two methods have not been called against the Paystack API.** They change the account's Apple Pay domain configuration, which is account-wide and public and may reach live mode even with a test key (`sk_test_`), so they were deliberately not tried. They follow Paystack's docs and OpenAPI spec: one domain per call, sent as `domainName`, and `unregister_domain` is a `DELETE` that carries the domain in a JSON body. How Paystack answers (and whether it reads a body on `DELETE`) is unconfirmed. Try them with a domain you own, and check the result in the dashboard.
