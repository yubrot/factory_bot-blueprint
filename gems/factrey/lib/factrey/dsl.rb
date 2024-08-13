# frozen_string_literal: true

require "set"

module Factrey
  # {Blueprint} DSL implementation.
  class DSL
    # Methods reserved for DSL.
    RESERVED_METHODS = %i[
      ref ext object_node computed_node let on args
      __send__ __method__ __id__ nil? is_a? to_s inspect object_id class instance_eval instance_variables
      initialize block_given? enum_for raise
    ].to_set.freeze

    (instance_methods + private_instance_methods).each do |method|
      undef_method(method) unless RESERVED_METHODS.include?(method)
    end

    # @param blueprint [Blueprint]
    # @param ext [Object]
    def initialize(blueprint:, ext:)
      @blueprint = blueprint
      @ext = ext
      @ancestors = []
    end

    include Ref::ShorthandMethods

    # @return [Object] the external object passed to {Factrey.blueprint}
    attr_reader :ext

    # Add an object node to the blueprint.
    #
    # This method is usually not called directly. Use the shorthand method defined by {.add_type} instead.
    # @param name [Symbol, nil]
    # @param type [Blueprint::Type]
    # @yieldparam ref [Ref]
    # @return [Ref]
    def object_node(name, type, ...)
      node = @blueprint.add_node(Blueprint::Node.new(name, type, ancestors: @ancestors))
      on(node.name, ...)
    end

    # Add a computed node to the blueprint.
    #
    # This method is usually not called directly. Use {#let} instead.
    # @param name [Symbol, nil]
    # @param value [Object]
    def computed_node(name, value)
      node = @blueprint.add_node(Blueprint::Node.computed(name, value, ancestors: @ancestors))
      node.to_ref
    end

    # Define a computed node with name.
    # @param setter_name [Symbol, nil] the setter name for the computed node
    # @return [Ref, Proxy] returns a {Proxy} for <code>let.node_name = ...</code> notation if no argument is given
    # @example
    #   bp =
    #     Factrey.blueprint do
    #       article(title: "Foo")                # object itself has no meaningful name (See Blueprint::Node#anonymous?)
    #       let.article = article(title: "Bar")  # an alias `article` to the article object is defined
    #       let.article(title: "Bar")            # We can omit `.node_name =` if the name is the same as the method name
    #       let.article2 = article(title: "Baz") # an alias `article2` to the article object is defined
    #     end
    #   bp.instantiate              #=> { article: ..., article2: ..., ... }
    def let(setter_name = nil, *args, **kwargs, &block)
      return Proxy.new(self, __method__) unless setter_name

      if setter_name.end_with? "="
        raise ArgumentError, "Wrong setter use" if args.size != 1 || !kwargs.empty? || block

        computed_node(setter_name[0..-2].to_sym, args[0])
      else
        # `let.node_name(...)` is a shorthand for `let.node_name = node_name(...)`
        let(:"#{setter_name}=", __send__(setter_name, *args, **kwargs, &block))
      end
    end

    # Enter the node to configure arguments and child nodes.
    # @param node_name [Symbol, nil] the node name to enter
    # @return [Ref, Proxy] returns a {Proxy} for <code>on.node_name(...)</code> notation if no argument is given
    # @example
    #   Factrey.blueprint do
    #     let.blog do
    #       let.article1 = article
    #       let.article2 = article
    #     end
    #
    #     # Add article to `blog`
    #     on.blog { let.article3 = article }
    #     # Add title to `article2`
    #     on.article2(title: "This is an article 2")
    #   end
    def on(node_name = nil, ...)
      return Proxy.new(self, __method__) unless node_name

      node = @blueprint.resolve_node(node_name)
      raise ArgumentError, "unknown node: #{node_name}" unless node

      stashed_ancestors = @ancestors
      @ancestors = node.ancestors + [node]
      begin
        args(...)
      ensure
        @ancestors = stashed_ancestors
      end
    end

    # Add arguments to the current node.
    # @example
    #   Factrey.blueprint do
    #     let.blog
    #
    #     # The following two lines are equivalent:
    #     on.blog { args :premium, title: "Who-ha" }
    #     on.blog(:premium, title: "Who-ha")
    #   end
    def args(*args, **kwargs)
      raise NameError, "cannot use args at toplevel" if @ancestors.empty?
      raise NameError, "cannot use args to computed nodes" if @ancestors.last.type == Blueprint::Type::COMPUTED

      @ancestors.last.args.concat(args)
      @ancestors.last.kwargs.update(kwargs)
      yield @ancestors.last.to_ref if block_given?
      @ancestors.last.to_ref
    end

    class << self
      # @return [Hash{Symbol => Type}] the types defined in this DSL
      def types
        @types ||= {}
      end

      # Add a new type that will be available in this DSL.
      # This method defines a helper method with the same name as the type name. For example,
      # if you have added the <code>foo</code> type, you can declare an object node with <code>#foo</code>.
      #
      # {.add_type} is called automatically when you use <code>factory_bot-blueprint</code> gem.
      # @param type [Blueprint::Type] blueprint type
      # @example
      #   factory = ->(type, _ctx, *args, **kwargs) { FactoryBot.create(type.name, *args, **kwargs) }
      #   Factrey::DSL.add_type(Factrey::Blueprint::Type.new(:blog, &factory))
      #   Factrey::DSL.add_type(Factrey::Blueprint::Type.new(:article, auto_references: :blog, &factory))
      #
      #   Factrey.blueprint do
      #     blog do
      #       article(title: "Article 1")
      #       article(title: "Article 2")
      #     end
      #   end
      def add_type(type)
        if RESERVED_METHODS.member? type.name
          raise ArgumentError, "Cannot use reserved method name '#{type.name}' for type name"
        end

        if types.member? type.name
          raise ArgumentError, "duplicate type definition: #{type.name}" if types[type.name] != type

          return
        end

        types[type.name] = type
        define_method(type.name) { |*args, **kwargs, &block| object_node(nil, type, *args, **kwargs, &block) }
      end
    end
  end
end
