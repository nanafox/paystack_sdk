# frozen_string_literal: true

RSpec.describe PaystackSdk::Webhook do
  let(:secret) { "sk_test_secret_for_specs" }
  let(:payload) do
    '{"event":"charge.success","data":{"id":302961,"reference":"qTPrJoy9Bx","amount":10000,"currency":"GHS"}}'
  end
  # Computed independently with: openssl dgst -sha512 -hmac <secret> -hex <payload file>
  let(:signature) do
    "d812debbe18ecd6074bb99a19f2b560dfd41116d2bff41023609312fead8c2a2" \
      "7b2cb83a98b76474cc9ae7116c3a5bce279439cf42f561b48cce573b868aec57"
  end

  describe "constants" do
    it "names the header Paystack signs events with" do
      expect(described_class::SIGNATURE_HEADER).to eq("x-paystack-signature")
    end

    it "lists the IP addresses Paystack documents for webhooks" do
      expect(described_class::IP_ADDRESSES).to contain_exactly("52.31.139.75", "52.49.173.169", "52.214.14.220")
    end

    it "lists the events Paystack documents" do
      expect(described_class::EVENTS).to contain_exactly(
        "charge.dispute.create", "charge.dispute.remind", "charge.dispute.resolve", "charge.success",
        "customeridentification.failed", "customeridentification.success",
        "dedicatedaccount.assign.failed", "dedicatedaccount.assign.success",
        "invoice.create", "invoice.payment_failed", "invoice.update",
        "paymentrequest.pending", "paymentrequest.success",
        "refund.failed", "refund.pending", "refund.processed", "refund.processing",
        "subscription.create", "subscription.disable", "subscription.expiring_cards", "subscription.not_renew",
        "transfer.failed", "transfer.reversed", "transfer.success"
      )
    end
  end

  describe ".sign" do
    it "returns the lowercase hex HMAC SHA512 of the payload" do
      expect(described_class.sign(payload, secret)).to eq(signature)
    end
  end

  describe ".valid_signature?" do
    it "accepts the genuine signature" do
      expect(described_class.valid_signature?(payload: payload, signature: signature, secret: secret)).to be(true)
    end

    it "rejects a payload that was changed after signing" do
      tampered = payload.sub("10000", "1")
      expect(described_class.valid_signature?(payload: tampered, signature: signature, secret: secret)).to be(false)
    end

    it "rejects a signature made with a different secret" do
      expect(described_class.valid_signature?(payload: payload, signature: signature, secret: "sk_test_other")).to be(false)
    end

    it "rejects a re-serialised body, which differs byte for byte" do
      reserialised = JSON.generate(JSON.parse(payload)).sub(":", ": ")
      expect(described_class.valid_signature?(payload: reserialised, signature: signature, secret: secret)).to be(false)
    end

    it "rejects a missing, empty or truncated signature" do
      [nil, "", signature[0, 64], "#{signature}00"].each do |bad|
        expect(described_class.valid_signature?(payload: payload, signature: bad, secret: secret)).to be(false)
      end
    end

    it "rejects an uppercased signature, since Paystack sends lowercase hex" do
      expect(described_class.valid_signature?(payload: payload, signature: signature.upcase, secret: secret)).to be(false)
    end

    it "raises ArgumentError for a payload that is not the raw string body" do
      expect { described_class.valid_signature?(payload: JSON.parse(payload), signature: signature, secret: secret) }
        .to raise_error(ArgumentError, /raw request body/)
    end

    it "raises ArgumentError when the secret is blank, instead of verifying against nothing" do
      [nil, ""].each do |blank|
        expect { described_class.valid_signature?(payload: payload, signature: signature, secret: blank) }
          .to raise_error(ArgumentError, /secret/)
      end
    end

    it "compares in constant time" do
      expect(OpenSSL).to receive(:fixed_length_secure_compare).and_call_original
      described_class.valid_signature?(payload: payload, signature: signature, secret: secret)
    end
  end

  describe ".verify!" do
    it "returns true for a genuine signature" do
      expect(described_class.verify!(payload: payload, signature: signature, secret: secret)).to be(true)
    end

    it "raises InvalidSignatureError otherwise" do
      expect { described_class.verify!(payload: payload, signature: "nope", secret: secret) }
        .to raise_error(PaystackSdk::InvalidSignatureError)
    end
  end

  describe ".construct_event" do
    it "verifies, then returns the event with its wrapped data" do
      event = described_class.construct_event(payload: payload, signature: signature, secret: secret)

      expect(event).to be_a(PaystackSdk::Webhook::Event)
      expect(event.event).to eq("charge.success")
      expect(event.data.reference).to eq("qTPrJoy9Bx")
      expect(event.data[:amount]).to eq(10_000)
      expect(event.known?).to be(true)
      expect(event.payload["data"]["currency"]).to eq("GHS")
    end

    it "does not parse a payload whose signature is invalid" do
      expect(JSON).not_to receive(:parse)
      expect { described_class.construct_event(payload: payload, signature: "bad", secret: secret) }
        .to raise_error(PaystackSdk::InvalidSignatureError)
    end

    it "returns events Paystack adds later, marked as not known" do
      later = '{"event":"something.new","data":{"x":1}}'
      event = described_class.construct_event(payload: later, signature: described_class.sign(later, secret), secret: secret)

      expect(event.event).to eq("something.new")
      expect(event.known?).to be(false)
      expect(event.data.x).to eq(1)
    end

    it "raises InvalidPayloadError when a correctly signed body is not a JSON event" do
      ["not json", "[]", '{"data":{}}', '{"event":123}', '{"event":""}'].each do |body|
        expect { described_class.construct_event(payload: body, signature: described_class.sign(body, secret), secret: secret) }
          .to raise_error(PaystackSdk::InvalidPayloadError)
      end
    end

    it "returns nil data when a signed event carries none, rather than dropping it" do
      body = '{"event":"charge.success"}'
      event = described_class.construct_event(payload: body, signature: described_class.sign(body, secret), secret: secret)

      expect(event.event).to eq("charge.success")
      expect(event.data).to be_nil
    end

    it "accepts events whose data is an array" do
      body = '{"event":"subscription.expiring_cards","data":[{"id":1}]}'
      event = described_class.construct_event(payload: body, signature: described_class.sign(body, secret), secret: secret)

      expect(event.data.first.id).to eq(1)
    end
  end

  describe ".trusted_ip?" do
    it "is true for Paystack's documented addresses" do
      described_class::IP_ADDRESSES.each { |ip| expect(described_class.trusted_ip?(ip)).to be(true) }
    end

    it "is false for anything else, including blank values" do
      ["1.2.3.4", "", nil, "52.31.139.750"].each { |ip| expect(described_class.trusted_ip?(ip)).to be(false) }
    end
  end

  describe "errors" do
    it "are all PaystackSdk::Error" do
      expect(PaystackSdk::InvalidSignatureError.ancestors).to include(PaystackSdk::WebhookError, PaystackSdk::Error)
      expect(PaystackSdk::InvalidPayloadError.ancestors).to include(PaystackSdk::WebhookError, PaystackSdk::Error)
    end
  end
end
