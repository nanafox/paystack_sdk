#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates the content of the docs site from a checkout of the gem: the guide pages (split from README.md),
# the API reference (from the YARD comments), the AI skills, the changelog, llms.txt / llms-full.txt and a raw
# markdown copy of every page. VitePress then renders docs/content.
#
#   ruby docs/scripts/build-content.rb --version 0.5.0 --base /paystack_sdk/latest/ [--src .] [--out docs/content]
#
# Run it from a checkout of the version you are documenting; `--src` can point at another one.

require "fileutils"
require "json"
require "optparse"
require_relative "lib/readme_splitter"
require_relative "lib/reference_builder"
require_relative "lib/skills_builder"
require_relative "lib/llms_builder"

module PaystackDocs
  class ContentBuild
    SITE = "https://nanafox.github.io"

    def initialize(src:, out:, version:, base:)
      @src = File.expand_path(src)
      @out = File.expand_path(out)
      @public = "#{@out}-public"
      @version = version
      @base = base.end_with?("/") ? base : "#{base}/"
    end

    def run
      FileUtils.rm_rf([@out, @public])
      write_pages
      write_public
      write_static
      write_site
      puts "#{pages.size} pages, #{llms.files.size} raw files -> #{@out}"
    end

    def readme = @readme ||= ReadmeSplitter.new(File.read(File.join(@src, "README.md")))

    def skills = @skills ||= SkillsBuilder.new(@src)

    def pages
      @pages ||= readme.pages + concept_pages + ReferenceBuilder.new(@src).pages + skills.pages + [changelog_page].compact
    end

    def llms
      @llms ||= LlmsBuilder.new(pages: pages, skills: skills, site_url: "#{SITE}#{@base}", version: @version)
    end

    private

    # Hand-written pages under docs/concepts/: the ideas the generated pages assume.
    def concept_pages
      Dir[File.join(__dir__, "..", "concepts", "*.md")].sort.map do |file|
        text = File.read(file)
        title = text[/^# (.+)$/, 1]
        slug = File.basename(file, ".md").sub(/\A\d+-/, "")
        # A line that is only a component (`<PaymentFlow />`) is meant for Vue: leave it alone.
        body = Markdown.map_prose(text) { |line| line.match?(/\A<[A-Z]\w* \/>\s*\z/) ? line : Markdown.escape_for_vue(line) }
        ReadmeSplitter::Page.new(path: "concepts/#{slug}", title: title, group: "Concepts", body: body)
      end
    end

    def changelog_page
      file = File.join(@src, "CHANGELOG.md")
      return unless File.exist?(file)

      body = Markdown.shift_headings(File.read(file), 0)
      body = Markdown.map_prose(body) { |line| Markdown.escape_for_vue(line) }
      ReadmeSplitter::Page.new(path: "changelog", title: "Changelog", group: "Changelog", body: body)
    end

    def write_pages
      pages.each do |page|
        path = File.join(@out, "#{page.path}.md")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, frontmatter(page) + page.body)
      end
      home = File.join(__dir__, "..", "home.md")
      File.write(File.join(@out, "index.md"), File.read(home).gsub("{{VERSION}}", @version))
    end

    def frontmatter(page)
      desc = page.description.to_s.empty? ? nil : "description: #{page.description.inspect}\n"
      "---\ntitle: #{page.title.inspect}\n#{desc}---\n\n"
    end

    def write_public
      llms.files.each do |rel, text|
        path = File.join(@public, rel)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, text)
      end
    end

    # One sidebar per section, so a reference page does not list forty guides.
    SECTIONS = {
      "/guide/" => ["Getting started", "Guides", "Advanced", "AI skills", "Project"],
      "/concepts/" => %w[Concepts],
      "/reference/" => %w[Core Resources],
      "/skills/" => %w[Skills]
    }.freeze

    # Static assets (the logo) go beside the pages for `vitepress dev`, and into the post-build copy.
    def write_static
      Dir[File.join(__dir__, "..", "static", "*")].each do |file|
        [File.join(@out, "public"), @public].each do |dir|
          FileUtils.mkdir_p(dir)
          FileUtils.cp(file, dir)
        end
      end
    end

    def write_site
      sidebar = SECTIONS.transform_values do |groups|
        groups.filter_map do |group|
          items = pages.select { |p| p.group == group }
          next if items.empty?

          {text: group, collapsed: false, items: items.map { |p| {text: p.title, link: "/#{p.path}"} }}
        end
      end
      File.write(File.join(@out, "site.json"), JSON.pretty_generate(version: @version, base: @base, sidebar: sidebar))
    end
  end
end

if $PROGRAM_NAME == __FILE__
  opts = {src: File.expand_path("../..", __dir__), out: File.expand_path("../content", __dir__), version: nil, base: "/paystack_sdk/next/"}
  OptionParser.new do |o|
    o.on("--src DIR") { |v| opts[:src] = v }
    o.on("--out DIR") { |v| opts[:out] = v }
    o.on("--version V") { |v| opts[:version] = v }
    o.on("--base PATH") { |v| opts[:base] = v }
  end.parse!
  opts[:version] ||= File.read(File.join(opts[:src], "lib/paystack_sdk/version.rb"))[/VERSION = "([^"]+)"/, 1]
  PaystackDocs::ContentBuild.new(**opts).run
end
