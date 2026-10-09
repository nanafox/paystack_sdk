# frozen_string_literal: true

require "paystack_sdk/skills"
require "date"

# paystack-sdk-payments states how the hosted checkout flow behaves through the gem. These examples run those
# statements, and run the skill's ConfirmPayment service against a stand-in model, so the skill cannot say
# something the code does not do. Responses are trimmed to the fields the skill reasons about, hence contract: false.
RSpec.describe "what paystack-sdk-payments says", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_payments") }
  let(:text) { File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-payments", "SKILL.md")) }
  let(:ruby_blocks) { text.scan(/^```ruby\n(.*?)^```/m).flatten }

  def stub_json(verb, path, body, status: 200)
    stub_request(verb, "https://api.paystack.co#{path}")
      .to_return(status: status, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  def keywords(method)
    PaystackSdk::Resources::Transactions.instance_method(method).parameters
      .filter_map { |kind, name| name if %i[keyreq key].include?(kind) }
  end

  describe "initiate" do
    it "takes every keyword the skill names, and none it says are missing" do
      table = text[/## Start the payment.*?(?=\n```ruby)/m]
      named = table.scan(/`(\w+):`/).flatten.map(&:to_sym)

      expect(named).to include(:email, :amount, :currency, :reference, :callback_url, :channels, :metadata, :plan, :label)
      expect(keywords(:initiate)).to include(*(named - %i[first_name last_name phone]))
      expect(keywords(:initiate)).not_to include(:first_name, :last_name, :phone)
      expect(PaystackSdk::Resources::Transactions.instance_method(:initiate).parameters).to include([:keyreq, :email], [:keyreq, :amount])
    end

    it "refuses 0, a Float and a String amount, and a malformed email, before sending anything" do
      [0, 50.0, "5000"].each do |amount|
        expect { client.transactions.initiate(email: "ama@example.com", amount: amount) }.to raise_error(PaystackSdk::InvalidValueError)
      end
      expect { client.transactions.initiate(email: "not-an-email", amount: 5000) }.to raise_error(PaystackSdk::ValidationError)
      expect(WebMock).not_to have_requested(:any, /api.paystack.co/)
    end

    it "accepts the currencies the skill lists and refuses another" do
      stub_json(:post, "/transaction/initialize", {status: true, message: "Authorization URL created", data: {}})

      %w[GHS KES NGN ZAR USD].each { |currency| client.transactions.initiate(email: "a@b.co", amount: 100, currency: currency) }
      expect { client.transactions.initiate(email: "a@b.co", amount: 100, currency: "XOF") }.to raise_error(PaystackSdk::ValidationError)
    end

    it "accepts letters, digits and - . = _ in a reference, a pay-<uuid> one among them, and refuses others" do
      stub_json(:post, "/transaction/initialize", {status: true, message: "Authorization URL created", data: {}})

      ["pay-#{SecureRandom.uuid}", "a.b=c_d-1"].each do |reference|
        expect(client.transactions.initiate(email: "a@b.co", amount: 100, reference: reference).success?).to be(true)
      end
      ["pay 1", "pay/1", "pay#1"].each do |reference|
        expect { client.transactions.initiate(email: "a@b.co", amount: 100, reference: reference) }.to raise_error(PaystackSdk::InvalidFormatError)
      end
    end

    it "sends channels as an Array and metadata as a JSON object, and returns authorization_url" do
      stub_json(:post, "/transaction/initialize", {status: true, message: "Authorization URL created",
        data: {authorization_url: "https://checkout.paystack.com/abc", access_code: "abc", reference: "pay-1"}})

      response = client.transactions.initiate(email: "ama@example.com", amount: 5000, currency: "GHS", reference: "pay-1",
        callback_url: "https://example.com/payments/callback", channels: ["card", "mobile_money"], metadata: {payment_id: 7})

      expect(response.authorization_url).to eq("https://checkout.paystack.com/abc")
      expect(WebMock).to have_requested(:post, "https://api.paystack.co/transaction/initialize").with { |req|
        body = JSON.parse(req.body)
        body["channels"] == ["card", "mobile_money"] && body["metadata"] == {"payment_id" => 7} && body["amount"] == 5000
      }
    end

    it "returns, does not raise, an unsuccessful Response for a duplicate reference" do
      stub_json(:post, "/transaction/initialize", {status: false, message: "Duplicate Transaction Reference"}, status: 400)

      response = client.transactions.initiate(email: "ama@example.com", amount: 100, currency: "GHS", reference: "pay-1")

      expect(response.success?).to be(false)
      expect(response.error_message).to eq("Duplicate Transaction Reference")
    end

    it "raises TimeoutError and does not retry initiate after a timeout" do
      stub = stub_request(:post, "https://api.paystack.co/transaction/initialize").to_timeout

      expect { client.transactions.initiate(email: "ama@example.com", amount: 100, reference: "pay-1") }.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.once
    end
  end

  describe "verify" do
    it "returns an unsuccessful Response with no data for an unknown reference, without raising" do
      stub_json(:get, "/transaction/verify/pay-unknown", {status: false, message: "Transaction reference not found."}, status: 400)

      response = client.transactions.verify(reference: "pay-unknown")

      expect(response.success?).to be(false)
      expect(response.error_message).to eq("Transaction reference not found.")
      expect(response.original_response["data"]).to be_nil
    end

    it "says paid? only for status success with the expected amount and currency, while success? stays true" do
      %w[abandoned failed ongoing pending reversed].each do |status|
        stub_json(:get, "/transaction/verify/r-#{status}", {status: true, message: "Verification successful", data: {status: status, amount: 100, currency: "GHS"}})
        response = client.transactions.verify(reference: "r-#{status}")
        expect(response.success?).to be(true)
        expect(response.paid?(amount: 100, currency: "GHS")).to be(false)
      end

      stub_json(:get, "/transaction/verify/r-ok", {status: true, message: "Verification successful", data: {status: "success", amount: 100, currency: "GHS"}})
      response = client.transactions.verify(reference: "r-ok")
      expect(response.paid?(amount: 100, currency: "GHS")).to be(true)
      expect(response.paid?(amount: 200, currency: "GHS")).to be(false)
      expect(response.paid?(amount: 100, currency: "NGN")).to be(false)
    end
  end

  it "raises NoMethodError on dot access to a missing key, while [] and the raw data give nil" do
    stub_json(:get, "/transaction/verify/r-1", {status: true, message: "Verification successful", data: {status: "abandoned"}})

    response = client.transactions.verify(reference: "r-1")

    expect { response.paid_at }.to raise_error(NoMethodError)
    expect(response[:paid_at]).to be_nil
    expect(response.original_response["data"]["paid_at"]).to be_nil
  end

  describe "ConfirmPayment (the skill's design advice, run against a stand-in model)" do
    let(:payment_class) do
      Class.new do
        attr_accessor :reference, :amount, :currency, :status, :paystack_status, :paystack_id, :paid_at,
          :gateway_response, :authorization_code, :locks

        class << self
          attr_accessor :rows

          def find_by(reference:) = rows.find { |row| row.reference == reference }
        end

        def initialize(**attrs)
          @locks = 0
          attrs.each { |key, value| public_send(:"#{key}=", value) }
        end

        def with_lock
          @locks += 1
          yield
        end

        def update!(**attrs) = attrs.each { |key, value| public_send(:"#{key}=", value) }
      end
    end

    let(:service) do
      code = ruby_blocks.find { |block| block.include?("class ConfirmPayment") }
      mod = Module.new
      mod.const_set(:Payment, payment_class)
      mod.module_eval(code)
      mod.const_get(:ConfirmPayment)
    end

    let(:payment) { payment_class.new(reference: "pay-1", amount: 5000, currency: "GHS", status: "pending") }

    before { payment_class.rows = [payment] }

    def verify_returns(data, status: 200, message: "Verification successful")
      stub_json(:get, "/transaction/verify/pay-1", {status: status == 200, message: message, data: data}, status: status)
    end

    it "marks a matching success paid, with its id, paid_at, gateway_response and reusable authorization code" do
      verify = verify_returns({id: 6641910154, status: "success", amount: 5000, currency: "GHS", paid_at: "2026-10-09T19:55:13.000Z",
        gateway_response: "Successful", authorization: {authorization_code: "AUTH_lqium3ok6i", reusable: true, last4: "4081"}})

      expect(service.call("pay-1", client: client)).to be(payment)

      expect(payment.status).to eq("paid")
      expect(payment.paystack_status).to eq("success")
      expect(payment.paystack_id).to eq(6641910154)
      expect(payment.paid_at).to eq("2026-10-09T19:55:13.000Z")
      expect(payment.gateway_response).to eq("Successful")
      expect(payment.authorization_code).to eq("AUTH_lqium3ok6i")
      expect(payment.locks).to eq(1)

      service.call("pay-1", client: client)
      expect(verify).to have_been_requested.once
    end

    it "keeps no authorization code when the authorization is not reusable" do
      verify_returns({id: 1, status: "success", amount: 5000, currency: "GHS", authorization: {authorization_code: "AUTH_abc", reusable: false}})

      service.call("pay-1", client: client)

      expect(payment.status).to eq("paid")
      expect(payment.authorization_code).to be_nil
    end

    it "does nothing inside the lock when another confirmation marked it paid first" do
      verify_returns({id: 1, status: "success", amount: 5000, currency: "GHS", authorization: {}})
      allow(payment).to receive(:with_lock) do |&block|
        payment.status = "paid" # the other caller won the race
        payment.paid_at = "first"
        block.call
      end

      service.call("pay-1", client: client)

      expect(payment.paid_at).to eq("first")
    end

    it "sends a success with the wrong amount to needs_review, not paid" do
      verify_returns({id: 1, status: "success", amount: 100, currency: "GHS", authorization: {}})

      service.call("pay-1", client: client)

      expect(payment.status).to eq("needs_review")
    end

    it "keeps an abandoned payment pending and marks a failed one failed" do
      verify_returns({status: "abandoned", amount: 5000, currency: "GHS", gateway_response: "The transaction was not completed", authorization: {}})
      service.call("pay-1", client: client)
      expect([payment.status, payment.paystack_status]).to eq(%w[pending abandoned])

      verify_returns({status: "failed", amount: 5000, currency: "GHS", gateway_response: "Incorrect PIN", authorization: {}})
      service.call("pay-1", client: client)
      expect([payment.status, payment.gateway_response]).to eq(["failed", "Incorrect PIN"])
    end

    it "leaves the payment pending when Paystack does not know the reference" do
      verify_returns(nil, status: 400, message: "Transaction reference not found.")

      service.call("pay-1", client: client)

      expect(payment.status).to eq("pending")
      expect(payment.locks).to eq(0)
    end

    it "returns nil, and calls nothing, for a reference that is not ours" do
      expect(service.call("pay-not-ours", client: client)).to be_nil
      expect(WebMock).not_to have_requested(:any, /api.paystack.co/)
    end
  end

  it "reads the reference from a signed charge.success webhook as the skill's handler does" do
    secret = "sk_test_payments"
    payload = {event: "charge.success", data: {reference: "pay-1", status: "success"}}.to_json

    event = PaystackSdk::Webhook.construct_event(payload: payload, signature: PaystackSdk::Webhook.sign(payload, secret), secret: secret)

    expect(event.event).to eq("charge.success")
    expect(event.data.reference).to eq("pay-1")
    expect(text).to include("ConfirmPayment.call(event.data.reference) if event.event == \"charge.success\"")
  end

  describe "looking transactions up" do
    it "returns an unsuccessful Response for an unknown ID on fetch" do
      stub_json(:get, "/transaction/1", {status: false, message: "Transaction not found"}, status: 404)

      response = client.transactions.fetch(id: 1)

      expect(response.success?).to be(false)
      expect(response.error_message).to eq("Transaction not found")
    end

    it "sends per_page as perPage and customer_id as customer, formats dates, and gives rows and meta" do
      stub = stub_request(:get, "https://api.paystack.co/transaction")
        .with(query: {"perPage" => "50", "page" => "1", "status" => "success", "from" => "2026-10-01", "to" => "2026-10-31", "customer" => "407293981"})
        .to_return(status: 200, headers: {"Content-Type" => "application/json"}, body: {status: true, message: "Transactions retrieved",
                                                                                        data: [{reference: "pay-1", status: "success"}], meta: {total: 1, perPage: 50, page: 1, pageCount: 1}}.to_json)

      page = client.transactions.list(per_page: 50, page: 1, status: "success", from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 31), customer_id: 407293981)

      expect(stub).to have_been_requested
      expect(page.original_response["data"].map { |row| row["reference"] }).to eq(["pay-1"])
      page.each { |row| expect(row.reference).to eq("pay-1") }
      expect([page.meta.total, page.meta.pageCount, page.meta.perPage]).to eq([1, 1, 50])
    end

    it "accepts a Time and an ISO 8601 String for from and to, and only the four statuses the skill lists" do
      stub_request(:get, %r{\Ahttps://api.paystack.co/transaction\?}).to_return(status: 200, body: {status: true, data: []}.to_json, headers: {"Content-Type" => "application/json"})

      client.transactions.list(from: Time.utc(2026, 10, 1, 9), to: "2026-10-31T23:59:59Z")
      expect(WebMock).to have_requested(:get, "https://api.paystack.co/transaction").with(query: {"from" => "2026-10-01T09:00:00Z", "to" => "2026-10-31T23:59:59Z"})

      %w[success failed abandoned reversed].each { |status| client.transactions.list(status: status) }
      expect { client.transactions.list(status: "pending") }.to raise_error(PaystackSdk::ValidationError)
      expect { client.transactions.list(from: "last week") }.to raise_error(PaystackSdk::InvalidFormatError)
    end
  end
end
