# frozen_string_literal: true

require "factrey"
require "factory_bot"
require_relative "blueprint/version"
require_relative "blueprint/dsl"
require_relative "blueprint/methods"

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
      #   # Create a set of objects in FactoryBot (with `build` build strategy) from the blueprint:
      #   objects = FactoryBot::Blueprint.build(bp)
      #
      #   # This behaves as:
      #   objects = {}
      #   objects[:blog] = blog = FactoryBot.build(:blog)
      #   objects[random_anon_sym] = FactoryBot.build(:article, title: "Article 1", blog:)
      #   objects[random_anon_sym] = FactoryBot.build(:article, title: "Article 2", blog:)
      #   objects[random_anon_sym] = article3 = FactoryBot.build(:article, title: "Article 3", blog:)
      #   objects[random_anon_sym] = FactoryBot.build(:comment, name: "John", article: article3)
      #   objects[random_anon_sym] = FactoryBot.build(:comment, name: "Doe", article: article3)
      #   objects[Factrey::Blueprint::Node::RESULT_NAME] = blog
      def plan(blueprint = nil, ext: nil, &) = Factrey.blueprint(blueprint, ext:, dsl: DSL, &)

      # Create a set of objects by <code>build</code> build strategy in FactoryBot.
      # See {.plan} for more details.
      # @param blueprint [Factrey::Blueprint, nil]
      # @param ext [Object] an external object that can be accessed using {DSL#ext} in the DSL
      # @yield Write Blueprint DSL code here
      # @return [Hash{Symbol => Object}] the created objects
      def build(blueprint = nil, ext: nil, &) = instantiate(:build, blueprint, ext:, &)

      # Create a set of objects by <code>build_stubbed</code> build strategy in FactoryBot.
      # See {.plan} for more details.
      # @param blueprint [Factrey::Blueprint, nil]
      # @param ext [Object] an external object that can be accessed using {DSL#ext} in the DSL
      # @yield Write Blueprint DSL code here
      # @return [Hash{Symbol => Object}] the created objects
      def build_stubbed(blueprint = nil, ext: nil, &) = instantiate(:build_stubbed, blueprint, ext:, &)

      # Create a set of objects by <code>create</code> build strategy in FactoryBot.
      # See {.plan} for more details.
      # @param blueprint [Factrey::Blueprint, nil]
      # @param ext [Object] an external object that can be accessed using {DSL#ext} in the DSL
      # @yield Write Blueprint DSL code here
      # @return [Hash{Symbol => Object}] the created objects
      def create(blueprint = nil, ext: nil, &) = instantiate(:create, blueprint, ext:, &)

      # @!visibility private
      def instantiate(build_strategy, blueprint = nil, ext: nil, &)
        unless %i[create build build_stubbed].include?(build_strategy)
          raise ArgumentError, "Unsupported build strategy: #{build_strategy}"
        end

        plan(blueprint, ext:, &).instantiate(build_strategy:)
      end
    end
  end
end
