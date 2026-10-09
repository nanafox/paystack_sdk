# frozen_string_literal: true

require "paystack_sdk/skills"

# paystack-sdk-charge-statuses and paystack-sdk-mobile-money state how charges behave. These examples run
# those statements against the gem, so the skills cannot say something the code does not do.
RSpec.describe "what the charge skills say", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_charge") }
  let(:statuses_text) { File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-charge-statuses", "SKILL.md")) }
  let(:momo_text) { File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-mobile-money", "SKILL.md")) }

  def stub_json(verb, path, body, status: 200)
    stub_request(verb, "https://api.paystack.co#{path}")
      .to_return(status: status, body: body.to_json, headers: {"Content-Type" => "application/json"})
  end

  describe "the status table" do
    it "names only charges calls that exist, with the keywords the table gives" do
      rows = statuses_text.lines.grep(/\A\| `/)
      calls = rows.flat_map { |row| row.scan(/`charges\.(\w+)\(([^)]*)\)`/) }

      expect(calls.map(&:first)).to include("submit_pin", "submit_otp", "submit_phone", "submit_birthday", "submit_address", "check_pending")
      calls.each do |name, args|
        method = PaystackSdk::Resources::Charges.instance_method(name)
        keywords = method.parameters.filter_map { |kind, param| param if %i[keyreq key].include?(kind) }
        given = args.scan(/(\w+):/).flatten.map(&:to_sym)
        expect(keywords).to include(*given), "#{name} takes #{keywords}, the skill says #{given}"
      end
    end

    it "spells zip_code, not zipcode" do
      expect(PaystackSdk::Resources::Charges.instance_method(:submit_address).parameters.map(&:last)).to include(:zip_code)
    end
  end

  describe "the calls" do
    it "send each follow-up to its endpoint with the reference" do
      pin = stub_json(:post, "/charge/submit_pin", {status: true, message: "Charge attempted", data: {status: "send_otp"}})
      otp = stub_json(:post, "/charge/submit_otp", {status: true, message: "Charge attempted", data: {status: "success"}})
      phone = stub_json(:post, "/charge/submit_phone", {status: true, message: "Charge attempted", data: {status: "send_otp"}})
      pending = stub_json(:get, "/charge/ref-1", {status: true, message: "Reference check successful", data: {status: "pending"}})

      expect(client.charges.submit_pin(pin: "1234", reference: "ref-1").status?(:send_otp)).to be(true)
      expect(client.charges.submit_otp(otp: "123456", reference: "ref-1").status?(:success)).to be(true)
      client.charges.submit_phone(phone: "0551234987", reference: "ref-1")
      expect(client.charges.check_pending(reference: "ref-1").status?(:pending)).to be(true)
      [pin, otp, phone, pending].each { |stub| expect(stub).to have_been_requested }
      expect(WebMock).to have_requested(:post, "https://api.paystack.co/charge/submit_pin").with(body: {pin: "1234", reference: "ref-1"})
    end
  end

  describe "the success? trap" do
    it "reports success? true while the charge status is failed (HTTP 200)" do
      stub_json(:post, "/charge", {status: true, message: "Charge attempted", data: {status: "failed", message: "Invalid phone"}})

      response = client.charges.mobile_money(email: "ama@example.com", amount: 100, currency: "GHS", reference: "r1",
        mobile_money: {phone: "0551234", provider: "mtn"})

      expect(response.success?).to be(true)
      expect(response.status?(:failed)).to be(true)
      expect(response.original_response.dig("data", "message")).to eq("Invalid phone")
    end

    it "reports success? false for a wrong PIN or OTP (HTTP 400) and exposes the reason" do
      stub_json(:post, "/charge/submit_pin", {status: false, message: "Charge attempted", data: {status: "failed", message: "Incorrect PIN"}}, status: 400)

      response = client.charges.submit_pin(pin: "9999", reference: "r2")

      expect(response.success?).to be(false)
      expect(response.status?(:failed)).to be(true)
      expect(response.original_response.dig("data", "message")).to eq("Incorrect PIN")
    end

    it "returns an unsuccessful Response, with no data status, for an unknown reference" do
      stub_json(:post, "/charge/submit_otp", {status: false, message: "Transaction reference is invalid"}, status: 400)

      response = client.charges.submit_otp(otp: "123456", reference: "nope")

      expect(response.success?).to be(false)
      expect(response.original_response["data"]).to be_nil
    end
  end

  describe "mobile money" do
    let(:charge) { stub_json(:post, "/charge", {status: true, message: "Charge attempted", data: {reference: "r3", status: "pay_offline", display_text: "Please complete authorization process on your mobile phone"}}) }

    it "sends the provider in lowercase whatever case it was given, and leaves the caller's hash alone" do
      charge
      details = {phone: "0551234987", provider: "MTN"}

      response = client.charges.mobile_money(email: "ama@example.com", amount: 5000, currency: "GHS", reference: "r3", mobile_money: details)

      expect(WebMock).to have_requested(:post, "https://api.paystack.co/charge").with { |req| JSON.parse(req.body)["mobile_money"] == {"phone" => "0551234987", "provider" => "mtn"} }
      expect(details).to eq(phone: "0551234987", provider: "MTN")
      expect(response.status?(:pay_offline)).to be(true)
      expect(response.display_text).to start_with("Please complete")
    end

    it "accepts every Ghana provider the skill lists, and the others it names" do
      listed = momo_text.scan(/`(mtn|vod|atl|mpesa_offline|mptill|mpesa|orange|wave)`/).flatten.uniq

      expect(listed).to include("mtn", "vod", "atl")
      expect(PaystackSdk::Resources::Charges::MOBILE_MONEY_PROVIDERS).to include(*listed)
    end

    it "refuses an unknown provider and a missing phone before sending anything" do
      expect { client.charges.mobile_money(email: "ama@example.com", amount: 100, mobile_money: {phone: "0551234987", provider: "zzz"}) }
        .to raise_error(PaystackSdk::ValidationError)
      expect { client.charges.mobile_money(email: "ama@example.com", amount: 100, mobile_money: {provider: "mtn"}) }
        .to raise_error(PaystackSdk::ValidationError)
    end

    it "converts E.164 to the local ten-digit form with the helper the skill gives" do
      code = momo_text[/```ruby\n(def local_ghana_number.*?)^```/m, 1]
      expect(code).not_to be_nil
      definition = code.lines.reject { |line| line.start_with?("local_ghana_number(") }.join
      mod = Module.new
      mod.module_eval(definition)
      helper = Object.new.extend(mod)

      expect(helper.local_ghana_number("+233551234987")).to eq("0551234987")
      expect(helper.local_ghana_number("0551234987")).to eq("0551234987")
      expect(helper.local_ghana_number("+233 55 123 4987")).to eq("0551234987")
      expect(helper.local_ghana_number("233551234987")).to eq("0551234987")
      expect(helper.local_ghana_number("551234987")).to eq("0551234987")
      expect(helper.local_ghana_number("055-123-4987")).to eq("0551234987")
    end

    it "makes that helper raise for something that is not a Ghana number, instead of passing junk on" do
      code = momo_text[/```ruby\n(def local_ghana_number.*?)^```/m, 1]
      mod = Module.new
      mod.module_eval(code.lines.reject { |line| line.start_with?("local_ghana_number(") }.join)
      helper = Object.new.extend(mod)

      [nil, "", "0551234", "+254710000000", "abc"].each do |junk|
        expect { helper.local_ghana_number(junk) }.to raise_error(ArgumentError, /not a Ghana mobile number/)
      end
    end

    it "does not retry the charge after a timeout" do
      stub = stub_request(:post, "https://api.paystack.co/charge").to_timeout

      expect do
        client.charges.mobile_money(email: "ama@example.com", amount: 100, currency: "GHS", reference: "r4", mobile_money: {phone: "0551234987", provider: "mtn"})
      end.to raise_error(PaystackSdk::TimeoutError)
      expect(stub).to have_been_requested.once
    end
  end
end
