# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs (Transfers Control page) and test API that the generated
# wire-shape specs do not exercise. Response bodies below are shaped like real test API responses.
RSpec.describe PaystackSdk::Resources::Balances do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:balances) { client.balances }
  let(:json) { {"Content-Type" => "application/json"} }

  describe "#fetch" do
    it "returns one entry per currency, with the balance in the currency's subunit" do
      stub = stub_request(:get, "https://api.paystack.co/balance")
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true,
            message: "Balances retrieved",
            data: [{currency: "GHS", balance: 48400}]
          }.to_json
        )

      response = balances.fetch

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.data.size).to eq(1)
      expect(response.data.first.currency).to eq("GHS")
      expect(response.data.first.balance).to eq(48400)
    end

    it "raises on an invalid key, as every other resource does" do
      stub_request(:get, "https://api.paystack.co/balance")
        .to_return(status: 401, headers: json, body: {status: false, message: "Invalid key"}.to_json)

      expect { balances.fetch }.to raise_error(PaystackSdk::AuthenticationError)
    end
  end

  describe "#ledger" do
    let(:body) do
      {
        status: true,
        message: "Balance ledger retrieved",
        data: [
          {
            balance: 48400, createdAt: "2026-10-09T10:25:44.000Z", currency: "GHS", difference: 100,
            domain: "test", id: 2512059357, integration: 2047140, model_responsible: "Transaction",
            model_row: 6640226336, reason: "", updatedAt: "2026-10-09T10:25:44.000Z"
          },
          {
            balance: 48300, createdAt: "2026-10-09T09:44:22.000Z", currency: "GHS", difference: -2500,
            domain: "test", id: 2512020828, integration: 2047140, model_responsible: "Refund",
            model_row: 1, reason: "", updatedAt: "2026-10-09T09:44:22.000Z"
          }
        ],
        meta: {total: 17, skipped: 0, perPage: 2, page: 1, pageCount: 9}
      }.to_json
    end

    it "sends per_page as perPage, with page, and returns entries and pagination meta" do
      stub = stub_request(:get, "https://api.paystack.co/balance/ledger")
        .with(query: {"perPage" => "2", "page" => "1"})
        .to_return(status: 200, headers: json, body: body)

      response = balances.ledger(per_page: 2, page: 1)

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.data.first.difference).to eq(100)
      expect(response.data.last.difference).to eq(-2500)
      expect(response.data.last.model_responsible).to eq("Refund")
      expect(response.meta.pageCount).to eq(9)
    end

    it "sends from and to as dates" do
      stub = stub_request(:get, "https://api.paystack.co/balance/ledger")
        .with(query: {"from" => "2026-10-01", "to" => "2026-10-31"})
        .to_return(status: 200, headers: json, body: body)

      balances.ledger(from: Date.new(2026, 10, 1), to: "2026-10-31")

      expect(stub).to have_been_requested
    end

    it "returns an unsuccessful response for a date Paystack rejects" do
      stub_request(:get, "https://api.paystack.co/balance/ledger")
        .with(query: {"from" => "2026-10-01"})
        .to_return(
          status: 400,
          headers: json,
          body: {status: false, message: "Invalid 'from' date passed", type: "validation_error", code: "invalid_params"}.to_json
        )

      response = balances.ledger(from: "2026-10-01")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Invalid 'from' date passed")
    end

    it "refuses a date that is not ISO 8601 before sending anything" do
      expect { balances.ledger(from: "yesterday") }.to raise_error(PaystackSdk::InvalidFormatError)
    end
  end
end
