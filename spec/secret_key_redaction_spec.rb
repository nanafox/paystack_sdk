# frozen_string_literal: true

require "pp"

# Ruby's default `inspect` prints every instance variable, and the Faraday connection holds the secret key in
# its Authorization header. Logging a client, a resource or a connection (or `pp`, an error page, an error
# tracker that serialises locals) must never write the key out.
RSpec.describe "secret key redaction", contract: false do
  let(:key) { "sk_test_SECRETSECRETSECRET1234" }
  let(:client) { PaystackSdk::Client.new(secret_key: key, max_retries: 0) }

  def leaks?(text) = text.to_s.include?("SECRETSECRET")

  it "keeps the key out of inspect and pp of a Client" do
    expect(leaks?(client.inspect)).to be(false)
    expect(leaks?(client.pretty_inspect)).to be(false)
    expect(client.inspect).to eq("#<PaystackSdk::Client>")
  end

  it "keeps the key out of inspect and pp of every resource" do
    resources = PaystackSdk::Client.public_instance_methods(false) - [:live?, :connection, :inspect]
    expect(resources.size).to be > 20

    resources.each do |name|
      resource = client.public_send(name)
      expect(leaks?(resource.inspect)).to be(false), "#{name}.inspect leaks the key"
      expect(leaks?(resource.pretty_inspect)).to be(false), "#{name}.pretty_inspect leaks the key"
    end
    expect(client.transactions.inspect).to eq("#<PaystackSdk::Resources::Transactions>")
  end

  it "keeps the key out of the connection's inspect, pp and headers.inspect" do
    connection = client.connection

    expect(leaks?(connection.inspect)).to be(false)
    expect(leaks?(connection.pretty_inspect)).to be(false)
    expect(leaks?(connection.headers.inspect)).to be(false)
    expect(connection.headers.inspect).to include("[REDACTED]")
  end

  it "still sends the key" do
    expect(client.connection.headers["Authorization"]).to eq("Bearer #{key}")
    stub = stub_request(:get, "https://api.paystack.co/transaction/verify/r1")
      .with(headers: {"Authorization" => "Bearer #{key}"})
      .to_return(status: 200, body: {status: true, message: "ok", data: {status: "success"}}.to_json, headers: {"Content-Type" => "application/json"})

    client.transactions.verify(reference: "r1")

    expect(stub).to have_been_requested
    expect(client.live?).to be(false)
  end

  it "keeps the key out of the errors the SDK raises, their causes and a Response" do
    {
      timeout: -> { stub_request(:post, "https://api.paystack.co/transaction/initialize").to_timeout },
      failed: -> { stub_request(:post, "https://api.paystack.co/transaction/initialize").to_raise(Faraday::ConnectionFailed.new("boom")) },
      unauthorized: -> { stub_request(:post, "https://api.paystack.co/transaction/initialize").to_return(status: 401, body: {status: false, message: "Invalid key"}.to_json, headers: {"Content-Type" => "application/json"}) },
      server: -> { stub_request(:post, "https://api.paystack.co/transaction/initialize").to_return(status: 500, body: {status: false, message: "x"}.to_json, headers: {"Content-Type" => "application/json"}) }
    }.each do |label, arrange|
      arrange.call
      error = begin
        client.transactions.initiate(email: "ama@example.com", amount: 100)
      rescue PaystackSdk::Error => e
        e
      end
      expect(error).to be_a(PaystackSdk::Error), "#{label} did not raise"
      texts = [error.inspect, error.message, error.full_message(highlight: false), error.pretty_inspect, error.backtrace.join("\n"),
        error.cause&.inspect, error.cause&.message, error.cause&.cause&.inspect]
      expect(texts.map { |t| leaks?(t) }).to all(be(false)), "#{label} error leaks the key"
    end

    stub_request(:get, "https://api.paystack.co/transaction/verify/x")
      .to_return(status: 404, body: {status: false, message: "not found"}.to_json, headers: {"Content-Type" => "application/json"})
    response = client.transactions.verify(reference: "x")
    expect([response.inspect, response.pretty_inspect, response.error_details.to_s, response.original_response.to_s].map { |t| leaks?(t) }).to all(be(false))
  end

  it "redacts a connection built by the SDK for a resource created on its own" do
    resource = PaystackSdk::Resources::Transactions.new(secret_key: key)

    expect(leaks?(resource.inspect)).to be(false)
    expect(leaks?(resource.instance_variable_get(:@connection).inspect)).to be(false)
  end
end
