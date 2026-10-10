# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "json"

$LOAD_PATH.unshift(File.expand_path("../docs/scripts/lib", __dir__))
require "readme_splitter"
require "reference_builder"
require "skills_builder"
require "llms_builder"

# The docs site is generated from README.md, the YARD comments and the shipped skills. These specs keep the
# generators honest: no page may link to a page that does not exist, and the raw files agents read must be
# whole.
RSpec.describe "the docs site content" do
  let(:root) { File.expand_path("..", __dir__) }
  let(:readme_pages) { PaystackDocs::ReadmeSplitter.new(File.read(File.join(root, "README.md"))).pages }
  let(:reference_pages) { PaystackDocs::ReferenceBuilder.new(root).pages }
  let(:skills) { PaystackDocs::SkillsBuilder.new(root) }
  let(:pages) { readme_pages + reference_pages + skills.pages }

  def internal_links(page)
    PaystackDocs::Markdown.map_prose(page.body) { |l| l }
    links = []
    PaystackDocs::Markdown.each_line(page.body) do |line, in_code|
      next if in_code

      line.scan(%r{\]\((/[^)\s#]*)}) { links << $1 }
    end
    links
  end

  it "has no internal link to a missing page" do
    known = pages.map { |p| "/#{p.path}" } + ["/skills/", "/llms.txt", "/changelog"]
    known += pages.select { |p| p.path.end_with?("/index") }.map { |p| "/#{p.path.delete_suffix("index")}" }
    missing = pages.flat_map { |p| internal_links(p).reject { |l| known.include?(l) || l.end_with?("/") }.map { |l| "#{p.path} -> #{l}" } }

    expect(missing).to be_empty
  end

  it "gives every README section a page and leaves no in-page anchor link behind" do
    expect(readme_pages.map(&:path).uniq.size).to eq(readme_pages.size)
    leftovers = readme_pages.select { |p| p.body.match?(/\]\(#[\w-]+\)/) }.map(&:path)

    expect(leftovers).to be_empty
  end

  it "has a reference page for every resource the Client exposes" do
    accessors = PaystackSdk::Client.instance_methods(false).map(&:to_s)
    paths = reference_pages.map(&:path)
    resources = Dir[File.join(root, "lib/paystack_sdk/resources/*.rb")].map { |f| File.basename(f, ".rb") } - ["base"]

    expect(resources.map { |r| "reference/#{r.tr("_", "-")}" } - paths).to be_empty
    expect(accessors).to include("transactions")
  end

  it "lists every webhook event and renders signatures without parentheses when there are no arguments" do
    webhook = reference_pages.find { |p| p.path == "reference/webhook" }
    client = reference_pages.find { |p| p.path == "reference/client" }

    expect(webhook.body.scan(/^- `[\w.\-]+`$/).size).to eq(PaystackSdk::Webhook::EVENTS.size)
    expect(client.body).to include("client.live?")
    expect(client.body).not_to include("live?()")
  end

  it "publishes each skill raw with relative links and rendered with site links" do
    raw = skills.raw_files

    expect(raw.keys.sort).to eq(Dir[File.join(root, "lib/paystack_sdk/skills/*")].map { |d| File.basename(d) }.sort)
    expect(raw.values.join).not_to include("[[")
    expect(skills.pages.map(&:path)).to include("skills/index", "skills/paystack-sdk-overview")
    expect(skills.pages.map(&:body).join).not_to include("[[")
  end

  describe PaystackDocs::LlmsBuilder do
    subject(:files) do
      described_class.new(pages: pages, skills: skills, site_url: "https://example.test/paystack_sdk/latest", version: "9.9.9").files
    end

    it "writes llms.txt that links only to raw markdown that exists" do
      urls = files["llms.txt"].scan(%r{\(https://example\.test/paystack_sdk/latest/([^)]+)\)}).flatten
      missing = urls.reject { |u| u == "llms-full.txt" || files.key?(u) }

      expect(missing).to be_empty
      expect(files["llms.txt"]).to start_with("# Paystack Ruby SDK (paystack_sdk 9.9.9)")
    end

    it "makes internal links in raw pages absolute and keeps code fences untouched" do
      body = files["md/guide/transactions.md"]

      expect(body).not_to match(%r{\]\(/})
      expect(files["llms-full.txt"]).to include("# Skill: paystack-sdk-overview")
    end
  end

  describe "versions.rb" do
    it "lists versions newest first and writes the redirect" do
      Dir.mktmpdir do |dir|
        %w[0.4.1 0.5.0 0.10.0 next latest].each { |d| Dir.mkdir(File.join(dir, d)) }
        script = File.join(root, "docs/scripts/versions.rb")

        expect(`ruby #{script} #{dir} --print-latest`.strip).to eq("0.10.0")
        system("ruby", script, dir, out: File::NULL, exception: true)
        data = JSON.parse(File.read(File.join(dir, "versions.json")))

        expect(data).to eq("latest" => "0.10.0", "versions" => %w[0.10.0 0.5.0 0.4.1], "next" => true)
        expect(File.read(File.join(dir, "index.html"))).to include("url=latest/")
      end
    end
  end
end
