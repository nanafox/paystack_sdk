# frozen_string_literal: true

# Webhook Events API: documented by Paystack but not in its OpenAPI spec, so the requests are checked against
# spec/fixtures/docs_only_operations.yml instead. The bodies below follow what the test API returned.
RSpec.describe PaystackSdk::Resources::WebhookEvents do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_webhookevents") }
  let(:events) { client.webhook_events }
  let(:base) { "https://api.paystack.co/integration/webhooks/events" }

  let(:event) do
    {"_id" => "6ac94b47fdad55440ef2066a", "domain" => "test", "category" => "refund", "category_row_id" => 18_633_077,
     "event_name" => "refund.processed", "integration" => 2_047_140, "status" => "Pending", "status_detail" => "retrying",
     "response_code" => 404, "webhook_url_code" => nil, "trial_count" => 7,
     "createdAt" => "2026-10-09T20:15:03.000Z", "updatedAt" => "2026-10-09T22:13:10.000Z"}
  end
  let(:detail) do
    event.merge("event_description" => "Refund status for transaction ref: null", "webhook_url" => "https://example.com/hooks",
      "event_payload" => {"event" => "refund.processed", "data" => {"id" => 18_633_077, "status" => "processed"}},
      "merchant_response_body" => "{}", "trials" => [])
  end

  def json(body, status: 200) = {status: status, body: body.to_json, headers: {"Content-Type" => "application/json"}}

  it "is available as client.webhook_events and is not a generated resource" do
    expect(client.webhook_events).to be_a(described_class)
    expect(File.read(File.expand_path("../../lib/paystack_sdk/resources/webhook_events.rb", __dir__))).not_to include("scaffold-digest")
  end

  describe "#list" do
    it "gets the events, with the page cursors in meta" do
      stub = stub_request(:get, base).to_return(json({status: true, message: "Webhooks listed", data: [event],
        meta: {next: "eyJvaWQiOiI2YWM5In0", previous: nil, perPage: 50}}))

      response = events.list

      expect(stub).to have_been_requested
      expect(response.success?).to be(true)
      expect(response.first.event_name).to eq("refund.processed")
      expect(response.original_response["meta"]).to include("next" => "eyJvaWQiOiI2YWM5In0", "perPage" => 50)
    end

    it "sends the filters under the names Paystack documents, next_cursor as next" do
      stub = stub_request(:get, base)
        .with(query: {"category" => "transactions", "event_type" => "charge.success", "status" => "Failed",
                      "category_row_id" => "6641907106", "limit" => "20", "next" => "abc"})
        .to_return(json({status: true, message: "Webhooks listed", data: []}))

      events.list(category: "transactions", event_type: "charge.success", status: "Failed",
        category_row_id: 6_641_907_106, limit: 20, next_cursor: "abc")

      expect(stub).to have_been_requested
    end

    it "formats from and to as Paystack expects" do
      stub = stub_request(:get, base).with(query: hash_including("from" => "2026-10-01", "to" => "2026-10-09T12:00:00Z"))
        .to_return(json({status: true, message: "Webhooks listed", data: []}))

      events.list(from: Date.new(2026, 10, 1), to: Time.utc(2026, 10, 9, 12))

      expect(stub).to have_been_requested
    end

    it "sends the previous cursor as previous" do
      stub = stub_request(:get, base).with(query: {"previous" => "xyz"}).to_return(json({status: true, message: "ok", data: []}))

      events.list(previous: "xyz")

      expect(stub).to have_been_requested
    end

    it "refuses a status Paystack does not know, a bad limit, and both cursors, before sending anything" do
      any = stub_request(:get, /api\.paystack\.co/)

      expect { events.list(status: "bogus") }.to raise_error(PaystackSdk::InvalidValueError, /Delivered, Pending, Failed/)
      expect { events.list(limit: 0) }.to raise_error(PaystackSdk::InvalidValueError)
      expect { events.list(limit: "abc") }.to raise_error(PaystackSdk::InvalidValueError)
      expect { events.list(next_cursor: "a", previous: "b") }.to raise_error(PaystackSdk::InvalidValueError, /previous/)
      expect(any).not_to have_been_requested
    end

    it "refuses a date that is not ISO 8601 before sending" do
      expect { events.list(from: "garbage") }.to raise_error(PaystackSdk::InvalidFormatError, /from/)
    end
  end

  describe "#lookup" do
    it "sends the id as reference, the name the docs give it" do
      stub = stub_request(:get, "#{base}/lookup").with(query: {"reference" => "6641907106"})
        .to_return(json({status: true, message: "Webhook Retrieved", data: event}))

      response = events.lookup(id: 6_641_907_106)

      expect(stub).to have_been_requested
      expect(response.event_name).to eq("refund.processed")
    end

    it "returns an unsuccessful Response when nothing matches (404 Webhook not found)" do
      stub_request(:get, "#{base}/lookup").with(query: {"reference" => "0"})
        .to_return(json({status: false, message: "Webhook not found"}, status: 404))

      response = events.lookup(id: "0")

      expect(response.success?).to be(false)
      expect(response.error_message).to eq("Webhook not found")
    end

    it "needs an id" do
      expect { events.lookup(id: "") }.to raise_error(PaystackSdk::MissingParamError)
      expect { events.lookup }.to raise_error(ArgumentError)
    end
  end

  describe "#fetch" do
    it "returns the event with the payload Paystack sent and what the endpoint answered" do
      stub_request(:get, "#{base}/6ac94b47fdad55440ef2066a").to_return(json({status: true, message: "Webhook Retrieved", data: detail}))

      response = events.fetch(id: "6ac94b47fdad55440ef2066a")

      expect(response.event_payload.event).to eq("refund.processed")
      # a key named data is read with brackets: Response#data returns the response itself
      expect(response.event_payload[:data].id).to eq(18_633_077)
      expect(response.original_response.dig("data", "event_payload", "data", "status")).to eq("processed")
      expect(response.merchant_response_body).to eq("{}")
      expect(response.trials).not_to be_nil
    end

    it "is 404 Webhook not found as an unsuccessful Response, and cannot be steered to another endpoint" do
      stub_request(:get, "#{base}/000000000000000000000000").to_return(json({status: false, message: "Webhook not found"}, status: 404))

      expect(events.fetch(id: "000000000000000000000000").success?).to be(false)
      expect { events.fetch(id: "..") }.to raise_error(PaystackSdk::InvalidValueError)
      expect { events.fetch(id: "") }.to raise_error(PaystackSdk::MissingParamError)
    end
  end

  describe "#resend" do
    it "posts the ids" do
      stub = stub_request(:post, "#{base}/resend").with(body: {ids: %w[a b]}.to_json)
        .to_return(json({status: true, message: "Webhooks resent", data: {}}))

      events.resend(ids: %w[a b])

      expect(stub).to have_been_requested
    end

    it "refuses something that is not a non-empty Array of strings, or more than 100, before sending" do
      any = stub_request(:post, /api\.paystack\.co/)

      [nil, [], "a", [1], [""], ["a", nil], Array.new(101) { |i| "id#{i}" }].each do |bad|
        expect { events.resend(ids: bad) }.to raise_error(PaystackSdk::InvalidValueError, /ids/), "#{bad.inspect} was accepted"
      end
      expect(any).not_to have_been_requested
      expect { events.resend(ids: Array.new(100) { |i| "id#{i}" }) }.not_to raise_error
    end

    it "is not retried after a timeout" do
      stub = stub_request(:post, "#{base}/resend").to_timeout

      expect { events.resend(ids: ["a"]) }.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.once
    end
  end

  describe "#resend_matching" do
    it "makes you say whether it is a preview: preview: has no default" do
      expect { events.resend_matching }.to raise_error(ArgumentError, /preview/)
      expect { events.resend_matching(preview: "true") }.to raise_error(PaystackSdk::InvalidValueError, /true.*false/)
      expect { events.resend_matching(preview: nil) }.to raise_error(PaystackSdk::InvalidValueError)
    end

    it "sends preview as a query parameter and the filters in the body" do
      stub = stub_request(:post, "#{base}/resend-matching?preview=true")
        .with(body: {filters: {"status" => "Failed", "event_type" => "charge.success", "from" => "2026-10-01"}}.to_json)
        .to_return(json({status: true, message: "ok", data: {count: 3}}))

      events.resend_matching(preview: true, filters: {status: "Failed", event_type: "charge.success", from: Date.new(2026, 10, 1)})

      expect(stub).to have_been_requested
    end

    it "sends an empty body with no filters, and preview=false when you mean to resend" do
      stub = stub_request(:post, "#{base}/resend-matching?preview=false").with(body: "{}")
        .to_return(json({status: true, message: "ok", data: {}}))

      events.resend_matching(preview: false)

      expect(stub).to have_been_requested
    end

    it "refuses an unknown filter, a bad status or date, and a non-Hash, before sending" do
      any = stub_request(:post, /api\.paystack\.co/)

      expect { events.resend_matching(preview: true, filters: {color: "red"}) }.to raise_error(PaystackSdk::InvalidValueError, /color/)
      expect { events.resend_matching(preview: true, filters: {status: "bogus"}) }.to raise_error(PaystackSdk::InvalidValueError)
      expect { events.resend_matching(preview: true, filters: {from: "garbage"}) }.to raise_error(PaystackSdk::InvalidFormatError)
      expect { events.resend_matching(preview: true, filters: "status=Failed") }.to raise_error(PaystackSdk::ValidationError)
      expect(any).not_to have_been_requested
    end
  end

  describe "the contract check for operations the spec lacks" do
    it "flags a parameter the docs do not list for the operation" do
      problems = PaystackContract.check(method: "get", url: "#{base}?status=Failed&colour=red", body: nil,
        headers: {"Authorization" => "Bearer sk_test_x"})

      expect(problems).to eq(["unknown query parameter `colour` (the docs list #{%w[category event_type status category_row_id from to limit next previous].inspect})"])
    end

    it "prefers the literal lookup path to the {id} one, and accepts a request that conforms" do
      ok = PaystackContract.check(method: "get", url: "#{base}/lookup?reference=1", body: nil, headers: {"Authorization" => "Bearer sk_test_x"})
      id = PaystackContract.check(method: "get", url: "#{base}/6ac94b47fdad55440ef2066a", body: nil, headers: {"Authorization" => "Bearer sk_test_x"})

      expect(ok).to be_empty
      expect(id).to be_empty
    end

    it "flags a body parameter the docs do not list" do
      problems = PaystackContract.check(method: "post", url: "#{base}/resend", body: {ids: ["a"], all: true}.to_json,
        headers: {"Authorization" => "Bearer sk_test_x", "Content-Type" => "application/json"})

      expect(problems.join).to include("unknown body parameter `all`")
    end
  end
end
