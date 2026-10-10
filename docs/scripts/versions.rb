#!/usr/bin/env ruby
# frozen_string_literal: true

# Rewrites versions.json and the root redirect of the published site (the gh-pages checkout).
#
#   ruby docs/scripts/versions.rb SITE_DIR [--print-latest]
#
# A version is a directory named like 0.5.0; `latest` and `next` are built separately. The newest version is
# what `latest` should be built from; --print-latest prints it so the workflow can build that alias.

require "json"

dir = ARGV.reject { |a| a.start_with?("--") }.first or abort "usage: versions.rb SITE_DIR"
versions = Dir.children(dir).select { |d| d.match?(/\A\d+\.\d+\.\d+\z/) && File.directory?(File.join(dir, d)) }
  .sort_by { |v| Gem::Version.new(v) }.reverse

if ARGV.include?("--print-latest")
  puts versions.first
  exit
end

File.write(File.join(dir, "versions.json"), JSON.pretty_generate(
  latest: versions.first, versions: versions, next: File.directory?(File.join(dir, "next"))
) + "\n")

File.write(File.join(dir, "index.html"), <<~HTML)
  <!doctype html>
  <meta charset="utf-8">
  <title>paystack_sdk</title>
  <meta http-equiv="refresh" content="0; url=latest/">
  <link rel="canonical" href="latest/">
  <p>Redirecting to the <a href="latest/">latest documentation</a>.</p>
HTML
File.write(File.join(dir, ".nojekyll"), "")
puts "versions: #{versions.join(", ")}"
