# frozen_string_literal: true

module Factrey
  class Ref
    # {Resolver} resolves {Ref}s and {Defer}s.
    class Resolver
      # @param recursion_limit [Integer, nil] how many recursions are allowed
      # @yieldparam name [Symbol] the name of the reference to be resolved
      def initialize(recursion_limit: nil, &handler)
        @recursion_limit = recursion_limit
        @handler = handler
      end

      # Traverse data recursively and resolve all {Ref}s and {Defer}s.
      #
      # This method supports recursive traversal for {Array} and {Hash}. For other structures, consider using {Defer}.
      # @param object [Object]
      # @param recursion_count [Integer]
      def resolve(object, recursion_count: 0)
        return object if !@recursion_limit.nil? && @recursion_limit < recursion_count

        recursion_count += 1
        case object
        when Array
          object.map { resolve(_1, recursion_count:) }
        when Hash
          object.to_h { |key, value| [resolve(key, recursion_count:), resolve(value, recursion_count:)] }
        when Ref
          @handler.call(object.name)
        when Defer
          object.body.call(*object.refs.map { resolve(_1) })
        else
          object
        end
      end
    end
  end
end
