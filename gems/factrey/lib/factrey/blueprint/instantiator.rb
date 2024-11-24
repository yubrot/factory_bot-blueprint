# frozen_string_literal: true

require "set"

module Factrey
  class Blueprint
    # An internal class used by {Blueprint#instantiate}.
    class Instantiator
      # @return [Hash{Symbol => Object}]
      attr_reader :objects

      # @param context [Object]
      # @param blueprint [Blueprint]
      def initialize(context, blueprint)
        @context = context
        @objects = {}
        @visited = Set.new
        @blueprint = blueprint
      end

      def instantiate_objects
        @blueprint.nodes.each_value { ensure_object_instantiated(_1) }
        @objects
      end

      private

      # @param node [Node]
      # @return [Object]
      def ensure_object_instantiated(node)
        @objects.fetch(node.name) do
          unless @visited.add?(node.name)
            raise ArgumentError, "Circular references detected around #{node.type_annotated_name}"
          end

          args = resolver.resolve(node.args)
          kwargs = resolver.resolve(node.kwargs)
          resolve_auto_references(node.type.auto_references, node.ancestors, kwargs)
          @objects[node.name] = node.type.factory.call(node.type, @context, *args, **kwargs)
        end
      end

      # @return [Ref::Resolver]
      def resolver
        @resolver ||= Ref::Resolver.new(recursion_limit: 5) do |name|
          node = @blueprint.nodes.fetch(name) { raise ArgumentError, "Missing definition: #{name}" }
          ensure_object_instantiated(node)
        end
      end

      # @param auto_references [Hash{Symbol => Symbol}]
      # @param referenceable_nodes [Array<Node>]
      # @param dest [Hash{Symbol => Object}]
      def resolve_auto_references(auto_references, referenceable_nodes, dest)
        candidates = {}
        auto_references.each do |type_name, attribute|
          next if dest.member? attribute # this attribute is explicitly specified

          compatible_node, index = referenceable_nodes.each_with_index.find do |node, _|
            node.type.compatible_types.include?(type_name)
          end
          next unless compatible_node

          # the node closest to the end of the array has priority
          next if candidates.member?(attribute) && candidates[attribute][1] <= index

          candidates[attribute] = [compatible_node, index]
        end

        candidates.each do |attribute, (node, _)|
          dest[attribute] = ensure_object_instantiated(node)
        end
      end
    end
  end
end
