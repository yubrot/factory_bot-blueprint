# frozen_string_literal: true

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
        @blueprint = blueprint

        # Intermediate state
        @creating_objects = Set.new
      end

      def instantiate_objects
        @blueprint.nodes.each_value { ensure_object_created(_1) }
        @objects
      end

      private

      # @param node [Node]
      # @return [Object]
      def ensure_object_created(node)
        @objects.fetch(node.name) do
          unless @creating_objects.add?(node.name)
            raise ArgumentError, "Circular references detected around #{node.type_annotated_name}"
          end

          args = resolver.resolve(node.args)
          kwargs = resolver.resolve(node.kwargs)
          node.auto_referenced_ancestors.each { kwargs[_1] = ensure_object_created(_2) }
          @objects[node.name] = node.type.create_object(@context, *args, **kwargs)
        end
      end

      # @return [Ref::Resolver]
      def resolver
        @resolver ||= Ref::Resolver.new(recursion_limit: 5) do |name|
          node = @blueprint.nodes.fetch(name) { raise ArgumentError, "Missing definition: #{name}" }
          ensure_object_created(node)
        end
      end
    end
  end
end
