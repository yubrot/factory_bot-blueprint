# frozen_string_literal: true

module FactoryBot
  module Blueprint
    module RSpec
      # An intermediate object for <code>letbp</code> syntax. See {Driver#letbp} for more details.
      class Letbp
        # @!visibility private
        def initialize(context, kind, name, items, let_it_be_options: nil)
          raise TypeError, "context must include FactoryBot::Blueprint::RSpec::Driver" unless context.is_a?(Driver)
          raise ArgumentError, "unknown kind: #{kind}" unless %i[lazy eager let_it_be].include?(kind)
          raise TypeError, "name must be a Symbol" unless name.is_a?(Symbol)
          unless items.is_a?(Array) && items.all? { _1.is_a?(Symbol) }
            raise TypeError, "items must be an Array of Symbols"
          end
          if let_it_be_options && kind != :let_it_be
            raise ArgumentError, "`let_it_be_options` must be used with `let_it_be` kind"
          end

          @context = context
          @kind = kind
          @name = name
          @items = items
          @let_it_be_options = let_it_be_options
        end

        # Create a new blueprint, and create a set of objects (with <code>build</code> build strategy) from it.
        # @yield Write Blueprint DSL code here
        # @example
        #   letbp(:blog, %i[article]).build do
        #     blog(title: "Daily log") do
        #       let.article(title: "Article 1")
        #       article(title: "Article 2")
        #       article(title: "Article 3")
        #     end
        #   end
        def build(&)
          let_blueprint(:new, &)
          let_instance(:build)
          let_objects
        end

        # Create a new blueprint, and create a set of objects (with <code>build_stubbed</code> build strategy) from it.
        # @yield Write Blueprint DSL code here
        def build_stubbed(&)
          let_blueprint(:new, &)
          let_instance(:build_stubbed)
          let_objects
        end

        # Create a new blueprint, and create a set of objects (with <code>create</code> build strategy) from it.
        # @yield Write Blueprint DSL code here
        def create(&)
          let_blueprint(:new, &)
          let_instance(:create)
          let_objects
        end

        # Create a set of objects (with <code>build</code> build strategy) from an existing blueprint.
        # @yield Usual let context for retrieving an existing blueprint
        # @example
        #   let(:blog_blueprint) do
        #     bp.plan do
        #       blog(title: "Daily log") do
        #         let.article(title: "Article 1")
        #         article(title: "Article 2")
        #         article(title: "Article 3")
        #       end
        #     end
        #   end
        #   letbp(:blog, %i[article]).build_from { blog_blueprint }
        def build_from(&)
          let_blueprint(:from, &)
          let_instance(:build)
          let_objects
        end

        # Create a set of objects (with <code>build_stubbed</code> build strategy) from an existing blueprint.
        # @yield Usual let context for retrieving an existing blueprint
        def build_stubbed_from(&)
          let_blueprint(:from, &)
          let_instance(:build_stubbed)
          let_objects
        end

        # Create a set of objects (with <code>create</code> build strategy) from an existing blueprint.
        # @yield Usual let context for retrieving an existing blueprint
        def create_from(&)
          let_blueprint(:from, &)
          let_instance(:create)
          let_objects
        end

        # Extend <code>super()</code> blueprint.
        # @yield Write Blueprint DSL code here
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
        def inherit(&)
          let_blueprint(:inherit, &)
          # We don't need `let_instance` here because it's already defined in the parent context
          let_objects
        end

        private

        def blueprint_name = :"_letbp_#{@name}_blueprint"
        def instance_name = :"_letbp_#{@name}_instance"

        def let(var, &)
          case @kind
          when :lazy
            @context.let(var, &)
          when :eager
            @context.let!(var, &)
          when :let_it_be
            @context.let_it_be(var, **@let_it_be_options, &)
          end
        end

        # @param source [:new, :from, :inherit]
        def let_blueprint(source, &)
          case source
          when :new
            let(blueprint_name) { ::FactoryBot::Blueprint.plan(ext: self, &) }
          when :from
            let(blueprint_name, &)
          when :inherit
            raise ArgumentError, "#inherit does not work with `letbp_it_be`" if @kind == :let_it_be

            let(blueprint_name) { ::FactoryBot::Blueprint.plan(super(), ext: self, &) }
          end
        end

        # @param build_strategy [:build, :build_stubbed, :create]
        def let_instance(build_strategy)
          blueprint_name = self.blueprint_name
          let(instance_name) { ::FactoryBot::Blueprint.instantiate(build_strategy, __send__(blueprint_name)) }
        end

        def let_objects
          instance_name = self.instance_name

          let(@name) { __send__(instance_name)[::Factrey::Blueprint::Node::RESULT_NAME] }
          @items.each { |item| let(item) { __send__(instance_name)[item] } }
        end
      end
    end
  end
end
