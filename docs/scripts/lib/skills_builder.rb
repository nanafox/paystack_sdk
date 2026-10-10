# frozen_string_literal: true

require_relative "markdown"
require_relative "readme_splitter"

module PaystackDocs
  # The AI skills the gem ships (lib/paystack_sdk/skills/*/SKILL.md), as rendered pages and as raw markdown.
  # The raw files are what an agent without the gem can fetch; they keep their frontmatter and link to each
  # other with relative links.
  class SkillsBuilder
    Page = ReadmeSplitter::Page
    Skill = Struct.new(:name, :description, :text, :body, keyword_init: true)

    def initialize(src)
      @dir = File.join(src, "lib", "paystack_sdk", "skills")
    end

    # @return [Array<Skill>] sorted by name, the overview first
    def skills
      @skills ||= begin
        found = Dir[File.join(@dir, "*", "SKILL.md")].map do |file|
          text = File.read(file)
          front = text[/\A---\n(.*?)\n---\n/m, 1].to_s
          body = text.sub(/\A---\n.*?\n---\n/m, "").strip
          Skill.new(name: File.basename(File.dirname(file)), description: description_of(front), text: text, body: body)
        end
        found.sort_by { |s| [(s.name == "paystack-sdk-overview") ? 0 : 1, s.name] }
      end
    end

    # @return [Array<Page>] an index page and one page per skill
    def pages
      return [] if skills.empty?

      [index_page] + skills.map { |skill| skill_page(skill) }
    end

    # @return [Hash{String => String}] name => raw markdown (frontmatter kept, [[links]] made relative)
    def raw_files
      skills.to_h { |skill| [skill.name, skill.text.gsub(/\[\[([\w-]+)\]\]/) { "[#{$1}](#{$1}.md)" }] }
    end

    private

    # Frontmatter values are single-quoted YAML scalars (they contain ": ").
    def description_of(front)
      raw = front[/^description:\s*(.+)$/, 1].to_s
      (raw =~ /\A'(.*)'\z/m) ? $1.gsub("''", "'") : raw
    end

    def link_skills(text) = text.gsub(/\[\[([\w-]+)\]\]/) { "[#{$1}](/skills/#{$1})" }

    def skill_page(skill)
      intro = <<~MD
        ::: tip For AI agents
        This is one of the skills `paystack_sdk` installs for Claude Code (`paystack_sdk skills install`). The raw file, with its frontmatter, is served at `/skills/#{skill.name}.md` on this site.
        :::

      MD
      Page.new(path: "skills/#{skill.name}", title: skill.name, group: "Skills", description: skill.description,
        body: intro + Markdown.map_prose(link_skills(skill.body)) { |l| Markdown.escape_for_vue(l) } + "\n")
    end

    def index_page
      rows = skills.map { |s| "| [`#{s.name}`](/skills/#{s.name}) | #{s.description.gsub("|", "\\|")} |" }
      body = <<~MD
        # AI skills

        `paystack_sdk` ships skills for AI coding agents (Claude Code `SKILL.md` folders) that teach an agent how to use the gem correctly: the conventions, what raises and what returns, and the checks that keep money safe. They are installed from the gem you have, so they match its version.

        ```sh
        bundle exec paystack_sdk skills install      # any Ruby project: into ./.claude/skills
        bin/rails generate paystack_sdk:skills       # a Rails app
        ```

        Installing is safe to repeat. It only touches folders it installed (each carries a `.paystack_sdk.json` marker), never overwrites a skill of yours, and stamps each `SKILL.md` with the gem version. Run it again after upgrading the gem.

        ## The skills

        An agent picks a skill from its description, so each one starts with *Use when...*.

        | Skill | Load it when |
        |---|---|
        #{rows.join("\n")}

        ## For agents that cannot install a gem

        Every skill is also published as raw markdown at `/skills/<name>.md`, with an index at `/skills/index.md`, and the whole site is summarised in [`/llms.txt`](/llms.txt). Fetch the one that matches the task.
      MD
      Page.new(path: "skills/index", title: "AI skills", group: "Skills", body: body)
    end
  end
end
