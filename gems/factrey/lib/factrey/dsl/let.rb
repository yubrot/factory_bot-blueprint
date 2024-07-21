# frozen_string_literal: true

module Factrey
  class DSL
    # An intermediate object for <code>let(:name).node(...)</code> notation. See {DSL#let}.
    class Let < BasicObject
      attr_reader :name

      # @param dsl [DSL]
      # @param name [Symbol, nil]
      def initialize(dsl, name)
        @dsl = dsl
        @name = name
      end

      # @!visibility private
      def respond_to_missing?(_method_name, _) = true

      def method_missing(method_name, ...) = @dsl.let(@name) { @dsl.__send__(method_name, ...) }
    end
  end
end
