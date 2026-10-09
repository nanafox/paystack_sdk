# frozen_string_literal: true

# Every value a caller supplies that ends up in a URL path must be escaped, and `.` / `..` refused:
# the URL builder resolves dot segments, so `/transaction/verify/..` would call `/transaction`.
#
# contract: false because these specs are about the path only. They pass minimal payloads on purpose;
# whether each payload matches the spec is covered by the per-resource specs.
RSpec.describe "escaping of path segments", contract: false do
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_x", max_retries: 0) }
  let(:ok) do
    {status: 200, headers: {"Content-Type" => "application/json"}, body: {status: true, message: "ok", data: {}}.to_json}
  end

  # [description, HTTP verb, path before the value, path after the value, how to call it with the value]
  calls = [
    ["transactions.verify", :get, "/transaction/verify/", "", ->(c, v) { c.transactions.verify(reference: v) }],
    ["transactions.fetch", :get, "/transaction/", "", ->(c, v) { c.transactions.fetch(id: v) }],
    ["transactions.timeline", :get, "/transaction/timeline/", "", ->(c, v) { c.transactions.timeline(id: v) }],
    ["transfers.fetch", :get, "/transfer/", "", ->(c, v) { c.transfers.fetch(id_or_code: v) }],
    ["transfers.verify", :get, "/transfer/verify/", "", ->(c, v) { c.transfers.verify(reference: v) }],
    ["transfer_recipients.fetch", :get, "/transferrecipient/", "", ->(c, v) { c.transfer_recipients.fetch(id_or_code: v) }],
    ["transfer_recipients.update", :put, "/transferrecipient/", "", ->(c, v) { c.transfer_recipients.update(id_or_code: v, name: "Ama") }],
    ["transfer_recipients.delete", :delete, "/transferrecipient/", "", ->(c, v) { c.transfer_recipients.delete(id_or_code: v) }],
    ["customers.fetch", :get, "/customer/", "", ->(c, v) { c.customers.fetch(email_or_code: v) }],
    ["customers.update", :put, "/customer/", "", ->(c, v) { c.customers.update(code: v, first_name: "Ama") }],
    ["customers.validate", :post, "/customer/", "/identification", lambda { |c, v|
      c.customers.validate(code: v, first_name: "Ama", last_name: "Mensah", type: "bank_account", country: "NG",
        bvn: "20012345677", bank_code: "007", account_number: "0123456789")
    }],
    ["customers.verify_authorization", :get, "/customer/authorization/verify/", "", ->(c, v) { c.customers.verify_authorization(reference: v) }],
    ["customers.initialize_direct_debit", :post, "/customer/", "/initialize-direct-debit", lambda { |c, v|
      c.customers.initialize_direct_debit(id: v, account: {number: "0123456789", bank_code: "058"}, address: {street: "1 Road", city: "Ikeja", state: "Lagos"})
    }],
    ["customers.direct_debit_activation_charge", :put, "/customer/", "/directdebit-activation-charge", lambda { |c, v|
      c.customers.direct_debit_activation_charge(id: v, authorization_id: 1)
    }],
    ["customers.fetch_mandate_authorizations", :get, "/customer/", "/directdebit-mandate-authorizations", lambda { |c, v|
      c.customers.fetch_mandate_authorizations(id: v)
    }],
    ["miscellaneous.resolve_card_bin", :get, "/decision/bin/", "", ->(c, v) { c.miscellaneous.resolve_card_bin(bin: v) }],
    ["refunds.fetch", :get, "/refund/", "", ->(c, v) { c.refunds.fetch(id: v) }],
    ["refunds.retry_with_customer_details", :post, "/refund/retry_with_customer_details/", "", lambda { |c, v|
      c.refunds.retry_with_customer_details(id: v, refund_account_details: {currency: "GHS", account_number: "0123456789", bank_id: "1"})
    }]
  ].freeze

  it "covers every method that puts a caller's value in a path" do
    expect(calls.size).to eq(18)
  end

  calls.each do |description, verb, before, after, call|
    describe description do
      it "keeps ordinary identifiers as they are" do
        stub = stub_request(verb, "https://api.paystack.co#{before}CUS_123abc#{after}").to_return(ok)

        call.call(client, "CUS_123abc")

        expect(stub).to have_been_requested
      end

      it "encodes characters that would change the path, so the call stays on its endpoint" do
        stub = stub_request(verb, "https://api.paystack.co#{before}a%2Fb%3Fc%23d%20e#{after}").to_return(ok)

        call.call(client, "a/b?c#d e")

        expect(stub).to have_been_requested
      end

      it "refuses `..` and `.`, which would resolve to a different endpoint, without sending anything" do
        stub = stub_request(:any, /api\.paystack\.co/).to_return(ok)

        [".", ".."].each do |segment|
          expect { call.call(client, segment) }.to raise_error(PaystackSdk::InvalidValueError, /must not be/)
        end

        expect(stub).not_to have_been_requested
      end
    end
  end

  it "encodes the @ in an email used to fetch a customer" do
    stub = stub_request(:get, "https://api.paystack.co/customer/ama%40example.com").to_return(ok)

    client.customers.fetch(email_or_code: "ama@example.com")

    expect(stub).to have_been_requested
  end

  it "names the parameter in the error" do
    expect { client.transactions.verify(reference: "..") }.to raise_error(PaystackSdk::InvalidValueError, /reference/)
  end
end
