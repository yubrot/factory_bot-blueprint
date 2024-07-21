# frozen_string_literal: true

module Factrey
  class DSL
    # An intermediate object for <code>on.name(...)</code> notation. See {DSL#on}.
    class On < BasicObject
      # @param dsl [DSL]
      def initialize(dsl) = @dsl = dsl

      # @!visibility private
      def respond_to_missing?(_name, _) = true

      def method_missing(name, ...) = @dsl.on(name, ...)
    end
  end
end
