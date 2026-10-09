# frozen_string_literal: true

RSpec.describe PaystackSdk::Client do
  describe "#live?" do
    it "is true only for a live key" do
      expect(described_class.new(secret_key: "sk_live_abc")).to be_live
      expect(described_class.new(secret_key: "sk_test_abc")).not_to be_live
      expect(described_class.new(secret_key: "something_else")).not_to be_live
    end

    it "reads the key from a pre-built connection" do
      connection = Faraday.new(headers: {"Authorization" => "Bearer sk_live_abc"})

      expect(described_class.new(connection)).to be_live
    end
  end

  describe "sandbox_only: true" do
    it "accepts a test key" do
      expect { described_class.new(secret_key: "sk_test_abc", sandbox_only: true) }.not_to raise_error
    end

    it "refuses a live key, without printing it" do
      expect { described_class.new(secret_key: "sk_live_abc", sandbox_only: true) }
        .to raise_error(ArgumentError, /sandbox_only.*test key/) { |e| expect(e.message).not_to include("sk_live_abc") }
    end

    it "refuses a key it cannot recognise as a test key" do
      expect { described_class.new(secret_key: "abc", sandbox_only: true) }.to raise_error(ArgumentError)
    end

    it "checks the key in the environment when none is given" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PAYSTACK_SECRET_KEY").and_return("sk_live_abc")

      expect { described_class.new(sandbox_only: true) }.to raise_error(ArgumentError)
    end

    it "checks a pre-built connection too" do
      live = Faraday.new(headers: {"Authorization" => "Bearer sk_live_abc"})
      test = Faraday.new(headers: {"Authorization" => "Bearer sk_test_abc"})

      expect { described_class.new(live, sandbox_only: true) }.to raise_error(ArgumentError)
      expect { described_class.new(test, sandbox_only: true) }.not_to raise_error
    end

    it "makes no request when it refuses" do
      expect(Faraday).not_to receive(:new)

      expect { described_class.new(secret_key: "sk_live_abc", sandbox_only: true) }.to raise_error(ArgumentError)
    end
  end
end
