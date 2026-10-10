# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"
require "yaml"

# The scaffold generates most resources from three inputs: the pinned spec, bin/scaffold_names.yml and
# spec/support/paystack_contract_exceptions.yml. If an input is damaged (a merge once emptied two entries),
# the generated files still look fine until someone regenerates, and then a keyword changes silently.
# These examples fail the moment the inputs and the generated files disagree.
RSpec.describe "generated resources and their inputs", contract: false do
  root = File.expand_path("..", __dir__)
  script = File.join(root, "bin", "paystack-scaffold")
  empty_docs = Dir.mktmpdir("no-docs")

  after(:all) { FileUtils.remove_entry(empty_docs) if File.exist?(empty_docs) }

  def run_scaffold(script, *args) = Open3.capture3(RbConfig.ruby, script, *args)

  # @see lines depend on saved docs pages (not in CI) and the digest depends on them
  def normalise(text) = text.lines.reject { |l| l.include?("# @see ") || l.include?("scaffold-digest:") }.join

  describe "the inputs" do
    let(:names) { YAML.safe_load_file(File.join(root, "bin", "scaffold_names.yml")) }
    let(:exceptions) { YAML.safe_load_file(File.join(root, "spec", "support", "paystack_contract_exceptions.yml")) }

    it "has no empty entry in the names file" do
      empty = names.select { |_, value| value.nil? || value == {} || value == "" }.keys

      expect(empty).to be_empty, "empty names entries: #{empty.inspect}"
    end

    it "has no names entry with a hash that says nothing" do
      names.each do |key, value|
        next unless value.is_a?(Hash)

        expect(value.keys & %w[name keywords body note]).not_to be_empty, "#{key} is a hash with no usable key"
      end
    end

    it "gives every exception its operation, location, wire name and a reason" do
      incomplete = exceptions.reject { |e| e["operation"] && e["in"] && e["wire"] && e["reason"] }

      expect(incomplete).to be_empty, "incomplete entries: #{incomplete.map { |e| e["operation"] }.inspect}"
    end

    it "has no two exceptions for the same operation, location and wire name" do
      keys = exceptions.map { |e| [e["operation"], e["in"], e["wire"]] }

      expect(keys.tally.select { |_, n| n > 1 }.keys).to be_empty
    end
  end

  describe "each resource the scaffold generates and nobody has hand-edited" do
    Dir[File.join(root, "lib", "paystack_sdk", "resources", "*.rb")].sort.each do |file|
      tag = File.read(file)[/regenerate it with `bin\/paystack-scaffold (.+?)`/, 1] or next

      it "#{File.basename(file)} is what `bin/paystack-scaffold #{tag}` produces from the current inputs" do
        status, = run_scaffold(script, tag, "--dry-run", "--docs", empty_docs)
        # a hand-owned file is reported as protected: it is not ours to compare
        next if status.lines.any? { |l| l =~ /protected\s+lib\/paystack_sdk\/resources\/#{File.basename(file)}/ }

        printed, _, result = run_scaffold(script, tag, "--print", "--docs", empty_docs)
        expect(result).to be_success
        expect(normalise(File.read(file))).to eq(normalise(printed)),
          "#{File.basename(file)} no longer matches what the scaffold generates. Regenerate it with " \
          "`bin/paystack-scaffold \"#{tag}\"`, or fix the names/exceptions entry that changed."
      end
    end
  end
end
