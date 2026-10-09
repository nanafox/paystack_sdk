# frozen_string_literal: true

# Tests of the contract checker itself. They build requests by hand, so the checker that guards
# the other specs is not asked to approve them.
RSpec.describe PaystackContract, contract: false do
  let(:url) { "https://api.paystack.co" }
  let(:auth) { {"Authorization" => "Bearer sk_test_x"} }
  let(:json) { auth.merge("Content-Type" => "application/json") }

  def check(method, path, body: nil, headers: nil)
    body = JSON.generate(body) if body.is_a?(Hash)
    described_class.check(method: method, url: "#{url}#{path}", body: body, headers: headers || (body ? json : auth))
  end

  it "accepts a request that matches the spec" do
    expect(check(:post, "/transaction/initialize", body: {email: "a@b.co", amount: 1000, currency: "GHS"})).to eq([])
  end

  describe "operation" do
    it "rejects a path the spec does not have" do
      expect(check(:post, "/customer/deactivate_authorization", body: {authorization_code: "AUTH_1"}))
        .to contain_exactly(match(/no operation POST \/customer\/deactivate_authorization/))
    end

    it "rejects a method the path does not support" do
      expect(check(:delete, "/bank")).to contain_exactly(match(/no operation DELETE \/bank/))
    end

    it "prefers a literal path over a templated one" do
      expect(check(:get, "/transaction/totals?from=2026-01-01&to=2026-02-01")).to eq([])
    end

    it "fills path templates" do
      expect(check(:get, "/transaction/verify/ref-123")).to eq([])
    end
  end

  describe "query" do
    it "rejects an unknown parameter" do
      expect(check(:get, "/bank?nope=1")).to contain_exactly(match(/unknown query parameter `nope`/))
    end

    it "rejects a value outside an enum" do
      expect(check(:get, "/bank?currency=EUR")).to contain_exactly(match(/`currency`.*EUR.*one of/))
    end

    it "rejects a value of the wrong type" do
      expect(check(:get, "/transaction?per_page=lots")).to contain_exactly(match(/`per_page`.*integer/))
    end

    it "rejects a malformed date-time" do
      expect(check(:get, "/transaction/totals?from=yesterday")).to contain_exactly(match(/`from`.*date-time/))
    end

    it "accepts the parameter names the canonical docs use where they differ from the spec" do
      expect(check(:get, "/transaction?perPage=20&customer=123&terminalid=T1&page=2")).to eq([])
    end

    it "still checks the type on a documented exception" do
      expect(check(:get, "/transaction?customer=not-a-number")).to contain_exactly(match(/`customer`.*integer/))
    end

    it "requires the spec's required parameters" do
      expect(check(:get, "/transfer/verify/ref-1")).to eq([])
    end
  end

  describe "body" do
    it "rejects a missing required field" do
      expect(check(:post, "/transaction/initialize", body: {amount: 1000}))
        .to contain_exactly(match(/missing required properties: email/))
    end

    it "rejects a value of the wrong type" do
      expect(check(:post, "/transaction/initialize", body: {email: "a@b.co", amount: "1000"}))
        .to contain_exactly(match(/\/amount.*not an integer/))
    end

    it "rejects a value outside an enum" do
      expect(check(:post, "/transaction/initialize", body: {email: "a@b.co", amount: 1, currency: "EUR"}))
        .to contain_exactly(match(/\/currency.*one of/))
    end

    it "accepts a whole number where the spec says number (float is a hint, not a constraint)" do
      body = {business_name: "Ama's Shop", settlement_bank: "044", account_number: "0123456789", percentage_charge: 10}
      expect(check(:post, "/subaccount", body: body)).to eq([])
    end

    it "rejects a field the spec does not have" do
      expect(check(:post, "/transaction/initialize", body: {email: "a@b.co", amount: 1, amnount: 2}))
        .to contain_exactly(match(/unknown body field `amnount`/))
    end

    it "honours required fields declared in a base schema" do
      expect(check(:post, "/transfer", body: {source: "balance", amount: 1, recipient: "RCP_1"}))
        .to contain_exactly(match(/missing required properties: reference/))
    end

    it "catches an object sent where the spec wants stringified JSON" do
      body = {email: "a@b.co", amount: 1, authorization_code: "AUTH_1", metadata: {a: 1}}
      expect(check(:post, "/transaction/charge_authorization", body: body))
        .to contain_exactly(match(/\/metadata.*not a string/))
    end

    it "accepts a body field the exceptions file records as differing from the spec" do
      # customer metadata: the spec says stringified JSON, Paystack requires an object
      expect(check(:put, "/customer/CUS_1", body: {metadata: {a: 1}})).to eq([])
    end

    it "lets a renamed body field satisfy the spec's required field" do
      # subaccount bank_code: the docs' name for the spec's required settlement_bank
      body = {business_name: "Ama's Shop", bank_code: "MTN", account_number: "0551234987", percentage_charge: 10}
      expect(check(:post, "/subaccount", body: body)).to eq([])
      expect(check(:post, "/subaccount", body: body.except(:bank_code)))
        .to contain_exactly(match(/missing required properties: settlement_bank/))
    end

    it "checks nested objects the spec describes" do
      body = {email: "a@b.co", amount: 1, mobile_money: {phone: "0551234987", provider: "mtn", bogus: 1}}
      expect(check(:post, "/charge", body: body)).to contain_exactly(match(/unknown body field `mobile_money.bogus`/))
    end

    it "lets an exception excuse a field the spec requires but the API does not" do
      # payment request amount: Paystack adds up line_items and tax when it is left out
      body = {customer: "CUS_1", line_items: [{name: "Seat", amount: 2000}]}
      expect(check(:post, "/paymentrequest", body: body)).to eq([])
      expect(check(:post, "/paymentrequest", body: {amount: 2000}))
        .to contain_exactly(match(/missing required properties: customer/))
    end

    it "rejects a body on an operation that takes none" do
      expect(check(:get, "/bank", body: {a: 1})).to contain_exactly(match(/takes no request body/))
    end

    it "accepts a body of docs-only fields on an operation the spec gives none" do
      # Finalize Payment Request: the docs list send_notification; the spec has no body
      expect(check(:post, "/paymentrequest/finalize/PRQ_1", body: {send_notification: false})).to eq([])
      expect(check(:post, "/paymentrequest/finalize/PRQ_1", body: {bogus: 1})).to contain_exactly(match(/takes no request body/))
    end

    it "rejects a missing body where one is required" do
      expect(check(:post, "/transaction/initialize", headers: json)).to contain_exactly(match(/requires a request body/))
    end

    it "rejects a body that is not JSON" do
      expect(check(:post, "/transaction/initialize", body: "email=a%40b.co", headers: json))
        .to contain_exactly(match(/not valid JSON/))
    end
  end

  describe "headers" do
    it "requires a bearer token" do
      expect(check(:get, "/bank", headers: {})).to contain_exactly(match(/Authorization: Bearer/))
    end

    it "requires a JSON content type when there is a body" do
      expect(check(:post, "/transaction/initialize", body: {email: "a@b.co", amount: 1}, headers: auth))
        .to contain_exactly(match(/Content-Type: application\/json/))
    end
  end

  describe "violations collected during a spec" do
    it "records requests to api.paystack.co and ignores other hosts" do
      described_class.reset
      stub_request(:any, /.*/).to_return(status: 200, body: "{}")
      Faraday.get("#{url}/bank?nope=1", nil, auth)
      Faraday.get("https://example.com/anything?x=1")

      expect(described_class.violations.size).to eq(1)
      expect(described_class.violations.first).to match(/nope/)
      described_class.reset
    end
  end
end
