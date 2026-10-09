# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "version"

module PaystackSdk
  # The AI skills the gem ships (Claude Code `SKILL.md` folders under `lib/paystack_sdk/skills`) and the
  # installer that copies them into a project's `.claude/skills/`.
  #
  # Installing is safe to repeat and safe next to skills of your own:
  #
  # * Every folder it writes carries a `.paystack_sdk.json` marker. Only marked folders are ever updated or
  #   removed, so a gem upgrade changes the skills it installed and nothing else.
  # * A folder with the same name that it did not install is never overwritten (it is reported as a
  #   `conflict`) unless you pass `force: true`.
  # * Each installed `SKILL.md` is stamped with the gem version it was installed from.
  module Skills
    # Where the skills live inside the gem.
    SOURCE_DIR = File.expand_path("skills", __dir__)

    # Marker file written into every folder this gem installs.
    MARKER = ".paystack_sdk.json"

    # A skill shipped in the gem.
    Skill = Struct.new(:name, :description, :path, keyword_init: true)

    # What installing did to one folder: status is one of create, update, identical, remove, conflict, force.
    Result = Struct.new(:status, :name, :note, keyword_init: true)

    class << self
      # @return [Array<Skill>] the skills shipped in the gem, sorted by name
      def all
        Dir.children(SOURCE_DIR).sort.filter_map do |name|
          path = File.join(SOURCE_DIR, name)
          file = File.join(path, "SKILL.md")
          next unless File.directory?(path) && File.file?(file)

          Skill.new(name: name, description: frontmatter(File.read(file))["description"].to_s, path: path)
        end
      end

      # Copies the skills into +dir+ (a `.claude/skills` directory).
      #
      # @param dir [String] the directory to install into; created if missing
      # @param dry_run [Boolean] report what would happen and write nothing
      # @param force [Boolean] replace a same-named folder that this gem did not install
      # @return [Array<Result>]
      def install(dir, dry_run: false, force: false)
        skills = all
        results = skills.map { |skill| install_skill(skill, dir, dry_run: dry_run, force: force) }
        results + remove_stale(dir, skills.map(&:name), dry_run: dry_run)
      end

      # Removes every folder this gem installed into +dir+, and nothing else.
      #
      # @return [Array<Result>]
      def uninstall(dir, dry_run: false)
        owned_dirs(dir).map do |name|
          FileUtils.rm_rf(File.join(dir, name)) unless dry_run
          Result.new(status: "remove", name: name)
        end
      end

      # The files a skill folder holds once installed: relative path => content. `SKILL.md` gets the gem
      # version stamped into its frontmatter.
      #
      # @param skill [Skill]
      # @return [Hash{String => String}]
      def files_for(skill)
        files = Dir.glob("**/*", base: skill.path).select { |f| File.file?(File.join(skill.path, f)) }.sort
        content = files.to_h { |f| [f, File.read(File.join(skill.path, f))] }
        content["SKILL.md"] = stamp(content.fetch("SKILL.md"))
        content[MARKER] = marker_json
        content
      end

      # Parses the `key: value` lines of a SKILL.md's frontmatter (single-level; quotes are stripped).
      #
      # @param text [String]
      # @return [Hash{String => String}]
      def frontmatter(text)
        block = text[/\A---\n(.*?)\n---\n/m, 1] or return {}
        block.lines.each_with_object({}) do |line, found|
          key, value = line.chomp.match(/\A([A-Za-z_][\w-]*):\s*(.*)\z/)&.captures
          next unless key

          value = value.strip
          value = value[1..-2].gsub("''", "'") if value.match?(/\A'.*'\z/m)
          value = value[1..-2] if value.match?(/\A".*"\z/m)
          found[key] = value
        end
      end

      private

      def install_skill(skill, dir, dry_run:, force:)
        dest = File.join(dir, skill.name)
        wanted = files_for(skill)

        if !File.exist?(dest)
          write(dest, wanted) unless dry_run
          Result.new(status: "create", name: skill.name)
        elsif owned?(dest)
          return Result.new(status: "identical", name: skill.name) if current_files(dest) == wanted

          write(dest, wanted) unless dry_run
          Result.new(status: "update", name: skill.name)
        elsif force
          write(dest, wanted) unless dry_run
          Result.new(status: "force", name: skill.name, note: "replaced a folder paystack_sdk did not install")
        else
          Result.new(status: "conflict", name: skill.name,
            note: "a folder with this name exists that paystack_sdk did not install; left alone (use --force to replace it)")
        end
      end

      def remove_stale(dir, current, dry_run:)
        (owned_dirs(dir) - current).map do |name|
          FileUtils.rm_rf(File.join(dir, name)) unless dry_run
          Result.new(status: "remove", name: name, note: "no longer shipped with this version")
        end
      end

      def owned_dirs(dir)
        return [] unless File.directory?(dir)

        Dir.children(dir).sort.select { |name| owned?(File.join(dir, name)) }
      end

      def owned?(path)
        file = File.join(path, MARKER)
        File.directory?(path) && File.file?(file) && JSON.parse(File.read(file))["gem"] == "paystack_sdk"
      rescue JSON::ParserError
        false
      end

      def current_files(dest)
        Dir.glob("**/*", File::FNM_DOTMATCH, base: dest).select { |f| File.file?(File.join(dest, f)) }.sort
          .to_h { |f| [f, File.read(File.join(dest, f))] }
      end

      def write(dest, files)
        FileUtils.rm_rf(dest)
        files.each do |relative, content|
          path = File.join(dest, relative)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
        end
      end

      def marker_json
        "#{JSON.pretty_generate("gem" => "paystack_sdk", "version" => VERSION)}\n"
      end

      # Adds `metadata: gem / gem_version` to the frontmatter so an agent (and a person) can see which gem
      # version the skill describes.
      def stamp(text)
        text.sub(/\A---\n(.*?)\n---\n/m) do
          "---\n#{$1}\nmetadata:\n  gem: paystack_sdk\n  gem_version: \"#{VERSION}\"\n---\n"
        end
      end
    end
  end
end
