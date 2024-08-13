# frozen_string_literal: true

# This module contains data types and factories for testing this gem.
module Test
  # TESTING aliases
  User = Struct.new(:name, keyword_init: true)
  Post = Struct.new(:title, :author, keyword_init: true)
  Comment = Struct.new(:text, :commenter, keyword_init: true)
  Account = Struct.new(:user, keyword_init: true)

  FactoryBot.define do
    factory(:user, class: "Test::User", aliases: %i[author commenter])
    factory(:post, class: "Test::Post") { author }
    factory(:comment, class: "Test::Comment") { commenter }
    factory(:account, class: "Test::Account") { user }
  end

  # TESTING parent
  Color = Struct.new(:code, keyword_init: true)
  Gradient = Struct.new(:from, :to, keyword_init: true)

  FactoryBot.define do
    factory(:color, class: "Test::Color") do
      factory(:white) { code { "white" } }
    end
    factory(:gradient, class: "Test::Gradient") do
      from factory: :color
      to factory: :color # TESTING same type
    end
  end

  # TESTING auto_complete
  Customer = Struct.new(:id, :plan, keyword_init: true)
  CustomerProfile = Struct.new(:name, :customer, keyword_init: true)

  FactoryBot.define do
    factory(:customer, class: "Test::Customer") do
      factory(:premium_customer) { plan { "premium" } }
    end
    factory(:customer_profile, class: "Test::CustomerProfile") { customer }
  end

  # TESTING traits
  Video = Struct.new(:title, keyword_init: true)
  Photo = Struct.new(:title, keyword_init: true)
  Tag = Struct.new(:taggable, keyword_init: true)

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
  Student = Struct.new(:school, :profile, :name, keyword_init: true)
  Profile = Struct.new(:school, :student, :name, keyword_init: true)
  School = Struct.new(:name, keyword_init: true)

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
