# frozen_string_literal: true

require "open3"
require "rbconfig"

# bin/paystack-spec docs-diff compares Paystack's docs pages with the OpenAPI spec. Its findings are
# leads for a person to settle, so what matters is that each kind of difference is reported.
RSpec.describe "bin/paystack-spec docs-diff", contract: false do
  let(:script) { File.expand_path("../bin/paystack-spec", __dir__) }
  let(:fixtures) { File.expand_path("fixtures/docs", __dir__) }
  let(:output) do
    stdout, = Open3.capture3(RbConfig.ruby, script, "docs-diff", "--spec", File.join(fixtures, "widget_openapi.yaml"), "--docs", fixtures)
    stdout
  end

  it "reports a parameter only the docs list, and one only the spec lists" do
    expect(output).to match(/docs-only\s+query `perPage`/)
    expect(output).to match(/spec-only\s+query `per_page`/)
    expect(output).to match(/spec-only\s+query `shape`/)
  end

  it "reports a type disagreement" do
    expect(output).to match(/type\s+query `color`: docs say string, spec says integer/)
  end

  it "reports a path variable renamed between the docs and the spec" do
    expect(output).not_to include("operation docs-only")
    expect(output).to match(/path\s+path variable is `widget_id` in the docs and `id` in the spec/)
  end

  it "lists spec operations that appear on no docs page" do
    expect(output).to include("Spec operations on no docs page (1)")
    expect(output).to include("GET /widget/unlisted")
  end

  it "reads an unlabelled parameter as required, unless its description gives a default" do
    expect(output).to match(/required\s+query `size`: docs say required, spec says optional/)
    expect(output).not_to match(/required\s+query `perPage`/)
    expect(output).not_to match(/required\s+query `color`/)
  end

  it "stops with a hint when no pages have been downloaded" do
    _, stderr, status = Open3.capture3(RbConfig.ruby, script, "docs-diff", "--docs", File.join(fixtures, "none"))

    expect(status).not_to be_success
    expect(stderr).to include("docs-fetch")
  end
end
