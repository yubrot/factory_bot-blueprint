# frozen_string_literal: true

require_relative "ref/builder"
require_relative "ref/defer"
require_relative "ref/resolver"
require_relative "ref/shorthand_methods"

module Factrey
  # Represents a reference that can be embedded in the data and resolved later.
  #
  # {Ref}s and {Defer}s are usually created through {ShorthandMethods#ref}.
  # @example
  #   # Some data containing several references:
  #   include Factrey::Ref::ShorthandMethods
  #   some_data1 = [12, ref.foo, 34, ref.bar, 56]
  #   some_data2 = { foo: ref.foo, foobar: ref { |foo, bar| foo + bar } }
  #
  #   # Resolve references by a `mapping` hash table:
  #   mapping = { foo: 'hello', bar: 'world' }
  #   resolver = Factrey::Ref::Resolver.new { mapping.fetch(_1) }
  #   resolver.resolve(some_data1) #=> [12, 'hello', 34, 'world', 56]
  #   resolver.resolve(some_data2) #=> { foo: 'hello', foobar: 'helloworld' }
  class Ref
    # @return [Symbol]
    attr_reader :name

    # @param name [Symbol]
    def initialize(name)
      raise TypeError, "name must be a Symbol" unless name.is_a?(Symbol)

      @name = name
    end

    def ==(other) = other.is_a?(Ref) && other.name == name

    def eql?(other) = self == other

    def hash = name.hash
  end
end
