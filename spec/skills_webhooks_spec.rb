# frozen_string_literal: true

require "paystack_sdk/skills"
require "stringio"

# paystack-sdk-webhooks gives a framework-free receiver and a Rack app. This spec takes that Ruby out of the
# skill text and runs it, so the skill cannot show code that does not work. It also checks that every method
# and keyword the skill names exists. There is no Rails here: the Rack-style stub stands in for a controller.
RSpec.describe "what the webhooks skill says", contract: false do
  let(:text) { File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-webhooks", "SKILL.md")) }
  let(:blocks) { text.scan(/^```ruby\n(.*?)^```/m).flatten }
  let(:secret) { "sk_test_spec_secret" }
  let(:jobs) { [] }
  let(:store) do
    Class.new do
      def initialize
        @seen = {}
      end

      def claim(key)
        return false if @seen.key?(key)

        @seen[key] = true
      end
    end.new
  end

  def remove_skill_classes
    %i[PaystackReceiver PaystackWebhookApp].each do |name|
      Object.send(:remove_const, name) if Object.const_defined?(name)
    end
  end

  before do
    # Load the receiver and Rack app exactly as written in the skill.
    code = blocks.find { |b| b.include?("class PaystackReceiver") }
    expect(code).not_to be_nil
    remove_skill_classes
    TOPLEVEL_BINDING.eval(code)
  end

  after { remove_skill_classes }

  let(:receiver) { PaystackReceiver.new(secret: secret, store: store, enqueue: ->(payload) { jobs << payload }) }
  let(:app) { PaystackWebhookApp.new(receiver) }
  let(:body) { {event: "charge.success", data: {id: 302961, reference: "ref-1", amount: 5000, currency: "GHS"}}.to_json }

  # A Rack env, the way a server hands a POST to an app.
  def post(app, raw, signature: :none, ip: "52.31.139.75")
    env = {"REQUEST_METHOD" => "POST", "rack.input" => StringIO.new(raw), "REMOTE_ADDR" => ip}
    env["HTTP_X_PAYSTACK_SIGNATURE"] = signature unless signature == :none
    app.call(env).first
  end

  it "accepts a correctly signed delivery, answers 200 and enqueues one job" do
    expect(post(app, body, signature: PaystackSdk::Webhook.sign(body, secret))).to eq(200)
    expect(jobs.size).to eq(1)
    expect(jobs.first["event"]).to eq("charge.success")
  end

  it "rejects a body changed after signing, with 400 and no job" do
    signature = PaystackSdk::Webhook.sign(body, secret)
    expect(post(app, body.sub("5000", "1"), signature: signature)).to eq(400)
    expect(jobs).to be_empty
  end

  it "rejects a missing signature header" do
    expect(post(app, body)).to eq(400)
    expect(jobs).to be_empty
  end

  it "rejects a signature made with the wrong key" do
    expect(post(app, body, signature: PaystackSdk::Webhook.sign(body, "sk_test_other"))).to eq(400)
    expect(jobs).to be_empty
  end

  it "rejects a signed body that is not an event" do
    junk = "[1,2]"
    expect(post(app, junk, signature: PaystackSdk::Webhook.sign(junk, secret))).to eq(400)
    expect(jobs).to be_empty
  end

  it "answers 200 to a replayed delivery and enqueues it once" do
    signature = PaystackSdk::Webhook.sign(body, secret)
    expect(post(app, body, signature: signature)).to eq(200)
    expect(post(app, body, signature: signature)).to eq(200)
    expect(jobs.size).to eq(1)
  end

  it "treats a different event for the same data id as new" do
    refund = {event: "refund.processed", data: {id: 302961}}.to_json
    post(app, body, signature: PaystackSdk::Webhook.sign(body, secret))
    post(app, refund, signature: PaystackSdk::Webhook.sign(refund, secret))
    expect(jobs.map { |j| j["event"] }).to eq(%w[charge.success refund.processed])
  end

  it "falls back to data.reference when there is no data.id" do
    one = {event: "charge.success", data: {reference: "ref-9"}}.to_json
    sig = PaystackSdk::Webhook.sign(one, secret)
    post(app, one, signature: sig)
    post(app, one, signature: sig)
    expect(jobs.size).to eq(1)
    event = PaystackSdk::Webhook.construct_event(payload: one, signature: sig, secret: secret)
    expect(PaystackReceiver.key(event)).to eq("charge.success:ref-9")
  end

  it "handles an array data payload without raising" do
    one = {event: "subscription.expiring_cards", data: [{id: 1}]}.to_json
    expect(post(app, one, signature: PaystackSdk::Webhook.sign(one, secret))).to eq(200)
  end

  it "rewinds the body after reading it, so a framework can still use it" do
    input = StringIO.new(body)
    app.call({"rack.input" => input, "HTTP_X_PAYSTACK_SIGNATURE" => PaystackSdk::Webhook.sign(body, secret)})
    expect(input.read).to eq(body)
  end

  describe "the optional IP allow-list" do
    let(:receiver) do
      PaystackReceiver.new(secret: secret, store: store, enqueue: ->(p) { jobs << p },
        allowed_ips: PaystackSdk::Webhook::IP_ADDRESSES)
    end

    it "lets Paystack's addresses through and answers 403 to others, even with a valid signature" do
      signature = PaystackSdk::Webhook.sign(body, secret)
      expect(post(app, body, signature: signature, ip: "52.49.173.169")).to eq(200)
      expect(post(app, body, signature: signature, ip: "203.0.113.9")).to eq(403)
    end
  end

  describe "the local test snippet" do
    it "produces a signature the SDK verifies" do
      code = blocks.find { |b| b.include?("sk_test_example") }
      expect(code).not_to be_nil
      scope = binding
      scope.eval(code)

      expect(
        PaystackSdk::Webhook.valid_signature?(
          payload: scope.local_variable_get(:body), signature: scope.local_variable_get(:signature),
          secret: scope.local_variable_get(:secret)
        )
      ).to be(true)
    end
  end

  describe "the errors and calls the skill names" do
    it "uses the documented error classes" do
      expect(PaystackSdk::InvalidSignatureError.ancestors).to include(PaystackSdk::WebhookError, PaystackSdk::Error)
      expect(PaystackSdk::InvalidPayloadError.ancestors).to include(PaystackSdk::WebhookError)
      expect { PaystackSdk::Webhook.verify!(payload: "{}", signature: "no", secret: secret) }
        .to raise_error(PaystackSdk::InvalidSignatureError)
      expect { PaystackSdk::Webhook.valid_signature?(payload: {}, signature: "x", secret: secret) }.to raise_error(ArgumentError)
      expect { PaystackSdk::Webhook.valid_signature?(payload: "{}", signature: "x", secret: "") }.to raise_error(ArgumentError)
      bad = "nope"
      expect { PaystackSdk::Webhook.construct_event(payload: bad, signature: PaystackSdk::Webhook.sign(bad, secret), secret: secret) }
        .to raise_error(PaystackSdk::InvalidPayloadError)
    end

    it "has every Webhook method with the keywords the table names" do
      %i[valid_signature? verify! construct_event].each do |name|
        keywords = PaystackSdk::Webhook.method(name).parameters.map(&:last)
        expect(keywords).to include(:payload, :signature, :secret)
      end
      expect(PaystackSdk::Webhook.method(:sign).arity).to eq(2)
      expect(PaystackSdk::Webhook::Event.instance_methods).to include(:event, :payload, :data, :known?)
      expect(PaystackSdk::Resources::Transactions.instance_method(:verify).parameters).to include([:keyreq, :reference])
      expect(PaystackSdk::Response.instance_method(:paid?).parameters.map(&:last)).to include(:amount, :currency)
    end

    it "lists every event in Webhook::EVENTS, and says how many" do
      expect(PaystackSdk::Webhook::EVENTS.size).to eq(29)
      expect(text).to include("these 29")
      PaystackSdk::Webhook::EVENTS.each { |name| expect(text).to include("`#{name}`") }
    end
  end

  describe "verify by reference, as the job block shows" do
    let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_webhook") }

    it "is paid only when status, amount and currency match" do
      stub_request(:get, "https://api.paystack.co/transaction/verify/ref-1")
        .to_return(status: 200, headers: {"Content-Type" => "application/json"},
          body: {status: true, message: "Verification successful",
                 data: {status: "success", reference: "ref-1", amount: 5000, currency: "GHS"}}.to_json)

      response = client.transactions.verify(reference: "ref-1")
      expect(response.paid?(amount: 5000, currency: "GHS")).to be(true)
      expect(response.paid?(amount: 1, currency: "GHS")).to be(false)
      expect(response.paid?(amount: 5000, currency: "NGN")).to be(false)
    end
  end

  describe "the payload facts and the Webhook Events API section" do
    let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_webhook") }

    def key_for(event, data)
      body = {event: event, data: data}.to_json
      PaystackReceiver.key(PaystackSdk::Webhook.construct_event(payload: body, signature: PaystackSdk::Webhook.sign(body, secret), secret: secret))
    end

    it "keys a refund's pending and processed events differently although they share data.id" do
      same_id = {id: 18_633_077, status: "pending", transaction_reference: "t1", refund_reference: "r1"}

      expect(key_for("refund.pending", same_id)).not_to eq(key_for("refund.processed", same_id.merge(status: "processed")))
      expect(key_for("refund.processed", same_id)).to eq(key_for("refund.processed", same_id))
    end

    it "names the methods and keywords of client.webhook_events that the skill uses" do
      resource = PaystackSdk::Resources::WebhookEvents
      expect(resource.instance_method(:list).parameters.map(&:last)).to include(:status, :limit, :category, :event_type, :next_cursor, :previous)
      expect(resource.instance_method(:lookup).parameters).to include([:keyreq, :id])
      expect(resource.instance_method(:fetch).parameters).to include([:keyreq, :id])
      expect(resource.instance_method(:resend).parameters).to include([:keyreq, :ids])
      expect(resource.instance_method(:resend_matching).parameters).to include([:keyreq, :preview], [:key, :filters])
      expect(PaystackSdk::Resources::WebhookEvents::STATUSES).to eq(%w[Delivered Pending Failed])
    end

    it "reads an event's delivery state and the payload as the skill shows, with brackets for the nested data" do
      stub_request(:get, "https://api.paystack.co/integration/webhooks/events/6ac94b47fdad55440ef2066a")
        .to_return(status: 200, headers: {"Content-Type" => "application/json"}, body: {status: true, message: "Webhook Retrieved", data: {
          _id: "6ac94b47fdad55440ef2066a", status: "Pending", status_detail: "retrying", response_code: 404,
          merchant_response_body: "<html>", event_payload: {event: "refund.processed", data: {id: 18_633_077}}
        }}.to_json)

      event = client.webhook_events.fetch(id: "6ac94b47fdad55440ef2066a")

      expect(event.status_detail).to eq("retrying")
      expect(event.response_code).to eq(404)
      expect(event.merchant_response_body).to eq("<html>")
      expect(event.event_payload[:data].id).to eq(18_633_077)
    end

    it "says resend_matching needs preview, and refuses both cursors" do
      expect { client.webhook_events.resend_matching }.to raise_error(ArgumentError, /preview/)
      expect { client.webhook_events.list(next_cursor: "a", previous: "b") }.to raise_error(PaystackSdk::InvalidValueError)
      expect(text).to include("`preview: true` first")
    end

    it "keeps the skill's claims about where the payload shapes come from honest" do
      expect(text).to include("No webhook was received by code written for this skill")
      expect(text).to include("not what your endpoint will see in live mode")
    end
  end
end
