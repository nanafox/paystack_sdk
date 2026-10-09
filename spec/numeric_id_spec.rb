# frozen_string_literal: true

# Paystack answers a filter that expects a numeric ID with an empty list, and no error, when it is given a
# code (CUS_xxx) or a name. That looks exactly like "no results", so the SDK refuses it up front.
RSpec.describe "numeric ID filters", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_numericid") }

  def stub_ok(verb, path_regex)
    stub_request(verb, path_regex).to_return(status: 200, body: {status: true, message: "ok", data: []}.to_json,
      headers: {"Content-Type" => "application/json"})
  end

  describe "PaystackSdk::Validations#validate_numeric_id!" do
    let(:checker) { Class.new { include PaystackSdk::Validations }.new }

    it "accepts an Integer or a string of digits, and nil when nil is allowed" do
      expect { checker.validate_numeric_id!(value: 123, name: "customer") }.not_to raise_error
      expect { checker.validate_numeric_id!(value: "123", name: "customer") }.not_to raise_error
      expect { checker.validate_numeric_id!(value: nil, name: "customer") }.not_to raise_error
    end

    it "refuses a code, a name, zero, a negative, a Float, a blank string and a boolean" do
      ["CUS_abc123", "ama@example.com", 0, -4, 1.5, "", " ", "12 3", "0123", true, [1]].each do |bad|
        expect { checker.validate_numeric_id!(value: bad, name: "customer") }
          .to raise_error(PaystackSdk::InvalidValueError, /customer.*numeric ID/), "#{bad.inspect} was accepted"
      end
    end

    it "refuses nil when nil is not allowed" do
      expect { checker.validate_numeric_id!(value: nil, name: "authorization_id", allow_nil: false) }
        .to raise_error(PaystackSdk::MissingParamError)
    end
  end

  {
    "transactions.list(customer_id:)" => ->(c, v) { c.transactions.list(customer_id: v) },
    "transactions.export(customer_id:)" => ->(c, v) { c.transactions.export(customer_id: v) },
    "subscriptions.list(customer_id:)" => ->(c, v) { c.subscriptions.list(customer_id: v) },
    "subscriptions.list(plan_id:)" => ->(c, v) { c.subscriptions.list(plan_id: v) },
    "refunds.list(transaction_id:)" => ->(c, v) { c.refunds.list(transaction_id: v) },
    "payment_requests.list(customer_id:)" => ->(c, v) { c.payment_requests.list(customer_id: v) }
  }.each do |name, call|
    it "#{name} refuses a code before sending anything and sends a numeric ID as it is" do
      any = stub_ok(:get, %r{\Ahttps://api\.paystack\.co/})

      expect { call.call(client, "CUS_abc123") }.to raise_error(PaystackSdk::InvalidValueError, /numeric ID/)
      expect(any).not_to have_been_requested

      call.call(client, 12345)
      expect(any).to have_been_requested.once
    end
  end

  it "still sends the customer filter under the name Paystack documents" do
    stub = stub_request(:get, "https://api.paystack.co/transaction?customer=12345")
      .to_return(status: 200, body: {status: true, message: "ok", data: []}.to_json, headers: {"Content-Type" => "application/json"})

    client.transactions.list(customer_id: 12_345)

    expect(stub).to have_been_requested
  end
end
