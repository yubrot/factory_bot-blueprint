# frozen_string_literal: true

require "set"

module Factrey
  class Blueprint
    # A node corresponds to an object to be created. A {Blueprint} consists of a set of nodes.
    class Node
      ANONYMOUS_NAME_PREFIX = "_anon_"

      # @return [Symbol] name given to the object to be created
      attr_reader :name
      # @return [Type] type of the object
      attr_reader :type
      # @return [Array<Node>] list of ancestor nodes, from root to terminal nodes
      attr_reader :ancestors
      # @return [Array<Object>] positional arguments to be passed to the factory
      attr_reader :args
      # @return [Hash{Object => Object}] keyword arguments to be passed to the factory
      attr_reader :kwargs

      def initialize(name, type, ancestors: [], args: [], kwargs: {})
        raise TypeError, "name must be a Symbol" if name && !name.is_a?(Symbol)
        raise TypeError, "type must be a Blueprint::Type" unless type.is_a? Blueprint::Type
        unless ancestors.is_a?(Array) && ancestors.all? { _1.is_a?(Node) }
          raise TypeError, "ancestors must be an Array of Nodes"
        end
        raise TypeError, "args must be an Array" unless args.is_a? Array
        raise TypeError, "kwargs must be a Hash" unless kwargs.is_a? Hash

        @name = name || :"#{ANONYMOUS_NAME_PREFIX}#{SecureRandom.hex(6)}"
        @type = type
        @ancestors = ancestors
        @args = args
        @kwargs = kwargs
      end

      # @return [Boolean]
      def root? = ancestors.empty?

      # @return [Boolean]
      def anonymous? = name.start_with?(ANONYMOUS_NAME_PREFIX)

      # Used for debugging and error reporting.
      # @return [String]
      def type_annotated_name = "#{name}(#{type.name})"
    end
  end
end
