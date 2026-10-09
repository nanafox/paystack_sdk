# frozen_string_literal: true

require "optparse"
require_relative "skills"
require_relative "version"

module PaystackSdk
  # The `paystack_sdk` command. It only handles the AI skills; it does not load Faraday or call Paystack.
  #
  #   paystack_sdk skills install [--dir DIR | --global] [--dry-run] [--force]
  #   paystack_sdk skills list
  #   paystack_sdk skills path
  #   paystack_sdk skills uninstall [--dir DIR | --global] [--dry-run]
  #   paystack_sdk version
  class CLI
    USAGE = <<~TEXT
      Usage:
        paystack_sdk skills install [--dir DIR | --global] [--dry-run] [--force]
        paystack_sdk skills uninstall [--dir DIR | --global] [--dry-run]
        paystack_sdk skills list
        paystack_sdk skills path
        paystack_sdk version

      `skills install` copies the AI skills that ship with this gem into .claude/skills/ (Claude Code),
      ready for an agent to load. It is safe to repeat, never overwrites a skill folder it did not
      install, and after a gem upgrade updates only its own folders.

      Options:
        --dir DIR    install into DIR instead of ./.claude/skills
        --global     install into ~/.claude/skills
        --dry-run    say what would happen and change nothing
        --force      replace a same-named folder that paystack_sdk did not install
    TEXT

    # Runs the command.
    #
    # @param argv [Array<String>]
    # @param out [IO]
    # @param err [IO]
    # @return [Integer] the exit status
    def self.run(argv, out: $stdout, err: $stderr)
      new(out: out, err: err).run(argv.dup)
    end

    def initialize(out:, err:)
      @out = out
      @err = err
    end

    def run(argv)
      command = argv.shift
      case command
      when "skills" then skills(argv)
      when "version", "--version", "-v" then @out.puts("paystack_sdk #{VERSION}").then { 0 }
      when nil, "help", "--help", "-h" then @out.puts(USAGE).then { 0 }
      else fail_with("unknown command #{command.inspect}")
      end
    rescue OptionParser::ParseError => e
      fail_with(e.message)
    end

    private

    def skills(argv)
      sub = argv.shift
      case sub
      when "install" then install(argv)
      when "uninstall" then uninstall(argv)
      when "list" then list
      when "path" then @out.puts(Skills::SOURCE_DIR).then { 0 }
      else fail_with("unknown skills command #{sub.inspect}")
      end
    end

    def install(argv)
      options = parse(argv, force: true)
      dir = target(options)
      results = Skills.install(dir, dry_run: options[:dry_run], force: options[:force])
      report(results, dir, options)
      (results.any? { |r| r.status == "conflict" }) ? 1 : 0
    end

    def uninstall(argv)
      options = parse(argv, force: false)
      dir = target(options)
      results = Skills.uninstall(dir, dry_run: options[:dry_run])
      report(results, dir, options)
      0
    end

    def list
      Skills.all.each { |skill| @out.puts("#{skill.name}\n    #{skill.description}") }
      0
    end

    def parse(argv, force:)
      options = {}
      OptionParser.new do |o|
        o.on("--dir DIR") { |v| options[:dir] = v }
        o.on("--global") { options[:global] = true }
        o.on("--dry-run") { options[:dry_run] = true }
        o.on("--force") { options[:force] = true } if force
      end.parse!(argv)
      raise OptionParser::InvalidOption, argv.first unless argv.empty?
      raise OptionParser::InvalidOption, "--dir and --global together" if options[:dir] && options[:global]

      options
    end

    def target(options)
      return File.expand_path(options[:dir]) if options[:dir]
      return File.join(Dir.home, ".claude", "skills") if options[:global]

      File.join(Dir.pwd, ".claude", "skills")
    end

    def report(results, dir, options)
      @out.puts("#{"Dry run: " if options[:dry_run]}#{dir}")
      results.each do |r|
        @out.puts("#{r.status.rjust(12)}  #{r.name}#{"  (#{r.note})" if r.note}")
      end
      @out.puts("\nDry run: nothing was written.") if options[:dry_run]
      @out.puts("\nSome folders were left alone. Re-run with --force to replace them.") if results.any? { |r| r.status == "conflict" }
    end

    def fail_with(message)
      @err.puts("paystack_sdk: #{message}\n\n#{USAGE}")
      1
    end
  end
end
