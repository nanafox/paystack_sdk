# frozen_string_literal: true

require "paystack_sdk/skills"

# paystack-sdk-refunds states how refunds behave in the gem. These examples run those statements.
RSpec.describe "what paystack-sdk-refunds says", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_refunds") }
  let(:text) { File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-refunds", "SKILL.md")) }

  def stub_json(verb, path, body, status: 200)
    stub_request(verb, "https://api.paystack.co#{path}")
      .to_return(status: status, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  def helpers
    code = text[/```ruby\n(# Returns the refunds Paystack already has.*?)^```/m, 1]
    expect(code).not_to be_nil
    mod = Module.new
    mod.module_eval(code)
    Object.new.extend(mod)
  end

  it "names only keywords the refunds methods have" do
    {
      create: %i[transaction amount currency customer_note merchant_note],
      fetch: %i[id],
      list: %i[per_page page from to transaction_id],
      retry_with_customer_details: %i[id refund_account_details]
    }.each do |name, given|
      keywords = PaystackSdk::Resources::Refunds.instance_method(name).parameters.map(&:last)
      expect(keywords).to match_array(given)
      expect(text).to include("#{name}(") if name != :create
    end
  end

  it "sends a full refund without an amount and a partial one with it" do
    stub = stub_json(:post, "/refund", {status: true, message: "Refund has been queued for processing", data: {id: 1, status: "pending", amount: 200}})

    client.refunds.create(transaction: "order-1042")
    client.refunds.create(transaction: 6_641_908_848, amount: 200, currency: "GHS", customer_note: "a", merchant_note: "b")

    expect(WebMock).to have_requested(:post, "https://api.paystack.co/refund").with(body: {transaction: "order-1042"})
    expect(WebMock).to have_requested(:post, "https://api.paystack.co/refund")
      .with(body: {transaction: 6_641_908_848, amount: 200, currency: "GHS", customer_note: "a", merchant_note: "b"})
    expect(stub).to have_been_requested.twice
  end

  it "validates amount and currency before sending" do
    expect { client.refunds.create(transaction: "r", amount: 0) }.to raise_error(PaystackSdk::ValidationError)
    expect { client.refunds.create(transaction: "r", amount: 1.5) }.to raise_error(PaystackSdk::ValidationError)
    expect { client.refunds.create(transaction: "r", currency: "XXX") }.to raise_error(PaystackSdk::ValidationError)
    expect { client.refunds.create(transaction: "") }.to raise_error(PaystackSdk::ValidationError)
  end

  it "sends transaction_id as transaction and per_page as perPage" do
    stub_json(:get, "/refund?transaction=55&perPage=5", {status: true, message: "Refunds retrieved", data: []})

    client.refunds.list(transaction_id: 55, per_page: 5)

    expect(WebMock).to have_requested(:get, "https://api.paystack.co/refund?transaction=55&perPage=5")
  end

  it "returns an unsuccessful Response, not an exception, for a rejected refund" do
    stub_json(:post, "/refund", {status: false, message: "Total refund amount cannot exceed original transaction amount"}, status: 400)

    response = client.refunds.create(transaction: "r1")

    expect(response.success?).to be(false)
    expect(response.error_message).to include("cannot exceed")
  end

  it "does not retry a create after a timeout" do
    stub = stub_request(:post, "https://api.paystack.co/refund").to_timeout

    expect { client.refunds.create(transaction: "r1") }.to raise_error(PaystackSdk::TimeoutError)
    expect(stub).to have_been_requested.once
  end

  it "lists the refund webhook events the skill names, all in Webhook::EVENTS, and says needs-attention is not" do
    %w[refund.pending refund.processing refund.processed refund.failed].each do |event|
      expect(text).to include(event)
      expect(PaystackSdk::Webhook::EVENTS).to include(event)
    end
    expect(PaystackSdk::Webhook::EVENTS).not_to include("refund.needs-attention")
  end

  describe "the helper code" do
    it "finds the refunds for a payment through the numeric transaction id" do
      stub_json(:get, "/transaction/verify/order-1", {status: true, message: "Verification successful", data: {id: 77, status: "reversal-pending"}})
      stub_json(:get, "/refund?transaction=77", {status: true, message: "Refunds retrieved", data: [{id: 1, amount: 100, status: "pending"}]})

      rows = helpers.refunds_for_payment(client, "order-1")

      expect(rows).to eq([{"id" => 1, "amount" => 100, "status" => "pending"}])
    end

    it "returns nil when the payment cannot be verified" do
      stub_json(:get, "/transaction/verify/nope", {status: false, message: "Transaction reference not found"}, status: 404)

      expect(helpers.refunds_for_payment(client, "nope")).to be_nil
    end

    it "does not count failed refunds and refuses to go past the payment or under 100 pesewas" do
      rows = [{"amount" => 100, "status" => "pending"}, {"amount" => 100, "status" => "failed"}]
      h = helpers

      expect(h.refunded_amount(rows)).to eq(100)
      expect(h.can_refund?(rows, 300, 200)).to be(true)
      expect(h.can_refund?(rows, 300, 201)).to be(false)
      expect(h.can_refund?(rows, 300, 50)).to be(false)
    end
  end

  it "says a refunded payment no longer passes paid?" do
    stub_json(:get, "/transaction/verify/order-1", {status: true, message: "ok", data: {status: "reversal-pending", amount: 300, currency: "GHS"}})

    expect(client.transactions.verify(reference: "order-1").paid?(amount: 300, currency: "GHS")).to be(false)
  end
end
