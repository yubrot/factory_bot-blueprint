# frozen_string_literal: true

module Factrey
  class Blueprint
    # A type representation on Factrey blueprints.
    # This definition includes how the actual object is created ({#factory}) and
    # what other types the object refers to ({#auto_references}).
    class Type
      # @return [Symbol] the name of this type. It is also used as the default object name at instantiation phase
      attr_reader :name
      # @return [Set<Symbol>] List of type names to be considered compatible with this type
      attr_reader :compatible_types
      # @return [Hash{Symbol => Symbol}] a name-to-attribute mapping for auto-referencing
      attr_reader :auto_references
      # @return [Proc] procedure that actually creates an object. See {Blueprint::Instantiator} implementation
      attr_reader :factory

      # @param name [Symbol]
      # @param compatible_types [Array<Symbol>, Symbol]
      # @param auto_references [Hash{Symbol => Symbol}, Array<Symbol>, Symbol]
      # @yield [type, context, *args, **kwargs]
      def initialize(name, compatible_types: [], auto_references: {}, &factory)
        compatible_types = [compatible_types] if compatible_types.is_a? Symbol
        auto_references = [auto_references] if auto_references.is_a? Symbol
        auto_references = auto_references.to_h { [_1, _1] } if auto_references.is_a? Array

        raise TypeError, "name must be a Symbol" unless name.is_a? Symbol
        unless compatible_types.is_a?(Array) && compatible_types.all? { _1.is_a?(Symbol) }
          raise TypeError, "compatible_types must be an Array of Symbols"
        end
        unless auto_references.is_a?(Hash) && auto_references.all? { |k, v| k.is_a?(Symbol) && v.is_a?(Symbol) }
          raise TypeError, "auto_references must be a Hash containing Symbol keys and values"
        end
        raise ArgumentError, "factory must be provided" unless factory

        compatible_types = [name] + compatible_types unless compatible_types.include? name

        @name = name
        @compatible_types = Set.new(compatible_types).freeze
        @auto_references = auto_references.freeze
        @factory = factory
      end

      # A special type that represents values computed from other objects.
      COMPUTED = Type.new(:_computed) { |_, _, arg| arg }
    end
  end
end
