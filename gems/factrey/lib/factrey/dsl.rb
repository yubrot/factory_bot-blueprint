# frozen_string_literal: true

require "set"
require "securerandom"

require_relative "dsl/let"
require_relative "dsl/on"

module Factrey
  # {Blueprint} DSL implementation.
  class DSL
    # Methods reserved for DSL.
    RESERVED_METHODS = %i[
      ref ext let node on type args
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

    # By preceding <code>let(name).</code> to the declaration, give a name to the node.
    # @param name [Symbol, nil] defaults to {Blueprint::Type#name} if omitted
    # @return [Let]
    # @example
    #   bp =
    #     Factrey.blueprint do
    #       article                 # no meaningful name is given (See Blueprint::Node#anonymous?)
    #       let.article             # named as article
    #       let(:article2).article  # named as article2
    #     end
    #   bp.instantiate              #=> { article: ..., article2: ..., ... }
    def let(name = nil, &)
      raise TypeError, "name must be a Symbol" if name && !name.is_a?(Symbol)
      raise ArgumentError, "nested let" if @let_scope

      let = Let.new(self, name)
      return let unless block_given?

      @let_scope = let
      ret = yield
      @let_scope = nil
      ret
    end

    # Add a node to the blueprint.
    #
    # This method is usually not called directly. Use the shorthand method defined by {.add_type} instead.
    # @param type [Blueprint::Type]
    # @yieldparam ref [Ref]
    # @return [Ref]
    def node(type, ...)
      name = @let_scope ? (@let_scope.name || type.name) : nil
      @let_scope = nil # consumed

      node = @blueprint.add_node(Blueprint::Node.new(name, type, ancestors: @ancestors))
      on(node.name, ...)
    end

    # Enter the node to configure arguments and child nodes.
    # @yieldparam ref [Ref]
    # @return [Ref]
    # @example
    #   Factrey.blueprint do
    #     let.blog do
    #       let(:article1).article
    #       let(:article2).article
    #     end
    #
    #     # Add article to `blog`
    #     on.blog { let(:article3).article }
    #     # Add title to `article2`
    #     on.article2(title: "This is an article 2")
    #   end
    def on(name = nil, *args, **kwargs)
      return On.new(self) if name.nil? && !block_given?

      node = @blueprint.nodes[name]
      raise ArgumentError, "unknown node: #{name}" unless node

      stashed_ancestors = @ancestors
      @ancestors = node.ancestors + [node]
      args(*args, **kwargs)
      yield node.to_ref if block_given?
      @ancestors = stashed_ancestors
      node.to_ref
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
      raise NameError, "Cannot use args at toplevel" if @ancestors.empty?

      @ancestors.last.args.concat(args)
      @ancestors.last.kwargs.update(kwargs)
    end

    class << self
      # @return [Hash{Symbol => Type}] the types defined in this DSL
      def types
        @types ||= {}
      end

      # Add a new type that will be available in this DSL.
      # A helper method with the same name as the type name is also defined in the DSL. For example,
      # if you have added the <code>foo</code> type, you can declare node with <code>#foo</code>.
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
        define_method(type.name) { |*args, **kwargs, &block| node(type, *args, **kwargs, &block) }
      end
    end
  end
end
