# frozen_string_literal: true

# This module contains data types and factories for testing this gem.
module Test
  # TESTING aliases
  User = Struct.new(:name, keyword_init: true)
  Blog = Struct.new(:title, :user, keyword_init: true)
  Article = Struct.new(:title, :blog, keyword_init: true)
  Comment = Struct.new(:text, :article, keyword_init: true)

  FactoryBot.define do
    factory(:user, class: "Test::User")
    factory(:blog, class: "Test::Blog") { user }
    factory(:article, class: "Test::Article") { blog }
    factory(:comment, class: "Test::Comment") { article }
  end
end
