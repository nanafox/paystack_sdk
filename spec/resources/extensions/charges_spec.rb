# frozen_string_literal: true

# Hand-written specs for Charges: the mobile_money convenience method (lib/paystack_sdk/resources/
# extensions/charges.rb) and the exact bodies the generated methods send.
RSpec.describe PaystackSdk::Resources::Charges do
  let(:resource) { described_class.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:ok) do
    {
      status: 200,
      headers: {"Content-Type" => "application/json"},
      body: {status: true, message: "Charge attempted", data: {status: "pay_offline", reference: "r13havfcdt7btcm"}}.to_json
    }
  end

  describe "#mobile_money" do
    it "sends POST /charge with the mobile_money object" do
      stub = stub_request(:post, "https://api.paystack.co/charge")
        .with(body: {
          email: "customer@email.com",
          amount: 10_000,
          currency: "GHS",
          mobile_money: {phone: "0551234987", provider: "mtn"}
        })
        .to_return(ok)

      response = resource.mobile_money(
        email: "customer@email.com",
        amount: 10_000,
        currency: "GHS",
        mobile_money: {phone: "0551234987", provider: "mtn"}
      )

      expect(stub).to have_been_requested
      expect(response.status).to eq("pay_offline")
    end

    it "lowercases the provider, accepts string keys and leaves the caller's hash alone" do
      wallet = {"phone" => "0551234987", "provider" => "MTN"}
      stub = stub_request(:post, "https://api.paystack.co/charge")
        .with(body: {email: "customer@email.com", amount: 100, mobile_money: {phone: "0551234987", provider: "mtn"}})
        .to_return(ok)

      resource.mobile_money(email: "customer@email.com", amount: 100, mobile_money: wallet)

      expect(stub).to have_been_requested
      expect(wallet).to eq("phone" => "0551234987", "provider" => "MTN")
    end

    it "sends reference and metadata when given" do
      stub = stub_request(:post, "https://api.paystack.co/charge")
        .with(body: {
          email: "customer@email.com",
          amount: 100,
          reference: "order-42",
          metadata: {order_id: 42},
          mobile_money: {phone: "+254700000000", provider: "mpesa"}
        })
        .to_return(ok)

      resource.mobile_money(
        email: "customer@email.com",
        amount: 100,
        reference: "order-42",
        metadata: {order_id: 42},
        mobile_money: {phone: "+254700000000", provider: "mpesa"}
      )

      expect(stub).to have_been_requested
    end

    # The Mobile Money guide sends the till number as mobile_money.account with provider mptill. The
    # spec's MobileMoney schema only knows phone and provider, and the contract checker cannot record
    # an exception for a nested field, so this example opts out of it.
    it "accepts an M-PESA Till account in place of a phone number", contract: false do
      stub = stub_request(:post, "https://api.paystack.co/charge")
        .with(body: {email: "customer@email.com", amount: 100, currency: "KES", mobile_money: {account: "1234567", provider: "mptill"}})
        .to_return(ok)

      resource.mobile_money(
        email: "customer@email.com",
        amount: 100,
        currency: "KES",
        mobile_money: {account: "1234567", provider: "mptill"}
      )

      expect(stub).to have_been_requested
    end

    it "refuses an unknown provider" do
      expect do
        resource.mobile_money(email: "customer@email.com", amount: 100, mobile_money: {phone: "0551234987", provider: "invalid"})
      end.to raise_error(PaystackSdk::InvalidValueError, /mobile_money provider/)
    end

    it "requires a provider" do
      expect do
        resource.mobile_money(email: "customer@email.com", amount: 100, mobile_money: {phone: "0551234987"})
      end.to raise_error(PaystackSdk::MissingParamError, /mobile_money provider/)
    end

    it "requires a phone number or account" do
      expect do
        resource.mobile_money(email: "customer@email.com", amount: 100, mobile_money: {provider: "mtn"})
      end.to raise_error(PaystackSdk::MissingParamError, /mobile_money phone/)
    end

    it "requires mobile_money to be a hash" do
      expect do
        resource.mobile_money(email: "customer@email.com", amount: 100, mobile_money: "0551234987")
      end.to raise_error(PaystackSdk::InvalidFormatError, /mobile_money/)
    end

    it "refuses a currency that is not a 3-letter code" do
      expect do
        resource.mobile_money(email: "customer@email.com", amount: 100, currency: "cedi", mobile_money: {phone: "0551234987", provider: "mtn"})
      end.to raise_error(PaystackSdk::InvalidFormatError, /currency/)
    end

    it "checks email and amount like #create" do
      expect do
        resource.mobile_money(email: "not-an-email", amount: 100, mobile_money: {phone: "0551234987", provider: "mtn"})
      end.to raise_error(PaystackSdk::InvalidFormatError, /email/i)
      expect do
        resource.mobile_money(email: "customer@email.com", amount: 0, mobile_money: {phone: "0551234987", provider: "mtn"})
      end.to raise_error(PaystackSdk::InvalidValueError, /amount/)
    end

    it "lists the providers Paystack documents" do
      expect(described_class::MOBILE_MONEY_PROVIDERS).to eq(%w[mtn atl vod mpesa orange wave mpesa_offline mptill])
    end
  end

  describe "#create" do
    it "sends the channel objects and split fields as given" do
      stub = stub_request(:post, "https://api.paystack.co/charge")
        .with(body: {
          email: "customer@email.com",
          amount: 5000,
          currency: "NGN",
          bank_transfer: {account_expires_at: "2026-10-10T12:00:00Z"},
          split_code: "SPL_98WF13Eb3w"
        })
        .to_return(ok)

      resource.create(
        email: "customer@email.com",
        amount: 5000,
        currency: "NGN",
        bank_transfer: {account_expires_at: "2026-10-10T12:00:00Z"},
        split_code: "SPL_98WF13Eb3w"
      )

      expect(stub).to have_been_requested
    end

    it "sends a bank charge with the customer's birthday as YYYY-MM-DD" do
      stub = stub_request(:post, "https://api.paystack.co/charge")
        .with(body: {email: "customer@email.com", amount: 10_000, bank: {code: "057", account_number: "0000000000"}, birthday: "1995-12-23"})
        .to_return(ok)

      resource.create(
        email: "customer@email.com",
        amount: 10_000,
        bank: {code: "057", account_number: "0000000000"},
        birthday: Date.new(1995, 12, 23)
      )

      expect(stub).to have_been_requested
    end
  end

  describe "#submit_address" do
    it "sends zip_code, the name the API reads" do
      stub = stub_request(:post, "https://api.paystack.co/charge/submit_address")
        .with(body: {address: "140 N 2ND ST", city: "Stroudsburg", state: "PA", zip_code: "18360", reference: "7c7rpkqpc0tijs8"})
        .to_return(ok)

      resource.submit_address(address: "140 N 2ND ST", city: "Stroudsburg", state: "PA", zip_code: "18360", reference: "7c7rpkqpc0tijs8")

      expect(stub).to have_been_requested
    end
  end

  describe "#check_pending" do
    it "puts the reference in the path, escaped" do
      stub = stub_request(:get, "https://api.paystack.co/charge/ref%2Fwith%20slash").to_return(ok)

      resource.check_pending(reference: "ref/with slash")

      expect(stub).to have_been_requested
    end
  end
end
