# frozen_string_literal: true

require "paystack_sdk/skills"

# paystack-sdk-saved-card-renewals states how saved-card charges behave in the gem and gives helper code.
# These examples run those statements and that code, so the skill cannot say something the gem does not do.
# contract: false because the stubs are trimmed Paystack bodies; the resource specs carry the contract checks.
RSpec.describe "what paystack-sdk-saved-card-renewals says", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_renewals") }
  let(:text) { File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-saved-card-renewals", "SKILL.md")) }
  let(:card) { Struct.new(:email, :authorization_code).new("kwes@email.com", "AUTH_50w0d0f5xo") }
  let(:verify_url) { "https://api.paystack.co/transaction/verify/renewal-42-2026-10-a1" }
  let(:charge_url) { "https://api.paystack.co/transaction/charge_authorization" }

  def stub_json(verb, path, body, status: 200)
    stub_request(verb, "https://api.paystack.co#{path}")
      .to_return(status: status, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  def json_response(body, status: 200)
    {status: status, body: body.to_json, headers: {"Content-Type" => "application/json"}}
  end

  # Loads the Ruby block of the skill that starts with `def <name>` and returns an object with its methods.
  def helpers_from(name)
    code = text[/```ruby\n(def #{name}.*?)^```/m, 1]
    raise "no ```ruby block starting with def #{name}" if code.nil?

    mod = Module.new
    mod.module_eval(code)
    Object.new.extend(mod)
  end

  def keywords(klass, name)
    klass.instance_method(name).parameters.filter_map { |kind, param| param if %i[keyreq key].include?(kind) }
  end

  def paid_body(amount: 100, requested: 100, status: "success", authorization: {})
    {status: true, message: "Verification successful",
     data: {status: status, amount: amount, requested_amount: requested, currency: "GHS", reference: "renewal-42-2026-10-a1",
            customer: {email: "kwes@email.com"}, authorization: authorization}}
  end

  describe "the methods and keywords it names" do
    it "gives charge_authorization every keyword the skill lists, with only email, amount and authorization_code required" do
      method = PaystackSdk::Resources::Transactions.instance_method(:charge_authorization)
      required = method.parameters.filter_map { |kind, param| param if kind == :keyreq }

      expect(required).to contain_exactly(:email, :amount, :authorization_code)
      expect(keywords(PaystackSdk::Resources::Transactions, :charge_authorization))
        .to include(:currency, :reference, :metadata, :queue, :split_code, :split, :subaccount, :transaction_charge, :bearer)
    end

    it "gives partial_debit the signature the skill states, with currency required" do
      given = text[/`transactions\.partial_debit\(([^)]*)\)`/, 1].scan(/(\w+):/).flatten.map(&:to_sym)
      method = PaystackSdk::Resources::Transactions.instance_method(:partial_debit)

      expect(keywords(PaystackSdk::Resources::Transactions, :partial_debit)).to match_array(given)
      expect(method.parameters).to include([:keyreq, :currency])
    end

    it "has the other calls it names" do
      expect(client.customers).to respond_to(:deactivate_authorization, :fetch)
      expect(client).to respond_to(:plans, :subscriptions)
    end

    it "refuses a Float amount before sending, and checks bearer" do
      expect do
        client.transactions.charge_authorization(email: "kwes@email.com", amount: 100.0, currency: "GHS", authorization_code: "AUTH_x")
      end.to raise_error(PaystackSdk::InvalidValueError)
      expect do
        client.transactions.charge_authorization(email: "kwes@email.com", amount: 100, authorization_code: "AUTH_x", bearer: "nobody")
      end.to raise_error(PaystackSdk::ValidationError)
    end
  end

  describe "a renewal charge" do
    it "posts to charge_authorization and sends a metadata Hash as a JSON string" do
      stub = stub_json(:post, "/transaction/charge_authorization", {status: true, message: "Charge attempted", data: {status: "success"}})

      response = client.transactions.charge_authorization(email: "kwes@email.com", amount: 5000, currency: "GHS",
        authorization_code: "AUTH_50w0d0f5xo", reference: "renewal-42-2026-10-a1", metadata: {membership_id: 42, period: "2026-10"})

      expect(response.status?(:success)).to be(true)
      expect(stub.with { |req| JSON.parse(JSON.parse(req.body)["metadata"]) == {"membership_id" => 42, "period" => "2026-10"} })
        .to have_been_requested
    end

    it "returns, without raising, an unsuccessful Response for each 400 the table lists" do
      messages = text.scan(/^\| [^|]+ \| 400 \| false \| "([^"]+)"/).flatten
      expect(messages).to include("Authorization code is invalid", "Currency not supported by merchant", "Duplicate Transaction Reference")

      messages.each do |message|
        stub_json(:post, "/transaction/charge_authorization", {status: false, message: message}, status: 400)
        response = client.transactions.charge_authorization(email: "kwes@email.com", amount: 100, currency: "GHS", authorization_code: "AUTH_x")

        expect(response.success?).to be(false)
        expect(response.error_message).to eq(message)
      end
    end

    it "is not retried after a timeout" do
      stub = stub_request(:post, charge_url).to_timeout

      expect do
        client.transactions.charge_authorization(email: "kwes@email.com", amount: 100, currency: "GHS", authorization_code: "AUTH_x", reference: "r1")
      end.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.once
    end

    it "makes paid? false for a partial debit that charged less than was requested" do
      stub_json(:get, "/transaction/verify/renewal-42-2026-10-a1", paid_body(amount: 60, requested: 100))

      response = client.transactions.verify(reference: "renewal-42-2026-10-a1")

      expect(response.paid?(amount: 100, currency: "GHS")).to be(false)
      expect(response.requested_amount).to eq(100)
      expect(helpers_from("renewal_reference").renewal_outcome(response, amount: 100, currency: "GHS")).to eq(:check_amount)
    end
  end

  describe "reusable_card_authorization" do
    let(:helper) { helpers_from("reusable_card_authorization") }
    let(:card_auth) do
      {authorization_code: "AUTH_50w0d0f5xo", reusable: true, signature: "SIG_x", last4: "4081", exp_month: "12",
       exp_year: "2030", bank: "TEST BANK", card_type: "visa ", channel: "card"}
    end

    def verified(body)
      stub_json(:get, "/transaction/verify/renewal-42-2026-10-a1", body)
      client.transactions.verify(reference: "renewal-42-2026-10-a1")
    end

    it "returns the code with the email it belongs to, and no card number" do
      saved = helper.reusable_card_authorization(verified(paid_body(authorization: card_auth)), amount: 100, currency: "GHS")

      expect(saved).to eq(email: "kwes@email.com", authorization_code: "AUTH_50w0d0f5xo", signature: "SIG_x", last4: "4081",
        exp_month: "12", exp_year: "2030", bank: "TEST BANK", card_type: "visa")
    end

    it "returns nil for a mobile money authorization, a non-reusable card, or an unpaid payment" do
      momo = card_auth.merge(reusable: false, signature: nil, channel: "mobile_money")

      expect(helper.reusable_card_authorization(verified(paid_body(authorization: momo)), amount: 100, currency: "GHS")).to be_nil
      expect(helper.reusable_card_authorization(verified(paid_body(authorization: card_auth.merge(reusable: false))), amount: 100, currency: "GHS")).to be_nil
      expect(helper.reusable_card_authorization(verified(paid_body(status: "failed", authorization: card_auth)), amount: 100, currency: "GHS")).to be_nil
      expect(helper.reusable_card_authorization(verified(paid_body(authorization: card_auth)), amount: 200, currency: "GHS")).to be_nil
    end
  end

  describe "renewal_reference, renewal_outcome and charge_renewal" do
    let(:helper) { helpers_from("renewal_reference") }

    def charge_renewal
      helper.charge_renewal(client, card: card, amount: 100, currency: "GHS", reference: "renewal-42-2026-10-a1")
    end

    it "builds one reference per attempt that the SDK accepts, and refuses one it would not" do
      expect(helper.renewal_reference(42, "2026-10", 1)).to eq("renewal-42-2026-10-a1")
      expect(helper.renewal_reference(42, "2026-10", 2)).to eq("renewal-42-2026-10-a2")
      expect { helper.renewal_reference("42/x", "2026-10", 1) }.to raise_error(ArgumentError)
    end

    it "looks the reference up first and does not charge again when it already exists" do
      stub_request(:get, verify_url).to_return(json_response(paid_body))
      charge = stub_request(:post, charge_url)

      expect(charge_renewal).to eq([:paid, nil])
      expect(charge).not_to have_been_requested
    end

    it "charges when the reference is not found, then grants only on a verify by reference" do
      stub_request(:get, verify_url).to_return(
        json_response({status: false, message: "Transaction reference not found."}, status: 400),
        json_response(paid_body)
      )
      charge = stub_request(:post, charge_url).to_return(json_response({status: true, message: "Charge attempted", data: {status: "success"}}))

      expect(charge_renewal).to eq([:paid, nil])
      expect(charge.with(body: hash_including("email" => "kwes@email.com", "amount" => 100, "currency" => "GHS",
        "authorization_code" => "AUTH_50w0d0f5xo", "reference" => "renewal-42-2026-10-a1"))).to have_been_requested.once
    end

    it "reports :failed and :pending from the verified status" do
      stub_request(:get, verify_url).to_return(json_response(paid_body(status: "failed")))
      expect(charge_renewal).to eq([:failed, nil])

      stub_request(:get, verify_url).to_return(json_response(paid_body(status: "ongoing")))
      expect(charge_renewal).to eq([:pending, nil])
    end

    it "reports :rejected with Paystack's message for a 400, and :unknown for a duplicate reference" do
      not_found = json_response({status: false, message: "Transaction reference not found."}, status: 400)
      stub_request(:get, verify_url).to_return(not_found)
      stub_request(:post, charge_url).to_return(json_response({status: false, message: "Authorization code is invalid"}, status: 400))
      expect(charge_renewal).to eq([:rejected, "Authorization code is invalid"])

      stub_request(:post, charge_url).to_return(json_response({status: false, message: "Duplicate Transaction Reference"}, status: 400))
      expect(charge_renewal).to eq([:unknown, "Duplicate Transaction Reference"])
    end

    it "reports :unknown after a timeout and sends the charge only once" do
      stub_request(:get, verify_url).to_return(json_response({status: false, message: "Transaction reference not found."}, status: 400))
      charge = stub_request(:post, charge_url).to_timeout

      expect(charge_renewal).to eq([:unknown, "PaystackSdk::TimeoutError"])
      expect(charge).to have_been_requested.once
    end

    it "reports :unknown when Paystack answers 5xx" do
      stub_request(:get, verify_url).to_return(json_response({status: false, message: "Transaction reference not found."}, status: 400))
      stub_request(:post, charge_url).to_return(json_response({status: false, message: "oops"}, status: 500))

      expect(charge_renewal).to eq([:unknown, "PaystackSdk::ServerError"])
    end
  end
end
