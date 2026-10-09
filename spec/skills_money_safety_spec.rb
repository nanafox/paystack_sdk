# frozen_string_literal: true

require "bigdecimal"
require "ostruct"
require "paystack_sdk/skills"

# The money-safety skill states how the gem behaves. These examples run those statements and the helper
# code the skill gives, so the skill and the code cannot drift apart without a failure here.
RSpec.describe "what paystack-sdk-money-safety says", contract: false do
  key = "sk_test_moneysafetyspeckey"

  let(:text) { File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-money-safety", "SKILL.md")) }
  let(:client) { PaystackSdk::Client.new(secret_key: key, retry_interval: 0) }
  let(:payment) { OpenStruct.new(reference: "gift-1", amount: 5000, currency: "GHS", email: "ama@example.com") }
  let(:helpers) do
    code = text.scan(/^```ruby\n(.*?)^```/m).flatten.grep(/^def /)
    expect(code.size).to eq(2)
    Object.new.extend(Module.new { code.each { |definition| module_eval(definition) } })
  end

  def stub_json(verb, path, body, status: 200)
    stub_request(verb, "https://api.paystack.co#{path}")
      .to_return(status: status, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  def verified(status: "success", amount: 5000, currency: "GHS", email: "ama@example.com")
    stub_json(:get, "/transaction/verify/gift-1", {status: true, message: "Verification successful",
      data: {status: status, amount: amount, currency: currency, reference: "gift-1", customer: {email: email}}})
  end

  describe "amounts" do
    it "converts a decimal price to minor units as the skill shows" do
      expect((BigDecimal("50.00") * 100).to_i).to eq(5000)
      expect((BigDecimal("0.10") * 100).to_i).to eq(10)
    end

    it "refuses a Float, a String, zero and a negative amount before sending anything" do
      [100.5, 100.0, "100", "100.50", 0, -100].each do |amount|
        expect { client.transactions.initiate(email: "ama@example.com", amount: amount, currency: "GHS") }
          .to raise_error(PaystackSdk::InvalidValueError)
      end
      expect(a_request(:any, /api.paystack.co/)).not_to have_been_made
    end
  end

  describe "payment_outcome" do
    it "is :paid only when status, amount, currency and email all match what you stored" do
      verified
      expect(helpers.payment_outcome(client, payment)).to eq(:paid)
    end

    it "is :mismatch when the amount, the currency or the email differ" do
      verified(amount: 4000)
      expect(helpers.payment_outcome(client, payment)).to eq(:mismatch)
      verified(currency: "NGN")
      expect(helpers.payment_outcome(client, payment)).to eq(:mismatch)
      verified(email: "someone@else.com")
      expect(helpers.payment_outcome(client, payment)).to eq(:mismatch)
    end

    it "compares the email without regard to case" do
      verified(email: "Ama@Example.com")
      expect(helpers.payment_outcome(client, payment)).to eq(:paid)
    end

    it "is :not_paid for an abandoned transaction" do
      verified(status: "abandoned")
      expect(helpers.payment_outcome(client, payment)).to eq(:not_paid)
    end

    it "is :not_found for an unknown reference, which returns (HTTP 400) and does not raise" do
      stub_json(:get, "/transaction/verify/gift-1", {status: false, message: "Transaction reference not found."}, status: 400)
      expect(helpers.payment_outcome(client, payment)).to eq(:not_found)
    end

    it "relies on paid? checking only the status when given no amount or currency" do
      verified(amount: 1)
      expect(client.transactions.verify(reference: "gift-1").paid?).to be(true)
    end
  end

  describe "writes after a timeout" do
    it "sends a POST once and raises on a timeout" do
      stub = stub_request(:post, "https://api.paystack.co/transaction/initialize").to_timeout

      expect { client.transactions.initiate(email: "ama@example.com", amount: 5000) }.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.once
    end

    it "does not resend a POST after a 502 either" do
      stub = stub_json(:post, "/transaction/initialize", {status: false, message: "Bad gateway"}, status: 502)

      expect { client.transactions.initiate(email: "ama@example.com", amount: 5000) }.to raise_error(PaystackSdk::ServerError)
      expect(stub).to have_been_requested.once
    end

    it "retries a POST only on 429" do
      stub = stub_request(:post, "https://api.paystack.co/transaction/initialize")
        .to_return({status: 429, body: {status: false, message: "slow"}.to_json, headers: {"Content-Type" => "application/json"}},
          {status: 200, body: {status: true, message: "ok", data: {reference: "r"}}.to_json, headers: {"Content-Type" => "application/json"}})

      expect(client.transactions.initiate(email: "ama@example.com", amount: 5000)).to be_success
      expect(stub).to have_been_requested.twice
    end

    it "retries a GET (verify) after a 502" do
      stub = stub_json(:get, "/transaction/verify/gift-1", {status: false, message: "Bad gateway"}, status: 502)

      expect { client.transactions.verify(reference: "gift-1") }.to raise_error(PaystackSdk::ServerError)
      expect(stub).to have_been_requested.times(3)
    end

    it "retries a GET (verify) after a timeout" do
      stub = stub_request(:get, "https://api.paystack.co/transaction/verify/gift-1").to_timeout

      expect { client.transactions.verify(reference: "gift-1") }.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.times(3)
    end

    it "resends a POST after a timeout, twice more by default, when retry_non_idempotent: true is set" do
      risky = PaystackSdk::Client.new(secret_key: key, retry_interval: 0, retry_non_idempotent: true)
      stub = stub_request(:post, "https://api.paystack.co/transaction/initialize").to_timeout

      expect { risky.transactions.initiate(email: "ama@example.com", amount: 5000) }.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.times(3)
    end

    it "makes charge_saved_card answer :unknown after a timeout, without resending or verifying" do
      charge = stub_request(:post, "https://api.paystack.co/transaction/charge_authorization").to_timeout

      expect(helpers.charge_saved_card(client, payment, "AUTH_abc123")).to eq(:unknown)
      expect(charge).to have_been_requested.once
      expect(a_request(:get, /verify/)).not_to have_been_made
    end

    it "makes charge_saved_card answer :unknown after a 5xx" do
      stub_json(:post, "/transaction/charge_authorization", {status: false, message: "boom"}, status: 500)
      expect(helpers.charge_saved_card(client, payment, "AUTH_abc123")).to eq(:unknown)
    end

    it "makes charge_saved_card decide from verify after the charge call" do
      stub_json(:post, "/transaction/charge_authorization", {status: true, message: "Charge attempted",
        data: {status: "success", reference: "gift-1"}})
      verified
      expect(helpers.charge_saved_card(client, payment, "AUTH_abc123")).to eq(:paid)

      stub_json(:post, "/transaction/charge_authorization", {status: false, message: "Duplicate Transaction Reference"}, status: 400)
      verified(status: "failed")
      expect(helpers.charge_saved_card(client, payment, "AUTH_abc123")).to eq(:not_paid)
    end
  end

  describe "secret keys" do
    it "keeps the key out of SDK error messages" do
      messages = []
      stub_request(:post, "https://api.paystack.co/transaction/initialize").to_timeout
      begin
        client.transactions.initiate(email: "ama@example.com", amount: 5000)
      rescue PaystackSdk::Error => e
        messages << e.message << e.inspect << e.full_message
      end

      stub_request(:get, "https://api.paystack.co/transaction/verify/down").to_raise(Faraday::ConnectionFailed.new("refused"))
      {"down" => nil, "bad" => 401, "limited" => 429, "broken" => 500}.each do |ref, status|
        stub_json(:get, "/transaction/verify/#{ref}", {status: false, message: "nope"}, status: status) if status
        begin
          client.transactions.verify(reference: ref)
        rescue PaystackSdk::Error => e
          messages << e.message << e.inspect << e.full_message
        end
      end

      expect(messages.size).to eq(15)
      messages.each { |message| expect(message).not_to include(key) }
    end

    it "keeps the key out of Response#inspect, error_details and original_response" do
      stub_json(:get, "/transaction/verify/missing", {status: false, message: "Transaction reference not found."}, status: 400)
      response = client.transactions.verify(reference: "missing")

      expect(response.inspect).not_to include(key)
      expect(response.error_details.to_s).not_to include(key)
      expect(response.original_response.to_s).not_to include(key)
    end

    it "keeps the key out of inspect of a Client, a resource and the connection, as the skill says" do
      expect(client.inspect).not_to include(key)
      expect(client.transactions.inspect).not_to include(key)
      expect(client.connection.inspect).not_to include(key)
      expect(client.connection.headers.inspect).to include("[REDACTED]")
      expect(client.connection.headers["Authorization"]).to eq("Bearer #{key}")
    end

    it "says in the skill which versions leaked it and how to be safe on them" do
      text = File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-money-safety", "SKILL.md"))

      expect(text).to include("Versions before 0.4.1 printed the key in full")
      expect(text).to include("rotate the key")
    end
  end

  describe "key hygiene" do
    it "makes sandbox_only a prefix check and live? true only for sk_live_" do
      expect { PaystackSdk::Client.new(secret_key: "sk_live_x", sandbox_only: true) }.to raise_error(ArgumentError)
      expect { PaystackSdk::Client.new(secret_key: "pk_test_x", sandbox_only: true) }.to raise_error(ArgumentError)
      expect(PaystackSdk::Client.new(secret_key: "sk_test_anything", sandbox_only: true)).not_to be_live
      expect(PaystackSdk::Client.new(secret_key: "sk_live_x")).to be_live
    end

    it "has storefronts.publish documented as reaching live mode with a test key" do
      expect(client.storefronts).to respond_to(:publish)
      source = File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "..", "resources", "storefronts.rb"))
      expect(source).to include("Publishing copies the storefront and its products into LIVE mode, even when you call")
    end
  end

  describe "the methods and keywords the skill names" do
    def keywords(object, name)
      object.method(name).parameters.map(&:last)
    end

    it "exist on the gem" do
      expect(keywords(client.transactions, :verify)).to eq([:reference])
      expect(keywords(client.transactions, :charge_authorization))
        .to include(:email, :amount, :currency, :authorization_code, :reference)
      expect(keywords(client.transactions, :list)).to include(:status, :from, :to, :per_page, :page)
      expect(keywords(client.settlements, :list)).to include(:from, :to)
      expect(keywords(client.settlements, :transactions)).to eq([:id])
      expect(keywords(client.balances, :ledger)).to include(:from, :to)
      expect(client.balances).to respond_to(:fetch)
      expect(PaystackSdk::Client.instance_method(:initialize).parameters.map(&:last)).to include(:sandbox_only)
      %i[construct_event valid_signature? verify! trusted_ip?].each do |name|
        expect(PaystackSdk::Webhook).to respond_to(name)
      end
      [PaystackSdk::TimeoutError, PaystackSdk::ServerError].each { |klass| expect(klass).to be < PaystackSdk::Error }
      expect(PaystackSdk::TimeoutError).to be < PaystackSdk::ConnectionError
    end
  end
end
