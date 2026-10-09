# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API that differs from the OpenAPI spec, or that
# the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
RSpec.describe PaystackSdk::Resources::Customers do
  let(:resource) { described_class.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:ok) do
    {status: 200, headers: {"Content-Type" => "application/json"}, body: {status: true, message: "ok", data: {}}.to_json}
  end

  describe "metadata" do
    # The spec calls it stringified JSON; Paystack rejects a string with
    # 400 "\"metadata\" must be of type object".
    it "is sent as a JSON object on create" do
      stub = stub_request(:post, "https://api.paystack.co/customer")
        .with(body: {email: "ama@example.com", metadata: {plan: "gold"}}.to_json)
        .to_return(ok)

      resource.create(email: "ama@example.com", metadata: {plan: "gold"})

      expect(stub).to have_been_requested
    end

    it "is sent as a JSON object on update" do
      stub = stub_request(:put, "https://api.paystack.co/customer/CUS_123")
        .with(body: {metadata: {plan: "gold"}}.to_json)
        .to_return(ok)

      resource.update(code: "CUS_123", metadata: {plan: "gold"})

      expect(stub).to have_been_requested
    end
  end

  describe "#list" do
    it "sends perPage, page and the date range as Paystack documents them" do
      stub = stub_request(:get, "https://api.paystack.co/customer")
        .with(query: {perPage: "20", page: "2", from: "2026-01-01T00:00:00Z", to: "2026-01-31T00:00:00Z"})
        .to_return(ok)

      resource.list(per_page: 20, page: 2, from: "2026-01-01T00:00:00Z", to: "2026-01-31T00:00:00Z")

      expect(stub).to have_been_requested
    end

    it "sends cursor pagination as use_cursor and next" do
      stub = stub_request(:get, "https://api.paystack.co/customer")
        .with(query: {use_cursor: "true", next: "Y3VzdG9tZXI6MQ=="})
        .to_return(ok)

      resource.list(use_cursor: true, next_cursor: "Y3VzdG9tZXI6MQ==")

      expect(stub).to have_been_requested
    end

    it "refuses a per_page that is not a positive integer, without sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

      expect { resource.list(per_page: 0) }.to raise_error(PaystackSdk::InvalidValueError)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#validate" do
    let(:identification) do
      {first_name: "Asta", last_name: "Lavista", type: "bank_account", country: "NG",
       bvn: "20012345677", bank_code: "007", account_number: "0123456789"}
    end

    it "sends the identification fields Paystack documents" do
      stub = stub_request(:post, "https://api.paystack.co/customer/CUS_123/identification")
        .with(body: identification.to_json)
        .to_return(ok)

      resource.validate(code: "CUS_123", **identification)

      expect(stub).to have_been_requested
    end

    # Paystack answers 400 when any of these is missing ("Please enter a valid `bvn`", ...).
    %i[bvn bank_code account_number first_name last_name type country].each do |field|
      it "requires #{field}" do
        expect { resource.validate(code: "CUS_123", **identification.except(field)) }
          .to raise_error(ArgumentError, /#{field}/)
      end
    end
  end
end
