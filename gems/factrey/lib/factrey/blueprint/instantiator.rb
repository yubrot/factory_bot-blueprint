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

      # @param node [Node]
      # @return [Object]
      def visit(node)
        @objects.fetch(node.name) do
          unless @visited.add?(node.name)
            raise ArgumentError, "Circular references detected around #{node.type_annotated_name}"
          end

          @objects[node.name] = instantiate_object(node)
        end
      end

      private

      # @param node [Node]
      # @return [Object]
      def instantiate_object(node)
        resolver = Ref::Resolver.new(recursion_limit: 5) do |name|
          visit(
            @blueprint.nodes.fetch(name) do
              raise ArgumentError, "Missing definition #{name} around #{node.type_annotated_name}"
            end,
          )
        end

        args = resolver.resolve(node.args)
        kwargs = resolver.resolve(node.kwargs)

        # Resolve auto references to the ancestors
        auto_references = {}
        node.type.auto_references.each do |type_name, attribute|
          next if kwargs.member? attribute # explicitly specified

          compatible_ancestor, index = node.ancestors.reverse_each.with_index.find do |ancestor, _|
            ancestor.type.compatible_types.include?(type_name)
          end
          next unless compatible_ancestor
          next if auto_references.member?(attribute) && auto_references[attribute][1] <= index

          auto_references[attribute] = [compatible_ancestor, index]
        end
        auto_references.each { |attribute, (ancestor, _)| kwargs[attribute] = visit(ancestor) }

        node.type.factory.call(node.type, @context, *args, **kwargs)
      end
    end
  end
end
