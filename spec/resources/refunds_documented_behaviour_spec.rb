# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API (2026-10-09) that differs from the OpenAPI spec,
# or that the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
# Response bodies are trimmed copies of what the test API returned, with personal details replaced, except
# the retry response, which follows the docs sample (no test refund was in a state that allows a retry).
RSpec.describe PaystackSdk::Resources::Refunds do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:json) { {"Content-Type" => "application/json"} }

  let(:queued_partial) do
    {
      status: true,
      message: "Refund has been queued for processing",
      data: {
        integration: 100_032,
        transaction: {id: 6_638_079_211, domain: "test", reference: "attd14x21t", amount: 10_000, currency: "GHS",
                      channel: "mobile_money", paid_at: "2026-10-08T17:05:41.000Z", requested_amount: 10_000},
        id: 18_625_648,
        domain: "test",
        currency: "GHS",
        amount: 2500,
        status: "pending",
        expected_at: "2026-10-20T09:44:22.668Z",
        channel: "mtn_gha",
        refunded_by: "admin@example.com",
        customer_note: "Duplicate tithe",
        merchant_note: "Refunded by the finance team",
        deducted_amount: 0,
        fully_deducted: false,
        reason: "PENDING",
        customer: nil,
        initiated_by: "admin@example.com",
        session_id: nil
      }
    }
  end

  describe "#create" do
    it "sends a partial refund by transaction reference, with the currency and notes" do
      stub = stub_request(:post, "https://api.paystack.co/refund")
        .with(body: {transaction: "attd14x21t", amount: 2500, currency: "GHS",
                     customer_note: "Duplicate tithe", merchant_note: "Refunded by the finance team"}.to_json)
        .to_return(status: 200, headers: json, body: queued_partial.to_json)

      response = client.refunds.create(transaction: "attd14x21t", amount: 2500, currency: "GHS",
        customer_note: "Duplicate tithe", merchant_note: "Refunded by the finance team")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.message).to eq("Refund has been queued for processing")
      expect(response.data.id).to eq(18_625_648)
      expect(response.data.amount).to eq(2500)
      expect(response.data.status).to eq("pending")
      expect(response.data.transaction.reference).to eq("attd14x21t")
    end

    # The docs say "Transaction reference or id"; the test API accepts the ID as a JSON integer.
    # With no amount Paystack refunds the whole transaction amount.
    it "sends a full refund by transaction ID as an integer, leaving amount out" do
      stub = stub_request(:post, "https://api.paystack.co/refund")
        .with(body: {transaction: 6_639_844_361}.to_json)
        .to_return(status: 200, headers: json, body: {
          status: true,
          message: "Refund has been queued for processing",
          data: {transaction: {id: 6_639_844_361, reference: "ne41x69actv8b1e", amount: 100, currency: "GHS"},
                 id: 18_625_649, currency: "GHS", amount: 100, status: "pending"}
        }.to_json)

      response = client.refunds.create(transaction: 6_639_844_361)

      expect(stub).to have_been_requested
      expect(response.data.amount).to eq(100)
    end

    it "returns an unsuccessful response for a transaction Paystack does not know" do
      stub_request(:post, "https://api.paystack.co/refund")
        .with(body: {transaction: "no-such-reference"}.to_json)
        .to_return(status: 400, headers: json, body: {
          status: false,
          message: "Transaction not found",
          type: "validation_error",
          code: "transaction_not_found",
          meta: {nextStep: "Ensure the transaction reference or ID is correct"}
        }.to_json)

      response = client.refunds.create(transaction: "no-such-reference")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Transaction not found")
      expect(response.error_details[:status_code]).to eq(400)
    end

    it "returns an unsuccessful response for an amount above the transaction amount" do
      stub_request(:post, "https://api.paystack.co/refund")
        .to_return(status: 400, headers: json, body: {
          status: false,
          message: "Refund amount exceeds transaction amount",
          type: "validation_error",
          code: "refund_amount_exceeds_transaction_amount",
          meta: {nextStep: "The refund amount should not exceed original transaction amount."}
        }.to_json)

      response = client.refunds.create(transaction: "attd14x21t", amount: 10_000_000)

      expect(response).not_to be_success
      expect(response.error_message).to eq("Refund amount exceeds transaction amount")
    end

    it "refuses an amount that is not a positive integer, without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { client.refunds.create(transaction: "attd14x21t", amount: 0) }
        .to raise_error(PaystackSdk::InvalidValueError, /amount/)
      expect(stub).not_to have_been_requested
    end

    it "refuses a currency the spec does not list, without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { client.refunds.create(transaction: "attd14x21t", currency: "XYZ") }
        .to raise_error(PaystackSdk::InvalidValueError, /currency/)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#list" do
    # transaction filters by the numeric transaction ID; a reference returns no refunds.
    it "filters by transaction ID and pages with perPage" do
      stub = stub_request(:get, "https://api.paystack.co/refund")
        .with(query: {transaction: "6638079211", perPage: "10", page: "1"})
        .to_return(status: 200, headers: json, body: {
          status: true,
          message: "Refunds retrieved",
          data: [{id: 18_625_648, transaction: 6_638_079_211, currency: "GHS", amount: 2500, status: "pending"}],
          meta: {total: 1, skipped: 0, perPage: 10, page: 1, pageCount: 1, totalRetriable: 0, partialAmountLeft: 7500}
        }.to_json)

      response = client.refunds.list(transaction_id: 6_638_079_211, per_page: 10, page: 1)

      expect(stub).to have_been_requested
      expect(response.first.id).to eq(18_625_648)
      expect(response.meta.partialAmountLeft).to eq(7500)
    end
  end

  describe "#fetch" do
    it "returns an unsuccessful response for a refund Paystack does not know" do
      stub_request(:get, "https://api.paystack.co/refund/999999999")
        .to_return(status: 404, headers: json, body: {
          status: false,
          message: "Refund not found",
          type: "validation_error",
          code: "not_found"
        }.to_json)

      response = client.refunds.fetch(id: 999_999_999)

      expect(response).not_to be_success
      expect(response.error_message).to eq("Refund not found")
    end
  end

  describe "#retry_with_customer_details" do
    it "sends the customer's account details as a refund_account_details object" do
      details = {currency: "GHS", account_number: "0123456789", bank_id: "9"}
      stub = stub_request(:post, "https://api.paystack.co/refund/retry_with_customer_details/18625648")
        .with(body: {refund_account_details: details}.to_json)
        .to_return(status: 200, headers: json, body: {
          status: true,
          message: "Refund retried and has been queued for processing",
          data: {id: 18_625_648, currency: "GHS", amount: 2500, status: "processing"}
        }.to_json)

      response = client.refunds.retry_with_customer_details(id: 18_625_648, refund_account_details: details)

      expect(stub).to have_been_requested
      expect(response.data.status).to eq("processing")
    end
  end
end
