# frozen_string_literal: true

module FactoryBot
  module Blueprint
    # This module provides a shortcut to FactoryBot::Blueprint.
    # @example
    #   # Configure the same way as FactoryBot::Syntax::Methods
    #   RSpec.configure do |config|
    #     config.include FactoryBot::Syntax::Methods
    #     config.include FactoryBot::Blueprint::Methods
    #   end
    #
    #   # You can use `bp` in your spec files
    #   RSpec.describe "something" do
    #     before do
    #       bp.create do
    #         blog do
    #           article(title: "Article 1")
    #           article(title: "Article 2")
    #           article(title: "Article 3") do
    #             comment(name: "John")
    #             comment(name: "Doe")
    #           end
    #         end
    #       end
    #     end
    #   end
    module Methods
      # @return [Class<FactoryBot::Blueprint>]
      def bp = FactoryBot::Blueprint
    end
  end
end
