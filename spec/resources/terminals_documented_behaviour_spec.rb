# frozen_string_literal: true

# Behaviour the generated wire-shape specs do not exercise. The Paystack test account used to build
# this SDK (Ghana, GHS) has no Terminal access: on 2026-10-09 every GET (list, fetch, presence, event
# status) returned the 403 below, so the success bodies here are the docs' samples, not real responses.
# Send Event, Update, Commission and Decommission were never called (they act on physical devices).
RSpec.describe PaystackSdk::Resources::Terminals do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:terminals) { client.terminals }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:terminal) do
    {
      id: 30, serial_number: "033301504100A563877", device_make: nil, terminal_id: "2872S934",
      integration: 463433, domain: "live", name: "Damilola's Terminal", address: nil, status: "active"
    }
  end

  describe "an account without Terminal access" do
    it "returns Paystack's 403 as an unsuccessful response, not an exception" do
      stub_request(:get, "https://api.paystack.co/terminal").to_return(
        status: 403,
        headers: json,
        body: {
          status: false, message: "Sorry, this feature is not yet available in your country.",
          meta: {nextStep: "Try again later"}, type: "api_error", code: "unknown"
        }.to_json
      )

      response = terminals.list

      expect(response).not_to be_success
      expect(response.error_message).to eq("Sorry, this feature is not yet available in your country.")
    end
  end

  describe "#list" do
    it "pages with cursors and returns the terminals (docs sample)" do
      stub = stub_request(:get, "https://api.paystack.co/terminal")
        .with(query: {per_page: "1", next: "cursor_abc"})
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true, message: "Terminals retrieved successfully", data: [terminal],
            meta: {next: nil, previous: nil, perPage: 1}
          }.to_json
        )

      response = terminals.list(per_page: 1, next_cursor: "cursor_abc")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.data.first.terminal_id).to eq("2872S934")
    end
  end

  describe "#fetch_status" do
    it "says whether the terminal is online and available (docs sample)" do
      stub_request(:get, "https://api.paystack.co/terminal/2872S934/presence").to_return(
        status: 200,
        headers: json,
        body: {status: true, message: "Terminal status retrieved", data: {online: true, available: false}}.to_json
      )

      response = terminals.fetch_status(terminal_id: "2872S934")

      expect(response.online).to be(true)
      expect(response.available).to be(false)
    end
  end

  describe "#send_event" do
    it "refuses an action outside the documented ones without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { terminals.send_event(terminal_id: "2872S934", type: "invoice", action: "refund") }
        .to raise_error(PaystackSdk::InvalidValueError, /action/)
      expect(stub).not_to have_been_requested
    end
  end
end
