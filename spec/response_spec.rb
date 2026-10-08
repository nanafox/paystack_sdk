# frozen_string_literal: true

RSpec.describe PaystackSdk::Response do
  def faraday_response(body, status: 200)
    Faraday::Response.new(status: status, response_headers: {}, body: body)
  end

  # Paystack returns JSON, which Faraday parses into string keys.
  let(:body) do
    {
      "status" => true,
      "message" => "Transaction retrieved",
      "data" => {
        "id" => 4_099_260_516,
        "reference" => "re4lyvq3s3",
        "amount" => 40_333,
        "customer" => {"email" => "a@b.co", "id" => 7},
        "log" => nil
      }
    }
  end
  let(:response) { described_class.new(faraday_response(body)) }

  describe "dot access" do
    it "reads top-level and nested values" do
      expect(response.reference).to eq("re4lyvq3s3")
      expect(response.customer.email).to eq("a@b.co")
    end

    it "raises NoMethodError for keys that are not in the body" do
      expect { response.nope }.to raise_error(NoMethodError)
    end
  end

  describe "#[]" do
    it "reads string-keyed bodies with a symbol key" do
      expect(response[:reference]).to eq("re4lyvq3s3")
    end

    it "reads string-keyed bodies with a string key" do
      expect(response["reference"]).to eq("re4lyvq3s3")
    end

    it "wraps nested hashes so access can continue" do
      expect(response[:customer][:email]).to eq("a@b.co")
      expect(response["customer"]["email"]).to eq("a@b.co")
    end

    it "returns nil for a missing key" do
      expect(response[:nope]).to be_nil
    end

    it "returns nil for a key that is present with a nil value" do
      expect(response[:log]).to be_nil
    end

    it "still reads symbol-keyed data" do
      symbol_keyed = described_class.new({reference: "abc"})
      expect(symbol_keyed[:reference]).to eq("abc")
      expect(symbol_keyed["reference"]).to eq("abc")
    end

    it "indexes arrays by position" do
      list = described_class.new(faraday_response({"data" => [{"id" => 1}, {"id" => 2}]}))
      expect(list[1][:id]).to eq(2)
    end
  end

  describe "#key?" do
    it "is true for present keys given as symbols or strings" do
      expect(response.key?(:reference)).to be(true)
      expect(response.key?("reference")).to be(true)
    end

    it "is true for a present key whose value is nil" do
      expect(response.key?(:log)).to be(true)
    end

    it "is false for absent keys" do
      expect(response.key?(:nope)).to be(false)
    end

    it "works for symbol-keyed data" do
      expect(described_class.new({reference: "abc"}).key?("reference")).to be(true)
    end
  end

  describe "#meta" do
    let(:list_body) do
      {
        "status" => true,
        "message" => "Transactions retrieved",
        "data" => [{"id" => 1}, {"id" => 2}],
        "meta" => {"total" => 40, "page" => 1, "pageCount" => 2, "perPage" => 20}
      }
    end
    let(:list) { described_class.new(faraday_response(list_body)) }

    it "exposes pagination metadata from list responses" do
      expect(list.meta.total).to eq(40)
      expect(list.meta.pageCount).to eq(2)
      expect(list.meta[:perPage]).to eq(20)
    end

    it "does not disturb access to the data" do
      expect(list.size).to eq(2)
      expect(list.first.id).to eq(1)
    end

    it "is nil when the response has no meta" do
      expect(response.meta).to be_nil
    end

    it "is still available through original_response" do
      expect(list.original_response["meta"]["total"]).to eq(40)
    end
  end

  describe "status handling" do
    it "reports success for 2xx" do
      expect(response).to be_success
      expect(response.message).to eq("Transaction retrieved")
    end

    it "returns an unsuccessful response with details for a 404" do
      missing = described_class.new(faraday_response({"status" => false, "message" => "Transaction reference not found"}, status: 404))

      expect(missing).to be_failed
      expect(missing.error_message).to eq("Transaction reference not found")
      expect(missing.error_details).to include(status_code: 404, message: "Transaction reference not found")
    end

    it "raises AuthenticationError for 401" do
      expect { described_class.new(faraday_response({"message" => "Invalid key"}, status: 401)) }
        .to raise_error(PaystackSdk::AuthenticationError, "Invalid key")
    end

    it "raises ServerError for 5xx" do
      expect { described_class.new(faraday_response({"message" => "boom"}, status: 503)) }
        .to raise_error(PaystackSdk::ServerError) { |e| expect(e.status_code).to eq(503) }
    end
  end

  describe "iteration" do
    let(:list) { described_class.new(faraday_response({"data" => [{"id" => 1}, {"id" => 2}]})) }

    it "yields wrapped items" do
      expect(list.each.map(&:id)).to eq([1, 2])
    end

    it "supports first and last" do
      expect([list.first.id, list.last.id]).to eq([1, 2])
    end
  end
end
