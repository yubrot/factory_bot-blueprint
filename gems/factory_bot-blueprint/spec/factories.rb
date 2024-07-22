# frozen_string_literal: true

# This module contains data types and factories for testing this gem.
module Test
  # TESTING aliases
  User = Struct.new(:name)
  Post = Struct.new(:title, :author)
  Comment = Struct.new(:text, :commenter)
  Account = Struct.new(:user)

  FactoryBot.define do
    factory(:user, class: "Test::User", aliases: %i[author commenter])
    factory(:post, class: "Test::Post") { author }
    factory(:comment, class: "Test::Comment") { commenter }
    factory(:account, class: "Test::Account") { user }
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

  # TESTING inline associations
  Student = Struct.new(:school, :profile, :name)
  Profile = Struct.new(:school, :student, :name)
  School = Struct.new(:name)

  FactoryBot.define do
    factory :student, class: "Test::Student" do
      school
      profile { association :profile, student: instance, school: }
    end

    factory :profile, class: "Test::Profile" do
      school
      student { association :student, profile: instance, school: }
    end

    factory :school, class: "Test::School"
  end
end
