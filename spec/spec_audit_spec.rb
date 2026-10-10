# frozen_string_literal: true

require "open3"
require "rbconfig"

# bin/paystack-spec audit reads the endpoints the SDK calls out of the resource source. It must keep
# seeing a call whose path interpolates an escaped value, quotes and all.
RSpec.describe "bin/paystack-spec audit", contract: false do
  let(:script) { File.expand_path("../bin/paystack-spec", __dir__) }
  let(:audit) { Open3.capture3(RbConfig.ruby, script, "audit") }

  it "exits 0 when every endpoint the SDK calls is in the spec" do
    _, _, status = audit

    expect(status).to be_success
  end

  it "still sees calls whose path holds an interpolation with quotes inside it" do
    stdout, = audit
    covered = stdout[/SDK covers: (\d+)/, 1].to_i

    # 32 operations at the time this was written; it can only grow as endpoints are added
    expect(covered).to be >= 32
  end

  it "reports the documented-only operations the SDK implements, and fails for an endpoint in neither the spec nor that list" do
    stdout, = audit

    expect(stdout).to include("documented-only operation")
    expect(stdout).to include("GET /integration/webhooks/events")
    expect(stdout).to include("POST /integration/webhooks/events/resend-matching")
    expect(stdout).not_to include("likely a bug")
  end
end
