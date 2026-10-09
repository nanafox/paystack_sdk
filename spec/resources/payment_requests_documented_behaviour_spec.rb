# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API that differs from the OpenAPI spec, or that
# the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
RSpec.describe PaystackSdk::Resources::PaymentRequests do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:payment_requests) { client.payment_requests }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:ok) { {status: 200, headers: json, body: {status: true, message: "ok", data: {}}.to_json} }
  let(:created) do
    {
      id: 24426435, integration: 2047140, domain: "test", amount: 4300, currency: "GHS",
      due_date: "2026-12-31T00:00:00.000Z", has_invoice: true, invoice_number: 1, description: "Harvest dues",
      line_items: [{name: "Seat", amount: 2000, quantity: 2}], tax: [{name: "VAT", amount: 300}],
      request_code: "PRQ_7w7dpecncnebg7e", status: "draft", paid: false, metadata: {branch: "Osu"},
      notifications: [], offline_reference: "204714024426435", customer: 407172149,
      created_at: "2026-10-09T12:12:20.897Z", discount: nil, split_code: nil, redirect_url: "https://example.com/done"
    }
  end

  describe "#create" do
    it "sends line items and tax without an amount (Paystack adds them up) and returns the request" do
      stub = stub_request(:post, "https://api.paystack.co/paymentrequest")
        .with(
          body: {
            customer: "CUS_p6i0reogc8ulu1n",
            currency: "GHS",
            due_date: "2026-12-31",
            description: "Harvest dues",
            line_items: [{name: "Seat", amount: 2000, quantity: 2}],
            tax: [{name: "VAT", amount: 300}],
            send_notification: false,
            draft: true,
            metadata: {branch: "Osu"},
            redirect_url: "https://example.com/done"
          }.to_json
        )
        .to_return(status: 200, headers: json, body: {status: true, message: "Payment request created", data: created}.to_json)

      response = payment_requests.create(
        customer: "CUS_p6i0reogc8ulu1n",
        currency: "GHS",
        due_date: Date.new(2026, 12, 31),
        description: "Harvest dues",
        line_items: [{name: "Seat", amount: 2000, quantity: 2}],
        tax: [{name: "VAT", amount: 300}],
        send_notification: false,
        draft: true,
        metadata: {branch: "Osu"},
        redirect_url: "https://example.com/done"
      )

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.amount).to eq(4300)
      expect(response.request_code).to eq("PRQ_7w7dpecncnebg7e")
      expect(response.status).to eq("draft")
    end

    it "sends a Time due date as UTC ISO 8601" do
      stub = stub_request(:post, "https://api.paystack.co/paymentrequest")
        .with(body: {customer: "CUS_p6i0reogc8ulu1n", amount: 2500, due_date: "2026-12-31T23:00:00Z"}.to_json)
        .to_return(ok)

      payment_requests.create(customer: "CUS_p6i0reogc8ulu1n", amount: 2500, due_date: Time.utc(2026, 12, 31, 23))

      expect(stub).to have_been_requested
    end

    it "refuses a due date that is not ISO 8601 without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

      expect { payment_requests.create(customer: "CUS_p6i0reogc8ulu1n", amount: 2500, due_date: "31/12/2026") }
        .to raise_error(PaystackSdk::InvalidFormatError, /due_date/)
      expect(stub).not_to have_been_requested
    end

    it "returns Paystack's refusal when neither an amount nor line items are given" do
      stub_request(:post, "https://api.paystack.co/paymentrequest")
        .to_return(
          status: 400,
          headers: json,
          body: {
            status: false,
            message: "Amount was not passed or could not be extrapolated from line items.",
            meta: {nextStep: "Try again later"},
            type: "api_error",
            code: "unknown"
          }.to_json
        )

      response = payment_requests.create(customer: "CUS_p6i0reogc8ulu1n", send_notification: false)

      expect(response).not_to be_success
      expect(response.error_message).to eq("Amount was not passed or could not be extrapolated from line items.")
    end
  end

  describe "#list" do
    it "filters by the numeric customer ID and includes archived requests when asked" do
      stub = stub_request(:get, "https://api.paystack.co/paymentrequest")
        .with(query: {customer: "407172149", status: "pending", include_archive: "true", perPage: "20"})
        .to_return(ok)

      payment_requests.list(customer_id: 407172149, status: "pending", include_archive: true, per_page: 20)

      expect(stub).to have_been_requested
    end

    it "leaves include_archive out unless it is given" do
      stub = stub_request(:get, "https://api.paystack.co/paymentrequest").to_return(ok)

      payment_requests.list

      expect(stub).to have_been_requested
    end

    it "refuses a status Paystack does not list without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

      expect { payment_requests.list(status: "paid") }.to raise_error(PaystackSdk::InvalidValueError, /status/)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#fetch, #update, #finalize and #archive" do
    it "take the numeric ID or the PRQ_ code in the path" do
      fetch = stub_request(:get, "https://api.paystack.co/paymentrequest/PRQ_7w7dpecncnebg7e").to_return(ok)
      update = stub_request(:put, "https://api.paystack.co/paymentrequest/24426435")
        .with(body: {due_date: "2027-02-01", description: "Harvest dues (updated)"}.to_json)
        .to_return(ok)
      archive = stub_request(:post, "https://api.paystack.co/paymentrequest/archive/PRQ_7w7dpecncnebg7e")
        .to_return(status: 200, headers: json, body: {status: true, message: "Payment request has been archived"}.to_json)

      payment_requests.fetch(id_or_code: "PRQ_7w7dpecncnebg7e")
      payment_requests.update(id_or_code: 24426435, description: "Harvest dues (updated)", due_date: "2027-02-01")
      response = payment_requests.archive(id_or_code: "PRQ_7w7dpecncnebg7e")

      expect([fetch, update, archive]).to all(have_been_requested)
      expect(response.message).to eq("Payment request has been archived")
    end

    it "finalizes a draft without emailing the customer when send_notification is false" do
      stub = stub_request(:post, "https://api.paystack.co/paymentrequest/finalize/PRQ_7w7dpecncnebg7e")
        .with(body: {send_notification: false}.to_json)
        .to_return(
          status: 200,
          headers: json,
          body: {status: true, message: "Payment request finalized", data: created.merge(status: "pending")}.to_json
        )

      response = payment_requests.finalize(id_or_code: "PRQ_7w7dpecncnebg7e", send_notification: false)

      expect(stub).to have_been_requested
      expect(response.status).to eq("pending")
    end
  end

  describe "#verify" do
    it "takes the PRQ_ code and returns Paystack's refusal for anything else" do
      stub_request(:get, "https://api.paystack.co/paymentrequest/verify/24426435")
        .to_return(
          status: 400,
          headers: json,
          body: {
            status: false,
            message: "Slug is invalid",
            meta: {nextStep: "Please check and pass the correct Invoice Code (Payment Request)"},
            type: "validation_error",
            code: "invalid_slug"
          }.to_json
        )

      response = payment_requests.verify(code: 24426435)

      expect(response).not_to be_success
      expect(response.error_message).to eq("Slug is invalid")
    end
  end

  describe "#totals" do
    it "returns the pending, successful and total amounts per currency" do
      stub_request(:get, "https://api.paystack.co/paymentrequest/totals")
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true,
            message: "Payment request totals",
            data: {
              pending: [{currency: "GHS", amount: 6800}],
              successful: [{currency: "GHS", amount: 0}],
              total: [{currency: "GHS", amount: 6800}]
            }
          }.to_json
        )

      response = payment_requests.totals

      expect(response.data.pending.first.amount).to eq(6800)
    end
  end
end
