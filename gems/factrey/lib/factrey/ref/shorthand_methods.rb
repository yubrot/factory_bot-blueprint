# frozen_string_literal: true

module Factrey
  class Ref
    # Provides shorthand methods for creating {Ref}s and {Defer}s.
    module ShorthandMethods
      # @return [Ref, Builder, Defer]
      # @example
      #   include Factrey::Ref::ShorthandMethods
      #
      #   # `ref(symbol)` returns a `Ref` instance
      #   ref(:foo)
      #   # `ref` returns a `Ref::Builder` instance; thus, we can write
      #   ref.foo
      #   # `ref { ... }` returns a `Ref::Defer` instance
      #   ref { |foo, bar| foo + bar }
      def ref(name = nil, &)
        if name
          raise ArgumentError, "both name and block given" if block_given?

          Ref.new(name)
        elsif block_given?
          Defer.new(&)
        else
          Builder.new
        end
      end
    end
  end
end
