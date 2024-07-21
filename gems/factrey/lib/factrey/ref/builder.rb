# frozen_string_literal: true

module Factrey
  class Ref
    # An intermediate object for creating {Ref}s. See {ShorthandMethods#ref}.
    class Builder < BasicObject
      # @!visibility private
      def respond_to_missing?(_name, _) = true

      # @example
      #   ref = Factrey::Ref::Builder.new
      #   ref.hoge # same as Factrey::Ref.new(:hoge)
      # @return [Ref]
      def method_missing(name) = Ref.new(name)
    end
  end
end
