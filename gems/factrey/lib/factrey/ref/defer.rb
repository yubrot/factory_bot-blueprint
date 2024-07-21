# frozen_string_literal: true

module Factrey
  class Ref
    # A thin wrapper around {Proc} to represent the procedure using the results of the reference resolution.
    # Each argument name is considered as a reference.
    # These references are resolved and the results are passed to the {Proc}.
    #
    # {Ref}s and {Defer}s are usually created through {ShorthandMethods#ref}.
    class Defer
      # @return [Proc]
      attr_reader :body

      # @return [Array<Ref>]
      def refs = @body.parameters.map { Ref.new(_1[1]) }

      # @example
      #   Factrey::Ref::Defer.new { |foo, bar| foo + bar }
      def initialize(&body)
        body.parameters.all? { _1[0] == :req || _1[0] == :opt } or
          raise ArgumentError, "block must take only fixed positional arguments"

        @body = body
      end
    end
  end
end
