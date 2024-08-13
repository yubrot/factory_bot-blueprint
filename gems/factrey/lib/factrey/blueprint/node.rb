# frozen_string_literal: true

require "set"
require "securerandom"

module Factrey
  class Blueprint
    # A node corresponds to an object to be created. A {Blueprint} consists of a set of nodes.
    class Node
      # A name prefix given to anonymous nodes for convenience.
      ANONYMOUS_NAME_PREFIX = "_anon_"
      # Name used for the node that hold the results of the blueprint.
      RESULT_NAME = :_result_

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

      # @param name [Symbol, nil]
      # @param value [Object]
      # @param ancestors [Array<Node>]
      def self.computed(name, value, ancestors: [])
        new(name, Blueprint::Type::COMPUTED, ancestors:, args: [value])
      end

      # @return [Boolean]
      def anonymous? = name.start_with?(ANONYMOUS_NAME_PREFIX)

      # @return [Boolean]
      def result? = name == RESULT_NAME

      # @return [Ref] the reference to this node
      def to_ref = Ref.new(name)

      # @return [Ref, nil] if this node works as an alias to another node, return the reference to the node
      def alias_ref
        case [@type, args]
        in Blueprint::Type::COMPUTED, [Ref => ref]
          ref
        else
          nil
        end
      end

      # Used for debugging and error reporting.
      # @return [String]
      def type_annotated_name = "#{name}(#{type.name})"
    end
  end
end
