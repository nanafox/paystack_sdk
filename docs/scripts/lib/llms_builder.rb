# frozen_string_literal: true

require_relative "markdown"

module PaystackDocs
  # llms.txt, llms-full.txt and the raw-markdown copies of every page, for agents that read a site as text.
  class LlmsBuilder
    # @param pages [Array<ReadmeSplitter::Page>] every page of the site
    # @param skills [SkillsBuilder] the skills (their raw files are published under /skills/)
    # @param site_url [String] where this version of the site is served, ending in a slash
    # @param version [String]
    def initialize(pages:, skills:, site_url:, version:)
      @pages = pages
      @skills = skills
      @site_url = site_url.end_with?("/") ? site_url : "#{site_url}/"
      @version = version
    end

    # The raw markdown URL of a site path such as /guide/transactions or /skills/paystack-sdk-payments.
    def raw_url(path)
      clean = path.sub(%r{\A/}, "")
      clean.start_with?("skills/") ? "#{@site_url}#{clean}.md" : "#{@site_url}md/#{clean}.md"
    end

    # Internal links (`](/guide/x#a)`) become absolute links to the raw markdown of the target.
    def absolutize(body)
      Markdown.map_prose(body) do |line|
        line.gsub(%r{\]\((/[^)\s#]*)(#[^)\s]*)?\)}) { "](#{raw_url($1)}#{$2})" }
      end
    end

    # @return [Hash{String => String}] relative file path (under public/) => content
    def files
      out = {"llms.txt" => llms_txt, "llms-full.txt" => llms_full}
      @pages.reject { |p| p.path == "skills/index" || p.path.start_with?("skills/") }.each do |page|
        out["md/#{page.path}.md"] = absolutize(page.body)
      end
      @skills.raw_files.each { |name, text| out["skills/#{name}.md"] = text }
      out["skills/index.md"] = skills_index
      out
    end

    private

    def entries(group_names)
      @pages.select { |p| group_names.include?(p.group) }.map do |page|
        "- [#{page.title}](#{raw_url("/#{page.path}")})#{": #{first_sentence(page)}" if first_sentence(page)}"
      end
    end

    def first_sentence(page)
      return page.description if page.description && !page.description.empty?

      text = page.body.lines.drop_while { |l| l.start_with?("#") || l.strip.empty? || l.start_with?(":::", "```") }.first.to_s.strip
      text = text.gsub(/\[([^\]]+)\]\([^)]*\)/, '\1').delete("`")
      return nil if text.empty? || text.start_with?("|", "-", "*", "<")

      text[/\A.{1,200}?[.!?](?=\s|\z)/] || text[0, 160]
    end

    def llms_txt
      lines = ["# Paystack Ruby SDK (paystack_sdk #{@version})", ""]
      lines << "> A Ruby client for the Paystack API. It mirrors Paystack's endpoints, takes keyword arguments, validates input before sending, " \
        "and ships skills for AI coding agents. Amounts are integers in the currency's smallest unit; `success?` on a response means the call " \
        "was accepted, not that a charge succeeded. Fetch the skill that matches your task first."
      lines << ""
      lines << "## Skills (start here)" << ""
      lines << "- [Skills index](#{@site_url}skills/index.md): every skill, and when to load it"
      @skills.skills.each { |s| lines << "- [#{s.name}](#{@site_url}skills/#{s.name}.md): #{s.description}" }
      lines << "" << "## Guides" << ""
      lines.concat(entries(["Getting started", "Concepts", "Guides", "Advanced"]))
      lines << "" << "## API reference" << ""
      lines.concat(entries(%w[Core Resources]))
      lines << "" << "## Project" << ""
      lines.concat(entries(%w[Project Changelog]))
      lines << "" << "## Everything in one file" << ""
      lines << "- [llms-full.txt](#{@site_url}llms-full.txt): the skills, the guides and the API reference concatenated"
      lines.join("\n") + "\n"
    end

    def skills_index
      rows = @skills.skills.map { |s| "- [#{s.name}](#{s.name}.md): #{s.description}" }
      "# Paystack Ruby SDK skills\n\nTask-focused guides for AI agents using the paystack_sdk gem. Each file is self-contained markdown. " \
        "Start with `paystack-sdk-overview.md`; it routes to the others.\n\n" \
        "These are the same skills the gem installs with `paystack_sdk skills install`.\n\n#{rows.join("\n")}\n"
    end

    def llms_full
      parts = ["# Paystack Ruby SDK (paystack_sdk #{@version}): full documentation", ""]
      @skills.skills.each do |skill|
        parts << "\n---\n\n<!-- source: #{@site_url}skills/#{skill.name}.md -->\n\n# Skill: #{skill.name}\n\n#{skill.body.gsub(/\[\[([\w-]+)\]\]/, '`\1`')}"
      end
      @pages.reject { |p| p.path.start_with?("skills/") }.each do |page|
        parts << "\n---\n\n<!-- source: #{raw_url("/#{page.path}")} -->\n\n#{absolutize(page.body)}"
      end
      parts.join("\n") + "\n"
    end
  end
end
