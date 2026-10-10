# frozen_string_literal: true

module PaystackDocs
  # Small helpers for working on Markdown text without breaking fenced code blocks.
  module Markdown
    FENCE = /\A\s*(```|~~~)/

    module_function

    # Yields each line with whether it is inside (or is the edge of) a fenced code block.
    def each_line(text)
      return enum_for(:each_line, text) unless block_given?

      fence = nil
      text.each_line do |line|
        if (marker = line[FENCE, 1])
          if fence.nil?
            fence = marker
            yield line, true
            next
          elsif marker == fence
            fence = nil
            yield line, true
            next
          end
        end
        yield line, !fence.nil?
      end
    end

    # GitHub-style heading anchor: lowercase, punctuation dropped, spaces to hyphens.
    def slugify(title)
      title.to_s.downcase.delete("`").gsub(/[^\p{Alnum}\s_-]/u, "").strip.gsub(/\s+/, "-")
    end

    # Changes the level of every heading outside code fences by +offset+ (never above 1 or below 6).
    def shift_headings(text, offset)
      each_line(text).map do |line, in_code|
        next line if in_code

        line.sub(/\A(\#{1,6})(?= )/) { "#" * ($1.size + offset).clamp(1, 6) }
      end.join
    end

    # Applies the block to every line outside code fences and returns the new text.
    def map_prose(text)
      each_line(text).map { |line, in_code| in_code ? line : yield(line) }.join
    end

    # Escapes what Vue would try to interpret in running text: `{{` and a `<` that starts a tag-like word.
    # Text inside backticks is left alone (VitePress renders inline code verbatim).
    def escape_for_vue(line)
      line.split(/(`+[^`]*`+)/).map do |part|
        part.start_with?("`") ? part : part.gsub("{{", "&#123;&#123;").gsub(/<(?=[A-Za-z\/])/, "&lt;")
      end.join
    end
  end
end
