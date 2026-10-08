# frozen_string_literal: true

RSpec.describe "HTTP resilience" do
  let(:url) { "https://api.paystack.co" }
  let(:client) { PaystackSdk::Client.new(secret_key: "sk_test_xxx", max_retries: 2, retry_interval: 0.01) }
  let(:json) { {"Content-Type" => "application/json"} }
  let(:ok_body) { {status: true, message: "ok", data: {id: 1}}.to_json }
  let(:ok) { {status: 200, headers: json, body: ok_body} }
  let(:unavailable) { {status: 503, headers: json, body: "{}"} }
  let(:rate_limited) { {status: 429, headers: json.merge("x-ratelimit-reset" => "1"), body: "{}"} }
  let(:payload) { {source: "balance", amount: 5000, recipient: "RCP_1", reference: "ref-123"} }

  def connection_attempts(method, path)
    a_request(method, "#{url}#{path}")
  end

  describe "timeouts" do
    it "configures sensible defaults" do
      expect(client.connection.options.timeout).to eq(30)
      expect(client.connection.options.open_timeout).to eq(5)
    end

    it "allows overriding them" do
      custom = PaystackSdk::Client.new(secret_key: "sk", timeout: 10, open_timeout: 2)
      expect(custom.connection.options.timeout).to eq(10)
      expect(custom.connection.options.open_timeout).to eq(2)
    end
  end

  describe "option passthrough" do
    it "reaches resources built directly" do
      resource = PaystackSdk::Resources::Banks.new(secret_key: "sk", timeout: 7)
      expect(resource.instance_variable_get(:@connection).options.timeout).to eq(7)
    end

    it "applies to the PAYSTACK_SECRET_KEY fallback" do
      original = ENV["PAYSTACK_SECRET_KEY"]
      ENV["PAYSTACK_SECRET_KEY"] = "sk_env"
      expect(PaystackSdk::Client.new(timeout: 9).connection.options.timeout).to eq(9)
    ensure
      ENV["PAYSTACK_SECRET_KEY"] = original
    end

    it "rejects options passed alongside a pre-built connection" do
      custom = Faraday.new(url: url)

      expect { PaystackSdk::Client.new(custom, timeout: 5, max_retries: 0) }
        .to raise_error(ArgumentError, /timeout, max_retries cannot be used with a pre-built connection/)
    end

    # contract: false because a user-supplied connection here has no Authorization header on purpose
    it "leaves a user-supplied connection untouched (no retries, no error wrapping)", contract: false do
      custom = Faraday.new(url: url) { |c| c.adapter Faraday.default_adapter }
      stub_request(:get, "#{url}/bank").to_timeout

      expect(PaystackSdk::Client.new(custom).connection).to be(custom)
      expect { PaystackSdk::Client.new(custom).banks.list }.to raise_error(Faraday::Error)
      expect(connection_attempts(:get, "/bank")).to have_been_made.once
    end
  end

  describe "option validation" do
    {
      timeout: [0, -1, "30", nil],
      open_timeout: [0, "5"],
      max_retries: [-1, 1.5, "2", nil],
      retry_interval: [-0.1, "1", nil]
    }.each do |option, bad_values|
      bad_values.each do |value|
        it "rejects #{option}: #{value.inspect}" do
          expect { PaystackSdk::Client.new(:secret_key => "sk", option => value) }.to raise_error(ArgumentError, /#{option}/)
        end
      end
    end

    it "accepts zero retries and a zero retry interval" do
      expect { PaystackSdk::Client.new(secret_key: "sk", max_retries: 0, retry_interval: 0) }.not_to raise_error
    end
  end

  describe "rate limiting (x-ratelimit-reset)" do
    it "raises RateLimitError carrying the reset value after retries are exhausted" do
      allow_any_instance_of(Faraday::Retry::Middleware).to receive(:sleep)
      stub_request(:get, "#{url}/bank").to_return(rate_limited)

      expect { client.banks.list }.to raise_error(PaystackSdk::RateLimitError) { |e| expect(e.retry_after).to eq(1) }
      expect(connection_attempts(:get, "/bank")).to have_been_made.times(3)
    end

    it "waits for the x-ratelimit-reset value before retrying" do
      waits = []
      allow_any_instance_of(Faraday::Retry::Middleware).to receive(:sleep) { |_, secs| waits << secs }
      stub_request(:get, "#{url}/bank").to_return(rate_limited, ok)

      expect(client.banks.list).to be_success
      expect(waits).to eq([1.0])
    end

    it "does not wait or retry when the reset exceeds the maximum wait" do
      long = {status: 429, headers: json.merge("x-ratelimit-reset" => "120"), body: "{}"}
      allow_any_instance_of(Faraday::Retry::Middleware).to receive(:sleep).and_raise("must not sleep")
      stub_request(:get, "#{url}/bank").to_return(long)

      expect { client.banks.list }.to raise_error(PaystackSdk::RateLimitError) { |e| expect(e.retry_after).to eq(120) }
      expect(connection_attempts(:get, "/bank")).to have_been_made.once
    end

    it "retries a write that was rate limited, then succeeds" do
      allow_any_instance_of(Faraday::Retry::Middleware).to receive(:sleep)
      stub_request(:post, "#{url}/transfer").to_return(rate_limited, ok)

      expect(client.transfers.create(payload)).to be_success
      expect(connection_attempts(:post, "/transfer")).to have_been_made.times(2)
    end
  end

  describe "retrying reads" do
    it "retries a GET on 503 and succeeds" do
      stub_request(:get, "#{url}/bank").to_return(unavailable, ok)

      expect(client.banks.list).to be_success
      expect(connection_attempts(:get, "/bank")).to have_been_made.times(2)
    end

    %w[502 503 504].each do |status|
      it "retries a GET on #{status}" do
        stub_request(:get, "#{url}/bank").to_return({status: status.to_i, headers: json, body: "{}"}, ok)

        expect(client.banks.list).to be_success
      end
    end

    it "raises ServerError when 5xx persists after retries" do
      stub_request(:get, "#{url}/bank").to_return(status: 502, headers: json, body: "{}")

      expect { client.banks.list }.to raise_error(PaystackSdk::ServerError)
      expect(connection_attempts(:get, "/bank")).to have_been_made.times(3)
    end

    it "does not retry a plain 500" do
      stub_request(:get, "#{url}/bank").to_return(status: 500, headers: json, body: "{}")

      expect { client.banks.list }.to raise_error(PaystackSdk::ServerError)
      expect(connection_attempts(:get, "/bank")).to have_been_made.once
    end

    it "does not retry a 4xx" do
      stub_request(:get, "#{url}/bank").to_return(status: 404, headers: json, body: {message: "nope"}.to_json)

      expect(client.banks.list).to be_failed
      expect(connection_attempts(:get, "/bank")).to have_been_made.once
    end

    it "does not retry when max_retries is 0" do
      no_retry = PaystackSdk::Client.new(secret_key: "sk", max_retries: 0)
      stub_request(:get, "#{url}/bank").to_return(unavailable)

      expect { no_retry.banks.list }.to raise_error(PaystackSdk::ServerError)
      expect(connection_attempts(:get, "/bank")).to have_been_made.once
    end
  end

  describe "writes are never retried on 5xx or network errors" do
    it "does not retry a POST on 503, even with a reference" do
      stub_request(:post, "#{url}/transfer").to_return(unavailable)

      expect { client.transfers.create(payload) }.to raise_error(PaystackSdk::ServerError)
      expect(connection_attempts(:post, "/transfer")).to have_been_made.once
    end

    it "does not retry a POST on timeout" do
      stub_request(:post, "#{url}/transfer").to_timeout

      expect { client.transfers.create(payload) }.to raise_error(PaystackSdk::TimeoutError)
      expect(connection_attempts(:post, "/transfer")).to have_been_made.once
    end

    it "does not retry a POST on connection failure" do
      stub_request(:post, "#{url}/transfer").to_raise(Faraday::ConnectionFailed.new("reset"))

      expect { client.transfers.create(payload) }.to raise_error(PaystackSdk::ConnectionError)
      expect(connection_attempts(:post, "/transfer")).to have_been_made.once
    end

    it "does not retry PUT or DELETE on 503" do
      stub_request(:put, "#{url}/customer/CUS_1").to_return(unavailable)
      stub_request(:delete, "#{url}/transferrecipient/RCP_1").to_return(unavailable)

      expect { PaystackSdk::Response.new(client.connection.put("/customer/CUS_1", {first_name: "Ama"})) }
        .to raise_error(PaystackSdk::ServerError)
      expect { PaystackSdk::Response.new(client.connection.delete("/transferrecipient/RCP_1")) }
        .to raise_error(PaystackSdk::ServerError)
      expect(connection_attempts(:put, "/customer/CUS_1")).to have_been_made.once
      expect(connection_attempts(:delete, "/transferrecipient/RCP_1")).to have_been_made.once
    end

    it "retries writes on 5xx and network errors only with retry_non_idempotent: true" do
      eager = PaystackSdk::Client.new(secret_key: "sk", retry_interval: 0.01, retry_non_idempotent: true)
      stub_request(:post, "#{url}/transfer").to_return(unavailable, ok)

      expect(eager.transfers.create(payload)).to be_success
      expect(connection_attempts(:post, "/transfer")).to have_been_made.times(2)
    end
  end

  describe "transport errors" do
    it "wraps timeouts in PaystackSdk::TimeoutError after retrying a read" do
      stub_request(:get, "#{url}/bank").to_timeout

      expect { client.banks.list }.to raise_error(PaystackSdk::TimeoutError)
      expect(connection_attempts(:get, "/bank")).to have_been_made.times(3)
    end

    it "wraps connection failures in PaystackSdk::ConnectionError" do
      stub_request(:get, "#{url}/bank").to_raise(Faraday::ConnectionFailed.new("refused"))

      expect { client.banks.list }.to raise_error(PaystackSdk::ConnectionError, /refused/)
      expect(connection_attempts(:get, "/bank")).to have_been_made.times(3)
    end

    it "is rescuable as PaystackSdk::Error, and TimeoutError as ConnectionError" do
      stub_request(:get, "#{url}/bank").to_timeout

      expect { client.banks.list }.to raise_error(PaystackSdk::Error)
      expect(PaystackSdk::TimeoutError.ancestors).to include(PaystackSdk::ConnectionError, PaystackSdk::Error)
    end
  end
end

RSpec.describe PaystackSdk::Middleware::TransportErrors do
  def call_with(error)
    app = ->(_env) { raise error }
    described_class.new(app).call({})
  end

  it "maps Faraday::TimeoutError to TimeoutError" do
    expect { call_with(Faraday::TimeoutError.new("slow")) }.to raise_error(PaystackSdk::TimeoutError, /slow/)
  end

  it "maps ConnectionFailed to ConnectionError" do
    expect { call_with(Faraday::ConnectionFailed.new("refused")) }
      .to raise_error(PaystackSdk::ConnectionError, /refused/) { |e| expect(e).not_to be_a(PaystackSdk::TimeoutError) }
  end

  it "maps SSL errors to ConnectionError" do
    expect { call_with(Faraday::SSLError.new("bad cert")) }.to raise_error(PaystackSdk::ConnectionError, /bad cert/)
  end

  it "maps a ConnectionFailed caused by a connect timeout to TimeoutError" do
    error = begin
      begin
        raise Net::OpenTimeout, "execution expired"
      rescue Net::OpenTimeout
        raise Faraday::ConnectionFailed, "execution expired"
      end
    rescue Faraday::ConnectionFailed => e
      e
    end

    expect { call_with(error) }.to raise_error(PaystackSdk::TimeoutError)
  end

  it "passes other errors and successful responses through" do
    expect { call_with(ArgumentError.new("x")) }.to raise_error(ArgumentError)
    expect(described_class.new(->(env) { env }).call(:ok)).to eq(:ok)
  end
end
