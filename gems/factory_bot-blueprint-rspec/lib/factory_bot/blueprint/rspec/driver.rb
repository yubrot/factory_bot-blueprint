# frozen_string_literal: true

module FactoryBot
  module Blueprint
    module RSpec
      # Helper methods to integrate <code>factory_bot-blueprint</code> with RSpec.
      # This module is automatically extended to <code>RSpec::Core::ExampleGroup</code>.
      #
      # To use FactoryBot::Blueprint from RSpec with minimal effort, usually {#letbp} is the best choice.
      module Driver
        # Shorthand method for <code>let(name) { ::FactoryBot::Blueprint.plan(...) }</code>.
        # You can access the let binding context by <code>#ext</code> in DSL code.
        # @param name [Symbol] name of the object to be declared using RSpec's <code>let</code>
        # @param inherit [Boolean] whether to extend the blueprint by <code>super()</code>
        # @yield Write Blueprint DSL code here
        # @example
        #   RSpec.describe "something" do
        #     let(:blog_id) { SecureRandom.uuid }
        #
        #     let_blueprint(:blog_bp) do
        #       let.blog(id: ext.blog_id, title: "Daily log") do
        #         let.article(title: "Article 1")
        #         article(title: "Article 2")
        #         article(title: "Article 3")
        #       end
        #     end
        #   end
        def let_blueprint(name, inherit: false, &)
          let(name) { ::FactoryBot::Blueprint.plan(inherit ? super() : nil, ext: self, &) }
          name
        end

        # <code>let!</code> version of {#let_blueprint}.
        def let_blueprint!(...)
          name = let_blueprint(...)
          before { __send__(name) }
        end

        # Create a set of objects by <code>build</code> build strategy in FactoryBot from a blueprint and declare them
        # using RSpec's <code>let</code>.
        # @param map [Hash{Symbol => Object}]
        #   map data structure from source blueprints to instance definitions.
        #   Each instance will be built with <code>FactoryBot::Blueprint.build(__send__(source))</code>
        # @example
        #   RSpec.describe "something" do
        #     let_blueprint(:blog_bp) do
        #       # ... Write some DSL ...
        #     end
        #
        #     # Simplest example:
        #     # This is equivalent to `let_blueprint_build(blog_bp: { result: :blog })`
        #     let_blueprint_build(blog_bp: :blog)
        #
        #     # Another shorthand example:
        #     # This is equivalent to `let_blueprint_build(blog_bp: { items: %i[blog article] })`
        #     let_blueprint_build(blog_bp: %i[blog article])
        #
        #     # Most flexible example:
        #     #   :result specifies the name of the result object to be declared. Defaults to nil
        #     #   :items specifies the names of the objects to be declared. Defaults to []
        #     #   :instance specifies the name of the instance object to be declared. Defaults to :"#{source}_instance"
        #     let_blueprint_build(blog_bp: { result: :blog, items: %i[article], instance: :blog_instance })
        #
        #     # Above example will be expanded to:
        #     let(:blog_instance) { ::FactoryBot::Blueprint.build(blog_bp) }       # the instance object
        #     let(:blog) { blog_instance[Factrey::Blueprint::Node::RESULT_NAME] }  # the result object
        #     let(:article) { blog_instance[:article] }                            # the item objects
        #   end
        def let_blueprint_build(**map) = let_blueprint_instantiate(:build, **map)

        # <code>let!</code> version of {#let_blueprint_build}.
        def let_blueprint_build!(**map) = let_blueprint_instantiate!(:build, **map)

        # Create a set of objects by <code>build_stubbed</code> build strategy in FactoryBot from a blueprint and
        # declare them using RSpec's <code>let</code>.
        # See {#let_blueprint_build} for more details.
        # @param map [Hash{Symbol => Object}]
        #   map data structure from source blueprints to instance definitions.
        #   Each instance will be built with <code>FactoryBot::Blueprint.build_stubbed(__send__(source))</code>
        def let_blueprint_build_stubbed(**map) = let_blueprint_instantiate(:build_stubbed, **map)

        # <code>let!</code> version of {#let_blueprint_build_stubbed}.
        def let_blueprint_build_stubbed!(**map) = let_blueprint_instantiate!(:build_stubbed, **map)

        # Create a set of objects by <code>create</code> build strategy in FactoryBot from a blueprint and declare them
        # using RSpec's <code>let</code>.
        # See {#let_blueprint_build} for more details.
        # @param map [Hash{Symbol => Object}]
        #   map data structure from source blueprints to instance definitions.
        #   Each instance will be built with <code>FactoryBot::Blueprint.create(__send__(source))</code>
        def let_blueprint_create(**map) = let_blueprint_instantiate(:create, **map)

        # <code>let!</code> version of {#let_blueprint_create}.
        def let_blueprint_create!(**map) = let_blueprint_instantiate!(:create, **map)

        # @!visibility private
        def let_blueprint_instantiate(build_strategy, **map)
          if build_strategy && !%i[create build build_stubbed].include?(build_strategy)
            raise ArgumentError, "Unsupported build strategy: #{build_strategy}"
          end

          map.map do |source, definition|
            raise TypeError, "source must be a Symbol" unless source.is_a?(Symbol)

            definition =
              case definition
              when Symbol
                { result: definition }
              when Array
                { items: definition }
              when Hash
                definition
              else
                raise TypeError, "definition must be one of Symbol, Array, Hash"
              end

            result_name = definition[:result]
            item_names = definition[:items] || []
            instance = definition[:instance] || :"#{source}_instance"

            raise TypeError, "result must be a Symbol" if result_name && !result_name.is_a?(Symbol)
            if !item_names.is_a?(Array) || !item_names.all? { _1.is_a?(Symbol) }
              raise TypeError, "items must be an Array of Symbols"
            end
            raise TypeError, "instance must be a Symbol" unless instance.is_a?(Symbol)

            if build_strategy # If no build strategy is specified, the instance is assumed to exist
              let(instance) { ::FactoryBot::Blueprint.instantiate(build_strategy, __send__(source)) }
            end

            let(result_name) { __send__(instance)[::Factrey::Blueprint::Node::RESULT_NAME] } if result_name

            item_names.each { |name| let(name) { __send__(instance)[name] } }

            instance
          end
        end

        # @!visibility private
        def let_blueprint_instantiate!(...)
          names = let_blueprint_instantiate(...)
          before { names.each { __send__(_1) } }
        end

        # Write the blueprint in DSL, create a set of objects from it, and declare each object using RSpec's
        # <code>let</code>.
        #
        # This is a shorthand for a combination of {#let_blueprint} with {#let_blueprint_build}
        # (or other build strategy).
        # @param name [Symbol]
        #   name of the result object to be declared using RSpec's <code>let</code>.
        #   It is also used as a name prefix of the blueprint
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
        #     # Above example will be expanded to:
        #     let_blueprint(:blog_blueprint) do
        #       blog(title: "Daily log") do
        #         let.article(title: "Article 1")
        #         article(title: "Article 2")
        #         article(title: "Article 3")
        #       end
        #     end
        #     let_blueprint_build(blog_blueprint: { result: :blog, items: %i[article] })
        #   end
        def letbp(name, items = []) = Letbp.new(self, name, items)

        # <code>let!</code> version of {#letbp}.
        # @param name [Symbol]
        # @param items [Array<Symbol>]
        # @return [Letbp]
        def letbp!(name, items = []) = Letbp.new(self, name, items, eager: true)
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
