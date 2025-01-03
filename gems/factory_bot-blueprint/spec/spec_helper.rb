# frozen_string_literal: true

require "factory_bot/blueprint"

Bundler.require

FactoryBot.find_definitions

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include FactoryBot::Blueprint::Methods
end
