# frozen_string_literal: true

# This module contains data types and factories for testing this gem.
module Test
  # TESTING aliases
  User = Struct.new(:name)
  Blog = Struct.new(:title, :user)
  Article = Struct.new(:title, :blog)
  Comment = Struct.new(:text, :article)

  FactoryBot.define do
    factory(:user, class: "Test::User")
    factory(:blog, class: "Test::Blog") { user }
    factory(:article, class: "Test::Article") { blog }
    factory(:comment, class: "Test::Comment") { article }
  end
end
