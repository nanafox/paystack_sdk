# frozen_string_literal: true

# Responses captured from the Paystack test API (2026-10-09). Paystack's docs page shows a different
# create body (customer, line_items); the API follows the OpenAPI spec, which these specs use.
RSpec.describe PaystackSdk::Resources::Orders do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:not_found) do
    {
      status: 404, headers: json,
      body: {status: false, message: "Order not found", type: "validation_error", code: "not_found"}.to_json
    }
  end

  it "lists orders, reflecting perPage in meta" do
    stub = stub_request(:get, "https://api.paystack.co/order").with(query: {perPage: "2"})
      .to_return(status: 200, headers: json, body: {
        status: true, message: "Orders retrieved", data: [],
        meta: {total: 0, revenue: {}, skipped: 0, perPage: 2, page: 1, pageCount: 0}
      }.to_json)

    response = client.orders.list(per_page: 2)

    expect(stub).to have_been_requested
    expect(response).to be_success
    expect(response.meta.perPage).to eq(2)
  end

  it "returns an unsuccessful response for an unknown order" do
    stub_request(:get, "https://api.paystack.co/order/99999999").to_return(not_found)

    response = client.orders.fetch(id: 99_999_999)

    expect(response).not_to be_success
    expect(response.error_message).to eq("Order not found")
  end

  it "validates by order code with a GET" do
    stub = stub_request(:get, "https://api.paystack.co/order/ORD_nope/validate").to_return(not_found)

    expect(client.orders.validate(code: "ORD_nope")).not_to be_success
    expect(stub).to have_been_requested
  end

  it "returns Paystack's refusal for an unknown product" do
    stub_request(:get, "https://api.paystack.co/order/product/99999999").to_return(
      status: 404, headers: json,
      body: {status: false, message: "Product not found", type: "validation_error", code: "not_found"}.to_json
    )

    expect(client.orders.fetch_product_orders(id: 99_999_999).error_message).to eq("Product not found")
  end

  let(:order) do
    {
      email: "sdk-order-probe@example.com", first_name: "Zz", last_name: "Probe", phone: "+233200000000", currency: "GHS",
      items: [{item: 2782736, type: "product", quantity: 2, amount: 200}],
      shipping: {street_line: "1 Test Road", city: "Accra", state: "Greater Accra", country: "Ghana", shipping_fee: 0}
    }
  end

  it "creates an order from items shaped item/type/quantity/amount, and returns it unpaid" do
    stub = stub_request(:post, "https://api.paystack.co/order").with(body: order.to_json)
      .to_return(status: 200, headers: json, body: {
        status: true, message: "Order created",
        data: {
          currency: "GHS", email: "sdk-order-probe@example.com", customer: 407209173, amount: 200, pay_for_me: false,
          order_code: "ORD_cjrr200xm7wv8cm", status: "created", refunded: false, shipping_fees: 0, id: 3301280
        }
      }.to_json)

    response = client.orders.create(**order)

    expect(stub).to have_been_requested
    expect(response).to be_success
    expect(response.order_code).to eq("ORD_cjrr200xm7wv8cm")
    expect(response.status).to eq("created")
  end

  it "returns Paystack's refusal when the total is below the minimum" do
    stub_request(:post, "https://api.paystack.co/order").to_return(
      status: 400, headers: json,
      body: {status: false, message: "Order total amount is invalid. Amount must be GHS2 or greater", type: "validation_error", code: "invalid_params"}.to_json
    )

    response = client.orders.create(**order)

    expect(response).not_to be_success
    expect(response.error_message).to match(/GHS2 or greater/)
  end
end
