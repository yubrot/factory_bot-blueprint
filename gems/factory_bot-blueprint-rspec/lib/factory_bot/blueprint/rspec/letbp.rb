# frozen_string_literal: true

module FactoryBot
  module Blueprint
    module RSpec
      # An intermediate object for <code>letbp</code> syntax. See {Driver#letbp} for more details.
      class Letbp
        # @!visibility private
        def initialize(context, name, items, eager: false)
          raise TypeError, "context must include FactoryBot::Blueprint::RSpec::Driver" unless context.is_a?(Driver)
          raise TypeError, "name must be a Symbol" unless name.is_a?(Symbol)
          unless items.is_a?(Array) && items.all? { _1.is_a?(Symbol) }
            raise TypeError, "items must be an Array of Symbols"
          end

          @context = context
          @name = name
          @items = items
          @eager = eager
        end

        # Create a set of objects by <code>build</code> build strategy in FactoryBot.
        def build(&) = instantiate(:build, &)

        # Create a set of objects by <code>build_stubbed</code> build strategy in FactoryBot.
        def build_stubbed(&) = instantiate(:build_stubbed, &)

        # Create a set of objects by <code>create</code> build strategy in FactoryBot.
        def create(&) = instantiate(:create, &)

        # Extend <code>super()</code> blueprint.
        # @example
        #   RSpec.describe "something" do
        #     letbp(:blog, %i[article]).build do
        #       blog(title: "Daily log") do
        #         let.article(title: "Article")
        #       end
        #     end
        #
        #     context "with a comment on the article" do
        #       letbp(:blog, %i[comment]).inherit do
        #         on.article do
        #           let.comment(text: "Comment")
        #         end
        #       end
        #     end
        #   end
        def inherit(&) = instantiate(nil, &)

        # @!visibility private
        def instantiate(build_strategy, &)
          source = :"#{@name}_blueprint"
          definitions = { result: @name, items: @items }
          inherit = build_strategy.nil?

          if @eager
            @context.let_blueprint!(source, inherit:, &)
            @context.let_blueprint_instantiate!(build_strategy, source => definitions)
          else
            @context.let_blueprint(source, inherit:, &)
            @context.let_blueprint_instantiate(build_strategy, source => definitions)
          end
        end
      end
    end
  end
end
