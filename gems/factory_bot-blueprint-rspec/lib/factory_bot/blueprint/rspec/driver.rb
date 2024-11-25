# frozen_string_literal: true

module FactoryBot
  module Blueprint
    module RSpec
      # Helper methods to integrate <code>factory_bot-blueprint</code> with RSpec.
      # This module is automatically extended to <code>RSpec::Core::ExampleGroup</code>.
      module Driver
        # This method expresses that the names given as arguments will be used in the let declaration for the set of
        # objects to be created from the blueprint. Subsequent method calls specify specifically how to use FactoryBot
        # to create the set of objects from the blueprint.
        #
        # @param name [Symbol] name of the result object to be declared using RSpec's <code>let</code>
        # @param items [Array<Symbol>] names of the objects to be declared using RSpec's <code>let</code>
        # @return [Letbp]
        # @example
        #   RSpec.describe "something" do
        #     letbp(:blog, %i[article]).build do
        #       blog(title: "Daily log") do
        #         let.article(title: "Article 1")
        #         article(title: "Article 2")
        #         article(title: "Article 3")
        #       end
        #     end
        #
        #     # Above example will be expanded to ...
        #
        #     # Create a blueprint:
        #     let(:blog_blueprint) do
        #       FactoryBot::Blueprint.plan(ext: self) do
        #         blog(title: "Daily log") do
        #           let.article(title: "Article 1")
        #           article(title: "Article 2")
        #           article(title: "Article 3")
        #         end
        #       end
        #     end
        #
        #     # Create a set of objects (with `build` build strategy) from it:
        #     let(:blog_instance) { FactoryBot::Blueprint.build(blog_blueprint) }
        #
        #     # Declare the result object:
        #     let(:blog) { blog_instance[Factrey::Blueprint::Node::RESULT_NAME] }
        #
        #     # Declare the named objects:
        #     let(:article) { blog_instance[:article] }
        #   end
        def letbp(name, items = []) = Letbp.new(self, :lazy, name, items)

        # <code>let!</code> version of {#letbp}.
        # @param name [Symbol]
        # @param items [Array<Symbol>]
        # @return [Letbp]
        def letbp!(name, items = []) = Letbp.new(self, :eager, name, items)

        # <code>let_it_be</code> version of {#letbp}. This requires {https://github.com/test-prof/test-prof test-prof}.
        # @param name [Symbol]
        # @param items [Array<Symbol>]
        # @param options [Hash] options for <code>let_it_be</code>
        # @return [Letbp]
        def letbp_it_be(name, items = [], **options)
          Letbp.new(self, :let_it_be, name, items, let_it_be_options: options)
        end
      end
    end
  end
end

# @!visibility private
module RSpec
  module Core
    class ExampleGroup
      extend ::FactoryBot::Blueprint::RSpec::Driver
    end
  end
end
