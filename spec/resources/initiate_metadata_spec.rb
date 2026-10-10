# frozen_string_literal: true

# Paystack accepts metadata as an object or as a stringified JSON object but stores them differently: an
# object turns a nested number into a string. initiate sends it stringified, as charge_authorization does,
# so both keep the types of the values (checked against the test API, 2026-10-09).
RSpec.describe "transaction metadata on the wire", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_metadata") }
  let(:metadata) { {branch: "Osu", fund: "tithe", count: 42} }

  def sent_body(path)
    body = nil
    stub_request(:post, "https://api.paystack.co#{path}").to_return do |request|
      body = JSON.parse(request.body)
      {status: 200, body: {status: true, message: "ok", data: {}}.to_json, headers: {"Content-Type" => "application/json"}}
    end
    yield
    body
  end

  it "sends initiate's metadata as a JSON string that keeps the number a number" do
    body = sent_body("/transaction/initialize") do
      client.transactions.initiate(email: "ama@example.com", amount: 5000, currency: "GHS", metadata: metadata)
    end

    expect(body["metadata"]).to be_a(String)
    expect(JSON.parse(body["metadata"])).to eq("branch" => "Osu", "fund" => "tithe", "count" => 42)
  end

  it "sends charge_authorization's metadata the same way" do
    body = sent_body("/transaction/charge_authorization") do
      client.transactions.charge_authorization(email: "ama@example.com", amount: 5000, currency: "GHS",
        authorization_code: "AUTH_abc123", metadata: metadata)
    end

    expect(body["metadata"]).to be_a(String)
    expect(JSON.parse(body["metadata"])["count"]).to eq(42)
  end

  it "passes a string you already stringified through unchanged, and sends nothing for nil" do
    given = JSON.generate(metadata)
    body = sent_body("/transaction/initialize") do
      client.transactions.initiate(email: "ama@example.com", amount: 5000, metadata: given)
    end
    expect(body["metadata"]).to eq(given)

    none = sent_body("/transaction/initialize") do
      client.transactions.initiate(email: "ama@example.com", amount: 5000)
    end
    expect(none).not_to have_key("metadata")
  end
end
