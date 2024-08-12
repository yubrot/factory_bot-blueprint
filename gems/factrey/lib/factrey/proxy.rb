# frozen_string_literal: true

module Factrey
  # An intermediate object to provide some notation combined with <code>method_missing</code>.
  # @example
  #   class Foo
  #     def foo(name = nil)
  #       return Factrey::Proxy.new(self, __method__) unless name
  #
  #       name
  #     end
  #   end
  #
  #   Foo.new.foo.bar #=> :bar
  class Proxy < BasicObject
    # @param receiver [Object]
    # @param method [Symbol]
    def initialize(receiver, method)
      @receiver = receiver
      @method = method
    end

    # @!visibility private
    def respond_to_missing?(_method_name, _) = true

    def method_missing(method_name, ...)
      @receiver.__send__(@method, method_name, ...)
    end
  end
end