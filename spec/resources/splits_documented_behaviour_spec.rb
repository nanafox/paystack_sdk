# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API that differs from the OpenAPI spec, or that
# the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
RSpec.describe PaystackSdk::Resources::Splits do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:ok) { {status: 200, headers: json, body: {status: true, message: "ok", data: {}}.to_json} }
  let(:subaccounts) { [{subaccount: "ACCT_6uujpqtzmnufzkw", share: 50}] }

  describe "#create" do
    let(:created) do
      {
        status: true,
        message: "Split created",
        data: {
          id: 2703655, name: "Halfsies", type: "percentage", currency: "GHS", integration: 463433,
          domain: "test", split_code: "SPL_RcScyW5jp2", active: true, bearer_type: "all",
          is_dynamic: false, total_subaccounts: 1,
          subaccounts: [{subaccount: {id: 1151727, subaccount_code: "ACCT_6uujpqtzmnufzkw"}, share: 50}]
        }
      }
    end

    it "sends the split and returns it, with Paystack's default bearer when none is given" do
      stub = stub_request(:post, "https://api.paystack.co/split")
        .with(body: {name: "Halfsies", type: "percentage", subaccounts:, currency: "GHS"}.to_json)
        .to_return(status: 200, headers: json, body: created.to_json)

      response = client.splits.create(name: "Halfsies", type: "percentage", subaccounts:, currency: "GHS")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.data.split_code).to eq("SPL_RcScyW5jp2")
      expect(response.data.bearer_type).to eq("all")
      expect(response.data.subaccounts.first.share).to eq(50)
    end

    it "sends the bearer when one is given" do
      stub = stub_request(:post, "https://api.paystack.co/split")
        .with(body: {
          name: "Halfsies", type: "flat", subaccounts:, currency: "GHS",
          bearer_type: "subaccount", bearer_subaccount: "ACCT_6uujpqtzmnufzkw"
        }.to_json)
        .to_return(ok)

      client.splits.create(
        name: "Halfsies", type: "flat", subaccounts:, currency: "GHS",
        bearer_type: "subaccount", bearer_subaccount: "ACCT_6uujpqtzmnufzkw"
      )

      expect(stub).to have_been_requested
    end

    it "returns Paystack's refusal as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/split").to_return(
        status: 400, headers: json,
        body: {status: false, message: "Specified currency is not allowed on this integration"}.to_json
      )

      response = client.splits.create(name: "Halfsies", type: "percentage", subaccounts:, currency: "NGN")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Specified currency is not allowed on this integration")
    end

    it "refuses a type or bearer_type Paystack does not accept, without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

      expect { client.splits.create(name: "x", type: "fixed", subaccounts:, currency: "GHS") }
        .to raise_error(PaystackSdk::InvalidValueError, /type/)
      expect { client.splits.create(name: "x", type: "flat", subaccounts:, currency: "GHS", bearer_type: "customer") }
        .to raise_error(PaystackSdk::InvalidValueError, /bearer_type/)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#list" do
    # The spec says per_page; Paystack ignores it and reads perPage.
    it "sends perPage and the filters as Paystack documents them" do
      stub = stub_request(:get, "https://api.paystack.co/split")
        .with(query: {perPage: "20", page: "2", active: "true", subaccount_code: "ACCT_6uujpqtzmnufzkw"})
        .to_return(ok)

      client.splits.list(per_page: 20, page: 2, active: true, subaccount_code: "ACCT_6uujpqtzmnufzkw")

      expect(stub).to have_been_requested
    end
  end

  describe "#fetch" do
    it "takes a split code as well as an ID" do
      stub = stub_request(:get, "https://api.paystack.co/split/SPL_RcScyW5jp2").to_return(ok)

      client.splits.fetch(id: "SPL_RcScyW5jp2")

      expect(stub).to have_been_requested
    end
  end

  describe "#add_subaccount" do
    it "sends the subaccount and its share" do
      stub = stub_request(:post, "https://api.paystack.co/split/2703655/subaccount/add")
        .with(body: {subaccount: "ACCT_eg4sob4590pq9vb", share: 20}.to_json)
        .to_return(ok)

      client.splits.add_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb", share: 20)

      expect(stub).to have_been_requested
    end

    # Paystack answers 400 "You have invalid or missing subaccount(s) key" without a share.
    it "requires share" do
      expect { client.splits.add_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb") }
        .to raise_error(ArgumentError, /share/)
      expect { client.splits.add_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb", share: nil) }
        .to raise_error(PaystackSdk::MissingParamError, /share/)
    end
  end

  describe "#remove_subaccount" do
    it "sends only the subaccount" do
      stub = stub_request(:post, "https://api.paystack.co/split/2703655/subaccount/remove")
        .with(body: {subaccount: "ACCT_eg4sob4590pq9vb"}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Subaccount removed"}.to_json)

      response = client.splits.remove_subaccount(id: 2703655, subaccount: "ACCT_eg4sob4590pq9vb")

      expect(stub).to have_been_requested
      expect(response).to be_success
    end
  end
end
