# frozen_string_literal: true

require "paystack_sdk/skills"

# The testing skill gives a helper module and stub shapes to copy. These examples take the helper out of the
# skill text and run every shape through the real SDK, so the skill cannot drift from the gem.
RSpec.describe "what paystack-sdk-testing says", contract: false do
  skill_text = File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-testing", "SKILL.md"))
  blocks = skill_text.scan(/^```ruby\n(.*?)^```/m).flatten
  # The helper is evaluated from the skill itself.
  eval(blocks.find { |code| code.include?("module PaystackStubs") }, TOPLEVEL_BINDING) # standard:disable Security/Eval
  webhook_code = blocks.find { |code| code.include?("Webhook.sign") }

  include PaystackStubs

  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_dummy", retry_interval: 0) }

  describe "keys" do
    it "refuses a live key with sandbox_only and reports live? only for sk_live_" do
      expect { PaystackSdk::Client.new(secret_key: "sk_live_x", sandbox_only: true) }.to raise_error(ArgumentError)
      expect(PaystackSdk::Client.new(secret_key: "sk_test_x", sandbox_only: true)).not_to be_live
      expect(PaystackSdk::Client.new(secret_key: "sk_live_x")).to be_live
    end

    it "checks the prefix only: a key that merely starts sk_test_ passes" do
      expect { PaystackSdk::Client.new(secret_key: "sk_test_anything", sandbox_only: true) }.not_to raise_error
    end
  end

  describe "the stub shapes" do
    it "success on initialize, with dot access" do
      stub_paystack(:post, "/transaction/initialize", paystack_ok(
        {authorization_url: "https://checkout.paystack.com/abc", access_code: "abc", reference: "order-1042"},
        message: "Authorization URL created"
      ))
      response = client.transactions.initiate(email: "ama@example.com", amount: 5000, currency: "GHS", reference: "order-1042")

      expect(response.success?).to be(true)
      expect(response.authorization_url).to eq("https://checkout.paystack.com/abc")
    end

    it "success on verify, paid? and a mismatch" do
      stub_paystack(:get, "/transaction/verify/order-1042", paystack_ok(paystack_transaction, message: "Verification successful"))
      verified = client.transactions.verify(reference: "order-1042")

      expect(verified.paid?(amount: 5000, currency: "GHS")).to be(true)
      expect(verified.paid?(amount: 4000, currency: "GHS")).to be(false)
      expect(verified.authorization.reusable).to be(true)

      stub_paystack(:get, "/transaction/verify/short", paystack_ok(paystack_transaction(amount: 4000)))
      expect(client.transactions.verify(reference: "short").paid?(amount: 5000, currency: "GHS")).to be(false)
    end

    it "a 400 returns an unsuccessful Response and raises nothing" do
      stub_paystack(:post, "/transaction/initialize", paystack_error("Duplicate Transaction Reference", code: "duplicate_reference"), status: 400)
      response = client.transactions.initiate(email: "ama@example.com", amount: 5000, reference: "order-1042")

      expect(response.success?).to be(false)
      expect(response.error_message).to eq("Duplicate Transaction Reference")

      expect { client.transactions.initiate(email: "x", amount: 5000) }.to raise_error(PaystackSdk::InvalidFormatError)
    end

    it "a 404 returns an unsuccessful Response" do
      stub_paystack(:get, "/transaction/verify/nope", paystack_error("Transaction reference not found.", code: "transaction_not_found"), status: 404)

      expect(client.transactions.verify(reference: "nope").error_message).to eq("Transaction reference not found.")
    end

    it "a 401 raises AuthenticationError" do
      stub_paystack(:get, "/transaction/verify/x", paystack_error("Invalid key", code: "invalid_Key"), status: 401)

      expect { client.transactions.verify(reference: "x") }.to raise_error(PaystackSdk::AuthenticationError, "Invalid key")
    end

    it "a 429 with a long x-ratelimit-reset raises RateLimitError with retry_after, without retrying" do
      stub = stub_paystack(:get, "/transaction/verify/x", paystack_error("Rate limit exceeded"), status: 429, headers: {"x-ratelimit-reset" => "30"})

      expect { client.transactions.verify(reference: "x") }.to raise_error(PaystackSdk::RateLimitError) { |e| expect(e.retry_after).to eq(30) }
      expect(stub).to have_been_requested.once
    end

    it "a 500 on a write raises ServerError and is sent once" do
      stub = stub_paystack(:post, "/transaction/initialize", paystack_error("Internal server error"), status: 500)

      expect { client.transactions.initiate(email: "ama@example.com", amount: 5000) }
        .to raise_error(PaystackSdk::ServerError) { |e| expect(e.status_code).to eq(500) }
      expect(stub).to have_been_requested.once
    end

    it "a timeout on a write raises TimeoutError and is sent once" do
      stub = stub_paystack_timeout(:post, "/transaction/initialize")

      expect { client.transactions.initiate(email: "ama@example.com", amount: 5000) }.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.once
    end

    it "a timeout on a read is retried (retry_interval: 0 keeps it fast)" do
      stub = stub_paystack_timeout(:get, "/transaction/verify/x")

      expect { client.transactions.verify(reference: "x") }.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.times(3)
    end

    it "a 429 on a write without a long reset is retried" do
      stub = stub_paystack(:post, "/transaction/initialize", paystack_error("Rate limit exceeded"), status: 429)

      expect { client.transactions.initiate(email: "ama@example.com", amount: 5000) }.to raise_error(PaystackSdk::RateLimitError)
      expect(stub).to have_been_requested.times(3)
    end

    it "lets a test assert the request body" do
      stub = stub_paystack(:post, "/transaction/initialize", paystack_ok({reference: "order-1042"}))
      client.transactions.initiate(email: "ama@example.com", amount: 5000, currency: "GHS", reference: "order-1042")

      expect(stub.with(body: hash_including("amount" => 5000, "currency" => "GHS"))).to have_been_requested
    end

    it "supports a path with a query string" do
      stub = stub_paystack(:get, "/transaction?perPage=5", paystack_ok([paystack_transaction]))

      expect(client.transactions.list(per_page: 5).first.reference).to eq("order-1042")
      expect(stub).to have_been_requested
    end
  end

  describe "why not to mock the client" do
    it "the SDK rejects a call a double would accept" do
      expect { client.transactions.initiate(amount: 5000) }.to raise_error(ArgumentError)
      expect { client.transactions.initiate("ama@example.com", 5000) }.to raise_error(ArgumentError)
    end
  end

  describe "the webhook block" do
    it "runs: signs a body, constructs the event, and rejects one changed byte" do
      expect(webhook_code).not_to be_nil
      scope = binding
      result = scope.eval(webhook_code) # standard:disable Security/Eval

      expect(result).to be(false)
      expect(scope.local_variable_get(:event).event).to eq("charge.success")
      expect(scope.local_variable_get(:event).data.reference).to eq("order-1042")
    end
  end

  describe "everything the skill names exists" do
    it "has the methods and keywords it uses" do
      expect(PaystackSdk::Webhook).to respond_to(:sign, :construct_event, :valid_signature?)
      expect(PaystackSdk::Client.instance_method(:live?)).not_to be_nil
      expect(PaystackSdk::Client.instance_method(:initialize).parameters).to include([:key, :sandbox_only], [:keyrest, :options])
      expect(PaystackSdk::Webhook::IP_ADDRESSES.size).to eq(3)
      expect(skill_text).to include("[[paystack-sdk-overview]]", "[[paystack-sdk-mobile-money]]", "[[paystack-sdk-charge-statuses]]")
    end

    it "links only to skills that are shipped (the content spec resolves every [[link]])" do
      links = skill_text.scan(/\[\[([\w-]+)\]\]/).flatten

      expect(links - PaystackSdk::Skills.all.map(&:name)).to be_empty
    end
  end

  # Observed on the Paystack test API; runs only when PAYSTACK_TEST_SECRET_KEY is an sk_test_ key.
  describe "against the test API", :sandbox do
    let(:key) { ENV["PAYSTACK_TEST_SECRET_KEY"].to_s }

    before do
      skip "set PAYSTACK_TEST_SECRET_KEY to an sk_test_ key" unless key.start_with?("sk_test_")
      WebMock.allow_net_connect!
    end

    after { WebMock.disable_net_connect! }

    let(:real) { PaystackSdk::Client.new(secret_key: key, sandbox_only: true) }

    it "matches the observed 401, 400 and 404 bodies" do
      bad = PaystackSdk::Client.new(secret_key: "sk_test_thisisnotarealkey123")
      expect { bad.transactions.verify(reference: "x") }.to raise_error(PaystackSdk::AuthenticationError, "Invalid key")
      raw = bad.connection.get("/transaction/verify/x")
      expect(raw.status).to eq(401)
      expect(raw.body).to include("status" => false, "message" => "Invalid key", "type" => "validation_error", "code" => "invalid_Key")

      invalid = real.connection.post("/transaction/initialize", {email: "not-an-email", amount: 100})
      expect(invalid.status).to eq(400)
      expect(invalid.body).to include("message" => "Invalid Email Address Passed", "code" => "invalid_email_address")

      missing = real.transactions.verify(reference: "no-such-ref-#{Time.now.to_i}-#{rand(100_000)}")
      expect(missing.error_message).to eq("Transaction reference not found.")
      expect(missing.original_response["code"]).to eq("transaction_not_found")
    end

    it "initializes and verifies a 100 pesewa payment as abandoned; a reused reference is a duplicate" do
      reference = "skilltest-#{Time.now.to_i}-#{rand(100_000)}"
      init = real.transactions.initiate(email: "skill-test@example.com", amount: 100, currency: "GHS", reference: reference)
      expect(init).to be_success
      expect(init.reference).to eq(reference)

      verified = real.transactions.verify(reference: reference)
      expect(verified.status).to eq("abandoned")
      expect(verified.paid?(amount: 100, currency: "GHS")).to be(false)

      again = real.transactions.initiate(email: "skill-test@example.com", amount: 100, currency: "GHS", reference: reference)
      expect(again.error_message).to eq("Duplicate Transaction Reference")
    end

    it "answers the MTN test number with success at once" do
      reference = "skilltest-momo-#{Time.now.to_i}-#{rand(100_000)}"
      charge = real.charges.mobile_money(email: "skill-test@example.com", amount: 100, currency: "GHS", reference: reference,
        mobile_money: {phone: "0551234987", provider: "mtn"})
      expect(charge.status).to eq("success")
      expect(real.transactions.verify(reference: reference).paid?(amount: 100, currency: "GHS")).to be(true)
    end
  end
end
