# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

# bin/paystack-scaffold creates a resource class, its specs and its place on the Client from the
# OpenAPI spec. These keep it from rotting: every tag must still produce valid Ruby, and the file
# handling must say what it did, Rails style.
RSpec.describe "bin/paystack-scaffold", contract: false do
  let(:script) { File.expand_path("../bin/paystack-scaffold", __dir__) }
  let(:client_source) { File.read(File.expand_path("../lib/paystack_sdk/client.rb", __dir__)) }
  let(:root) { Dir.mktmpdir("scaffold") }

  before do
    FileUtils.mkdir_p(File.join(root, "lib/paystack_sdk"))
    File.write(File.join(root, "lib/paystack_sdk/client.rb"), client_source)
  end

  after { FileUtils.remove_entry(root) }

  def scaffold(*args)
    Open3.capture3(RbConfig.ruby, script, *args)
  end

  def in_root(*args)
    scaffold(*args, "--root", root)
  end

  def path(relative)
    File.join(root, relative)
  end

  def valid_ruby?(source)
    RubyVM::InstructionSequence.compile(source)
    true
  rescue SyntaxError
    false
  end

  describe "--tags" do
    it "lists every tag in the spec" do
      stdout, = scaffold("--tags")
      tags = stdout.lines.map { |line| line.sub(/\s+\d+ operations\s*\z/, "").strip }

      expect(tags.size).to eq(27)
      expect(tags).to include("Charge", "Refund", "Subaccount", "Transfer Recipient")
    end
  end

  describe "--print" do
    it "produces valid Ruby for the class and the specs of every tag" do
      tags = scaffold("--tags").first.lines.map { |line| line.sub(/\s+\d+ operations\s*\z/, "").strip }

      tags.each do |tag|
        [[], ["--spec"]].each do |flags|
          stdout, stderr, status = scaffold(tag, "--print", *flags)
          expect(status).to be_success, "#{tag} #{flags.join}: #{stderr}"
          expect(valid_ruby?(stdout)).to be(true), "#{tag} #{flags.join} is not valid Ruby"
        end
      end
    end

    it "uses keywords, escapes path segments and cites the docs" do
      stdout, = scaffold("Subaccount", "--print")

      expect(stdout).to include("def fetch(code:)")
      expect(stdout).to include('"/subaccount/#{escape_path(code)}"')
      expect(stdout).to include("# @see https://paystack.com/docs/api/subaccount/#fetch-subaccount")
      expect(stdout).to match(/def create\(\n\s+business_name:,\n\s+settlement_bank:,\n\s+account_number:,\n\s+percentage_charge:,\n\s+description: nil/)
    end

    it "wraps long signatures and builds the wire hash in a named local" do
      stdout, = scaffold("Subaccount", "--print")

      expect(stdout).to include("wire_body = to_wire(")
      expect(stdout).to include("handle_response(@connection.post(\"/subaccount\", wire_body))")
      expect(stdout.lines.reject { |line| line.strip.start_with?("#") }.map(&:size).max).to be <= 120
    end

    it "wraps a long enum check one argument per line, so no code line runs long" do
      transfer = scaffold("Transfer", "--print").first
      dispute = scaffold("Dispute", "--print").first

      expect(transfer).to include("validate_allowed_values!(\n          value: status,\n          allowed_values: %w[pending success failed otp")
      [transfer, dispute].each do |source|
        expect(source.lines.reject { |line| line.strip.start_with?("#") }.map(&:size).max).to be <= 120
      end
    end

    it "leaves the parentheses off a method with no parameters" do
      expect(scaffold("Payment Request", "--print").first).to include("def payment_total\n")
    end

    it "sends the names Paystack documents, not the Ruby keywords" do
      expect(scaffold("Subaccount", "--print").first).to include('WIRE_NAMES = {per_page: "perPage"}')
    end

    it "sends a body on DELETE as a body, and a JSON array body as given" do
      expect(scaffold("Apple Pay", "--print").first).to include('@connection.delete("/apple-pay/domain") { |request| request.body = wire_body }')
      expect(scaffold("Bulk Charge", "--print").first).to include('@connection.post("/bulkcharge", items)')
    end

    it "writes hash samples the way StandardRB wants them" do
      expect(scaffold("Order", "--print", "--spec").first).not_to match(/"\w+"=>/)
    end
  end

  describe "creating files" do
    let(:class_file) { "lib/paystack_sdk/resources/refunds.rb" }
    let(:spec_file) { "spec/resources/refunds_spec.rb" }

    it "creates the class, the specs and the Client wiring, and says so" do
      stdout, _, status = in_root("Refund")

      expect(status).to be_success
      expect(stdout).to match(%r{create\s+#{class_file}})
      expect(stdout).to match(%r{create\s+#{spec_file}})
      expect(stdout).to match(%r{insert\s+lib/paystack_sdk/client.rb\s+\(require resources/refunds\)})
      expect(stdout).to match(%r{insert\s+lib/paystack_sdk/client.rb\s+\(client.refunds\)})

      expect(valid_ruby?(File.read(path(class_file)))).to be(true)
      expect(valid_ruby?(File.read(path(spec_file)))).to be(true)
      client = File.read(path("lib/paystack_sdk/client.rb"))
      expect(valid_ruby?(client)).to be(true)
      expect(client).to include('require_relative "resources/refunds"')
      expect(client).to include("def refunds\n      @refunds ||= Resources::Refunds.new(@connection)\n    end")
    end

    it "with --dry-run says what it would do and writes nothing" do
      before = File.read(path("lib/paystack_sdk/client.rb"))
      stdout, _, status = in_root("Refund", "--dry-run")

      expect(status).to be_success
      expect(stdout).to match(%r{create\s+#{class_file}})
      expect(stdout).to match(%r{insert\s+lib/paystack_sdk/client.rb})
      expect(stdout).to include("Dry run: nothing was written.")
      expect(File.exist?(path(class_file))).to be(false)
      expect(File.exist?(path(spec_file))).to be(false)
      expect(File.read(path("lib/paystack_sdk/client.rb"))).to eq(before)
    end

    it "is safe to run twice: everything is reported identical and nothing changes" do
      in_root("Refund")
      written = [class_file, spec_file, "lib/paystack_sdk/client.rb"].to_h { |file| [file, File.read(path(file))] }

      stdout, = in_root("Refund")

      expect(stdout).to match(%r{identical\s+#{class_file}})
      expect(stdout).to match(%r{identical\s+#{spec_file}})
      expect(stdout).not_to match(/\binsert\b/)
      written.each { |file, content| expect(File.read(path(file))).to eq(content) }
    end

    it "does not overwrite a file that differs, unless --force" do
      in_root("Refund")
      File.write(path(class_file), "# my own edits\n")

      stdout, = in_root("Refund")
      expect(stdout).to match(%r{conflict\s+#{class_file}.*--force})
      expect(File.read(path(class_file))).to eq("# my own edits\n")

      stdout, = in_root("Refund", "--force")
      expect(stdout).to match(%r{force\s+#{class_file}})
      expect(File.read(path(class_file))).to include("class Refunds")
    end

    it "leaves Client alone when a file conflicts" do
      File.write(path(class_file).tap { |file| FileUtils.mkdir_p(File.dirname(file)) }, "# mine\n")
      before = File.read(path("lib/paystack_sdk/client.rb"))

      stdout, = in_root("Refund")

      expect(stdout).to include("Client was not touched")
      expect(File.read(path("lib/paystack_sdk/client.rb"))).to eq(before)
    end

    it "with --skip-spec leaves the specs out" do
      stdout, = in_root("Refund", "--skip-spec")

      expect(stdout).not_to include(spec_file)
      expect(stdout).to include("2. bundle exec standardrb")
      expect(File.exist?(path(spec_file))).to be(false)
      expect(File.exist?(path(class_file))).to be(true)
    end

    it "names multi-word tags the way the existing resources are named" do
      in_root("Transfer Recipient", "--dry-run").first.then do |stdout|
        expect(stdout).to match(%r{create\s+lib/paystack_sdk/resources/transfer_recipients.rb})
      end
    end

    it "does not add what Client already has" do
      stdout, = in_root("Transfer", "--dry-run")

      expect(stdout).to match(%r{identical\s+lib/paystack_sdk/client.rb\s+\(require resources/transfers\)})
      expect(stdout).to match(%r{identical\s+lib/paystack_sdk/client.rb\s+\(client.transfers\)})
    end

    it "refuses an unknown tag" do
      _, stderr, status = in_root("Nonsense")

      expect(status).not_to be_success
      expect(stderr).to include("No operations tagged")
    end
  end

  describe "--destroy" do
    let(:class_file) { "lib/paystack_sdk/resources/refunds.rb" }
    let(:spec_file) { "spec/resources/refunds_spec.rb" }
    let(:client_file) { "lib/paystack_sdk/client.rb" }

    it "undoes a scaffold exactly, down to the Client file" do
      original = File.read(path(client_file))
      in_root("Refund")

      stdout, _, status = in_root("Refund", "--destroy")

      expect(status).to be_success
      expect(stdout).to match(%r{remove\s+#{class_file}})
      expect(stdout).to match(%r{remove\s+#{spec_file}})
      expect(stdout).to match(%r{remove\s+#{client_file}\s+\(require resources/refunds\)})
      expect(stdout).to match(%r{remove\s+#{client_file}\s+\(client.refunds\)})
      expect(File.exist?(path(class_file))).to be(false)
      expect(File.exist?(path(spec_file))).to be(false)
      expect(File.read(path(client_file))).to eq(original)
    end

    it "with --dry-run says what it would remove and removes nothing" do
      in_root("Refund")
      scaffolded = File.read(path(client_file))

      stdout, = in_root("Refund", "--destroy", "--dry-run")

      expect(stdout).to match(%r{remove\s+#{class_file}})
      expect(stdout).to include("Dry run: nothing was removed.")
      expect(File.exist?(path(class_file))).to be(true)
      expect(File.exist?(path(spec_file))).to be(true)
      expect(File.read(path(client_file))).to eq(scaffolded)
    end

    it "refuses a file you have edited, and leaves Client alone, unless --force" do
      in_root("Refund")
      File.write(path(class_file), "# my own edits\n")
      scaffolded_client = File.read(path(client_file))

      stdout, = in_root("Refund", "--destroy")

      expect(stdout).to match(%r{conflict\s+#{class_file}.*--force})
      expect(stdout).to include("Client was not touched")
      expect(File.read(path(class_file))).to eq("# my own edits\n")
      expect(File.read(path(client_file))).to eq(scaffolded_client)

      stdout, = in_root("Refund", "--destroy", "--force")

      expect(stdout).to match(%r{force\s+#{class_file}})
      expect(File.exist?(path(class_file))).to be(false)
    end

    it "says skip for what is already gone, so it is safe to repeat" do
      in_root("Refund")
      in_root("Refund", "--destroy")

      stdout, _, status = in_root("Refund", "--destroy")

      expect(status).to be_success
      expect(stdout).to match(%r{skip\s+#{class_file}\s+\(not found\)})
      expect(stdout).to match(/skip\s+#{client_file}\s+\(no client.refunds\)/)
    end

    it "never removes a hand-written accessor, or the require it depends on" do
      client = File.read(path(client_file))

      stdout, = in_root("Transfer", "--destroy")

      expect(stdout).to match(%r{conflict\s+#{client_file}\s+\(client.transfers is not the generated one})
      expect(File.read(path(client_file))).to eq(client)
    end
  end

  describe "protecting your work" do
    let(:class_file) { "lib/paystack_sdk/resources/refunds.rb" }
    let(:spec_file) { "spec/resources/refunds_spec.rb" }
    let(:client_file) { "lib/paystack_sdk/client.rb" }

    def git(*args)
      system("git", "-C", root, "-c", "user.name=spec", "-c", "user.email=spec@example.com", *args, out: File::NULL, err: File::NULL)
    end

    def commit_everything
      git("add", "-A")
      git("commit", "-q", "-m", "snapshot")
    end

    def backups
      Dir.glob(path("tmp/scaffold-backups/*/**/*")).select { |file| File.file?(file) }
    end

    before { git("init", "-q") }

    it "never overwrites a tracked file it did not write, even with --force" do
      FileUtils.mkdir_p(File.dirname(path(class_file)))
      File.write(path(class_file), "# hand-written, committed\n")
      commit_everything
      before_client = File.read(path(client_file))

      stdout, = in_root("Refund", "--force")

      expect(stdout).to match(%r{protected\s+#{class_file}.*tracked by git})
      expect(File.read(path(class_file))).to eq("# hand-written, committed\n")
      expect(File.read(path(client_file))).to eq(before_client)
      expect(stdout).to include("Client was not touched")
      expect(backups).to be_empty
    end

    it "never removes a tracked file it did not write, even with --force" do
      FileUtils.mkdir_p(File.dirname(path(class_file)))
      File.write(path(class_file), "# hand-written, committed\n")
      commit_everything

      stdout, = in_root("Refund", "--destroy", "--force")

      expect(stdout).to match(%r{protected\s+#{class_file}.*tracked by git})
      expect(stdout).to match(/git rm/)
      expect(File.read(path(class_file))).to eq("# hand-written, committed\n")
    end

    it "protects a tracked file even when it has uncommitted edits on top of the commit" do
      in_root("Refund")
      commit_everything
      File.write(path(class_file), "# edited after the commit\n")

      stdout, = in_root("Refund", "--destroy", "--force")

      expect(stdout).to match(%r{protected\s+#{class_file}})
      expect(File.read(path(class_file))).to eq("# edited after the commit\n")
    end

    it "still removes a committed file that is exactly what the scaffold wrote, without --force" do
      in_root("Refund")
      commit_everything

      stdout, = in_root("Refund", "--destroy")

      expect(stdout).to match(%r{remove\s+#{class_file}})
      expect(File.exist?(path(class_file))).to be(false)
    end

    it "backs up an untracked file you edited before --force replaces it, and says how much" do
      in_root("Refund")
      File.write(path(class_file), "# my edits\n# line two\n")

      stdout, = in_root("Refund", "--force")

      expect(stdout).to match(%r{force\s+#{class_file}\s+\(2 lines replaced; backup tmp/scaffold-backups/})
      expect(File.read(path(class_file))).to include("class Refunds")
      expect(backups.map { |file| File.read(file) }).to include("# my edits\n# line two\n")
    end

    it "backs up an untracked file you edited before --destroy --force removes it" do
      in_root("Refund")
      File.write(path(class_file), "# my edits\n")

      stdout, = in_root("Refund", "--destroy", "--force")

      expect(stdout).to match(%r{force\s+#{class_file}\s+\(1 lines removed; backup tmp/scaffold-backups/})
      expect(File.exist?(path(class_file))).to be(false)
      expect(backups.map { |file| File.read(file) }).to include("# my edits\n")
    end

    it "with --dry-run says it would back up, and changes and backs up nothing" do
      in_root("Refund")
      File.write(path(class_file), "# my edits\n")

      stdout, = in_root("Refund", "--destroy", "--force", "--dry-run")

      expect(stdout).to match(%r{force\s+#{class_file}\s+\(1 lines removed; would back up to tmp/scaffold-backups/})
      expect(File.read(path(class_file))).to eq("# my edits\n")
      expect(backups).to be_empty
    end
  end

  describe "stable names" do
    it "keeps the names the SDK already uses where Paystack's operation name differs" do
      transactions = scaffold("Transaction", "--print").first
      transfers = scaffold("Transfer", "--print").first

      expect(transactions).to include("def initiate(")
      expect(transactions).to include("def totals")
      expect(transactions).to include("def timeline(")
      expect(transactions).not_to include("def initialize")
      expect(transfers).to include("def create(")
      expect(transfers).to include("def initiate_bulk(")
    end

    it "refuses a method name that would shadow Ruby's own, and says where to rename it" do
      empty = File.join(root, "names.yml")
      File.write(empty, "{}\n")

      stdout, stderr, status = scaffold("Transaction", "--print", "--names", empty)

      expect(status).not_to be_success
      expect(stdout).to be_empty
      expect(stderr).to include("initialize")
      expect(stderr).to include("scaffold_names.yml")
    end

    it "does not mistake the scaffold's own helper names for Ruby's (Dispute's `resolve`)" do
      stdout, stderr, status = scaffold("Dispute", "--print")

      expect(status).to be_success, stderr
      expect(stdout).to include("def resolve(")
    end

    it "generates every tag with the shipped names file, none refused" do
      scaffold("--tags").first.lines.map { |line| line.sub(/\s+\d+ operations\s*\z/, "").strip }.each do |tag|
        _, stderr, status = scaffold(tag, "--print")
        expect(status).to be_success, "#{tag}: #{stderr}"
      end
    end

    it "uses a names file you point it at" do
      names = File.join(root, "names.yml")
      File.write(names, %("GET /refund": all_refunds\n))

      expect(scaffold("Refund", "--print", "--names", names).first).to include("def all_refunds(")
    end
  end

  describe "checks the SDK has always made" do
    let(:transaction) { scaffold("Transaction", "--print").first }

    it "checks the shape of an email, the size of an amount and the characters of a reference" do
      expect(transaction).to include('validate_email!(email: email, name: "email")')
      expect(transaction).to include('validate_positive_integer!(value: amount, name: "amount")')
      expect(transaction).to include('validate_reference_format!(reference: reference, name: "reference") unless reference.nil?')
    end

    it "checks page and per_page" do
      expect(transaction).to include('validate_positive_integer!(value: per_page, name: "perPage")')
      expect(transaction).to include('validate_positive_integer!(value: page, name: "page")')
    end

    it "does not hold a path value to the reference format, which is only about references you send" do
      verify = transaction[/def verify\(.*?\n      end/m]

      expect(verify).not_to include("validate_reference_format!")
    end
  end

  describe "extension modules" do
    it "includes a hand-written extension for the resource when one exists" do
      FileUtils.mkdir_p(path("lib/paystack_sdk/resources/extensions"))
      File.write(path("lib/paystack_sdk/resources/extensions/refunds.rb"), "module PaystackSdk\n  module Resources\n    module Extensions\n      module Refunds; end\n    end\n  end\nend\n")

      in_root("Refund")

      generated = File.read(path("lib/paystack_sdk/resources/refunds.rb"))
      expect(generated).to include('require_relative "extensions/refunds"')
      expect(generated).to include("include Extensions::Refunds")
    end

    it "leaves both lines out when there is none" do
      in_root("Refund")

      generated = File.read(path("lib/paystack_sdk/resources/refunds.rb"))
      expect(generated).not_to include("Extensions")
    end
  end

  describe "regenerating its own output" do
    let(:class_file) { "lib/paystack_sdk/resources/refunds.rb" }
    let(:names) { File.join(root, "names.yml") }

    before do
      git("init", "-q")
      File.write(names, %("GET /refund": all_refunds\n))
    end

    def git(*args)
      system("git", "-C", root, "-c", "user.name=spec", "-c", "user.email=spec@example.com", *args, out: File::NULL, err: File::NULL)
    end

    def commit_everything
      git("add", "-A")
      git("commit", "-q", "-m", "snapshot")
    end

    it "marks what it writes as generated, with a digest of its contents" do
      in_root("Refund")

      generated = File.read(path(class_file))
      expect(generated).to include("# Generated by bin/paystack-scaffold")
      expect(generated).to match(/^# scaffold-digest: [0-9a-f]{64}$/)
    end

    it "updates a committed file it wrote and nobody has edited, without --force" do
      in_root("Refund")
      commit_everything

      stdout, _, status = in_root("Refund", "--names", names)

      expect(status).to be_success
      expect(stdout).to match(%r{update\s+#{class_file}})
      expect(File.read(path(class_file))).to include("def all_refunds(")
    end

    it "protects a committed file once someone has edited it, even a single line" do
      in_root("Refund")
      edited = File.read(path(class_file)).sub("def list", "def list # tweaked\n      ")
      File.write(path(class_file), edited)
      commit_everything

      stdout, = in_root("Refund", "--names", names, "--force")

      expect(stdout).to match(%r{protected\s+#{class_file}})
      expect(File.read(path(class_file))).to eq(edited)
    end

    it "removes an unedited generated file on --destroy even though the spec has moved on since" do
      in_root("Refund", "--names", names)
      commit_everything

      stdout, = in_root("Refund", "--destroy")

      expect(stdout).to match(%r{remove\s+#{class_file}})
      expect(File.exist?(path(class_file))).to be(false)
    end
  end
end
