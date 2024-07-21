# frozen_string_literal: true

# This module contains data types and factories for testing this gem.
module Test
  # TESTING aliases
  User = Struct.new(:name)
  Post = Struct.new(:title, :author)
  Comment = Struct.new(:text, :commenter)
  Profile = Struct.new(:user)

  FactoryBot.define do
    factory(:user, class: "Test::User", aliases: %i[author commenter])
    factory(:post, class: "Test::Post") { author }
    factory(:comment, class: "Test::Comment") { commenter }
    factory(:profile, class: "Test::Profile") { user }
  end

  # TESTING parent
  RGB = Struct.new(:code)
  RGBA = Struct.new(:code, :opacity)
  Gradient = Struct.new(:from, :to)

  FactoryBot.define do
    factory(:rgb, class: "Test::RGB")
    factory(:rgba, class: "Test::RGBA", parent: :rgb)
    factory(:gradient, class: "Test::Gradient") do
      from factory: :rgb
      to factory: :rgb # TESTING same type
    end
  end

  # TESTING traits
  Video = Struct.new(:title)
  Photo = Struct.new(:title)
  Tag = Struct.new(:taggable)

  FactoryBot.define do
    factory(:video, class: "Test::Video")
    factory(:photo, class: "Test::Photo")
    factory(:tag, class: "Test::Tag") do
      trait :for_video do
        taggable factory: :video
      end

      trait :for_photo do
        taggable factory: :photo # TESTING same attribute
      end
    end
  end
end
