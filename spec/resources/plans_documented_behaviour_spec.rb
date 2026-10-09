# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API that differs from the OpenAPI spec, or that
# the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
RSpec.describe PaystackSdk::Resources::Plans do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:plans) { client.plans }
  let(:json) { {"Content-Type" => "application/json"} }

  def refusal(message)
    {
      status: false,
      message: message,
      meta: {nextStep: "Ensure that the value(s) you're passing are valid."},
      type: "validation_error",
      code: "invalid_params"
    }.to_json
  end

  describe "#create" do
    let(:params) do
      {name: "Quarterly tithe", amount: 200, interval: "quarterly", description: "Standing tithe",
       send_invoices: false, send_sms: false, invoice_limit: 3}
    end

    it "accepts quarterly, which the spec omits, and returns the plan" do
      stub = stub_request(:post, "https://api.paystack.co/plan")
        .with(body: params.to_json)
        .to_return(
          status: 201,
          headers: json,
          body: {
            status: true,
            message: "Plan created",
            data: {
              name: "Quarterly tithe", amount: 200, interval: "quarterly", description: "Standing tithe",
              send_invoices: false, send_sms: false, invoice_limit: 3, integration: 2047140, domain: "test",
              currency: "GHS", plan_code: "PLN_t7x733ei04lkz9j", hosted_page: false, migrate: false,
              is_archived: false, id: 4298025
            }
          }.to_json
        )

      response = plans.create(**params)

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.plan_code).to eq("PLN_t7x733ei04lkz9j")
      expect(response.currency).to eq("GHS")
      expect(response.send_sms).to be(false)
    end

    it "accepts hourly, which Create Plan's docs omit but the API takes" do
      stub = stub_request(:post, "https://api.paystack.co/plan")
        .with(body: {name: "Hourly", amount: 200, interval: "hourly"}.to_json)
        .to_return(status: 201, headers: json, body: {status: true, message: "Plan created", data: {}}.to_json)

      plans.create(name: "Hourly", amount: 200, interval: "hourly")

      expect(stub).to have_been_requested
    end

    it "refuses an interval Paystack does not define before sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { plans.create(name: "x", amount: 200, interval: "fortnightly") }
        .to raise_error(PaystackSdk::InvalidValueError, /interval/)
      expect { plans.create(name: "x", amount: 200, interval: "Monthly") }
        .to raise_error(PaystackSdk::InvalidValueError, /interval/)
      expect(stub).not_to have_been_requested
    end

    it "returns Paystack's refusal of an amount below the minimum as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/plan")
        .to_return(status: 400, headers: json, body: refusal("Amount is invalid. It must be a number and be 2 GHS or greater"))

      response = plans.create(name: "x", amount: 100, interval: "daily")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Amount is invalid. It must be a number and be 2 GHS or greater")
    end
  end

  describe "#update" do
    it "sends update_existing_subscriptions, which the spec omits, and returns the message Paystack gives" do
      stub = stub_request(:put, "https://api.paystack.co/plan/PLN_t7x733ei04lkz9j")
        .with(body: {amount: 250, update_existing_subscriptions: false}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Plan updated. 0 subscription(s) affected"}.to_json)

      response = plans.update(id_or_code: "PLN_t7x733ei04lkz9j", amount: 250, update_existing_subscriptions: false)

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.api_message).to eq("Plan updated. 0 subscription(s) affected")
    end

    it "sends hourly, which the spec omits, and a string description" do
      stub = stub_request(:put, "https://api.paystack.co/plan/4298025")
        .with(body: {interval: "hourly", description: "fake test plan 2"}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Plan updated. 0 subscription(s) affected"}.to_json)

      plans.update(id_or_code: 4298025, interval: "hourly", description: "fake test plan 2")

      expect(stub).to have_been_requested
    end

    it "needs no field besides the plan: every body field is optional" do
      stub = stub_request(:put, "https://api.paystack.co/plan/PLN_t7x733ei04lkz9j")
        .to_return(status: 200, headers: json, body: {status: true, message: "Plan updated. 0 subscription(s) affected"}.to_json)

      expect(plans.update(id_or_code: "PLN_t7x733ei04lkz9j")).to be_success
      expect(stub).to have_been_requested
    end
  end

  describe "#fetch" do
    it "returns Paystack's 404 for an unknown plan as an unsuccessful response" do
      stub_request(:get, "https://api.paystack.co/plan/PLN_nonexistent")
        .to_return(status: 404, headers: json, body: refusal("Plan ID/code specified is invalid"))

      response = plans.fetch(id_or_code: "PLN_nonexistent")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Plan ID/code specified is invalid")
    end
  end

  describe "#list" do
    it "filters by hourly interval and by status, which the spec omits" do
      stub = stub_request(:get, "https://api.paystack.co/plan")
        .with(query: {"interval" => "hourly", "status" => "active", "perPage" => "50"})
        .to_return(status: 200, headers: json, body: {status: true, message: "Plans retrieved", data: [], meta: {total: 0}}.to_json)

      expect(plans.list(interval: "hourly", status: "active", per_page: 50)).to be_success
      expect(stub).to have_been_requested
    end
  end
end
