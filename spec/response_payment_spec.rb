# frozen_string_literal: true

RSpec.describe PaystackSdk::Response do
  def response_for(data, status: 200)
    body = {"status" => true, "message" => "Verification successful", "data" => data}
    described_class.new(Faraday::Response.new(status: status, response_headers: {}, body: body))
  end

  let(:verified) do
    {"id" => 4_099_260_516, "status" => "success", "reference" => "re4lyvq3s3", "amount" => 5000, "currency" => "GHS",
     "authorization" => {"authorization_code" => "AUTH_x", "reusable" => true, "last4" => "4081"}}
  end

  describe "#paid?" do
    it "is true for a successful transaction" do
      expect(response_for(verified)).to be_paid
    end

    it "is false when the transaction did not succeed" do
      expect(response_for(verified.merge("status" => "abandoned"))).not_to be_paid
    end

    it "is false when the call itself failed, even if the body says success" do
      expect(response_for(verified, status: 400)).not_to be_paid
    end

    it "compares the amount and currency you expect" do
      response = response_for(verified)

      expect(response.paid?(amount: 5000, currency: "GHS")).to be true
      expect(response.paid?(amount: 5001)).to be false
      expect(response.paid?(currency: "NGN")).to be false
    end

    it "ignores the case of the currency" do
      expect(response_for(verified).paid?(currency: "ghs")).to be true
    end

    it "is false for a response with no status" do
      expect(response_for({"reference" => "x"})).not_to be_paid
    end
  end

  describe "#status?" do
    it "matches the status Paystack returned, as a string or symbol" do
      response = response_for({"status" => "send_pin", "display_text" => "Enter your PIN"})

      expect(response.status?(:send_pin)).to be true
      expect(response.status?("send_pin")).to be true
      expect(response.status?(:pending)).to be false
      expect(response.display_text).to eq("Enter your PIN")
    end
  end

  it "keeps Paystack's own field names on the authorization" do
    authorization = response_for(verified).authorization

    expect(authorization.authorization_code).to eq("AUTH_x")
    expect(authorization.reusable).to be true
    expect(authorization.last4).to eq("4081")
  end
end
