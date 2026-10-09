# frozen_string_literal: true

require "rails/generators"
require "paystack_sdk/skills"

module PaystackSdk
  module Generators
    # `rails generate paystack_sdk:skills`: installs the gem's AI skills into the app's `.claude/skills/`.
    # It never overwrites a skill folder it did not install, and after a gem upgrade it updates only its
    # own folders. `--pretend` shows what would happen.
    class SkillsGenerator < Rails::Generators::Base
      desc "Install the paystack_sdk AI skills into .claude/skills/ (Claude Code)"

      class_option :force, type: :boolean, default: false, desc: "Replace a same-named folder paystack_sdk did not install"

      COLORS = {"create" => :green, "update" => :yellow, "force" => :yellow, "remove" => :red, "conflict" => :red}.freeze

      def install_skills
        dir = File.join(destination_root, ".claude", "skills")
        results = PaystackSdk::Skills.install(dir, dry_run: options[:pretend], force: options[:force])

        results.each { |r| say_status(r.status, [r.name, r.note].compact.join(": "), COLORS.fetch(r.status, :blue)) }
        say_status("note", "Some skill folders were left alone; run with --force to replace them.", :red) if results.any? { |r| r.status == "conflict" }
      end
    end
  end
end
