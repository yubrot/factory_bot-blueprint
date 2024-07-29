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
    # @return [Object] the result of the DSL code is defined here
    attr_reader :result

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

    # Add a node. This method is used by {DSL} and usually does not need to be called directly.
    # @return [Node]
    def add_node(...)
      node = Node.new(...)
      raise ArgumentError, "duplicate node: #{node.name}" if nodes.member?(node.name)

      nodes[node.name] = node
      node
    end

    # Define the result. This method is used by {DSL} and usually does not need to be called directly.
    # @param result [Object]
    # @param overwrite [Boolean] whether to overwrite the existing result
    def define_result(result, overwrite: false)
      return if defined?(@result) && !overwrite

      @result = result
    end

    # Create a set of objects and compute the result based on this blueprint.
    # @param context [Object] context object to be passed to the factories
    # @return [(Object, {Symbol => Object})] the result and the created objects
    def instantiate(context = nil)
      instantiator = Instantiator.new(context, self)
      objects = instantiator.instantiate_objects
      result = instantiator.instantiate_result
      [result, objects]
    end
  end
end
