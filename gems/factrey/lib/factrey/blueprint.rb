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
        result.add_node(
          node.name,
          node.type,
          # This is OK since Hash insertion order in Ruby is retained
          ancestors: node.ancestors.map { result.nodes[_1.name] },
          args: node.args.dup,
          kwargs: node.kwargs.dup,
        )
      end

      result
    end

    # Get the last root node.
    # @return [Node, nil]
    def representative_node = nodes.each_value.reverse_each.find(&:root?)

    # Add a node. This method is used by {DSL} and usually does not need to be called directly.
    # @return [Node]
    def add_node(...)
      node = Node.new(...)
      raise ArgumentError, "duplicate node: #{node.name}" if nodes.member?(node.name)

      nodes[node.name] = node
      node
    end

    # Create a set of objects based on this blueprint.
    # @param context [Object] context object to be passed to the factories
    # @return [Hash{Symbol => Object}]
    def instantiate(context = nil)
      instantiator = Instantiator.new(context, self)

      nodes.each_value { instantiator.visit(_1) }

      instantiator.objects
    end
  end
end
