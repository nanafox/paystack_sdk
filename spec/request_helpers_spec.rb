# frozen_string_literal: true

RSpec.describe PaystackSdk::RequestHelpers do
  let(:helper) { Class.new { include PaystackSdk::RequestHelpers }.new }

  def call(name, *args, **kwargs)
    helper.send(name, *args, **kwargs)
  end

  describe "#escape_path" do
    it "leaves safe segments alone" do
      expect(call(:escape_path, "CUS_abc123")).to eq("CUS_abc123")
      expect(call(:escape_path, "ref-1.2=3")).to eq("ref-1.2%3D3")
    end

    it "encodes characters that would change the path" do
      expect(call(:escape_path, "a/b")).to eq("a%2Fb")
      expect(call(:escape_path, "a?b#c")).to eq("a%3Fb%23c")
      expect(call(:escape_path, "a b")).to eq("a%20b")
    end

    it "keeps `..` inside a longer value from escaping the segment" do
      expect(call(:escape_path, "a/../b")).to eq("a%2F..%2Fb")
      expect(call(:escape_path, "../transaction")).to eq("..%2Ftransaction")
    end

    it "does not double-decode: an already percent-encoded dot segment stays literal" do
      expect(call(:escape_path, "%2e%2e")).to eq("%252e%252e")
    end

    it "refuses `.` and `..`, which the URL builder would resolve to another endpoint" do
      [".", ".."].each do |segment|
        expect { call(:escape_path, segment) }
          .to raise_error(PaystackSdk::InvalidValueError, /must not be "\.{1,2}"/)
      end
    end

    it "refuses an empty segment, which would collapse into the path before it" do
      ["", nil].each do |segment|
        expect { call(:escape_path, segment) }.to raise_error(PaystackSdk::InvalidValueError, /must not be empty/)
      end
    end

    it "names the parameter in the error when given one" do
      expect { call(:escape_path, "..", name: "reference") }
        .to raise_error(PaystackSdk::InvalidValueError, /reference/)
    end

    it "never lets a built URL leave its endpoint, whatever the value" do
      conn = Faraday.new(url: "https://api.paystack.co")
      ["CUS_1", "a/b", "../x", "a b", "?x=1", "#frag", "%2e%2e", "..%2f..", "a\\b", "x" * 300].each do |value|
        url = conn.build_exclusive_url("/customer/#{call(:escape_path, value)}")
        expect(url.path).to start_with("/customer/")
        expect(url.path.delete_prefix("/customer/")).not_to include("/")
        expect(url.query).to be_nil
        expect(url.fragment).to be_nil
      end
    end

    it "encodes an email address" do
      expect(call(:escape_path, "ama@example.com")).to eq("ama%40example.com")
    end

    it "accepts integers" do
      expect(call(:escape_path, 42)).to eq("42")
    end
  end

  describe "#compact_params" do
    it "drops nil values only" do
      expect(call(:compact_params, a: 1, b: nil, c: false, d: 0, e: "")).to eq(a: 1, c: false, d: 0, e: "")
    end
  end

  describe "#to_wire" do
    it "renames keys to the names Paystack uses and leaves the rest" do
      params = {per_page: 20, terminal_id: "T1", status: "success"}
      mapping = {per_page: "perPage", terminal_id: "terminalid"}

      expect(call(:to_wire, params, mapping)).to eq("perPage" => 20, "terminalid" => "T1", "status" => "success")
    end

    it "drops nil values" do
      expect(call(:to_wire, {a: 1, b: nil}, {})).to eq("a" => 1)
    end

    it "returns string keys so the request carries exactly what Paystack documents" do
      expect(call(:to_wire, {page: 1}, {}).keys).to all(be_a(String))
    end
  end

  describe "#format_datetime" do
    it "formats a Time as UTC ISO 8601" do
      expect(call(:format_datetime, Time.utc(2026, 1, 2, 3, 4, 5))).to eq("2026-01-02T03:04:05Z")
      expect(call(:format_datetime, Time.new(2026, 1, 2, 5, 0, 0, "+02:00"))).to eq("2026-01-02T03:00:00Z")
    end

    it "formats a Date as a calendar date" do
      expect(call(:format_datetime, Date.new(2026, 1, 2))).to eq("2026-01-02")
    end

    it "passes through a valid ISO 8601 string" do
      expect(call(:format_datetime, "2026-01-02")).to eq("2026-01-02")
      expect(call(:format_datetime, "2016-09-24T00:00:05.000Z")).to eq("2016-09-24T00:00:05.000Z")
    end

    it "returns nil for nil" do
      expect(call(:format_datetime, nil)).to be_nil
    end

    it "rejects text that is not a date, naming the parameter" do
      expect { call(:format_datetime, "yesterday", name: "from") }
        .to raise_error(PaystackSdk::InvalidFormatError, /from/)
    end
  end

  describe "#format_date" do
    it "formats dates and times as YYYY-MM-DD" do
      expect(call(:format_date, Date.new(2016, 9, 21))).to eq("2016-09-21")
      expect(call(:format_date, Time.utc(2016, 9, 21, 23, 0, 0))).to eq("2016-09-21")
    end

    it "accepts a YYYY-MM-DD string and rejects other shapes" do
      expect(call(:format_date, "2016-09-21")).to eq("2016-09-21")
      expect { call(:format_date, "21/09/2016", name: "birthday") }.to raise_error(PaystackSdk::InvalidFormatError, /birthday/)
      expect { call(:format_date, "2016-13-45", name: "birthday") }.to raise_error(PaystackSdk::InvalidFormatError)
    end

    it "returns nil for nil" do
      expect(call(:format_date, nil)).to be_nil
    end
  end

  describe "#stringify_json" do
    it "turns a Hash or Array into a JSON string, for fields Paystack documents as stringified JSON" do
      expect(call(:stringify_json, {plan: "pro", seats: 3})).to eq('{"plan":"pro","seats":3}')
      expect(call(:stringify_json, [1, 2])).to eq("[1,2]")
    end

    it "leaves a String as given and nil as nil" do
      expect(call(:stringify_json, '{"a":1}')).to eq('{"a":1}')
      expect(call(:stringify_json, nil)).to be_nil
    end
  end
end
