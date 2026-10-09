# frozen_string_literal: true

require "open3"
require "rbconfig"

# RSpec (and Rails) load Ruby's `time` library, which hides a missing `require "time"`. These examples run the
# gem in a clean Ruby process with nothing but `require "paystack_sdk"`, the way a script or a worker without
# Rails would use it.
RSpec.describe "the gem in a plain Ruby process", contract: false do
  let(:lib) { File.expand_path("../lib", __dir__) }

  def run_ruby(code)
    Open3.capture3(RbConfig.ruby, "-I", lib, "-e", %(require "paystack_sdk"; #{code}))
  end

  it "formats a string date for a from: or to: filter without Time.iso8601 being missing" do
    stdout, stderr, status = run_ruby(<<~RUBY)
      include PaystackSdk::RequestHelpers
      puts format_datetime("2026-10-01", name: "from")
      puts format_datetime("2026-10-01T09:30:00Z", name: "to")
      puts format_datetime(Time.utc(2026, 10, 9, 12), name: "to")
      puts format_date("2026-10-01", name: "date")
    RUBY

    expect(stderr).to eq("")
    expect(status).to be_success
    expect(stdout.lines.map(&:chomp)).to eq(%w[2026-10-01 2026-10-01T09:30:00Z 2026-10-09T12:00:00Z 2026-10-01])
  end

  it "refuses a bad date with InvalidFormatError, not NoMethodError" do
    stdout, stderr, = run_ruby(<<~RUBY)
      include PaystackSdk::RequestHelpers
      begin
        format_datetime("not a date", name: "from")
      rescue PaystackSdk::InvalidFormatError => e
        puts "InvalidFormatError"
      end
    RUBY

    expect(stderr).to eq("")
    expect(stdout.chomp).to eq("InvalidFormatError")
  end

  it "builds a client and a resource with a date filter in a bare process (no request is sent)" do
    stdout, stderr, status = run_ruby(<<~RUBY)
      client = PaystackSdk::Client.new(secret_key: "sk_test_plain")
      puts client.transactions.method(:list).parameters.map(&:last).include?(:from)
      puts PaystackSdk::Webhook.sign("{}", "k").size
    RUBY

    expect(stderr).to eq("")
    expect(status).to be_success
    expect(stdout.lines.map(&:chomp)).to eq(["true", "128"])
  end
end
