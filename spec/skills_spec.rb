# frozen_string_literal: true

require "tmpdir"
require "paystack_sdk/skills"

RSpec.describe PaystackSdk::Skills, contract: false do
  let(:dir) { File.join(Dir.mktmpdir("skills"), ".claude", "skills") }
  let(:names) { described_class.all.map(&:name) }

  after { FileUtils.remove_entry(File.dirname(dir, 2)) if File.exist?(File.dirname(dir, 2)) }

  def statuses(results) = results.to_h { |r| [r.name, r.status] }

  describe ".all" do
    it "lists the shipped skills with their description" do
      overview = described_class.all.find { |s| s.name == "paystack-sdk-overview" }

      expect(overview.description).to start_with("Use when")
      expect(overview.path).to end_with("skills/paystack-sdk-overview")
    end
  end

  describe ".install" do
    it "creates every skill folder, marked and stamped with the gem version" do
      results = described_class.install(dir)

      expect(statuses(results).values.uniq).to eq(["create"])
      names.each do |name|
        marker = JSON.parse(File.read(File.join(dir, name, ".paystack_sdk.json")))
        expect(marker).to eq("gem" => "paystack_sdk", "version" => PaystackSdk::VERSION)
        front = described_class.frontmatter(File.read(File.join(dir, name, "SKILL.md")))
        expect(front["name"]).to eq(name)
        expect(File.read(File.join(dir, name, "SKILL.md"))).to include(%(gem_version: "#{PaystackSdk::VERSION}"))
      end
    end

    it "keeps the skill's own frontmatter and body unchanged apart from the stamp" do
      described_class.install(dir)
      source = File.read(File.join(described_class::SOURCE_DIR, "paystack-sdk-overview", "SKILL.md"))
      installed = File.read(File.join(dir, "paystack-sdk-overview", "SKILL.md"))

      expect(installed.sub(/metadata:\n  gem: paystack_sdk\n  gem_version: "[^"]+"\n/, "")).to eq(source)
    end

    it "is idempotent: a second run reports identical and changes nothing" do
      described_class.install(dir)
      before = Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }.to_h { |f| [f, File.mtime(f)] }

      results = described_class.install(dir)

      expect(statuses(results).values.uniq).to eq(["identical"])
      after = Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }.to_h { |f| [f, File.mtime(f)] }
      expect(after).to eq(before)
    end

    it "updates a folder it installed when it differs, and restores edited files" do
      described_class.install(dir)
      File.write(File.join(dir, "paystack-sdk-overview", "SKILL.md"), "edited")

      results = described_class.install(dir)

      expect(statuses(results)["paystack-sdk-overview"]).to eq("update")
      expect(File.read(File.join(dir, "paystack-sdk-overview", "SKILL.md"))).to start_with("---\nname: paystack-sdk-overview")
    end

    it "updates a folder installed by an older gem version, restamping it" do
      described_class.install(dir)
      marker = File.join(dir, "paystack-sdk-overview", ".paystack_sdk.json")
      File.write(marker, JSON.generate("gem" => "paystack_sdk", "version" => "0.0.1"))

      results = described_class.install(dir)

      expect(statuses(results)["paystack-sdk-overview"]).to eq("update")
      expect(JSON.parse(File.read(marker))["version"]).to eq(PaystackSdk::VERSION)
    end

    it "never touches a skill of the user's own" do
      mine = File.join(dir, "my-own-skill")
      FileUtils.mkdir_p(mine)
      File.write(File.join(mine, "SKILL.md"), "mine")

      described_class.install(dir)
      described_class.install(dir)

      expect(File.read(File.join(mine, "SKILL.md"))).to eq("mine")
      expect(Dir.children(mine)).to eq(["SKILL.md"])
    end

    it "leaves a same-named folder it did not install alone, and says conflict" do
      theirs = File.join(dir, "paystack-sdk-overview")
      FileUtils.mkdir_p(theirs)
      File.write(File.join(theirs, "SKILL.md"), "not ours")

      results = described_class.install(dir)

      expect(statuses(results)["paystack-sdk-overview"]).to eq("conflict")
      expect(File.read(File.join(theirs, "SKILL.md"))).to eq("not ours")
    end

    it "replaces that folder only with force" do
      theirs = File.join(dir, "paystack-sdk-overview")
      FileUtils.mkdir_p(theirs)
      File.write(File.join(theirs, "SKILL.md"), "not ours")

      results = described_class.install(dir, force: true)

      expect(statuses(results)["paystack-sdk-overview"]).to eq("force")
      expect(File.read(File.join(theirs, "SKILL.md"))).to start_with("---\nname: paystack-sdk-overview")
    end

    it "removes a folder it installed that the gem no longer ships, and only that" do
      described_class.install(dir)
      gone = File.join(dir, "paystack-sdk-retired")
      FileUtils.mkdir_p(gone)
      File.write(File.join(gone, ".paystack_sdk.json"), JSON.generate("gem" => "paystack_sdk", "version" => "0.0.1"))
      File.write(File.join(gone, "SKILL.md"), "old")
      other = File.join(dir, "someone-elses-retired")
      FileUtils.mkdir_p(other)
      File.write(File.join(other, ".paystack_sdk.json"), JSON.generate("gem" => "another_gem"))

      results = described_class.install(dir)

      expect(statuses(results)["paystack-sdk-retired"]).to eq("remove")
      expect(File.exist?(gone)).to be(false)
      expect(File.exist?(other)).to be(true)
    end

    it "with dry_run reports the same results and writes nothing" do
      results = described_class.install(dir, dry_run: true)

      expect(statuses(results).values.uniq).to eq(["create"])
      expect(File.exist?(dir)).to be(false)
    end

    it "treats a marker that is not valid JSON as not ours" do
      theirs = File.join(dir, "paystack-sdk-overview")
      FileUtils.mkdir_p(theirs)
      File.write(File.join(theirs, ".paystack_sdk.json"), "{ not json")

      expect(statuses(described_class.install(dir))["paystack-sdk-overview"]).to eq("conflict")
    end
  end

  describe ".uninstall" do
    it "removes the folders it installed and leaves everything else" do
      described_class.install(dir)
      mine = File.join(dir, "my-own-skill")
      FileUtils.mkdir_p(mine)

      results = described_class.uninstall(dir)

      expect(results.map(&:name)).to eq(names)
      expect(Dir.children(dir)).to eq(["my-own-skill"])
    end

    it "does nothing when the directory does not exist" do
      expect(described_class.uninstall(File.join(dir, "missing"))).to eq([])
    end
  end

  describe ".frontmatter" do
    it "reads single-quoted and plain values and ignores a missing block" do
      text = "---\nname: x\ndescription: 'It''s a: test'\n---\nbody"

      expect(described_class.frontmatter(text)).to eq("name" => "x", "description" => "It's a: test")
      expect(described_class.frontmatter("no frontmatter")).to eq({})
    end
  end
end
