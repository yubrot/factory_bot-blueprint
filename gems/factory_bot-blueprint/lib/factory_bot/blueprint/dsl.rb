# frozen_string_literal: true

module FactoryBot
  module Blueprint
    # A declarative DSL for building {Factrey::Blueprint}.
    # This DSL automatically recognizes factories defined in FactoryBot as types.
    class DSL < Factrey::DSL
      # Internals:
      # Here we rely on some of FactoryBot's internal APIs.
      # We would like to minimize these dependencies as much as possible.

      # @!visibility private
      def respond_to_missing?(type_name, _)
        FactoryBot.factories.registered? type_name
      end

      def method_missing(type_name, ...)
        raise NoMethodError, "Unknown type #{type_name}" unless FactoryBot.factories.registered? type_name

        factory = FactoryBot.factories.find(type_name)
        self.class.add_type(self.class.type_from_factory_bot_factory(type_name, factory))
        __send__(type_name, ...)
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

        FACTORY = lambda { |type, context, *args, **kwargs|
          FactoryBot.__send__(context[:strategy], type.name, *args, **kwargs)
        }

        private_constant :FACTORY
      end
    end
  end
end
