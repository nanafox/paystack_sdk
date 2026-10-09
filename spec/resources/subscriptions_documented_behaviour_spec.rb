# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API that differs from the OpenAPI spec, or that
# the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
RSpec.describe PaystackSdk::Resources::Subscriptions do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:subscriptions) { client.subscriptions }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:ok) { {status: 200, headers: json, body: {status: true, message: "ok", data: {}}.to_json} }

  def refusal(status, message, code)
    {
      status: status,
      headers: json,
      body: {status: false, message: message, meta: {nextStep: "Ensure that the value(s) you're passing are valid."}, type: "validation_error", code: code}.to_json
    }
  end

  describe "#create" do
    let(:params) { {customer: "CUS_xnxdt6s1zg1f4nx", plan: "PLN_gx2wn530m0i3w3m", authorization: "AUTH_6tmt288t0o"} }

    it "sends a Time start_date as ISO 8601 and returns the subscription code and email token" do
      stub = stub_request(:post, "https://api.paystack.co/subscription")
        .with(body: params.merge(start_date: "2027-01-15T10:00:00Z").to_json)
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true,
            message: "Subscription successfully created",
            data: {
              customer: 1173, plan: 28, integration: 100032, domain: "test", start: 1791548038, status: "active",
              quantity: 1, amount: 200, authorization: 1691619186, invoice_limit: 0, split_code: nil, metadata: nil,
              subscription_code: "SUB_vsyqdmlzble3uii", email_token: "d7gofp6yppn3qz7", id: 9,
              cron_expression: "0 10 15 * *", next_payment_date: "2027-01-15T10:00:00.000Z", open_invoice: nil
            }
          }.to_json
        )

      response = subscriptions.create(**params, start_date: Time.utc(2027, 1, 15, 10))

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.subscription_code).to eq("SUB_vsyqdmlzble3uii")
      expect(response.email_token).to eq("d7gofp6yppn3qz7")
      expect(response.next_payment_date).to eq("2027-01-15T10:00:00.000Z")
    end

    # contract: false because the spec gives start_date the date-time format. The test API accepted
    # 2027-03-10 on 2026-10-09 and set next_payment_date to 2027-03-10T00:00:00.000Z.
    it "sends a Date start_date as a date, which Paystack reads as midnight UTC", contract: false do
      stub = stub_request(:post, "https://api.paystack.co/subscription")
        .with(body: params.merge(start_date: "2027-03-10").to_json)
        .to_return(ok)

      subscriptions.create(**params, start_date: Date.new(2027, 3, 10))

      expect(stub).to have_been_requested
    end

    # The test API refuses an invalid start_date with a 400, but still creates an active subscription
    # with no next payment date, so the SDK refuses it before sending anything.
    it "refuses a start_date that is not ISO 8601 without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

      expect { subscriptions.create(**params, start_date: "15/01/2027") }
        .to raise_error(PaystackSdk::InvalidFormatError, /start_date/)
      expect(stub).not_to have_been_requested
    end

    it "returns an authorization that is not the customer's as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/subscription")
        .to_return(refusal(400, "Authorization specified is invalid or does not belong to customer", "invalid_params"))

      response = subscriptions.create(**params)

      expect(response).not_to be_success
      expect(response.error_message).to eq("Authorization specified is invalid or does not belong to customer")
    end

    it "returns a second active subscription to the same plan as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/subscription")
        .to_return(refusal(400, "This subscription is already in place.", "duplicate_subscription"))

      response = subscriptions.create(**params)

      expect(response).not_to be_success
      expect(response.error_message).to eq("This subscription is already in place.")
    end
  end

  describe "#list" do
    it "sends plan_id and customer_id as Paystack's numeric plan and customer filters" do
      stub = stub_request(:get, "https://api.paystack.co/subscription")
        .with(query: {perPage: "20", page: "1", plan: "4298026", customer: "406976740"})
        .to_return(ok)

      subscriptions.list(per_page: 20, page: 1, plan_id: 4298026, customer_id: 406976740)

      expect(stub).to have_been_requested
    end

    it "sends from and to as ISO 8601" do
      stub = stub_request(:get, "https://api.paystack.co/subscription")
        .with(query: {from: "2026-10-01", to: "2026-10-09T12:00:00Z"})
        .to_return(ok)

      subscriptions.list(from: Date.new(2026, 10, 1), to: Time.utc(2026, 10, 9, 12))

      expect(stub).to have_been_requested
    end
  end

  describe "#fetch" do
    it "takes a subscription code or numeric ID" do
      stub = stub_request(:get, "https://api.paystack.co/subscription/1358022").to_return(ok)

      subscriptions.fetch(id_or_code: 1358022)

      expect(stub).to have_been_requested
    end
  end

  describe "#disable" do
    it "sends the code and email token and returns the new status" do
      stub = stub_request(:post, "https://api.paystack.co/subscription/disable")
        .with(body: {code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7"}.to_json)
        .to_return(
          status: 200,
          headers: json,
          body: {status: true, message: "Subscription disabled successfully", data: {status: "non-renewing"}}.to_json
        )

      response = subscriptions.disable(code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.status).to eq("non-renewing")
    end

    it "returns a wrong token or an inactive subscription as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/subscription/disable")
        .to_return(refusal(404, "Subscription with code not found or already inactive", "not_found"))

      response = subscriptions.disable(code: "SUB_vsyqdmlzble3uii", token: "wrong")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Subscription with code not found or already inactive")
    end
  end

  describe "#enable" do
    it "returns Paystack's refusal to reactivate a cancelled subscription as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/subscription/enable")
        .with(body: {code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7"}.to_json)
        .to_return(refusal(400, "Subscription has been cancelled, and cannot be reactivated", "invalid_params"))

      response = subscriptions.enable(code: "SUB_vsyqdmlzble3uii", token: "d7gofp6yppn3qz7")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Subscription has been cancelled, and cannot be reactivated")
    end
  end

  describe "#generate_update_link" do
    it "returns the link to Paystack's card update page" do
      link = "https://paystack.com/manage/subscriptions/qlgwhpyq1ts9nsw?subscription_token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e30.x"
      stub_request(:get, "https://api.paystack.co/subscription/SUB_qlgwhpyq1ts9nsw/manage/link")
        .to_return(status: 200, headers: json, body: {status: true, message: "Link generated", data: {link: link}}.to_json)

      response = subscriptions.generate_update_link(code: "SUB_qlgwhpyq1ts9nsw")

      expect(response).to be_success
      expect(response.link).to eq(link)
    end
  end
end
