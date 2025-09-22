# frozen_string_literal: true

RSpec.describe PaystackSdk::Resources::Transactions do
  let(:connection) { instance_double("PaystackSdk::Connection") }
  let(:transactions) { described_class.new(connection) }

  describe "#initiate" do
    let(:params) do
      {
        email: "customer@email.com",
        amount: 10_000,
        currency: "GHS"
      }
    end

    context "with successful response" do
      it "initializes a transaction" do
        response_double = double("Response", success?: true,
          data: double("Data", authorization_url: "https://checkout.paystack.com/abc123"),
          authorization_url: "https://checkout.paystack.com/abc123")
        expect(connection).to receive(:post)
          .with("/transaction/initialize", params)
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
          .and_return(response_double)

        response = transactions.initiate(params)
        expect(response.success?).to be true
        expect(response.data.authorization_url).to eq("https://checkout.paystack.com/abc123")
        expect(response.authorization_url).to eq("https://checkout.paystack.com/abc123")
      end
    end

    context "with failed response" do
      it "returns an unsuccessful response" do
        response_double = double("Response", success?: false, failed?: true,
          error_message: "Transaction initialization failed")
        expect(connection).to receive(:post)
          .with("/transaction/initialize", params)
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
          .and_return(response_double)

        response = transactions.initiate(params)
        expect(response.success?).to be false
        expect(response.failed?).to be true
        expect(response.error_message).to eq("Transaction initialization failed")
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when email is missing" do
        invalid_params = params.except(:email)
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: email"
        )
      end

      it "raises MissingParamError when amount is missing" do
        invalid_params = params.except(:amount)
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: amount"
        )
      end

      it "raises InvalidFormatError when email format is invalid" do
        invalid_params = params.merge(email: "invalid-email")
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::InvalidFormatError,
          "Invalid format for Email. Expected format: valid email address"
        )
      end

      it "raises InvalidFormatError when currency format is invalid" do
        invalid_params = params.merge(currency: "INVALID")
        expect { transactions.initiate(invalid_params) }.to raise_error(
          PaystackSdk::InvalidFormatError,
          "Invalid format for currency. Expected format: 3-letter ISO code (e.g., NGN, USD, GHS)"
        )
      end
    end
  end

  describe "#verify" do
    let(:reference) { "ref_123" }

    context "with successful response" do
      it "verifies a transaction" do
        response_double = double("Response", success?: true, status: true)
        expect(connection).to receive(:get)
          .with("/transaction/verify/#{reference}")
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
          .and_return(response_double)

        response = transactions.verify(reference: reference)
        expect(response.success?).to be true
        expect(response.status).to be true
      end
    end

    context "with not found error" do
      it "returns an unsuccessful response" do
        response_double = double("Response", success?: false, failed?: true,
          error_message: "Transaction reference not found.")
        expect(connection).to receive(:get)
          .with("/transaction/verify/#{reference}")
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
          .and_return(response_double)

        response = transactions.verify(reference: reference)
        expect(response.success?).to be false
        expect(response.failed?).to be true
        expect(response.error_message).to eq("Transaction reference not found.")
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when reference is missing" do
        expect { transactions.verify(reference: nil) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: Reference"
        )
      end
    end
  end

  describe "#charge_authorization" do
    let(:payload) do
      {
        authorization_code: "AUTH_72btv547",
        email: "customer@email.com",
        amount: 10_000
      }
    end

    context "with successful response" do
      it "charges the authorization" do
        response_double = double("Response", success?: true, status: "success",
          api_message: "Charge attempted", amount: 35_247, reference: "0m7frfnr47ezyxl",
          authorization: double("Authorization", authorization_code: "AUTH_uh8bcl3zbn"),
          customer: double("Customer", email: "customer@email.com"))
        expect(connection).to receive(:post)
          .with("/transaction/charge_authorization", payload)
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
          .and_return(response_double)

        response = transactions.charge_authorization(payload)

        expect(response.success?).to be true
        expect(response.status).to be "success"
        expect(response.api_message).to eq("Charge attempted")
        expect(response.amount).to eq(35_247)
        expect(response.reference).to eq("0m7frfnr47ezyxl")
        expect(response.authorization.authorization_code).to eq("AUTH_uh8bcl3zbn")
        expect(response.customer.email).to eq("customer@email.com")
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when authorization_code is missing" do
        invalid_payload = payload.except(:authorization_code)
        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: authorization_code"
        )
      end

      it "raises MissingParamError when email is missing" do
        invalid_payload = payload.except(:email)
        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: email"
        )
      end

      it "raises MissingParamError when amount is missing" do
        invalid_payload = payload.except(:amount)
        expect { transactions.charge_authorization(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: amount"
        )
      end
    end
  end

  describe "#partial_debit" do
    let(:payload) do
      {
        authorization_code: "AUTH_72btv547",
        currency: "NGN",
        amount: 10_000,
        email: "customer@email.com"
      }
    end

    context "with successful response" do
      it "performs a partial debit" do
        response_double = double("Response", success?: true, status: "success")
        expect(connection).to receive(:post)
          .with("/transaction/partial_debit", payload)
          .and_return(response_double)
        expect(PaystackSdk::Response).to receive(:new).with(response_double)
          .and_return(response_double)

        response = transactions.partial_debit(payload)
        expect(response.success?).to be true
        expect(response.status).to eq("success")
      end
    end

    context "with validation errors" do
      it "raises MissingParamError when authorization_code is missing" do
        invalid_payload = payload.except(:authorization_code)
        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::MissingParamError,
          "Missing required parameter: authorization_code"
        )
      end

      it "raises InvalidFormatError when currency format is invalid" do
        invalid_payload = payload.merge(currency: "INVALID")
        expect { transactions.partial_debit(invalid_payload) }.to raise_error(
          PaystackSdk::InvalidFormatError,
          "Invalid format for currency. Expected format: 3-letter ISO code (e.g., NGN, USD, GHS)"
        )
      end
    end
  end
end
