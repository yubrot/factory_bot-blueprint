# frozen_string_literal: true

RSpec.describe FactoryBot::Blueprint do
  it "has the same version number with factrey" do
    expect(FactoryBot::Blueprint::VERSION).to eq Factrey::VERSION
  end

  describe ".plan" do
    it "is covered in .build tests"
  end

  describe ".build" do
    def build(&) = described_class.build(&)

    context "with an empty blueprint" do
      subject { build }

      it "creates no objects" do
        expect(subject).to eq [nil, {}]
      end
    end

    context "with a node" do
      subject { build { user } }

      it "creates a object and the object is used as a result" do
        expect(subject[0]).to eq subject[1].values.first
        expect(subject[1].values).to eq [
          Test::User.new,
        ]
      end
    end

    context "with multiple nodes" do
      subject do
        build do
          user(name: "A")
          user(name: "B")
          user(name: "C")
        end
      end

      it "creates objects and the last object is used as a result" do
        expect(subject[0]).to eq subject[1].values.last
        expect(subject[1].values).to eq [
          Test::User.new(name: "A"),
          Test::User.new(name: "B"),
          Test::User.new(name: "C"),
        ]
      end
    end

    context "with an unknown factory" do
      subject { build { unknown } }

      it "is an error" do
        expect { subject }.to raise_error NoMethodError
      end
    end

    context "with FactoryBot aliases" do
      subject do
        build do
          let.user(name: "A") do
            let(:user_account).account
            let(:user_post).post
            let(:user_comment).comment
          end
          let.author(name: "B") do
            let(:author_account).account
            let(:author_post).post
            let(:author_comment).comment
          end
          let.commenter(name: "C") do
            let(:commenter_account).account
            let(:commenter_post).post
            let(:commenter_comment).comment
          end
        end
      end

      it "is not considered to be compatible with aliases (behaves as inherited factories)" do
        expect(subject[1]).to include(
          user: Test::User.new(name: "A"),
          user_post: Test::Post.new(author: Test::User.new),
          user_comment: Test::Comment.new(commenter: Test::User.new),
          author: Test::User.new(name: "B"),
          author_post: Test::Post.new(author: subject[1][:author]),
          author_comment: Test::Comment.new(commenter: Test::User.new),
          commenter: Test::User.new(name: "C"),
          commenter_post: Test::Post.new(author: Test::User.new),
          commenter_comment: Test::Comment.new(commenter: subject[1][:commenter]),
        )
      end

      it "is considered to be compatible with the base type" do
        expect(subject[1]).to include(
          user_account: Test::Account.new(user: subject[1][:user]),
          author_account: Test::Account.new(user: subject[1][:author]),
          commenter_account: Test::Account.new(user: subject[1][:commenter]),
        )
      end
    end

    context "with FactoryBot parents and same type associations" do
      subject do
        build do
          let.color(code: "red") { let(:color_grad).gradient }
          let.white { let(:white_grad).gradient }
        end
      end

      it "is considered to be compatible with the base type and the first association takes precedence" do
        expect(subject[1]).to include(
          color: Test::Color.new(code: "red"),
          color_grad: Test::Gradient.new(from: subject[1][:color], to: Test::Color.new),
          white: Test::Color.new(code: "white"),
          white_grad: Test::Gradient.new(from: subject[1][:white], to: Test::Color.new),
        )
      end
    end

    context "with FactoryBot parents and autocompletion" do
      subject do
        build do
          let.customer(id: 1) { let.profile(name: "John") }
          let.premium_customer(id: 2) { let(:premium_customer_profile).profile(name: "Doe") }
        end
      end

      it "autocompletes the type names from ancestors" do
        expect(subject[1]).to include(
          customer: Test::Customer.new(id: 1),
          profile: Test::CustomerProfile.new(customer: subject[1][:customer], name: "John"),
          premium_customer: Test::Customer.new(id: 2, plan: "premium"),
          premium_customer_profile: Test::CustomerProfile.new(customer: subject[1][:premium_customer], name: "Doe"),
        )
      end
    end

    context "with FactoryBot traits and same field associations" do
      subject do
        build do
          let.video(title: "A") do
            let(:video_tag).tag
            let(:video_photo).photo(title: "A-1") { let(:video_photo_tag).tag }
            let(:video_video).video(title: "A-2") { let(:video_video_tag).tag }
          end
          let.photo(title: "B") do
            let(:photo_tag).tag
            let(:photo_photo).photo(title: "B-1") { let(:photo_photo_tag).tag }
            let(:photo_video).video(title: "B-2") { let(:photo_video_tag).tag }
          end
        end
      end

      it "knows the possible associations and the nearest ancestor takes precedence" do
        expect(subject[1]).to include(
          video: Test::Video.new(title: "A"),
          video_photo: Test::Photo.new(title: "A-1"),
          video_video: Test::Video.new(title: "A-2"),
          photo: Test::Photo.new(title: "B"),
          photo_photo: Test::Photo.new(title: "B-1"),
          photo_video: Test::Video.new(title: "B-2"),
          video_tag: Test::Tag.new(taggable: subject[1][:video]),
          video_photo_tag: Test::Tag.new(taggable: subject[1][:video_photo]),
          video_video_tag: Test::Tag.new(taggable: subject[1][:video_video]),
          photo_tag: Test::Tag.new(taggable: subject[1][:photo]),
          photo_photo_tag: Test::Tag.new(taggable: subject[1][:photo_photo]),
          photo_video_tag: Test::Tag.new(taggable: subject[1][:photo_video]),
        )
      end
    end

    context "with FactoryBot inline associations" do
      subject do
        build do
          let.school(name: "S") do
            let(:a).student(name: "A")
            let(:b).profile(name: "B")
            let(:c).student(name: "C") { let(:cp).profile(name: "CP") }
          end
        end
      end

      it "resolves associations" do
        expect(subject[1]).to include(
          a: have_attributes(
            school: subject[1][:school],
            profile: have_attributes(school: subject[1][:school], student: subject[1][:a]),
          ),
          b: have_attributes(
            school: subject[1][:school],
            student: have_attributes(school: subject[1][:school], profile: subject[1][:b]),
          ),
        )
      end

      it "resolves inline associations" do
        skip "inline associations are unsupported for now"
        expect(subject[1]).to include(
          cp: have_attributes(school: subject[1][:school], student: subject[1][:c]),
          # NOTE: Even if we could handle inline associations correctly,
          # it would be difficult to prevent profiles from being created here:
          c: have_attributes(school: subject[1][:school], profile: subject[1][:cp]),
        )
      end
    end
  end

  describe ".create" do
    it "is a variation of .build"
  end
end
