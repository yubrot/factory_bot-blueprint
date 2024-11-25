# frozen_string_literal: true

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
      # @return [Node, nil] parent node
      attr_reader :parent
      # @return [Array<Object>] positional arguments to be passed to the factory
      attr_reader :args
      # @return [Hash{Object => Object}] keyword arguments to be passed to the factory
      attr_reader :kwargs

      def initialize(name, type, parent: nil, args: [], kwargs: {})
        raise TypeError, "name must be a Symbol" if name && !name.is_a?(Symbol)
        raise TypeError, "type must be a Blueprint::Type" unless type.is_a? Blueprint::Type
        raise TypeError, "parent must be a Node" if parent && !parent.is_a?(Node)
        raise TypeError, "args must be an Array" unless args.is_a? Array
        raise TypeError, "kwargs must be a Hash" unless kwargs.is_a? Hash

        @name = name || :"#{ANONYMOUS_NAME_PREFIX}#{SecureRandom.hex(6)}"
        @type = type
        @parent = parent
        @args = args
        @kwargs = kwargs
      end

      # @param name [Symbol, nil]
      # @param value [Object]
      # @param parent [Node, nil]
      def self.computed(name, value, parent: nil)
        new(name, Blueprint::Type::COMPUTED, parent:, args: [value])
      end

      # @return [Boolean]
      def anonymous? = name.start_with?(ANONYMOUS_NAME_PREFIX)

      # @return [Boolean]
      def result? = name == RESULT_NAME

      # @return [Ref] the reference to this node
      def to_ref = Ref.new(name)

      # @return [Ref, nil] if this node works as an alias to another node, return the reference to the node
      def alias_ref
        case [type, args]
        in Blueprint::Type::COMPUTED, [Ref => ref]
          ref
        else
          nil
        end
      end

      # @return [Array<Node>] a list of ancestor nodes
      def ancestors = parent ? [parent].concat(parent.ancestors) : []

      # @return [Hash{Symbol => Node}] a map from attributes to auto-referenced ancestor nodes
      def auto_referenced_ancestors
        ancestors = self.ancestors
        candidates = {}
        type.auto_references.each do |type_name, attribute|
          next if kwargs.member? attribute # this attribute is explicitly specified

          # closer ancestors have higher (lower integer) priority
          compatible_node, priority = ancestors.each_with_index.find do |node, _|
            node.type.compatible_types.include?(type_name)
          end
          next unless compatible_node
          next if candidates.member?(attribute) && candidates[attribute][0] <= priority

          candidates[attribute] = [priority, compatible_node]
        end

        candidates.transform_values { _2 }
      end

      # Used for debugging and error reporting.
      # @return [String]
      def type_annotated_name = "#{name}(#{type.name})"
    end
  end
end
