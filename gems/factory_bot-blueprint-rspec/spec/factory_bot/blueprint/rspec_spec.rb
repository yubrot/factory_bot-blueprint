# frozen_string_literal: true

RSpec.describe FactoryBot::Blueprint::RSpec do
  it "has the same version number with factory_bot-blueprint" do
    expect(FactoryBot::Blueprint::RSpec::VERSION).to eq FactoryBot::Blueprint::VERSION
  end
end
