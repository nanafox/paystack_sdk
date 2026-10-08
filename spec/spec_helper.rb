# frozen_string_literal: true

require "debug"
require "webmock/rspec"
require_relative "../lib/paystack_sdk"
require_relative "support/paystack_contract"

WebMock.after_request { |request, _response| PaystackContract.record(request) }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Every request the SDK sends to api.paystack.co must conform to Paystack's OpenAPI spec.
  # Specs that send deliberately odd requests opt out with `contract: false`.
  config.before(:each) { PaystackContract.reset }
  config.after(:each) do |example|
    next if example.metadata[:contract] == false

    problems = PaystackContract.violations
    expect(problems).to be_empty, "Request does not match Paystack's OpenAPI spec:\n#{problems.map { |p| "  - #{p}" }.join("\n")}"
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
