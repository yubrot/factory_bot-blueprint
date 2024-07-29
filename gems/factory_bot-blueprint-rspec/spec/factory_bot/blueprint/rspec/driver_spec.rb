# frozen_string_literal: true

RSpec.describe FactoryBot::Blueprint::RSpec::Driver do
  describe "#let_blueprint" do
    let(:user_name) { "John" }

    let_blueprint(:foo) do
      let.user(name: ext.user_name) { let.blog }
    end

    it "works as a shorthand method for ::FactoryBot::Blueprint.plan" do
      expect(foo).to be_a Factrey::Blueprint
      expect(foo.nodes[:user]).to have_attributes(kwargs: { name: "John" })
    end

    describe "inherit: true" do
      let_blueprint(:foo, inherit: true) do
        on.blog(title: "Inherited")
      end

      it "extends a blueprint obtained from super()" do
        expect(foo.nodes).to include(
          user: have_attributes(kwargs: { name: "John" }),
          blog: have_attributes(kwargs: { title: "Inherited" }),
        )
      end
    end
  end

  describe "#let_blueprint_build" do
    let_blueprint(:source) do
      user(name: "User 1")
      user(name: "User 2") do
        let.blog(title: "User 2 Blog") do
          let.article(title: "Article 1")
          article(title: "Article 2")
        end
      end
    end

    context "with symbol definition" do
      let_blueprint_build(source: :built)

      it "declares objects" do
        expect(built).to have_attributes(name: "User 2")
      end
    end

    context "with array definition" do
      let_blueprint_build(source: %i[blog article])

      it "declares objects" do
        expect(blog).to have_attributes(title: "User 2 Blog")
        expect(article).to have_attributes(title: "Article 1")
      end
    end

    context "with hash definition" do
      let_blueprint_build(source: { result: :built, items: %i[blog article], instance: :instance })

      it "declares objects" do
        expect(instance[1]).to include(blog:, article:)
        expect(built).to have_attributes(name: "User 2")
        expect(blog).to have_attributes(title: "User 2 Blog", user: built)
        expect(article).to have_attributes(title: "Article 1", blog:)
      end
    end
  end

  describe "#let_blueprint_create" do
    it "is variation of #let_blueprint_build"
  end

  describe "#letbp" do
    letbp(:user, %i[blog article], strategy: :build) do
      user(name: "User 1")
      user(name: "User 2") do
        let.blog(title: "User 2 Blog") do
          let.article(title: "Article 1")
          article(title: "Article 2")
        end
      end
    end

    it "delcares a blueprint and objects" do
      expect(user_blueprint).to be_a Factrey::Blueprint
      expect(user_blueprint_instance[1]).to include(blog:, article:)
      expect(user).to have_attributes(name: "User 2")
      expect(blog).to have_attributes(title: "User 2 Blog", user:)
      expect(article).to have_attributes(title: "Article 1", blog:)
    end

    describe "inherit: true" do
      letbp(:user, %i[article2], inherit: true) do
        on.blog do
          let(:article2).article(title: "Article 3")
        end
      end

      it "extends a blueprint and declares objects" do
        expect(user_blueprint_instance[1]).to include(blog:, article:, article2:)
        expect(blog).to have_attributes(title: "User 2 Blog", user:)
        expect(article2).to have_attributes(title: "Article 3", blog:)
      end
    end
  end
end
