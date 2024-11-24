# frozen_string_literal: true

require_relative "blueprint/type"
require_relative "blueprint/node"
require_relative "blueprint/instantiator"

module Factrey
  # Represents how to create a set of objects.
  # {Blueprint} can be created and extended by the Blueprint DSL. See {Factrey.blueprint}.
  class Blueprint
    # @return [Hash{Symbol => Node}] a set of nodes
    attr_reader :nodes

    # Creates an empty blueprint.
    def initialize
      @nodes = {}
    end

    # @return [Blueprint]
    def dup
      result = self.class.new

      nodes.each_value do |node|
        new_node = Node.new(
          node.name,
          node.type,
          # This is OK since Hash insertion order in Ruby is retained
          parent: node.parent&.then { result.nodes[_1.name] },
          args: node.args.dup,
          kwargs: node.kwargs.dup,
        )
        result.add_node(new_node)
      end

      result
    end

    # Add a node. This method is used by {DSL} and usually does not need to be called directly.
    # @param node [Node]
    # @return [Node]
    def add_node(node)
      raise ArgumentError, "duplicate node: #{node.name}" if nodes.member?(node.name)

      nodes[node.name] = node
      node
    end

    # Resolve a node.
    # @param name [Symbol]
    # @param follow_alias [Boolean] whether to follow an alias node. See {Node#alias_ref}
    # @return [Node, nil]
    def resolve_node(name, follow_alias: true)
      node = nodes[name]
      return node unless follow_alias

      ref = node&.alias_ref
      ref ? resolve_node(ref.name) : node
    end

    # Create a set of objects based on this blueprint.
    # @param context [Object] context object to be passed to the factories
    # @return [Hash{Symbol => Object}] the created objects
    def instantiate(context = nil)
      Instantiator.new(context, self).instantiate_objects
    end
  end
end
