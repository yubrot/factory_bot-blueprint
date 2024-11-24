# frozen_string_literal: true

require_relative "lib/factory_bot/blueprint/version"

Gem::Specification.new do |spec|
  spec.name = "factory_bot-blueprint"
  spec.version = FactoryBot::Blueprint::VERSION
  spec.authors = ["yubrot"]
  spec.email = ["yubrot@gmail.com"]

  spec.summary = "FactoryBot extension for building structured objects using a declarative DSL"
  spec.description = <<~DESCRIPTION
    FactoryBot::Blueprint is a FactoryBot extension for building structured objects using a declarative DSL.
    On the DSL, the factories defined in FactoryBot can be used without any additional configuration.
  DESCRIPTION
  spec.homepage = "https://github.com/yubrot/factory_bot-blueprint"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

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

  spec.add_dependency "factory_bot", "~> 6.0"
  spec.add_dependency "factrey", "~> #{FactoryBot::Blueprint::VERSION}"
end
