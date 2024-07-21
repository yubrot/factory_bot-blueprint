# frozen_string_literal: true

require_relative "factrey/version"
require_relative "factrey/ref"
require_relative "factrey/blueprint"
require_relative "factrey/dsl"

# Factrey provides a declarative DSL to represent the creation plan of objects.
module Factrey
  class << self
    # Entry point to build or extend a {Blueprint}.
    # @param blueprint [Blueprint, nil] to extend an existing blueprint
    # @param ext [Object] an external object that can be accessed using {DSL#ext} in the DSL
    # @param dsl [Class<DSL>] which DSL is used
    # @yield Write Blueprint DSL code here. See {DSL} methods for DSL details
    # @return [Blueprint] the built or extended blueprint
    # @example
    #   bp =
    #     Factrey.blueprint do
    #       let.blog do
    #         article(title: "Article 1", body: "...")
    #         article(title: "Article 2", body: "...")
    #         article(title: "Article 3", body: "...") do
    #           comment(name: "John", body: "...")
    #           comment(name: "Doe", body: "...")
    #         end
    #       end
    #     end
    #
    #   instance = bp.instantiate
    #   # This creates...
    #   # - a blog (can be accessed by `instance[:blog]`)
    #   # - with three articles
    #   # - and two comments to the last article
    def blueprint(blueprint = nil, ext: nil, dsl: DSL, &)
      raise TypeError, "blueprint must be a Blueprint" if blueprint && !blueprint.is_a?(Blueprint)
      raise TypeError, "dsl must be a subclass of DSL" unless dsl <= DSL

      blueprint ||= Blueprint.new
      dsl.new(blueprint:, ext:).instance_exec(&) if block_given?
      blueprint
    end
  end
end
