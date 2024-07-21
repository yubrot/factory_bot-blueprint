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
        expect(subject.values).to eq []
      end
    end

    context "with a node" do
      subject { build { user } }

      it "creates a object" do
        expect(subject.values).to eq [
          Test::User.new,
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
            let(:user_profile).profile
            let(:user_post).post
            let(:user_comment).comment
          end
          let.author(name: "B") do
            let(:author_profile).profile
            let(:author_post).post
            let(:author_comment).comment
          end
          let.commenter(name: "C") do
            let(:commenter_profile).profile
            let(:commenter_post).post
            let(:commenter_comment).comment
          end
        end
      end

      it "is not considered to be compatible with aliases (behaves as inherited factories)" do
        expect(subject).to include(
          user: Test::User.new(name: "A"),
          user_post: Test::Post.new(author: Test::User.new),
          user_comment: Test::Comment.new(commenter: Test::User.new),
          author: Test::User.new(name: "B"),
          author_post: Test::Post.new(author: subject[:author]),
          author_comment: Test::Comment.new(commenter: Test::User.new),
          commenter: Test::User.new(name: "C"),
          commenter_post: Test::Post.new(author: Test::User.new),
          commenter_comment: Test::Comment.new(commenter: subject[:commenter]),
        )
      end

      it "is considered to be compatible with the base type" do
        expect(subject).to include(
          user_profile: Test::Profile.new(user: subject[:user]),
          author_profile: Test::Profile.new(user: subject[:author]),
          commenter_profile: Test::Profile.new(user: subject[:commenter]),
        )
      end
    end

    context "with FactoryBot parents and same type associations" do
      subject do
        build do
          let.rgb(code: "red") { let(:rgb_grad).gradient }
          let.rgba(code: "blue") { let(:rgba_grad).gradient }
        end
      end

      it "is considered to be compatible with the base type and the first association takes precedence" do
        expect(subject).to include(
          rgb: Test::RGB.new(code: "red"),
          rgb_grad: Test::Gradient.new(from: subject[:rgb], to: Test::RGB.new),
          rgba: Test::RGBA.new(code: "blue"),
          rgba_grad: Test::Gradient.new(from: subject[:rgba], to: Test::RGB.new),
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
        expect(subject).to include(
          video: Test::Video.new(title: "A"),
          video_photo: Test::Photo.new(title: "A-1"),
          video_video: Test::Video.new(title: "A-2"),
          photo: Test::Photo.new(title: "B"),
          photo_photo: Test::Photo.new(title: "B-1"),
          photo_video: Test::Video.new(title: "B-2"),
          video_tag: Test::Tag.new(taggable: subject[:video]),
          video_photo_tag: Test::Tag.new(taggable: subject[:video_photo]),
          video_video_tag: Test::Tag.new(taggable: subject[:video_video]),
          photo_tag: Test::Tag.new(taggable: subject[:photo]),
          photo_photo_tag: Test::Tag.new(taggable: subject[:photo_photo]),
          photo_video_tag: Test::Tag.new(taggable: subject[:photo_video]),
        )
      end
    end
  end

  describe ".create" do
    it "is a variation of .build"
  end
end
