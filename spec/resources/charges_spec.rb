# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Charges do
  let(:connection) { instance_double("PaystackSdk::Connection") }
  let(:charges) { described_class.new(connection) }

  describe "#mobile_money" do
    let(:payload) do
      {
        email: "customer@email.com",
        amount: 10_000,
        currency: "GHS",
        mobile_money: {
          phone: "0551234987",
          provider: "mtn"
        }
      }
    end

    it "creates a mobile money charge" do
      response_double = double("Response", success?: true, status: "pay_offline")
      expect(connection).to receive(:post)
        .with("/charge", payload)
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
        .and_return(response_double)

      response = charges.mobile_money(payload)

      expect(response.success?).to be true
      expect(response.status).to eq("pay_offline")
    end

    it "accepts provider codes in different cases" do
      payload[:mobile_money][:provider] = "MTN"
      response_double = double("Response", success?: true)
      expect(connection).to receive(:post)
        .with("/charge", payload)
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
        .and_return(response_double)

      expect { charges.mobile_money(payload) }.not_to raise_error
    end

    it "raises an error when mobile_money provider is invalid" do
      payload[:mobile_money][:provider] = "invalid"

      expect { charges.mobile_money(payload) }
        .to raise_error(PaystackSdk::InvalidValueError, /mobile_money provider/)
    end

    it "raises an error when required mobile_money details are missing" do
      payload[:mobile_money].delete(:phone)

      expect { charges.mobile_money(payload) }
        .to raise_error(PaystackSdk::MissingParamError, /mobile_money phone/)
    end
  end

  describe "#submit_otp" do
    let(:otp_payload) { {otp: "123456", reference: "r13havfcdt7btcm"} }

    it "submits the otp for a charge" do
      response_double = double("Response", success?: true, status: "success")
      expect(connection).to receive(:post)
        .with("/charge/submit_otp", otp_payload)
        .and_return(response_double)
      expect(PaystackSdk::Response).to receive(:new).with(response_double)
        .and_return(response_double)

      response = charges.submit_otp(otp_payload)
      expect(response.status).to eq("success")
    end

    it "raises an error when otp is missing" do
      otp_payload.delete(:otp)

      expect { charges.submit_otp(otp_payload) }
        .to raise_error(PaystackSdk::MissingParamError, /otp/)
    end
  end
end
