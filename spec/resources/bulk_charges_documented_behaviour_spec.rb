# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API (2026-10-09) that the generated wire-shape
# specs do not exercise. Response bodies are trimmed copies of real test-mode responses.
RSpec.describe PaystackSdk::Resources::BulkCharges do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:bulk_charges) { client.bulk_charges }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:batch) do
    {
      batch_code: "BCH_1uhxe0d181eu850", reference: "bulkcharge-1791555840669-len2stmluk", id: 235161370,
      integration: 2047140, domain: "test", status: "active", total_charges: 1, pending_charges: 1,
      createdAt: "2026-10-09T14:24:00.670Z", updatedAt: "2026-10-09T14:24:00.670Z"
    }
  end
  let(:not_found) do
    {
      status: 404,
      headers: json,
      body: {
        status: false, message: "Bulk charge code not found", type: "validation_error", code: "not_found",
        meta: {nextStep: "Ensure that you're passing the correct reference for the requested resource that exists on this integration"}
      }.to_json
    }
  end

  describe "#initiate" do
    it "sends the charges as the JSON array body and returns the queued batch" do
      stub = stub_request(:post, "https://api.paystack.co/bulkcharge")
        .with(body: [{authorization: "AUTH_50w0d0f5xo", amount: 100, reference: "sdk-bulk-probe-20261009a"}].to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Charges have been queued", data: batch}.to_json)

      response = bulk_charges.initiate(
        charges: [{authorization: "AUTH_50w0d0f5xo", amount: 100, reference: "sdk-bulk-probe-20261009a"}]
      )

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.message).to eq("Charges have been queued")
      expect(response.batch_code).to eq("BCH_1uhxe0d181eu850")
      expect(response.pending_charges).to eq(1)
    end

    it "refuses an empty list without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { bulk_charges.initiate(charges: []) }.to raise_error(PaystackSdk::MissingParamError, /charges/)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#fetch_batch" do
    it "takes the batch's numeric ID as well as its code" do
      stub = stub_request(:get, "https://api.paystack.co/bulkcharge/235161370")
        .to_return(status: 200, headers: json, body: {status: true, message: "Bulk charge retrieved", data: batch.merge(status: "paused")}.to_json)

      response = bulk_charges.fetch_batch(id_or_code: 235161370)

      expect(stub).to have_been_requested
      expect(response.status).to eq("paused")
    end

    it "returns Paystack's refusal for an unknown batch as an unsuccessful response" do
      stub_request(:get, "https://api.paystack.co/bulkcharge/BCH_doesnotexist123").to_return(not_found)

      response = bulk_charges.fetch_batch(id_or_code: "BCH_doesnotexist123")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Bulk charge code not found")
    end
  end

  describe "#fetch_charges" do
    it "filters by status and pages with perPage" do
      stub = stub_request(:get, "https://api.paystack.co/bulkcharge/BCH_1uhxe0d181eu850/charges")
        .with(query: {status: "success", perPage: "1", page: "1"})
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true,
            message: "Bulk charge items retrieved",
            data: [{bulkcharge: 235161370, amount: 100, currency: "GHS", reference: "sdk-bulk-probe-20261009a", status: "success", message: "Approved"}],
            meta: {total: 1, skipped: 0, perPage: 1, page: 1, pageCount: 1}
          }.to_json
        )

      response = bulk_charges.fetch_charges(id_or_code: "BCH_1uhxe0d181eu850", status: "success", per_page: 1, page: 1)

      expect(stub).to have_been_requested
      expect(response.data.first.reference).to eq("sdk-bulk-probe-20261009a")
      expect(response.meta.perPage).to eq(1)
    end
  end

  describe "#pause_batch and #resume_batch" do
    it "pause with a GET, as the docs and the API do" do
      stub = stub_request(:get, "https://api.paystack.co/bulkcharge/pause/BCH_1uhxe0d181eu850")
        .to_return(status: 200, headers: json, body: {status: true, message: "Bulk charge batch has been paused"}.to_json)

      response = bulk_charges.pause_batch(batch_code: "BCH_1uhxe0d181eu850")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.message).to eq("Bulk charge batch has been paused")
    end

    it "resume with a GET, as the docs and the API do" do
      stub = stub_request(:get, "https://api.paystack.co/bulkcharge/resume/BCH_1uhxe0d181eu850")
        .to_return(status: 200, headers: json, body: {status: true, message: "Bulk charge batch has been resumed"}.to_json)

      response = bulk_charges.resume_batch(batch_code: "BCH_1uhxe0d181eu850")

      expect(stub).to have_been_requested
      expect(response.message).to eq("Bulk charge batch has been resumed")
    end
  end
end
