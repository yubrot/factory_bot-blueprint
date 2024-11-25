# frozen_string_literal: true

RSpec.describe FactoryBot::Blueprint::RSpec::Driver do
  describe "#letbp" do
    describe "#build" do
      letbp(:user, %i[blog article]).build do
        user(name: "User 1")
        user(name: "User 2") do
          let.blog(title: "User 2 Blog") do
            let.article(title: "Article 1")
            article(title: "Article 2")
          end
        end
      end

      it "delcares a new blueprint and objects" do
        expect(_letbp_user_blueprint).to be_a Factrey::Blueprint
        expect(_letbp_user_instance).to include(blog:, article:)
        expect(user).to have_attributes(name: "User 2")
        expect(blog).to have_attributes(title: "User 2 Blog", user:)
        expect(article).to have_attributes(title: "Article 1", blog:)
      end

      describe "#inherit" do
        letbp(:user, %i[article2]).inherit do
          on.blog do
            let.article2 = article(title: "Article 3")
          end
        end

        it "extends a blueprint and declares objects" do
          expect(_letbp_user_instance).to include(blog:, article:, article2:)
          expect(blog).to have_attributes(title: "User 2 Blog", user:)
          expect(article2).to have_attributes(title: "Article 3", blog:)
        end
      end
    end

    describe "#build_from" do
      letbp(:user).build_from { user_blueprint }
      let(:user_blueprint) { bp.plan { user(name: "User 1") } }

      it "delcares a blueprint using existing one and objects" do
        expect(_letbp_user_blueprint).to eq user_blueprint
        expect(user).to have_attributes(name: "User 1")
      end
    end

    describe "#build_stubbed and #create" do
      it "is a variation of #build"
    end

    describe "#build_stubbed_from and #create_from" do
      it "is a variation of #build_from"
    end
  end

  describe "#letbp!" do
    let(:user_name) { { value: "John" } }

    letbp(:foo).build { user(name: ext.user_name[:value]) }
    letbp!(:bar).build { user(name: ext.user_name[:value]) }

    it "is evaluated before tests" do
      user_name[:value] = "Jane"

      expect(foo).to have_attributes(name: "Jane")
      expect(bar).to have_attributes(name: "John")
    end
  end

  describe "#letbp_it_be" do
    let_it_be(:user_name) { { value: "Tom" } }

    before { user_name[:value] = "Doe" }

    letbp!(:foo).build { user(name: ext.user_name[:value]) }
    letbp_it_be(:bar).build { user(name: ext.user_name[:value]) }

    it "is evaluated before all tests" do
      expect(foo).to have_attributes(name: "Doe")
      expect(bar).to have_attributes(name: "Tom")
    end
  end
end
