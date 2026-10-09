# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API that the generated wire-shape specs do not
# exercise. See spec/support/paystack_contract_exceptions.yml.
RSpec.describe PaystackSdk::Resources::Pages do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:pages) { client.pages }
  let(:json) { {"Content-Type" => "application/json"} }

  describe "#create" do
    it "creates a donation-style page without an amount and returns the page" do
      stub = stub_request(:post, "https://api.paystack.co/page")
        .with(body: {name: "Offering", description: "Give", type: "payment", collect_phone: true}.to_json)
        .to_return(
          status: 200,
          headers: json,
          body: {
            status: true,
            message: "Page created",
            data: {
              name: "Offering", integration: 2047140, domain: "test", slug: "z30p7ybtss", custom_fields: [],
              currency: "GHS", type: "payment", collect_phone: true, active: true, published: true,
              migrate: false, id: 2215275
            }
          }.to_json
        )

      response = pages.create(name: "Offering", description: "Give", type: "payment", collect_phone: true)

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.slug).to eq("z30p7ybtss")
      expect(response.id).to eq(2215275)
    end

    it "sends custom_fields as an array of objects and metadata as an object" do
      stub = stub_request(:post, "https://api.paystack.co/page")
        .with(
          body: {
            name: "Offering",
            metadata: {subaccount: "ACCT_1"},
            custom_fields: [{display_name: "Branch", variable_name: "branch"}]
          }.to_json
        )
        .to_return(status: 200, headers: json, body: {status: true, message: "Page created", data: {}}.to_json)

      pages.create(
        name: "Offering",
        metadata: {subaccount: "ACCT_1"},
        custom_fields: [{display_name: "Branch", variable_name: "branch"}]
      )

      expect(stub).to have_been_requested
    end

    it "returns Paystack's refusal as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/page")
        .to_return(
          status: 400,
          headers: json,
          body: {
            status: false,
            message: "Name is required",
            meta: {nextStep: "Provide all required params "},
            type: "validation_error",
            code: "missing_params"
          }.to_json
        )

      response = pages.create(name: "x")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Name is required")
    end
  end

  describe "#update" do
    it "accepts a single field: name and description are optional, as the spec says" do
      stub = stub_request(:put, "https://api.paystack.co/page/z30p7ybtss")
        .with(body: {description: "SDK probe"}.to_json)
        .to_return(
          status: 200,
          headers: json,
          body: {status: true, message: "Page updated", data: {id: 2215275, description: "SDK probe", active: true}}.to_json
        )

      response = pages.update(id_or_slug: "z30p7ybtss", description: "SDK probe")

      expect(stub).to have_been_requested
      expect(response.description).to eq("SDK probe")
    end

    it "deactivates a page with active: false" do
      stub = stub_request(:put, "https://api.paystack.co/page/2215275")
        .with(body: {active: false}.to_json)
        .to_return(
          status: 200,
          headers: json,
          body: {status: true, message: "Page updated", data: {id: 2215275, active: false}}.to_json
        )

      expect(pages.update(id_or_slug: 2215275, active: false).active).to be(false)
      expect(stub).to have_been_requested
    end
  end

  describe "#fetch" do
    it "fetches by slug as well as by numeric ID" do
      stub = stub_request(:get, "https://api.paystack.co/page/ecclesia-lite")
        .to_return(status: 200, headers: json, body: {status: true, message: "Page retrieved", data: {id: 2214363}}.to_json)

      expect(pages.fetch(id_or_slug: "ecclesia-lite").id).to eq(2214363)
      expect(stub).to have_been_requested
    end
  end

  describe "#check_slug_availability" do
    it "returns a successful response when the slug is free" do
      stub_request(:get, "https://api.paystack.co/page/check_slug_availability/free-slug")
        .to_return(status: 200, headers: json, body: {status: true, message: "Slug is available"}.to_json)

      response = pages.check_slug_availability(slug: "free-slug")

      expect(response).to be_success
      expect(response.message).to eq("Slug is available")
    end

    it "returns an unsuccessful response when the slug is taken" do
      stub_request(:get, "https://api.paystack.co/page/check_slug_availability/ecclesia-lite")
        .to_return(
          status: 400,
          headers: json,
          body: {
            status: false,
            message: "Slug already in use",
            meta: {nextStep: "You'll need to choose a different slug, and try again."},
            type: "validation_error",
            code: "duplicate_slug"
          }.to_json
        )

      response = pages.check_slug_availability(slug: "ecclesia-lite")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Slug already in use")
    end
  end

  describe "#add_products" do
    it "sends the list as `products`, the name the test API reads (the docs' `product` is ignored)" do
      stub = stub_request(:post, "https://api.paystack.co/page/102859/product")
        .with(body: {products: [473, 292]}.to_json)
        .to_return(
          status: 200,
          headers: json,
          body: {status: true, message: "Products added to page", data: {id: 102859, type: "product"}}.to_json
        )

      response = pages.add_products(id: 102859, products: [473, 292])

      expect(stub).to have_been_requested
      expect(response).to be_success
    end
  end
end
