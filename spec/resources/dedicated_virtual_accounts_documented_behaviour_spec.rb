# frozen_string_literal: true

# Behaviour seen on Paystack's test API, or shown on the docs page, that the generated wire-shape specs
# do not exercise.
RSpec.describe PaystackSdk::Resources::DedicatedVirtualAccounts do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:dedicated_virtual_accounts) { client.dedicated_virtual_accounts }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:ok) { {status: 200, headers: json, body: {status: true, message: "ok", data: {}}.to_json} }

  # The body every Dedicated Virtual Account endpoint returned on a test integration without the
  # feature (confirmed against the Paystack test API on 2026-10-09, a GHS integration).
  let(:feature_unavailable) do
    {
      status: 403,
      headers: json,
      body: {
        status: false,
        message: "Dedicated NUBAN is not available for your business",
        meta: {nextStep: "You can send us an email at support@paystack.com to make a request for the service"},
        type: "api_error",
        code: "feature_unavailable"
      }.to_json
    }
  end

  describe "an integration without Dedicated Virtual Accounts" do
    it "gets Paystack's 403 back as an unsuccessful response, not an exception" do
      stub_request(:get, "https://api.paystack.co/dedicated_account/available_providers").to_return(feature_unavailable)

      response = dedicated_virtual_accounts.fetch_bank_providers

      expect(response).not_to be_success
      expect(response.status_code).to eq(403)
      expect(response.error_message).to eq("Dedicated NUBAN is not available for your business")
    end

    it "gets the same refusal from a write" do
      stub_request(:post, "https://api.paystack.co/dedicated_account").to_return(feature_unavailable)

      response = dedicated_virtual_accounts.create(customer: "CUS_xnxdt6s1zg1f4nx")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Dedicated NUBAN is not available for your business")
    end
  end

  describe "#list" do
    it "sends per_page as perPage and the filters by the names the docs use" do
      stub = stub_request(:get, "https://api.paystack.co/dedicated_account")
        .with(query: {active: "true", currency: "NGN", provider_slug: "wema-bank", perPage: "10", page: "2"})
        .to_return(ok)

      dedicated_virtual_accounts.list(active: true, currency: "NGN", provider_slug: "wema-bank", per_page: 10, page: 2)

      expect(stub).to have_been_requested
    end
  end

  describe "#fetch_bank_providers" do
    it "returns the providers, as the docs sample shows them" do
      stub_request(:get, "https://api.paystack.co/dedicated_account/available_providers")
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true,
            message: "Dedicated account providers retrieved",
            data: [
              {provider_slug: "titan-paystack", bank_id: 629, bank_name: "Paystack-Titan", id: 9},
              {provider_slug: "wema-bank", bank_id: 20, bank_name: "Wema Bank", id: 5}
            ]
          }.to_json
        )

      response = dedicated_virtual_accounts.fetch_bank_providers

      expect(response).to be_success
      expect(response.data.first.provider_slug).to eq("titan-paystack")
      expect(response.data.first.bank_id).to eq(629)
    end
  end

  describe "#add_split" do
    it "posts the account number and split to /dedicated_account/split, as the spec describes it" do
      stub = stub_request(:post, "https://api.paystack.co/dedicated_account/split")
        .with(body: {account_number: "0033322211", split_code: "SPL_e7jnRLtzla"}.to_json)
        .to_return(ok)

      dedicated_virtual_accounts.add_split(account_number: "0033322211", split_code: "SPL_e7jnRLtzla")

      expect(stub).to have_been_requested
    end
  end

  describe "#remove_split" do
    it "sends the account number in the body of a DELETE" do
      stub = stub_request(:delete, "https://api.paystack.co/dedicated_account/split")
        .with(body: {account_number: "0033322211"}.to_json)
        .to_return(ok)

      dedicated_virtual_accounts.remove_split(account_number: "0033322211")

      expect(stub).to have_been_requested
    end
  end

  describe "#fetch" do
    it "refuses a missing dedicated_account_id without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

      expect { dedicated_virtual_accounts.fetch(dedicated_account_id: nil) }
        .to raise_error(PaystackSdk::MissingParamError, /dedicated_account_id/)
      expect(stub).not_to have_been_requested
    end
  end
end
