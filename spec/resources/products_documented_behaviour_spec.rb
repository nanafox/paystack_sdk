# frozen_string_literal: true

# Behaviour confirmed against the Paystack test API (2026-10-09) that differs from the OpenAPI spec and the
# docs, or that the generated wire-shape specs do not exercise. See spec/support/paystack_contract_exceptions.yml.
# Response bodies are trimmed copies of what the test API returned.
RSpec.describe PaystackSdk::Resources::Products do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:json) { {"Content-Type" => "application/json"} }

  let(:created) do
    {
      status: true,
      message: "Product successfully created",
      data: {
        name: "ZZ SDK Test C", description: "fake meta", currency: "GHS", price: 300, unlimited: true,
        integration: 2_047_140, domain: "test", metadata: {k: "v", background_color: "#F5F5F5"},
        slug: "zz-sdk-test-c-vndudw", product_code: "PROD_42njdr0si7h1l89", quantity: 0, quantity_sold: 0,
        type: "good", active: true, in_stock: true, id: 2_782_725, createdAt: "2026-10-09T14:23:16.385Z"
      }
    }
  end

  describe "#create" do
    # The API requires name, price and currency, not description (the spec and docs say it does).
    it "creates a product without a description" do
      stub = stub_request(:post, "https://api.paystack.co/product")
        .with(body: {name: "n", price: 100, currency: "GHS"}.to_json)
        .to_return(status: 201, headers: json, body: created.to_json)

      response = client.products.create(name: "n", price: 100, currency: "GHS")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.data.product_code).to eq("PROD_42njdr0si7h1l89")
    end

    it "sends metadata as a JSON object, unlimited stock and a price in pesewas" do
      stub = stub_request(:post, "https://api.paystack.co/product")
        .with(body: {name: "ZZ SDK Test C", price: 300, currency: "GHS", description: "fake meta",
                     unlimited: true, metadata: {k: "v"}}.to_json)
        .to_return(status: 201, headers: json, body: created.to_json)

      response = client.products.create(name: "ZZ SDK Test C", price: 300, currency: "GHS",
        description: "fake meta", unlimited: true, metadata: {k: "v"})

      expect(stub).to have_been_requested
      expect(response.data.metadata.k).to eq("v")
      expect(response.data.unlimited).to be(true)
    end

    it "returns the API's 400 for a missing price as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/product").to_return(
        status: 400, headers: json,
        body: {status: false, message: "Currency is required", type: "validation_error", code: "missing_params"}.to_json
      )

      response = client.products.create(name: "n", price: 100, currency: "GHS")

      expect(response).not_to be_success
      expect(response.message).to eq("Currency is required")
    end
  end

  describe "#update" do
    # Every field is optional on the API: sending only a description changes only that.
    it "sends only the fields given and treats 202 as success" do
      stub = stub_request(:put, "https://api.paystack.co/product/2782726")
        .with(body: {description: "fake desc"}.to_json)
        .to_return(status: 202, headers: json,
          body: {status: true, message: "Product successfully updated",
                 data: {name: "n", description: "fake desc", price: 100, currency: "GHS", id: 2_782_726}}.to_json)

      response = client.products.update(id: 2_782_726, description: "fake desc")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.data.description).to eq("fake desc")
    end
  end

  describe "#fetch" do
    it "returns the 404 for an unknown product as an unsuccessful response" do
      stub_request(:get, "https://api.paystack.co/product/99999999").to_return(
        status: 404, headers: json,
        body: {status: false, message: "Product not found", type: "validation_error", code: "not_found"}.to_json
      )

      response = client.products.fetch(id: 99_999_999)

      expect(response).not_to be_success
      expect(response.message).to eq("Product not found")
    end
  end

  describe "#delete" do
    it "deletes a product by numeric ID" do
      stub = stub_request(:delete, "https://api.paystack.co/product/2782726")
        .to_return(status: 200, headers: json, body: {status: true, message: "Product successfully deleted"}.to_json)

      response = client.products.delete(id: 2_782_726)

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.message).to eq("Product successfully deleted")
    end
  end

  describe "#list" do
    it "sends perPage, page and active" do
      stub = stub_request(:get, "https://api.paystack.co/product")
        .with(query: {perPage: 2, page: 2, active: false})
        .to_return(status: 200, headers: json,
          body: {status: true, message: "Products retrieved", data: [],
                 meta: {total: 0, skipped: 0, perPage: 2, page: 2, pageCount: 0}}.to_json)

      response = client.products.list(per_page: 2, page: 2, active: false)

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.meta.perPage).to eq(2)
    end
  end
end
