# frozen_string_literal: true

require_relative 'lib/paystack_sdk/version'

Gem::Specification.new do |spec|
  spec.name = 'paystack_sdk'
  spec.version = PaystackSdk::VERSION
  spec.authors = ['Maxwell Nana Forson (theLazyProgrammer)']
  spec.email = ['nanaforsonjnr@gmail.com']

  spec.summary = "A Ruby SDK for integrating with Paystack's payment gateway API."
  spec.description = <<~EOS
    The `paystack_sdk` gem provides a simple and intuitive interface for
    interacting with Paystack's payment gateway API. It allows developers to
    easily integrate Paystack's payment processing features into their Ruby
    applications. With support for various endpoints, this SDK simplifies tasks
    such as initiating transactions, verifying payments, managing customers, and more.
  EOS
  spec.homepage = 'https://github.com/nanafox/paystack_sdk'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.2'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/nanafox/paystack_sdk/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Dependencies
  spec.add_dependency 'faraday', '~> 2.13.1'
  spec.add_development_dependency 'debug', '~> 1.9.0'
  spec.add_development_dependency 'irb', '~> 1.15.1'
  spec.add_development_dependency 'rake', '~> 13.2.1'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'standard', '~> 1.49.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
