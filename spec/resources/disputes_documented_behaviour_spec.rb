# frozen_string_literal: true

# Responses and wire details the generated wire-shape specs do not exercise. The failure bodies are
# the ones Paystack's test API returned on 2026-10-09 (the account has no disputes).
# delivery_date: the spec says date-time, the docs say YYYY-MM-DD, and the test API could not settle it
# (it looks up the dispute first), so the SDK passes either ISO form through and this spec uses the spec form.
RSpec.describe PaystackSdk::Resources::Disputes do
  let(:resource) { described_class.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:json) { {"Content-Type" => "application/json"} }

  describe "#list" do
    it "returns the disputes and paging meta" do
      body = {
        status: true,
        message: "Disputes retrieved",
        data: [{id: 2867, status: "pending", refund_amount: nil, transaction: {id: 5991760, reference: "asjck8gf76zd1dr"}}],
        meta: {total: 1, skipped: 0, perPage: 50, page: 1, pageCount: 1}
      }
      stub_request(:get, "https://api.paystack.co/dispute").to_return(status: 200, headers: json, body: body.to_json)

      response = resource.list

      expect(response).to be_success
      expect(response.data.first.id).to eq(2867)
      expect(response.data.first.transaction.reference).to eq("asjck8gf76zd1dr")
    end

    it "sends per_page as perPage with the filters" do
      stub = stub_request(:get, "https://api.paystack.co/dispute")
        .with(query: {"perPage" => "20", "page" => "2", "status" => "pending", "transaction" => "5991760", "from" => "2026-01-01", "to" => "2026-01-31"})
        .to_return(status: 200, headers: json, body: {status: true, message: "ok", data: []}.to_json)

      resource.list(per_page: 20, page: 2, status: "pending", transaction: "5991760", from: "2026-01-01", to: "2026-01-31")

      expect(stub).to have_been_requested
    end

    it "refuses a status Paystack does not list before sending anything" do
      expect { resource.list(status: "bogus") }.to raise_error(PaystackSdk::Error, /status/)
    end

    it "returns an unsuccessful response when Paystack rejects a filter" do
      body = {status: false, message: "Invalid 'from' date passed", type: "validation_error", code: "invalid_params"}
      stub_request(:get, "https://api.paystack.co/dispute").with(query: {"from" => "2026-01-01"})
        .to_return(status: 400, headers: json, body: body.to_json)

      response = resource.list(from: "2026-01-01")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Invalid 'from' date passed")
    end
  end

  describe "#fetch" do
    it "returns an unsuccessful response for a dispute that does not exist" do
      body = {status: false, message: "Dispute not found", type: "validation_error", code: "not_found"}
      stub_request(:get, "https://api.paystack.co/dispute/123").to_return(status: 404, headers: json, body: body.to_json)

      response = resource.fetch(id: 123)

      expect(response).not_to be_success
      expect(response.error_message).to eq("Dispute not found")
    end
  end

  describe "#fetch_upload_url" do
    it "sends upload_filename and returns the signed URL" do
      body = {status: true, message: "Upload url generated", data: {signedUrl: "https://s3.example/x.pdf?sig=1", fileName: "x.pdf"}}
      stub = stub_request(:get, "https://api.paystack.co/dispute/1/upload_url")
        .with(query: {"upload_filename" => "a.pdf"})
        .to_return(status: 200, headers: json, body: body.to_json)

      response = resource.fetch_upload_url(id: 1, upload_filename: "a.pdf")

      expect(stub).to have_been_requested
      expect(response.data.fileName).to eq("x.pdf")
    end
  end

  describe "#update" do
    it "sends refund_amount and uploaded_filename in the body" do
      stub = stub_request(:put, "https://api.paystack.co/dispute/1")
        .with(body: {refund_amount: 5000, uploaded_filename: "x.pdf"}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Dispute updated successfully", data: {}}.to_json)

      expect(resource.update(id: 1, refund_amount: 5000, uploaded_filename: "x.pdf")).to be_success
      expect(stub).to have_been_requested
    end
  end

  describe "#resolve" do
    it "puts every field in the body of PUT /dispute/{id}/resolve" do
      stub = stub_request(:put, "https://api.paystack.co/dispute/1/resolve")
        .with(body: {resolution: "merchant-accepted", message: "Refunded", refund_amount: 5000, uploaded_filename: "x.pdf", evidence: 9}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Dispute successfully resolved", data: {status: "resolved"}}.to_json)

      response = resource.resolve(
        id: 1, resolution: "merchant-accepted", message: "Refunded", refund_amount: 5000, uploaded_filename: "x.pdf", evidence: 9
      )

      expect(response.data.status).to eq("resolved")
      expect(stub).to have_been_requested
    end
  end

  describe "#add_evidence" do
    it "sends the evidence fields and returns the created evidence" do
      fields = {
        customer_email: "cus@example.com", customer_name: "Ama Mensah", customer_phone: "0802345167",
        service_details: "Tithe payment", delivery_address: "1 Church Road", delivery_date: "2026-01-31T00:00:00Z"
      }
      stub = stub_request(:post, "https://api.paystack.co/dispute/1/evidence")
        .with(body: fields.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Evidence created", data: fields.merge(id: 7)}.to_json)

      response = resource.add_evidence(id: 1, **fields)

      expect(response).to be_success
      expect(response.data.id).to eq(7)
      expect(stub).to have_been_requested
    end
  end

  describe "#export" do
    it "returns the export path" do
      body = {status: true, message: "Export successful", data: {path: "https://s3.example/disputes.csv", expiresAt: "2026-10-09 11:58:18"}}
      stub_request(:get, "https://api.paystack.co/dispute/export").to_return(status: 200, headers: json, body: body.to_json)

      expect(resource.export.data.path).to eq("https://s3.example/disputes.csv")
    end

    it "returns an unsuccessful response when there is nothing to export" do
      body = {status: false, message: "No disputes found", type: "api_error", code: "unknown"}
      stub_request(:get, "https://api.paystack.co/dispute/export").to_return(status: 404, headers: json, body: body.to_json)

      response = resource.export

      expect(response).not_to be_success
      expect(response.error_message).to eq("No disputes found")
    end
  end

  describe "#list_transaction" do
    it "returns an unsuccessful response when the transaction has no dispute" do
      body = {status: false, message: "Dispute not found", type: "validation_error", code: "not_found"}
      stub_request(:get, "https://api.paystack.co/dispute/transaction/123").to_return(status: 404, headers: json, body: body.to_json)

      expect(resource.list_transaction(id: 123)).not_to be_success
    end
  end
end
