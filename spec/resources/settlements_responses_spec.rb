# frozen_string_literal: true

# Request and response behaviour for Settlements beyond the generated wire-shape specs in
# settlements_spec.rb (kept apart so that file stays exactly what bin/paystack-scaffold writes).
RSpec.describe PaystackSdk::Resources::Settlements do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:json) { {"Content-Type" => "application/json"} }

  describe "#list" do
    it "returns the settlements Paystack reports" do
      body = {
        status: true,
        message: "Settlements retrieved",
        data: [{id: 3090024, status: "success", currency: "NGN", total_amount: 995, settlement_date: "2022-11-09T00:00:00.000Z"}],
        meta: {total: 1, skipped: 0, perPage: 50, page: 1, pageCount: 1}
      }
      stub_request(:get, "https://api.paystack.co/settlement").to_return(status: 200, headers: json, body: body.to_json)

      response = client.settlements.list

      expect(response).to be_success
      expect(response.data.first.id).to eq(3090024)
      expect(response.data.first.total_amount).to eq(995)
    end

    it "sends perPage, page, from and to under the names Paystack documents" do
      stub = stub_request(:get, "https://api.paystack.co/settlement")
        .with(query: {"perPage" => "20", "page" => "2", "from" => "2026-01-01T00:00:00Z", "to" => "2026-01-31T23:59:59Z"})
        .to_return(status: 200, headers: json, body: {status: true, message: "ok", data: []}.to_json)

      client.settlements.list(per_page: 20, page: 2, from: "2026-01-01T00:00:00Z", to: "2026-01-31T23:59:59Z")

      expect(stub).to have_been_requested
    end

    it "returns an unsuccessful response when Paystack rejects the request" do
      body = {status: false, message: "Invalid 'from' date passed", type: "validation_error", code: "invalid_params"}
      stub_request(:get, "https://api.paystack.co/settlement").with(query: {"from" => "notadate"})
        .to_return(status: 400, headers: json, body: body.to_json)

      response = client.settlements.list(from: "notadate")

      expect(response).not_to be_success
      expect(response.message).to eq("Invalid 'from' date passed")
    end

    it "rejects a non-positive page before sending anything" do
      expect { client.settlements.list(page: 0) }.to raise_error(PaystackSdk::InvalidValueError)
    end
  end

  describe "#transactions" do
    it "returns the transactions that make up a settlement" do
      body = {
        status: true,
        message: "Transactions retrieved",
        data: [{id: 2067030515, status: "success", reference: "da8ed5u8sz6yn95", amount: 10000, fees: 390}]
      }
      stub_request(:get, "https://api.paystack.co/settlement/2856168/transactions")
        .to_return(status: 200, headers: json, body: body.to_json)

      response = client.settlements.transactions(id: 2856168)

      expect(response).to be_success
      expect(response.data.first.reference).to eq("da8ed5u8sz6yn95")
    end

    it "returns an unsuccessful response for a settlement that does not exist" do
      body = {status: false, message: "Settlement not found", type: "validation_error", code: "not_found"}
      stub_request(:get, "https://api.paystack.co/settlement/1/transactions")
        .to_return(status: 404, headers: json, body: body.to_json)

      response = client.settlements.transactions(id: 1)

      expect(response).not_to be_success
      expect(response.message).to eq("Settlement not found")
    end

    it "requires an id" do
      expect { client.settlements.transactions(id: nil) }.to raise_error(PaystackSdk::MissingParamError)
    end
  end
end
