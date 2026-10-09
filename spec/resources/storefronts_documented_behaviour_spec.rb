# frozen_string_literal: true

# Behaviour confirmed against Paystack's docs and test API (2026-10-09) that the generated wire-shape
# specs do not exercise. Response bodies are the test API's, trimmed, with the account's email and keys
# replaced.
RSpec.describe PaystackSdk::Resources::Storefronts do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:storefronts) { client.storefronts }
  let(:json) { {"Content-Type" => "application/json"} }

  def refusal(message, type: "validation_error", code: "invalid_params")
    {
      status: false,
      message: message,
      meta: {nextStep: "Ensure that the value(s) you're passing are valid."},
      type: type,
      code: code
    }.to_json
  end

  let(:storefront) do
    {
      social_media: [],
      contacts: [{value: "owner@example.com", id: 1863706, type_name: nil, type: 2}],
      name: "Harvest stall", slug: "harvest-stall", currency: "GHS",
      welcome_message: nil, success_message: nil, redirect_url: nil, description: nil,
      delivery_note: "disabled", background_color: "#FFAD00", status: "active", shippable: false,
      integration: 2047140, domain: "test", digital_product_expiry: nil, metadata: nil,
      id: 1852308, createdAt: "2026-10-09T14:24:26.000Z", updatedAt: "2026-10-09T14:24:26.000Z",
      products: [], shipping_fees: []
    }
  end

  describe "#create" do
    it "sends name, slug and currency, which the API requires, and returns the storefront" do
      stub = stub_request(:post, "https://api.paystack.co/storefront")
        .with(body: {name: "Harvest stall", slug: "harvest-stall", currency: "GHS"}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Storefront created", data: storefront}.to_json)

      response = storefronts.create(name: "Harvest stall", slug: "harvest-stall", currency: "GHS")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.id).to eq(1852308)
      expect(response.status).to eq("active")
      expect(response.delivery_note).to eq("disabled")
      expect(response.contacts.first.type).to eq(2)
    end

    it "refuses a currency Paystack does not list before sending anything" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { storefronts.create(name: "x", slug: "harvest-stall", currency: "EUR") }
        .to raise_error(PaystackSdk::InvalidValueError, /currency/)
      expect { storefronts.create(name: "x", slug: "harvest-stall", currency: "ghs") }
        .to raise_error(PaystackSdk::InvalidValueError, /currency/)
      expect(stub).not_to have_been_requested
    end

    it "returns Paystack's refusal of a currency the integration does not allow as an unsuccessful response" do
      stub_request(:post, "https://api.paystack.co/storefront")
        .to_return(status: 400, headers: json, body: refusal("Currency not supported or allowed"))

      response = storefronts.create(name: "x", slug: "harvest-stall", currency: "NGN")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Currency not supported or allowed")
    end

    it "returns Paystack's slug rules when it refuses a slug" do
      message = "Slug should be 5-100 characters, all lowercase, using only letters, numbers, dashes, or underscores."
      stub_request(:post, "https://api.paystack.co/storefront")
        .to_return(status: 400, headers: json, body: refusal(message))

      response = storefronts.create(name: "x", slug: "Bad Slug!", currency: "GHS")

      expect(response).not_to be_success
      expect(response.error_message).to eq(message)
    end

    it "returns Paystack's refusal of a slug already in use" do
      stub_request(:post, "https://api.paystack.co/storefront")
        .to_return(status: 400, headers: json, body: refusal("This link is already in use, please choose another.", type: "api_error", code: "unknown"))

      response = storefronts.create(name: "x", slug: "harvest-stall", currency: "GHS")

      expect(response).not_to be_success
      expect(response.error_message).to eq("This link is already in use, please choose another.")
    end
  end

  describe "#list" do
    it "sends the status filter and perPage" do
      stub = stub_request(:get, "https://api.paystack.co/storefront")
        .with(query: {status: "active", perPage: "1"})
        .to_return(
          status: 200, headers: json,
          body: {
            status: true, message: "Storefronts retrieved",
            data: [{id: 1852308, name: "Harvest stall", slug: "harvest-stall", orders_count: 0, status: "active",
                    revenue: nil, currency: "GHS", products: [], contacts: [], social_media: [], shipping_fees: []}],
            meta: {total: 1, skipped: 0, perPage: 1, page: 1, pageCount: 1}
          }.to_json
        )

      response = storefronts.list(status: "active", per_page: 1)

      expect(stub).to have_been_requested
      expect(response.data.first.orders_count).to eq(0)
    end

    it "refuses a status other than active or inactive before sending anything (the API answers 500)" do
      stub = stub_request(:any, /api\.paystack\.co/)

      expect { storefronts.list(status: "deleted") }.to raise_error(PaystackSdk::InvalidValueError, /status/)
      expect(stub).not_to have_been_requested
    end
  end

  describe "#update" do
    it "sends slug, which the spec lists and the docs omit, and returns only a message" do
      stub = stub_request(:put, "https://api.paystack.co/storefront/1852308")
        .with(body: {slug: "harvest-stall-2", description: "Sunday harvest"}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Storefront updated"}.to_json)

      response = storefronts.update(id: 1852308, slug: "harvest-stall-2", description: "Sunday harvest")

      expect(stub).to have_been_requested
      expect(response).to be_success
      expect(response.message).to eq("Storefront updated")
      expect(response.key?("slug")).to be(false)
    end
  end

  describe "#verify_slug" do
    it "returns the storefront that holds a slug that is taken" do
      taken = storefront.merge(integration: {key: "pk_test_x", name: "Example Ltd", allowed_currencies: ["GHS"]}, product_count: 0)
      stub_request(:get, "https://api.paystack.co/storefront/verify/harvest-stall")
        .to_return(status: 200, headers: json, body: {status: true, message: "Storefront retrieved", data: taken}.to_json)

      response = storefronts.verify_slug(slug: "harvest-stall")

      expect(response).to be_success
      expect(response.slug).to eq("harvest-stall")
    end

    it "answers 404 for a slug no storefront holds, which means it is free" do
      stub_request(:get, "https://api.paystack.co/storefront/verify/harvest-stall-free")
        .to_return(status: 404, headers: json, body: refusal("Storefront not found", code: "not_found"))

      response = storefronts.verify_slug(slug: "harvest-stall-free")

      expect(response).not_to be_success
      expect(response.error_message).to eq("Storefront not found")
    end
  end

  describe "#add_products" do
    it "sends products as an array of integer product IDs" do
      stub = stub_request(:post, "https://api.paystack.co/storefront/1852308/product")
        .with(body: {products: [2782728]}.to_json)
        .to_return(status: 200, headers: json, body: {status: true, message: "Product added"}.to_json)

      response = storefronts.add_products(id: 1852308, products: [2782728])

      expect(stub).to have_been_requested
      expect(response).to be_success
    end

    it "returns Paystack's refusal of a product code where it wants an ID" do
      stub_request(:post, "https://api.paystack.co/storefront/1852308/product")
        .to_return(status: 400, headers: json, body: refusal("\"products[0]\" must be a number"))

      response = storefronts.add_products(id: 1852308, products: [2782728])

      expect(response).not_to be_success
      expect(response.error_message).to eq("\"products[0]\" must be a number")
    end
  end

  describe "#fetch_orders" do
    it "returns the orders with revenue in meta" do
      stub_request(:get, "https://api.paystack.co/storefront/1852308/order")
        .to_return(
          status: 200, headers: json,
          body: {status: true, message: "Storefront orders", data: [],
                 meta: {revenue: nil, quantity_sold: nil, total: 0, skipped: 0, perPage: 50, pageCount: 0}}.to_json
        )

      response = storefronts.fetch_orders(id: 1852308)

      expect(response).to be_success
      expect(response.meta.total).to eq(0)
    end
  end

  describe "#publish" do
    it "returns the live copy Paystack makes of the storefront" do
      live = storefront.merge(id: 1852310, domain: "live", status: 1, delivery_note: 1)
      stub_request(:post, "https://api.paystack.co/storefront/1852309/publish")
        .to_return(status: 200, headers: json, body: {status: true, message: "Storefront published to live", data: live}.to_json)

      response = storefronts.publish(id: 1852309)

      expect(response).to be_success
      expect(response.message).to eq("Storefront published to live")
      expect(response.domain).to eq("live")
      expect(response.id).to eq(1852310)
    end
  end

  describe "#duplicate" do
    it "returns the copy, with a new ID and slug" do
      copy = storefront.merge(id: 1852309, name: "Copy of Harvest stall", slug: "copy-of-harvest-stall-z77b7u9jna")
      stub_request(:post, "https://api.paystack.co/storefront/1852308/duplicate")
        .to_return(status: 200, headers: json, body: {status: true, message: "Storefront successfully duplicated", data: copy}.to_json)

      response = storefronts.duplicate(id: 1852308)

      expect(response).to be_success
      expect(response.id).to eq(1852309)
      expect(response.name).to eq("Copy of Harvest stall")
    end
  end

  describe "#delete" do
    it "returns only a message" do
      stub_request(:delete, "https://api.paystack.co/storefront/1852308")
        .to_return(status: 200, headers: json, body: {status: true, message: "Storefront deleted"}.to_json)

      response = storefronts.delete(id: 1852308)

      expect(response).to be_success
      expect(response.message).to eq("Storefront deleted")
    end
  end
end
