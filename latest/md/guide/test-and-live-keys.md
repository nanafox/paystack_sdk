# Test and Live Keys

A live key (`sk_live_...`) moves real money. `client.live?` tells you which kind a client holds, and `sandbox_only: true` makes the client refuse anything but a test key (`sk_test_...`) at construction, before any request is sent. Set it in staging and CI:

```ruby
client = PaystackSdk::Client.new(secret_key: ENV["PAYSTACK_SECRET_KEY"], sandbox_only: true)
# => ArgumentError if the key is a live key, or anything not recognisable as a test key

client.live? # => false
```

The error never includes the key. A pre-built Faraday connection is checked too (the key is read from its `Authorization` header).
