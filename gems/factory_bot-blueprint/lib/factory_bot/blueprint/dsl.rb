# frozen_string_literal: true

module FactoryBot
  module Blueprint
    # A declarative DSL for building {https://rubydoc.info/gems/factrey/Factrey/Blueprint Factrey::Blueprint}.
    # This DSL automatically recognizes factories defined in FactoryBot as types.
    class DSL < Factrey::DSL
      # Internals:
      # Here we rely on some of FactoryBot's internal APIs.
      # We would like to minimize these dependencies as much as possible.

      # @!visibility private
      def respond_to_missing?(name, _)
        _autocompleted_method_names(name).any? do |method_name|
          self.class.method_defined?(method_name) || FactoryBot.factories.registered?(method_name)
        end
      end

      def method_missing(name, ...)
        _autocompleted_method_names(name).each do |method_name|
          if self.class.method_defined?(method_name)
            return __send__(method_name, ...)
          elsif FactoryBot.factories.registered?(method_name)
            factory = FactoryBot.factories.find(method_name)
            self.class.add_type(self.class.type_from_factory_bot_factory(method_name, factory))
            return __send__(method_name, ...)
          end
        end

        raise NoMethodError,
              "Undefined method `#{name}' for #{self} and cannot be resolved from FactoryBot factories"
      end

      private

      def _autocompleted_method_names(name)
        return enum_for(__method__, name) unless block_given?

        @ancestors.reverse_each do |ancestor|
          ancestor.type.compatible_types.each do |ancestor_type|
            yield :"#{ancestor_type}_#{name}"
          end
        end
        yield name
      end

      class << self
        # @!visibility private
        def type_from_factory_bot_factory(type_name, factory)
          # NOTE: We consider aliases to be incompatible with each other
          compatible_types = []
          auto_references = {}

          while factory.is_a?(FactoryBot::Factory)
            compatible_types << factory.name
            # Here, we use reverse_each to prioritize the upper association
            factory.with_traits(factory.defined_traits.map(&:name)).associations.reverse_each do |assoc|
              auto_references[Array(assoc.factory)[0].to_sym] = assoc.name
            end

            factory = factory.__send__(:parent)
          end

          Factrey::Blueprint::Type.new(type_name, compatible_types:, auto_references:, &FACTORY)
        end

        FACTORY = lambda do |type, context, *args, **kwargs|
          FactoryBot.__send__(context[:build_strategy], type.name, *args, **kwargs)
        end

        private_constant :FACTORY
      end
    end
  end
end
