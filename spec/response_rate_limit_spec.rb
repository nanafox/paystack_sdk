# frozen_string_literal: true

RSpec.describe PaystackSdk::Response do
  def faraday_response(status, headers = {}, body = {"message" => "x"})
    Faraday::Response.new(status: status, response_headers: headers, body: body)
  end

  describe "429 handling" do
    it "raises RateLimitError, not an unsuccessful response" do
      expect { described_class.new(faraday_response(429, {"x-ratelimit-reset" => "3"})) }
        .to raise_error(PaystackSdk::RateLimitError, /Retry after 3 seconds/) { |e| expect(e.retry_after).to eq(3) }
    end

    it "has a nil retry_after when the header is missing or not numeric" do
      [{}, {"x-ratelimit-reset" => "soon"}, {"x-ratelimit-reset" => "1e309"}].each do |headers|
        expect { described_class.new(faraday_response(429, headers)) }
          .to raise_error(PaystackSdk::RateLimitError, "Rate limit exceeded") { |e| expect(e.retry_after).to be_nil }
      end
    end

    it "rounds fractional resets up" do
      expect { described_class.new(faraday_response(429, {"x-ratelimit-reset" => "1.2"})) }
        .to raise_error(PaystackSdk::RateLimitError) { |e| expect(e.retry_after).to eq(2) }
    end

    it "still returns an unsuccessful response for other 4xx and raises on 401" do
      expect(described_class.new(faraday_response(404))).to be_failed
      expect { described_class.new(faraday_response(401)) }.to raise_error(PaystackSdk::AuthenticationError)
    end
  end
end
