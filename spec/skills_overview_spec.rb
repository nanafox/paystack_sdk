# frozen_string_literal: true

require "paystack_sdk/skills"

# The overview skill states how the gem behaves. These examples run those statements, so the skill and the
# code cannot drift apart without a failure here.
RSpec.describe "what paystack-sdk-overview says", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_overview") }

  def stub_json(verb, path, body, status: 200)
    stub_request(verb, "https://api.paystack.co#{path}")
      .to_return(status: status, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  it "lists every resource accessor the client has" do
    text = File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-overview", "SKILL.md"))
    named = text[/Each Paystack resource is a method on the client: (.*?)\./m, 1].scan(/`(\w+)`/).flatten
    accessors = (PaystackSdk::Client.public_instance_methods(false) - [:live?, :connection]).map(&:to_s)

    expect(named.sort).to eq(accessors.sort)
  end

  it "reads PAYSTACK_SECRET_KEY when no key is given" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("PAYSTACK_SECRET_KEY").and_return("sk_live_x")

    expect(PaystackSdk::Client.new).to be_live
  end

  it "refuses a live key with sandbox_only, and does not call it live for a test key" do
    expect { PaystackSdk::Client.new(secret_key: "sk_live_x", sandbox_only: true) }.to raise_error(ArgumentError)
    expect(client).not_to be_live
  end

  it "uses keyword arguments, not a hash" do
    expect { client.transactions.initiate({email: "ama@example.com", amount: 5000}) }.to raise_error(ArgumentError)
  end

  it "sends per_page as perPage" do
    stub = stub_json(:get, "/transaction?perPage=5", {status: true, message: "ok", data: []})

    client.transactions.list(per_page: 5)

    expect(stub).to have_been_requested
  end

  it "refuses a blank value (MissingParamError) and dot segments (InvalidValueError) in a path" do
    expect { client.transactions.verify(reference: "..") }.to raise_error(PaystackSdk::InvalidValueError)
    expect { client.transactions.verify(reference: ".") }.to raise_error(PaystackSdk::InvalidValueError)
    expect { client.transactions.verify(reference: "") }.to raise_error(PaystackSdk::MissingParamError)
  end

  it "reads a response by dot access, hash access, paid? and status?" do
    stub_json(:get, "/transaction/verify/order-1042", {status: true, message: "ok",
      data: {status: "success", amount: 5000, currency: "GHS", customer: {email: "a@b.co"}}})

    response = client.transactions.verify(reference: "order-1042")

    expect(response.success?).to be(true)
    expect(response.status).to eq("success")
    expect(response.customer.email).to eq("a@b.co")
    expect(response[:amount]).to eq(5000)
    expect(response.paid?(amount: 5000, currency: "GHS")).to be(true)
    expect(response.paid?(amount: 4000, currency: "GHS")).to be(false)
    expect(response.status?(:success)).to be(true)
  end

  it "gives wrapped rows from each/first/last, plain hashes to map, and a plain Array from original_response" do
    stub_json(:get, "/transaction", {status: true, message: "ok", data: [{reference: "a"}, {reference: "b"}],
      meta: {total: 2, page: 1, pageCount: 1, perPage: 50}})

    response = client.transactions.list

    rows = []
    response.each { |row| rows << row.reference }
    expect(rows).to eq(%w[a b])
    expect(response.first.reference).to eq("a")
    expect(response.last.reference).to eq("b")
    seen = []
    response.map { |row| seen << row }
    expect(seen).to all(be_a(Hash))
    expect(seen.first.keys).to eq(["reference"])
    expect(response.original_response["data"]).to be_an(Array)
    expect(response.original_response["data"].map { |row| row["reference"] }).to eq(%w[a b])
    expect(response.meta.total).to eq(2)
  end

  it "returns an unsuccessful Response for another 4xx and raises for 401, 429 and 5xx" do
    stub_json(:get, "/transaction/verify/missing", {status: false, message: "Transaction reference not found"}, status: 404)
    response = client.transactions.verify(reference: "missing")
    expect(response.success?).to be(false)
    expect(response.error_message).to eq("Transaction reference not found")

    stub_json(:get, "/transaction/verify/bad-key", {status: false, message: "Invalid key"}, status: 401)
    expect { client.transactions.verify(reference: "bad-key") }.to raise_error(PaystackSdk::AuthenticationError)

    stub_json(:get, "/transaction/verify/limited", {status: false, message: "slow down"}, status: 429)
    expect { client.transactions.verify(reference: "limited") }.to raise_error(PaystackSdk::RateLimitError)

    stub_json(:get, "/transaction/verify/broken", {status: false, message: "boom"}, status: 500)
    expect { client.transactions.verify(reference: "broken") }.to raise_error(PaystackSdk::ServerError)
  end

  it "has every error inherit from PaystackSdk::Error, with TimeoutError a kind of ConnectionError" do
    [PaystackSdk::ValidationError, PaystackSdk::AuthenticationError, PaystackSdk::RateLimitError,
      PaystackSdk::ServerError, PaystackSdk::ConnectionError].each { |klass| expect(klass).to be < PaystackSdk::Error }
    expect(PaystackSdk::TimeoutError).to be < PaystackSdk::ConnectionError
  end

  it "does not retry a write after a timeout" do
    stub = stub_request(:post, "https://api.paystack.co/transaction/initialize").to_timeout

    expect { client.transactions.initiate(email: "ama@example.com", amount: 5000) }.to raise_error(PaystackSdk::TimeoutError)
    expect(stub).to have_been_requested.once
  end
end
