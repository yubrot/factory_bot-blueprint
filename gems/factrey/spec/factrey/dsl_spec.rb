# frozen_string_literal: true

RSpec.describe Factrey::DSL do
  def factory = ->(type, context, *args, **kwargs) { [context[:strategy], type.name, *args, kwargs] }

  # Some example types for tests
  let(:user) { Factrey::Blueprint::Type.new(:user, &factory) }
  let(:blog) { Factrey::Blueprint::Type.new(:blog, auto_references: :author, &factory) }
  let(:post) { Factrey::Blueprint::Type.new(:post, auto_references: :blog, &factory) }
  let(:comment) { Factrey::Blueprint::Type.new(:comment, auto_references: { post: :post, user: :commenter }, &factory) }

  # Make the subclass to avoid polluting global space
  let(:dsl) { Class.new(described_class) }

  describe ".add_type" do
    subject { dsl.add_type type }

    let(:type) { user }

    it "adds the type and define a helper method for DSL" do
      expect { subject }.not_to raise_error
      expect(dsl.types).to include type.name
      expect(dsl).to be_method_defined type.name
    end

    context "when the type has already been added" do
      before { dsl.add_type type }

      it "succeeds without doing anything" do
        expect { subject }.not_to raise_error
      end
    end

    context "when a type with the same name has been added" do
      before { dsl.add_type type_with_same_name }

      let(:type_with_same_name) { Factrey::Blueprint::Type.new(:user, &factory) }

      it "fails with an error" do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context "when the type has a name reserved by DSL" do
      let(:type) { Factrey::Blueprint::Type.new(:let, &factory) }

      it "fails with an error" do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end

  describe "Blueprint DSL" do
    def blueprint(blueprint = nil, &) = Factrey.blueprint(blueprint, dsl:, ext:, &)

    let(:ext) { nil }

    before { [user, blog, post, comment].each { dsl.add_type _1 } }

    describe "results" do
      subject { blueprint { 123 } }

      it "defines the result" do
        expect(subject.result).to eq 123
      end

      context "when the blueprint is extended" do
        subject { blueprint(blueprint { 123 }) { 456 } }

        it "does not overwrite the result" do
          expect(subject.result).to eq 123
        end
      end
    end

    describe "#node" do
      # We use #node through helper methods defined by .add_type
      subject { blueprint { user } }

      it "adds a node" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(
            name: start_with("_anon_"),
            type: user,
            ancestors: [],
            args: [],
            kwargs: {},
          ),
        ]
      end

      context "with multiple declarations and arguments" do
        subject do
          blueprint do
            user(123)
            user(foo: 456)
            user
          end
        end

        it "adds as many nodes as declared" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(args: [123]),
            have_attributes(kwargs: { foo: 456 }),
            have_attributes(args: [], kwargs: {}),
          ]
        end
      end

      context "with nested declarations" do
        subject do
          blueprint do
            user(1) do
              user(2) do
                user(3)
                user(4)
              end
            end
          end
        end

        it "adds nodes and nodes ancestors reflects structures" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(args: [1], ancestors: []),
            have_attributes(args: [2], ancestors: [0].map { subject.nodes.values[_1] }),
            have_attributes(args: [3], ancestors: [0, 1].map { subject.nodes.values[_1] }),
            have_attributes(args: [4], ancestors: [0, 1].map { subject.nodes.values[_1] }),
          ]
        end
      end

      context "with block arguments and return values" do
        subject do
          blueprint do
            user(1) do |user1|
              user2 = user(2, user: user1)
              user(3, user: user2)
            end
          end
        end

        it "adds nodes and nodes ancestors reflects structures" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(args: [1], kwargs: {}),
            have_attributes(args: [2], kwargs: { user: subject.nodes.values[0].to_ref }),
            have_attributes(args: [3], kwargs: { user: subject.nodes.values[1].to_ref }),
          ]
        end
      end
    end

    describe "#ext" do
      subject { blueprint { user(name: ext) } }

      let(:ext) { "FOO" }

      it "returns an object set at Factrey.blueprint" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(kwargs: { name: "FOO" }),
        ]
      end
    end

    describe "#let" do
      subject do
        blueprint do
          user
          let.user
          let(:author).user
        end
      end

      it "gives names to nodes" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(name: start_with("_anon_")),
          have_attributes(name: :user),
          have_attributes(name: :author),
        ]
      end

      context "when there is a duplication" do
        subject do
          blueprint do
            let.user
            let.user
          end
        end

        it "is an error" do
          expect { subject }.to raise_error ArgumentError
        end
      end

      context "when let is used without node declaration" do
        subject do
          blueprint do
            let { nil }
            user
          end
        end

        # NOTE: Should we issue some kind of warning?
        it "does not affect other declarations" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(name: start_with("_anon_")),
          ]
        end
      end

      context "when let is used with multiple node declarations" do
        subject do
          blueprint do
            let(:foo) do
              user
              user
            end
          end
        end

        # NOTE: Should we issue some kind of warning?
        it "is only applied to the first declaration" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(name: :foo),
            have_attributes(name: start_with("_anon_")),
          ]
        end
      end

      context "when let is nested" do
        subject { blueprint { let.let.user } }

        it "is an error" do
          expect { subject }.to raise_error ArgumentError
        end
      end
    end

    describe "#on" do
      subject do
        blueprint do
          let.user
          on(:user, 12, 34)
          on(:user, 56, hello: "world")
          on(:user) { let(:user2).user }
        end
      end

      it "alters the node resolved by name" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(
            name: :user,
            args: [12, 34, 56],
            kwargs: { hello: "world" },
          ),
          have_attributes(
            name: :user2,
            ancestors: [subject.nodes[:user]],
          ),
        ]
      end

      context "when #on is used in another block" do
        subject do
          blueprint do
            let.user
            let(:user2).user do
              let(:user3).user
              on(:user) { let(:user4).user }
              let(:user5).user
            end
          end
        end

        it "does not affect ancestors outside block" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(name: :user, ancestors: []),
            have_attributes(name: :user2, ancestors: []),
            have_attributes(name: :user3, ancestors: [subject.nodes[:user2]]),
            have_attributes(name: :user4, ancestors: [subject.nodes[:user]]),
            have_attributes(name: :user5, ancestors: [subject.nodes[:user2]]),
          ]
        end
      end

      context "with unknown node name" do
        subject { blueprint { on(:unkown) } }

        it "is an error" do
          expect { subject }.to raise_error ArgumentError
        end
      end
    end

    describe "#args" do
      subject do
        blueprint do
          user(:foo) do
            args :bar
            args :baz, key: "value"
          end
        end
      end

      it "adds arguments to the current node" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(
            args: %i[foo bar baz],
            kwargs: { key: "value" },
          ),
        ]
      end
    end
  end
end
