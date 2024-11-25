# frozen_string_literal: true

require "factory_bot/blueprint/rspec"
require "test_prof/recipes/rspec/let_it_be"

Bundler.require

FactoryBot.find_definitions

TestProf::BeforeAll.adapter = Class.new do
  def begin_transaction; end
  def rollback_transaction; end
end.new

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include FactoryBot::Blueprint::Methods
end
