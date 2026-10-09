# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API that differs from the OpenAPI spec, or that
# the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
RSpec.describe PaystackSdk::Resources::Subaccounts do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:subaccounts) { client.subaccounts }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:ok) { {status: 200, headers: json, body: {status: true, message: "ok", data: {}}.to_json} }

  describe "#create" do
    let(:params) do
      {business_name: "Grace Chapel Accra", bank_code: "MTN", account_number: "0551234987", percentage_charge: 2.5}
    end

    it "sends bank_code, as Paystack's docs name the settlement bank, and returns the subaccount" do
      stub = stub_request(:post, "https://api.paystack.co/subaccount")
        .with(body: params.to_json)
        .to_return(
          status: 201,
          headers: json,
          body: {
            status: true,
            message: "Subaccount created",
            data: {
              business_name: "Grace Chapel Accra", account_number: "0551234987", percentage_charge: 2.5,
              settlement_bank: "MTN", currency: "GHS", bank: 28, integration: 463433, domain: "test",
              subaccount_code: "ACCT_6uujpqtzmnufzkw", is_verified: false, settlement_schedule: "AUTO",
              active: true, id: 1151727
            }
          }.to_json
        )

      response = subaccounts.create(**params)

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.subaccount_code).to eq("ACCT_6uujpqtzmnufzkw")
      expect(response.settlement_bank).to eq("MTN")
      expect(response.active).to be(true)
    end

    it "returns Paystack's refusal as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/subaccount")
        .to_return(
          status: 400,
          headers: json,
          body: {
            status: false,
            message: "Settlement Bank is invalid",
            meta: {nextStep: "Ensure that the value(s) you're passing are valid."},
            type: "validation_error",
            code: "invalid_params"
          }.to_json
        )

      response = subaccounts.create(**params, bank_code: "XYZ")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Settlement Bank is invalid")
    end

    it "sends metadata as stringified JSON, as the docs and spec describe it" do
      stub = stub_request(:post, "https://api.paystack.co/subaccount")
        .with(body: params.merge(metadata: {branch: "Osu"}.to_json).to_json)
        .to_return(ok)

      subaccounts.create(**params, metadata: {branch: "Osu"})

      expect(stub).to have_been_requested
    end

    it "refuses a missing bank_code without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

      expect { subaccounts.create(**params, bank_code: nil) }.to raise_error(PaystackSdk::MissingParamError, /bank_code/)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#list" do
    # Paystack reads active=1 as active and any other value (true included) as inactive.
    it "sends active as 1 or 0, with perPage and page" do
      stub = stub_request(:get, "https://api.paystack.co/subaccount")
        .with(query: {perPage: "20", page: "2", active: "1"})
        .to_return(ok)

      subaccounts.list(per_page: 20, page: 2, active: 1)

      expect(stub).to have_been_requested
    end
  end

  describe "#fetch" do
    it "takes a subaccount code or numeric ID" do
      stub = stub_request(:get, "https://api.paystack.co/subaccount/1151727").to_return(ok)

      subaccounts.fetch(id_or_code: 1151727)

      expect(stub).to have_been_requested
    end
  end

  describe "#update" do
    it "sends only the fields given; business_name and description are optional" do
      stub = stub_request(:put, "https://api.paystack.co/subaccount/ACCT_6uujpqtzmnufzkw")
        .with(body: {active: false}.to_json)
        .to_return(ok)

      subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", active: false)

      expect(stub).to have_been_requested
    end

    it "sends a new settlement account as bank_code and account_number" do
      stub = stub_request(:put, "https://api.paystack.co/subaccount/ACCT_6uujpqtzmnufzkw")
        .with(body: {bank_code: "040100", account_number: "1234567890123"}.to_json)
        .to_return(ok)

      subaccounts.update(id_or_code: "ACCT_6uujpqtzmnufzkw", bank_code: "040100", account_number: "1234567890123")

      expect(stub).to have_been_requested
    end
  end
end
