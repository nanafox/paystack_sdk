# frozen_string_literal: true

# Read-only calls against Paystack's real test API. Skipped unless PAYSTACK_TEST_SECRET_KEY is an sk_test_ key.
# `resend` and `resend_matching` are never called here: they make Paystack deliver webhooks to your endpoint.
RSpec.describe "Webhook Events API on the test API", :sandbox do
  key = ENV["PAYSTACK_TEST_SECRET_KEY"]

  before do
    skip "set PAYSTACK_TEST_SECRET_KEY to an sk_test_ key to run the sandbox suite" if key.to_s.empty?
    WebMock.allow_net_connect!
  end

  after { WebMock.disable_net_connect! }

  let(:events) { PaystackSdk::Client.new(secret_key: key, sandbox_only: true).webhook_events }

  it "lists events with the shape the resource documents, and pages with the cursor" do
    page = events.list(limit: 2)

    expect(page).to be_success
    rows = page.original_response["data"]
    skip "this test integration has no webhook events yet" if rows.empty?

    expect(rows.first.keys).to include("_id", "event_name", "status", "status_detail", "category", "category_row_id")
    expect(PaystackSdk::Resources::WebhookEvents::STATUSES).to include(rows.first["status"])
    expect(rows.size).to be <= 2
    next_cursor = page.original_response.dig("meta", "next")
    expect(events.list(limit: 2, next_cursor: next_cursor)).to be_success if next_cursor
  end

  it "fetches one event with the payload Paystack sent, and looks it up by its id" do
    rows = events.list(limit: 1).original_response["data"]
    skip "this test integration has no webhook events yet" if rows.empty?

    event = events.fetch(id: rows.first["_id"])

    expect(event).to be_success
    expect(event.original_response["data"]).to include("event_payload", "webhook_url", "merchant_response_body", "trials")
    expect(event.original_response.dig("data", "event_payload")).to include("event", "data")
    expect(events.lookup(id: rows.first["_id"])).to be_success
  end

  it "filters by status, and returns an unsuccessful Response for an event that does not exist" do
    expect(events.list(status: "Failed", limit: 1)).to be_success

    missing = events.fetch(id: "000000000000000000000000")
    expect(missing).not_to be_success
    expect(missing.error_message).to eq("Webhook not found")
  end
end
