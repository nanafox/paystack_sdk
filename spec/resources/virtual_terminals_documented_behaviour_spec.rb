# frozen_string_literal: true

# Behaviour taken from Paystack's docs and confirmed against the test API (2026-10-09) that the
# generated wire-shape specs do not exercise. Error bodies are copies of real test-mode responses.
# Create, assign and unassign destination were not run live, so create's success body is the docs'.
RSpec.describe PaystackSdk::Resources::VirtualTerminals do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:terminals) { client.virtual_terminals }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:next_step) { "Ensure that you're passing the correct reference for the requested resource that exists on this integration" }

  describe "#list" do
    it "returns an empty page for an account with no virtual terminals" do
      stub = stub_request(:get, "https://api.paystack.co/virtual_terminal")
        .with(query: {"perPage" => "1", "status" => "active"})
        .to_return(status: 200, headers: json, body: {
          status: true, message: "Virtual Terminals retrieved", data: [], meta: {next: nil, previous: nil, perPage: 1}
        }.to_json)

      response = terminals.list(per_page: 1, status: "active")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.message).to eq("Virtual Terminals retrieved")
      expect(response.data.to_a).to be_empty
    end

    it "returns the API's rejection of an unknown status as an unsuccessful response" do
      stub_request(:get, "https://api.paystack.co/virtual_terminal").with(query: {"status" => "bogus"})
        .to_return(status: 400, headers: json, body: {
          status: false, message: "\"status\" must be one of [active, inactive]", type: "validation_error", code: "invalid_params",
          meta: {nextStep: "Ensure that the value(s) you're passing are valid."}
        }.to_json)

      response = terminals.list(status: "bogus")

      expect(response).not_to be_success
      expect(response.message).to eq("\"status\" must be one of [active, inactive]")
    end
  end

  describe "#fetch" do
    it "returns an unsuccessful response for an unknown code" do
      stub_request(:get, "https://api.paystack.co/virtual_terminal/VT_NOPE")
        .to_return(status: 404, headers: json, body: {
          status: false, message: "Virtual Terminal not found", type: "validation_error", code: "not_found", meta: {nextStep: next_step}
        }.to_json)

      response = terminals.fetch(code: "VT_NOPE")

      expect(response).not_to be_success
      expect(response.message).to eq("Virtual Terminal not found")
    end
  end

  describe "#create" do
    it "sends the destinations and reads the terminal's code from the documented success body" do
      destinations = [{target: "+27639022319", name: "Phone Destination"}]
      stub = stub_request(:post, "https://api.paystack.co/virtual_terminal")
        .with(body: {name: "Sample Terminal", destinations:}.to_json)
        .to_return(status: 200, headers: json, body: {
          status: true, message: "Virtual Terminal created",
          data: {id: 27691, name: "Sample Terminal", code: "VT_LJK5892Z", active: true, currency: "ZAR",
                 destinations: [{target: "+27639022319", type: "whatsapp", name: "Phone Destination"}]}
        }.to_json)

      response = terminals.create(name: "Sample Terminal", destinations:)

      expect(stub).to have_been_requested
      expect(response.code).to eq("VT_LJK5892Z")
      expect(response.destinations.first.type).to eq("whatsapp")
    end
  end

  describe "#deactivate" do
    it "returns the documented message with no data" do
      stub_request(:put, "https://api.paystack.co/virtual_terminal/VT_LJK5892Z/deactivate")
        .to_return(status: 200, headers: json, body: {status: true, message: "Terminal set to inactive"}.to_json)

      response = terminals.deactivate(code: "VT_LJK5892Z")

      expect(response).to be_success
      expect(response.message).to eq("Terminal set to inactive")
    end
  end

  describe "#add_split_code" do
    it "returns an unsuccessful response for an invalid split code" do
      stub_request(:put, "https://api.paystack.co/virtual_terminal/VT_NOPE/split_code")
        .with(body: {split_code: "SPL_x"}.to_json)
        .to_return(status: 400, headers: json, body: {
          status: false, message: "Invalid split code", type: "validation_error", code: "invalid_params",
          meta: {nextStep: "Ensure that the value(s) you're passing are valid."}
        }.to_json)

      response = terminals.add_split_code(code: "VT_NOPE", split_code: "SPL_x")

      expect(response).not_to be_success
      expect(response.message).to eq("Invalid split code")
    end
  end

  describe "#remove_split_code" do
    it "sends a DELETE with the split code as a JSON body" do
      stub = stub_request(:delete, "https://api.paystack.co/virtual_terminal/VT_NOPE/split_code")
        .with(body: {split_code: "SPL_x"}.to_json, headers: {"Content-Type" => "application/json"})
        .to_return(status: 400, headers: json, body: {
          status: false, message: "Virtual Terminal split code assignment does not exist", type: "validation_error", code: "not_found",
          meta: {nextStep: next_step}
        }.to_json)

      response = terminals.remove_split_code(code: "VT_NOPE", split_code: "SPL_x")

      expect(stub).to have_been_requested
      expect(response).not_to be_success
      expect(response.message).to eq("Virtual Terminal split code assignment does not exist")
    end
  end
end
