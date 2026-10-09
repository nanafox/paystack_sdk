# frozen_string_literal: true

# Behaviour of the Integration resource. The fetch body is shaped like a real test API response
# (GET, 2026-10-09). The update (PUT) was NOT called against the API: it changes an account-wide
# setting that may be shared with LIVE mode, so it is described from the spec and docs only.
RSpec.describe PaystackSdk::Resources::Integrations do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:json) { {"Content-Type" => "application/json"} }

  describe "#fetch_payment_session_timeout" do
    it "returns the timeout in seconds under payment_session_timeout" do
      stub_request(:get, "https://api.paystack.co/integration/payment_session_timeout")
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true,
            message: "Payment session timeout retrieved",
            data: {payment_session_timeout: 0}
          }.to_json
        )

      response = client.integrations.fetch_payment_session_timeout

      expect(response).to be_success
      expect(response.data.payment_session_timeout).to eq(0)
    end
  end

  describe "#update_payment_session_timeout" do
    it "sends timeout, in seconds, as the JSON body" do
      stub = stub_request(:put, "https://api.paystack.co/integration/payment_session_timeout")
        .with(body: {timeout: 30}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "ok", data: {}}.to_json)

      client.integrations.update_payment_session_timeout(timeout: 30)

      expect(stub).to have_been_requested
    end
  end
end
