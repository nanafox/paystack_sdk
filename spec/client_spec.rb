# frozen_string_literal: true

RSpec.describe PaystackSdk::Client do
  let(:secret_key) { "sk_test_xxx" }
  let(:connection_double) { instance_double(Faraday::Connection) }
  let(:client) do
    allow(Faraday).to receive(:new).and_return(connection_double)
    described_class.new(secret_key: secret_key)
  end

  describe "#initialize" do
    it "initializes a new client with the given API key" do
      expect(client).to be_a(PaystackSdk::Client)
    end

    it "sets the correct base URL" do
      allow(connection_double).to receive(:url_prefix).and_return(URI("https://api.paystack.co"))
      expect(client.instance_variable_get(:@connection).url_prefix.to_s.chomp("/")).to eq("https://api.paystack.co")
    end

    it "sets the correct headers" do
      headers = {
        "Authorization" => "Bearer #{secret_key}",
        "Content-Type" => "application/json",
        "User-Agent" => "paystack_sdk/#{PaystackSdk::VERSION}"
      }
      allow(connection_double).to receive(:headers).and_return(headers)

      connection_headers = client.instance_variable_get(:@connection).headers
      expect(connection_headers["Authorization"]).to eq("Bearer #{secret_key}")
      expect(connection_headers["Content-Type"]).to eq("application/json")
      expect(connection_headers["User-Agent"]).to eq("paystack_sdk/#{PaystackSdk::VERSION}")
    end
  end

  describe "#transactions" do
    it "returns an instance of Transactions resource" do
      transactions_double = instance_double(PaystackSdk::Resources::Transactions)
      allow(PaystackSdk::Resources::Transactions).to receive(:new).and_return(transactions_double)

      expect(client.transactions).to eq(transactions_double)
    end
  end

  describe "#charges" do
    it "returns an instance of Charges resource" do
      charges_double = instance_double(PaystackSdk::Resources::Charges)
      allow(PaystackSdk::Resources::Charges).to receive(:new).and_return(charges_double)

      expect(client.charges).to eq(charges_double)
    end
  end
end
