# frozen_string_literal: true

require "stringio"
require "tmpdir"
require "paystack_sdk/cli"

RSpec.describe PaystackSdk::CLI, contract: false do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }
  let(:root) { Dir.mktmpdir("cli") }

  after { FileUtils.remove_entry(root) }

  def run(*argv) = described_class.run(argv, out: out, err: err)

  it "prints the version" do
    expect(run("version")).to eq(0)
    expect(out.string).to eq("paystack_sdk #{PaystackSdk::VERSION}\n")
  end

  it "prints usage with no arguments and for help" do
    expect(run).to eq(0)
    expect(out.string).to include("paystack_sdk skills install")
  end

  it "installs into --dir, showing a status per skill" do
    expect(run("skills", "install", "--dir", root)).to eq(0)

    expect(out.string).to match(/create\s+paystack-sdk-overview/)
    expect(File.exist?(File.join(root, "paystack-sdk-overview", "SKILL.md"))).to be(true)
  end

  it "installs into ./.claude/skills by default" do
    Dir.chdir(root) { expect(run("skills", "install")).to eq(0) }

    expect(File.exist?(File.join(root, ".claude", "skills", "paystack-sdk-overview", "SKILL.md"))).to be(true)
  end

  it "installs into ~/.claude/skills with --global" do
    allow(Dir).to receive(:home).and_return(root)

    expect(run("skills", "install", "--global")).to eq(0)

    expect(File.exist?(File.join(root, ".claude", "skills", "paystack-sdk-overview", "SKILL.md"))).to be(true)
  end

  it "says identical on a second run" do
    run("skills", "install", "--dir", root)
    out.truncate(0)
    out.rewind

    expect(run("skills", "install", "--dir", root)).to eq(0)
    expect(out.string).to match(/identical\s+paystack-sdk-overview/)
  end

  it "with --dry-run writes nothing" do
    target = File.join(root, "skills")

    expect(run("skills", "install", "--dir", target, "--dry-run")).to eq(0)

    expect(out.string).to include("Dry run").and include("nothing was written")
    expect(File.exist?(target)).to be(false)
  end

  it "exits 1 and explains a conflict, then replaces with --force" do
    FileUtils.mkdir_p(File.join(root, "paystack-sdk-overview"))
    File.write(File.join(root, "paystack-sdk-overview", "SKILL.md"), "not ours")

    expect(run("skills", "install", "--dir", root)).to eq(1)
    expect(out.string).to match(/conflict\s+paystack-sdk-overview/).and include("--force")
    expect(File.read(File.join(root, "paystack-sdk-overview", "SKILL.md"))).to eq("not ours")

    expect(run("skills", "install", "--dir", root, "--force")).to eq(0)
    expect(File.read(File.join(root, "paystack-sdk-overview", "SKILL.md"))).to start_with("---")
  end

  it "uninstalls only what it installed" do
    run("skills", "install", "--dir", root)
    FileUtils.mkdir_p(File.join(root, "mine"))

    expect(run("skills", "uninstall", "--dir", root)).to eq(0)

    expect(Dir.children(root)).to eq(["mine"])
  end

  it "lists the skills with their descriptions, and prints the source path" do
    expect(run("skills", "list")).to eq(0)
    expect(out.string).to include("paystack-sdk-overview").and include("Use when")

    out.truncate(0)
    out.rewind
    expect(run("skills", "path")).to eq(0)
    expect(out.string.chomp).to eq(PaystackSdk::Skills::SOURCE_DIR)
  end

  it "fails with usage on an unknown command, an unknown option, or --dir with --global" do
    expect(run("nope")).to eq(1)
    expect(run("skills", "install", "--bogus")).to eq(1)
    expect(run("skills", "install", "--dir", root, "--global")).to eq(1)
    expect(run("skills", "wat")).to eq(1)
    expect(err.string).to include("Usage:")
  end
end
