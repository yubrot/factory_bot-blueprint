# frozen_string_literal: true

require "factrey"
require "factory_bot"
require_relative "blueprint/version"
require_relative "blueprint/dsl"

module FactoryBot
  # A FactoryBot extension for building structured objects using a declarative DSL.
  # First we can build (or extend) a creation plan for a set of objects as <code>Blueprint</code>,
  # and then we can create actual objects from it.
  #
  # <code>Blueprint</code>s can be built using a declarative DSL provided by a core library called {Factrey}.
  # Each node declaration in the DSL code is automatically correspond to the FactoryBot's factory. For example,
  # a declaration <code>user(name: 'John')</code> corresponds to <code>FactoryBot.create(:user, name: 'John')</code>.
  module Blueprint
    class << self
      # Entry point to build or extend a {Factrey::Blueprint}.
      # @param blueprint [Factrey::Blueprint, nil] to extend an existing blueprint
      # @param ext [Object] an external object that can be accessed using {DSL#ext} in the DSL
      # @yield Write Blueprint DSL code here. See {Factrey::DSL} methods for DSL details
      # @return [Factrey::Blueprint] the built or extended blueprint
      # @example
      #   # In this example, we have three factories in FactoryBot:
      #   FactoryBot.define do
      #     factory(:blog)
      #     factory(:article) { association :blog }
      #     factory(:comment) { association :article }
      #   end
      #
      #   bp =
      #     FactoryBot::Blueprint.plan do
      #       let.blog do
      #         article(title: "Article 1")
      #         article(title: "Article 2")
      #         article(title: "Article 3") do
      #           comment(name: "John")
      #           comment(name: "Doe")
      #         end
      #       end
      #     end
      #
      #   # Create a set of objects in FactoryBot (with `build` strategy) from the blueprint:
      #   instance = FactoryBot::Blueprint.build(bp)
      #
      #   # This behaves as:
      #   instance = {}
      #   instance[:blog] = blog = FactoryBot.build(:blog)
      #   instance[gen_random_sym] = FactoryBot.build(:article, title: "Article 1", blog:)
      #   instance[gen_random_sym] = FactoryBot.build(:article, title: "Article 2", blog:)
      #   instance[gen_random_sym] = article3 = FactoryBot.build(:article, title: "Article 3", blog:)
      #   instance[gen_random_sym] = FactoryBot.build(:comment, name: "John", article: article3)
      #   instance[gen_random_sym] = FactoryBot.build(:comment, name: "Doe", article: article3)
      def plan(blueprint = nil, ext: nil, &) = Factrey.blueprint(blueprint, ext:, dsl: DSL, &)

      # Create a set of objects by <code>build</code> strategy in FactoryBot.
      # See {.plan} for more details.
      # @param blueprint [Factrey::Blueprint, nil]
      # @param ext [Object] an external object that can be accessed using {DSL#ext} in the DSL
      # @yield Write Blueprint DSL code here
      # @return [Hash{Symbol => Object}]
      def build(blueprint = nil, ext: nil, &) = instantiate(:build, blueprint, ext:, &)

      # Create a set of objects by <code>create</code> strategy in FactoryBot.
      # See {.plan} for more details.
      # @param blueprint [Factrey::Blueprint, nil]
      # @param ext [Object] an external object that can be accessed using {DSL#ext} in the DSL
      # @yield Write Blueprint DSL code here
      # @return [Hash{Symbol => Object}]
      def create(blueprint = nil, ext: nil, &) = instantiate(:create, blueprint, ext:, &)

      # @!visibility private
      def instantiate(strategy, blueprint = nil, ext: nil, &)
        raise ArgumentError, "Unsupported strategy: #{strategy}" unless %i[create build].include?(strategy)

        plan(blueprint, ext:, &).instantiate(strategy:)
      end
    end
  end
end
