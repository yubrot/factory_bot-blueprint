# frozen_string_literal: true

module FactoryBot
  module Blueprint
    module RSpec
      # Helper methods to integrate <code>factory_bot-blueprint</code> with RSpec.
      # This module is automatically extended to {RSpec::Core::ExampleGroup}.
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
        end

        # Build objects by <code>build</code> strategy in FactoryBot from a blueprint and declare them using RSpec's
        # <code>let</code>.
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
        #     # This is equivalent to `let_blueprint_build blog_bp: { representative: :blog }`
        #     let_blueprint_build blog_bp: :blog
        #
        #     # Another shorthand example:
        #     # This is equivalent to `let_blueprint_build blog_bp: { items: %i[blog article] }`
        #     let_blueprint_build blog_bp: %i[blog article]
        #
        #     # Most flexible example:
        #     #   :representative specifies the name of the representative object to be declared. Defaults to nil
        #     #   :items specifies the names of the objects to be declared. Defaults to []
        #     #   :instance specifies the name of the instance object to be declared. Defaults to :"#{source}_instance"
        #     let_blueprint_build blog_bp: { representative: :blog, items: %i[article], instance: :blog_instance }
        #
        #     # Above example will be expanded to:
        #     let(:blog_instance) { ::FactoryBot::Blueprint.build(blog_bp) }  # the instance object
        #     let(:blog) { blog_instance[blog_bp.representative_node.name] }  # the representative object
        #     let(:article) { blog_instance[:article] }                       # the item objects
        #   end
        def let_blueprint_build(**map) = let_blueprint_instantiate(:build, **map)

        # Build objects by <code>create</code> strategy in FactoryBot from a blueprint and declare them using RSpec's
        # <code>let</code>.
        # See {#let_blueprint_build} for more details.
        # @param map [Hash{Symbol => Object}]
        #   map data structure from source blueprints to instance definitions.
        #   Each instance will be built with <code>FactoryBot::Blueprint.build(__send__(source))</code>
        def let_blueprint_create(**map) = let_blueprint_instantiate(:create, **map)

        # @!visibility private
        def let_blueprint_instantiate(strategy, **map)
          raise ArgumentError, "Unsupported strategy: #{strategy}" if strategy && !%i[create build].include?(strategy)

          map.each do |source, definition|
            raise TypeError, "source must be a Symbol" unless source.is_a?(Symbol)

            definition =
              case definition
              when Symbol
                { representative: definition }
              when Array
                { items: definition }
              when Hash
                definition
              else
                raise TypeError, "definition must be one of Symbol, Array, Hash"
              end

            representative_name = definition[:representative]
            item_names = definition[:items] || []
            instance = definition[:instance] || :"#{source}_instance"

            if representative_name && !representative_name.is_a?(Symbol)
              raise TypeError, "representative must be a Symbol"
            end
            if !item_names.is_a?(Array) || !item_names.all? { _1.is_a?(Symbol) }
              raise TypeError, "items must be an Array of Symbols"
            end
            raise TypeError, "instance must be a Symbol" unless instance.is_a?(Symbol)

            if strategy # If no strategy is specified, the instance is assumed to exist
              let(instance) { ::FactoryBot::Blueprint.instantiate(strategy, __send__(source)) }
            end

            if representative_name
              let(representative_name) { __send__(instance)[__send__(source).representative_node.name] }
            end

            item_names.each do |name|
              let(name) { __send__(instance)[name] }
            end
          end
        end

        # Write the blueprint in DSL, create an instance of it, and declare each object of the instance using RSpec's
        # <code>let</code>.
        #
        # This is a shorthand for {#let_blueprint} with {#let_blueprint_build} or {#let_blueprint_create}.
        # @param name [Symbol]
        #   name of the representative object to be declared using RSpec's <code>let</code>.
        #   It is also used as a name prefix of the blueprint
        # @param items [Array<Symbol>] names of the objects to be declared using RSpec's <code>let</code>
        # @param inherit [Boolean] whether to extend the blueprint by <code>super()</code>
        # @param strategy [:create, :build]
        #   FactoryBot strategy to use when building objects.
        #   This option is ignored if <code>inherit: true</code>
        # @yield Write Blueprint DSL code here
        # @example
        #   RSpec.describe "something" do
        #     letbp(:blog, %i[article]) do
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
        #     let_blueprint_create blog_blueprint: { representative: :blog, items: %i[article] }
        #   end
        def letbp(name, items = [], inherit: false, strategy: :create, &)
          raise TypeError, "name must be a Symbol" unless name.is_a?(Symbol)

          source = :"#{name}_blueprint"
          strategy = nil if inherit

          let_blueprint(source, inherit:, &)
          let_blueprint_instantiate strategy, source => { representative: name, items: }
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
