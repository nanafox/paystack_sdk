# frozen_string_literal: true

require_relative "markdown"

module PaystackDocs
  # Turns README.md into the guide pages of the docs site, so the README stays the one place the guides are
  # written. `## Usage` and `## Advanced Usage` split into one page per `###` section; the other `##`
  # sections become a page each; the table of contents is dropped; in-page links (`](#slug)`) are pointed at
  # the page the target now lives on.
  class ReadmeSplitter
    # A page of the site.
    Page = Struct.new(:path, :title, :group, :body, :description, keyword_init: true) do
      # @return [String] where the page is served, without the base
      def url = "/#{path}"
    end

    # `##` sections whose `###` children become pages, and the group they go under.
    SPLIT_SECTIONS = {"Usage" => "Guides", "Advanced Usage" => "Advanced"}.freeze

    # `##` sections that are one page each, and the group they go under.
    WHOLE_SECTIONS = {
      "Installation" => "Getting started", "Quick Start" => "Getting started", "AI Skills" => "AI skills",
      "Development" => "Project"
    }.freeze

    # `##` sections folded into one closing page.
    CLOSING_SECTIONS = ["Contributing", "License", "Code of Conduct"].freeze

    DROPPED = ["Table of Contents"].freeze

    def initialize(text, group_dir: "guide")
      @text = text
      @group_dir = group_dir
    end

    # @return [Array<Page>] in README order, links already rewritten
    def pages
      @pages ||= rewrite_links(build_pages)
    end

    private

    Section = Struct.new(:level, :title, :lines)

    def sections
      @sections ||= begin
        found = []
        current = nil
        Markdown.each_line(@text) do |line, in_code|
          if !in_code && (m = line.match(/\A(\#{1,3}) (.+?)\s*\z/))
            current = Section.new(m[1].size, m[2], [])
            found << current
          elsif current
            current.lines << line
          end
        end
        found
      end
    end

    def preamble
      lines = []
      Markdown.each_line(@text) do |line, in_code|
        break if !in_code && line.start_with?("## ")

        lines << line unless !in_code && line.start_with?("# ")
      end
      lines.join
    end

    def build_pages
      pages = [introduction]
      children = nil
      closing = []
      sections.each do |section|
        next if section.level == 1

        if section.level == 2
          children = SPLIT_SECTIONS[section.title]
          next if DROPPED.include?(section.title) || children
          if WHOLE_SECTIONS.key?(section.title)
            pages << whole_page(section)
          elsif CLOSING_SECTIONS.include?(section.title)
            closing << section
          end
        elsif section.level == 3 && children
          pages << guide_page(section, children)
        end
      end
      pages << closing_page(closing) unless closing.empty?
      pages.compact
    end

    def introduction
      body = preamble.lines.reject { |l| l.start_with?("[![") }.join.strip
      Page.new(path: "#{@group_dir}/introduction", title: "Introduction", group: "Getting started", body: "# Introduction\n\n#{body}\n")
    end

    # A `##` section kept whole: its `###` headings become `##`.
    def whole_page(section)
      following = subsections_of(section)
      body = "# #{section.title}\n\n#{section.lines.join.strip}\n"
      body += "\n" + following.map { |s| "## #{s.title}\n\n#{s.lines.join.strip}\n" }.join("\n") unless following.empty?
      Page.new(path: "#{@group_dir}/#{Markdown.slugify(section.title)}", title: section.title,
        group: WHOLE_SECTIONS.fetch(section.title), body: Markdown.shift_headings(body, 0))
    end

    # A `###` section as a page of its own: its `####` headings become `##`.
    def guide_page(section, group)
      body = "# #{section.title}\n\n#{section.lines.join.strip}\n"
      Page.new(path: "#{@group_dir}/#{Markdown.slugify(section.title)}", title: section.title, group: group,
        body: Markdown.shift_headings(body, 0).then { |text| demote_deeper(text) })
    end

    def closing_page(parts)
      body = "# Contributing\n\n" + parts.map { |s| "## #{s.title}\n\n#{s.lines.join.strip}\n" }.join("\n")
      Page.new(path: "#{@group_dir}/contributing", title: "Contributing", group: "Project", body: body)
    end

    # `####` under a page's `#` title read as `##`.
    def demote_deeper(text)
      Markdown.map_prose(text) { |line| line.sub(/\A\#### /, "## ").sub(/\A\#\#\#\#\# /, "### ") }
    end

    # The `###` sections that follow a `##` section until the next `##` (for whole-page sections).
    def subsections_of(section)
      start = sections.index(section) + 1
      sections[start..].take_while { |s| s.level > 2 }
    end

    # --- links

    # Every heading of the README: its anchor and the page it ended up on.
    def anchor_targets(pages)
      targets = {}
      pages.each do |page|
        Markdown.each_line(page.body) do |line, in_code|
          next if in_code

          next unless (m = line.match(/\A\#{1,6} (.+?)\s*\z/))

          slug = Markdown.slugify(m[1])
          targets[slug] ||= [page, (line.start_with?("# ") ? nil : slug)]
        end
      end
      targets
    end

    def rewrite_links(pages)
      targets = anchor_targets(pages)
      # headings the README had but the pages dropped (the table of contents' own) are not linked
      pages.each do |page|
        page.body = Markdown.map_prose(page.body) do |line|
          line.gsub(/\]\(#([^)\s]+)\)/) do
            slug = $1
            (target, hash = targets[slug]) ? "](#{target.url}#{"##{hash}" if hash})" : "](#{page.url}##{slug})"
          end
        end
      end
      pages
    end
  end
end
