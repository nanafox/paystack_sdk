# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Style and Linting

This project uses [StandardRB](https://github.com/standardrb/standard) for code style and linting.

Add to your Gemfile (if not already present):

```ruby
gem "standard"
```

- Lint: `bundle exec standardrb`
- Auto-fix: `bundle exec standardrb --fix`
- Via Rake: `bundle exec rake standard`
- Default task (runs specs + standard): `bundle exec rake`

If you encounter cache permission issues locally, you can disable caching: `bundle exec standardrb --no-cache`.

## Testing

The SDK includes comprehensive test coverage with consistent response format handling. All test specifications use string keys with hashrocket notation (`=>`) to match the actual format returned by the Paystack API:

```ruby
# Example test response format
.and_return(Faraday::Response.new(status: 200, body: {
  "status" => true,
  "message" => "Transaction initialized",
  "data" => {
    "authorization_url" => "https://checkout.paystack.com/abc123",
    "access_code" => "access_code_123",
    "reference" => "ref_123"
  }
}))
```

Tests also validate specific error types to ensure proper exception handling:

```ruby
# Testing specific error types
expect { customers.set_risk_action(customer: "CUS_123", risk_action: "block") }
  .to raise_error(PaystackSdk::InvalidValueError, /risk_action/i)
```

## Installation and Release

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

To release a new version, update the version number in `version.rb`, and then run:

```bash
bundle exec rake release
```

This will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).
