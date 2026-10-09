# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API (2026-10-09) that the generated wire-shape
# specs do not exercise. Error bodies are copies of real test-mode responses; the mandate record is the
# docs' sample. Trigger Activation Charge was not called live (it charges customers' bank accounts), so
# its specs follow the docs' sample request and response.
RSpec.describe PaystackSdk::Resources::DirectDebits do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:direct_debits) { client.direct_debits }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:mandate) do
    {
      id: 112244, status: "active", mandate_id: 1560169, authorization_id: 1069309917,
      authorization_code: "AUTH_lEt8QgrSfW", integration_id: 463433, account_number: "0123456789",
      bank_code: "058", bank_name: "Guaranty Trust Bank",
      customer: {id: 28958104, customer_code: "CUS_5kye9bc41uw15pb", email: "customer@email.com", first_name: "Booker", last_name: "Jones"},
      authorized_at: "2025-06-23T12:47:10.632Z"
    }
  end

  describe "#trigger_activation_charge" do
    it "sends the customer IDs as a customer_ids array (docs sample)" do
      stub = stub_request(:put, "https://api.paystack.co/directdebit/activation-charge")
        .with(body: {customer_ids: [28958104, 983697220]}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Mandate is queued for retry"}.to_json)

      response = direct_debits.trigger_activation_charge(customer_ids: [28958104, 983697220])

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.message).to eq("Mandate is queued for retry")
    end

    it "refuses an empty list without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { direct_debits.trigger_activation_charge(customer_ids: []) }
        .to raise_error(PaystackSdk::MissingParamError, /customer_ids/)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#list_mandate_authorizations" do
    it "filters by status, pages by cursor and per_page, and exposes the cursor meta" do
      stub = stub_request(:get, "https://api.paystack.co/directdebit/mandate-authorizations")
        .with(query: {status: "active", per_page: "10", cursor: "MTI1OTc="})
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true, message: "Mandate authorizations retrieved successfully", data: [mandate],
            meta: {per_page: 10, next: "MTI1OTc=", count: 10, total: 40}
          }.to_json
        )

      response = direct_debits.list_mandate_authorizations(status: "active", per_page: 10, cursor: "MTI1OTc=")

      expect(stub).to have_been_requested
      expect(response.first.authorization_code).to eq("AUTH_lEt8QgrSfW")
      expect(response.first.customer.id).to eq(28958104)
      expect(response.meta.next).to eq("MTI1OTc=")
    end

    it "needs no parameters and returns an empty list with a null next cursor when there are none" do
      stub_request(:get, "https://api.paystack.co/directdebit/mandate-authorizations")
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true, message: "Mandate authorizations retrieved successfully", data: [],
            meta: {per_page: 50, next: nil, count: 0}
          }.to_json
        )

      response = direct_debits.list_mandate_authorizations

      expect(response).to be_success
      expect(response.to_a).to be_empty
      expect(response.meta.per_page).to eq(50)
      expect(response.meta.next).to be_nil
    end

    it "refuses a status outside pending, active and revoked without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { direct_debits.list_mandate_authorizations(status: "failed") }
        .to raise_error(PaystackSdk::InvalidValueError, /status/)
      expect(stub).not_to have_been_requested
    end

    it "raises on the 500 Paystack returns for a cursor it cannot read" do
      stub_request(:get, "https://api.paystack.co/directdebit/mandate-authorizations")
        .with(query: {cursor: "bogus"})
        .to_return(
          status: 500,
          headers: json,
          body: {
            status: false, message: "Something went wrong while getting Mandate authorizations!", data: [],
            meta: {nextStep: "Ensure that the value(s) you're passing are valid."},
            type: "validation_error", code: "invalid_params"
          }.to_json
        )

      expect { direct_debits.list_mandate_authorizations(cursor: "bogus") }
        .to raise_error(PaystackSdk::ServerError, /Something went wrong while getting Mandate authorizations!/)
    end
  end
end
