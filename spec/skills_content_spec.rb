# frozen_string_literal: true

require "paystack_sdk/skills"

# Every skill the gem ships is read by an agent that picks it by its description and then follows it, so
# each one is checked for the shape Claude Code expects, and its code blocks must at least be valid Ruby.
RSpec.describe "the AI skills shipped in the gem", contract: false do
  skills = PaystackSdk::Skills.all

  it "ships at least the overview" do
    expect(skills.map(&:name)).to include("paystack-sdk-overview")
  end

  it "routes to every other skill from the overview, so an agent that loads the overview first can find them" do
    overview = File.read(File.join(PaystackSdk::Skills::SOURCE_DIR, "paystack-sdk-overview", "SKILL.md"))
    linked = overview.scan(/\[\[([\w-]+)\]\]/).flatten

    expect(skills.map(&:name) - ["paystack-sdk-overview"] - linked).to be_empty
  end

  skills.each do |skill|
    describe skill.name do
      let(:text) { File.read(File.join(skill.path, "SKILL.md")) }
      let(:front) { PaystackSdk::Skills.frontmatter(text) }

      it "is namespaced paystack-sdk-<topic> and its frontmatter name is its folder name" do
        expect(skill.name).to match(/\Apaystack-sdk-[a-z0-9]+(-[a-z0-9]+)*\z/)
        expect(front["name"]).to eq(skill.name)
      end

      it "has a description that says when to load it, within Claude Code's limit" do
        expect(front["description"]).to match(/\AUse (when|before|after)\b/)
        expect(front["description"].size).to be <= 1024
      end

      it "leaves the metadata block to the installer" do
        expect(text[/\A---\n(.*?)\n---\n/m, 1]).not_to match(/^metadata:/)
      end

      it "has only markdown files, and every [[skill]] link points at a shipped skill" do
        files = Dir.glob("**/*", base: skill.path).select { |f| File.file?(File.join(skill.path, f)) }
        expect(files).to all(end_with(".md"))
        links = files.flat_map { |f| File.read(File.join(skill.path, f)).scan(/\[\[([\w-]+)\]\]/).flatten }
        expect(links - skills.map(&:name)).to be_empty
      end

      it "has Ruby code blocks that parse" do
        blocks = text.scan(/^```ruby\n(.*?)^```/m).flatten
        blocks.each do |code|
          expect { RubyVM::InstructionSequence.compile(code) }.not_to raise_error, "does not parse:\n#{code}"
        end
      end

      it "never contains something that looks like a real secret key" do
        expect(text).not_to match(/sk_(live|test)_[A-Za-z0-9]{12,}/)
      end
    end
  end
end
