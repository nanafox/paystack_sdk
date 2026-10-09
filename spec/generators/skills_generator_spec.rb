# frozen_string_literal: true

require "tmpdir"
require_relative "../support/fake_rails_generators"
require_relative "../../lib/generators/paystack_sdk/skills_generator"

RSpec.describe PaystackSdk::Generators::SkillsGenerator, contract: false do
  let(:root) { Dir.mktmpdir("rails-app") }

  after { FileUtils.remove_entry(root) }

  def generate(**options)
    described_class.new(destination_root: root, **options).tap(&:install_skills)
  end

  it "is found by Rails as paystack_sdk:skills (class path and name follow the generator convention)" do
    expect(described_class.name).to eq("PaystackSdk::Generators::SkillsGenerator")
    expect(File.exist?(File.expand_path("../../lib/generators/paystack_sdk/skills_generator.rb", __dir__))).to be(true)
  end

  it "installs the skills into the app's .claude/skills and reports each one" do
    generator = generate

    expect(File.exist?(File.join(root, ".claude", "skills", "paystack-sdk-overview", "SKILL.md"))).to be(true)
    expect(generator.statuses).to include(["create", "paystack-sdk-overview", :green])
  end

  it "is idempotent, and a --pretend run writes nothing" do
    generate
    expect(generate.statuses.map(&:first).uniq).to eq(["identical"])

    other = Dir.mktmpdir("rails-app-2")
    described_class.new(destination_root: other, pretend: true).install_skills
    expect(File.exist?(File.join(other, ".claude"))).to be(false)
    FileUtils.remove_entry(other)
  end

  it "leaves a skill of its own alone and says so" do
    FileUtils.mkdir_p(File.join(root, ".claude", "skills", "paystack-sdk-overview"))
    File.write(File.join(root, ".claude", "skills", "paystack-sdk-overview", "SKILL.md"), "mine")

    generator = generate

    expect(File.read(File.join(root, ".claude", "skills", "paystack-sdk-overview", "SKILL.md"))).to eq("mine")
    expect(generator.statuses.map(&:first)).to include("conflict", "note")
  end
end
