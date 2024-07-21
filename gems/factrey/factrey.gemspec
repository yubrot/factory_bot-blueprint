# frozen_string_literal: true

require_relative "lib/factrey/version"

Gem::Specification.new do |spec|
  spec.name = "factrey"
  spec.version = Factrey::VERSION
  spec.authors = ["yubrot"]
  spec.email = ["yubrot@gmail.com"]

  spec.summary = "Provides a declarative DSL to represent the creation plan of objects"
  spec.description = <<~DESCRIPTION
    Factrey provides a declarative DSL to represent the creation plan of objects, for FactoryBot::Blueprint.
    The name Factrey is derived from the words factory and tree.
  DESCRIPTION
  spec.homepage = "https://github.com/yubrot/factory_bot-blueprint"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ spec/ Gemfile Rakefile .rspec .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
