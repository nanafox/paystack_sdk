# frozen_string_literal: true

# Talks to Paystack's real test API. Skipped unless PAYSTACK_TEST_SECRET_KEY is set to an sk_test_ key.
#
#   PAYSTACK_TEST_SECRET_KEY=sk_test_... bundle exec rspec spec/sandbox
#
# Every request still goes through the OpenAPI contract check. The charge below is 1 GHS pesewa-scale
# (100 pesewas) in test mode and reuses a saved card from the account's earlier successful payments.
RSpec.describe "Paystack test API", :sandbox do
  key = ENV["PAYSTACK_TEST_SECRET_KEY"]

  before do
    skip "set PAYSTACK_TEST_SECRET_KEY to an sk_test_ key to run the sandbox suite" if key.to_s.empty?
    WebMock.allow_net_connect!
  end

  after { WebMock.disable_net_connect! }

  let(:client) { PaystackSdk::Client.new(secret_key: key, sandbox_only: true) }

  def reusable_card_payment
    payments = client.transactions.list(status: "success", per_page: 50).original_response["data"]
    payments.find { |t| t["channel"] == "card" && t.dig("authorization", "reusable") && t["currency"] == "GHS" }
  end

  it "uses a test key" do
    expect(client).not_to be_live
  end

  it "charges a saved card for a renewal and verifies it" do
    earlier = reusable_card_payment
    skip "the test account has no successful, reusable GHS card payment to renew" unless earlier

    reference = "sdk-sandbox-#{Time.now.to_i}-#{rand(1000)}"
    charge = client.transactions.charge_authorization(
      email: earlier.dig("customer", "email"), amount: 100, currency: "GHS", reference: reference,
      authorization_code: earlier.dig("authorization", "authorization_code")
    )

    expect(charge).to be_success
    expect(charge.paid?(amount: 100, currency: "GHS")).to be true

    verified = client.transactions.verify(reference: reference)
    expect(verified.paid?(amount: 100, currency: "GHS")).to be true
    expect(verified.paid?(amount: 101)).to be false
    expect(verified.authorization.reusable).to be true
  end

  it "returns an unsuccessful response for an invalid authorization code" do
    response = client.transactions.charge_authorization(
      email: "ama@example.com", amount: 100, currency: "GHS", authorization_code: "AUTH_doesnotexist",
      reference: "sdk-sandbox-bad-#{Time.now.to_i}-#{rand(1000)}"
    )

    expect(response).not_to be_success
    expect(response.paid?).to be false
    expect(response.error_message).to eq("Authorization code is invalid")
  end

  it "refuses a live key" do
    expect { PaystackSdk::Client.new(secret_key: "sk_live_not_a_real_key", sandbox_only: true) }.to raise_error(ArgumentError)
  end
end
