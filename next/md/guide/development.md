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

## Documentation site

The site at <https://nanafox.github.io/paystack_sdk/> is generated, not hand-written: the guides are this README split by section, the API reference comes from the YARD comments in `lib/`, and the AI skills are the ones the gem ships. There is one build per release (`/0.5.0/`), `latest` for the newest release and `next` from `main`. To build it locally (needs Node 22+):

```sh
cd docs
npm ci
npm run content          # writes docs/content from the README, lib/ and the skills
npm run dev              # live preview
npm run build            # the same build CI runs; fails on a dead link
```

Edit the README, a YARD comment or a skill to change a page; edit `docs/scripts/` to change how pages are generated. Pushing a `v*` tag publishes that release's docs; to rebuild an older release, run the Docs workflow by hand with its tag as `ref`.

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
