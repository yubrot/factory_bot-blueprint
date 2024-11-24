# frozen_string_literal: true

RSpec.describe Factrey::DSL do
  def factory = ->(type, context, *args, **kwargs) { [context[:build_strategy], type.name, *args, kwargs] }

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
        expect(subject.resolve_node(:_result_)).to have_attributes(
          type: Factrey::Blueprint::Type::COMPUTED,
          args: [123],
        )
      end

      context "when the blueprint is extended" do
        subject { blueprint(blueprint { 123 }) { 456 } }

        it "does not overwrite the result" do
          expect(subject.resolve_node(:_result_)).to have_attributes(
            type: Factrey::Blueprint::Type::COMPUTED,
            args: [123],
          )
        end
      end
    end

    describe "#object_node" do
      # We use #node through helper methods defined by .add_type
      subject { blueprint { user } }

      it "adds an object node and returns the reference to the node" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(
            name: start_with("_anon_"),
            type: user,
            parent: nil,
            args: [],
            kwargs: {},
          ),
          have_attributes(args: [Factrey::Ref.new(subject.nodes.values[0].name)]), # result
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
            have_attributes(args: [Factrey::Ref.new(subject.nodes.values[2].name)]), # result
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

        it "adds nodes and node parents reflects structures" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(args: [1], parent: nil),
            have_attributes(args: [2], parent: subject.nodes.values[0]),
            have_attributes(args: [3], parent: subject.nodes.values[1]),
            have_attributes(args: [4], parent: subject.nodes.values[1]),
            have_attributes(args: [Factrey::Ref.new(subject.nodes.values[0].name)]), # result
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

        it "adds nodes reflects structures" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(args: [1], kwargs: {}),
            have_attributes(args: [2], kwargs: { user: subject.nodes.values[0].to_ref }),
            have_attributes(args: [3], kwargs: { user: subject.nodes.values[1].to_ref }),
            have_attributes(args: [Factrey::Ref.new(subject.nodes.values[0].name)]), # result
          ]
        end
      end
    end

    describe "#computed_node" do
      subject { blueprint { computed_node(:foo, 123) } }

      it "adds a computed node and returns the reference to the node" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(
            name: :foo,
            type: Factrey::Blueprint::Type::COMPUTED,
            parent: nil,
            args: [123],
            kwargs: {},
          ),
          have_attributes(args: [Factrey::Ref.new(subject.nodes.values[0].name)]), # result
        ]
      end
    end

    describe "#ext" do
      subject { blueprint { user(name: ext) } }

      let(:ext) { "FOO" }

      it "returns an object set at Factrey.blueprint" do
        expect(subject.nodes.values.to_a).to match [
          have_attributes(kwargs: { name: "FOO" }),
          have_attributes(args: [Factrey::Ref.new(subject.nodes.values[0].name)]), # result
        ]
      end
    end

    describe "#let" do
      subject do
        blueprint do
          user("A")
          let.user("B")
          let.author = user("C")
        end
      end

      it "gives names to nodes" do
        objects, aliases = subject.nodes.values.partition(&:anonymous?)
        expect(objects).to match [
          have_attributes(args: ["A"]),
          have_attributes(args: ["B"]),
          have_attributes(args: ["C"]),
        ]
        expect(aliases).to match [
          have_attributes(name: :user, args: [Factrey::Ref.new(objects[1].name)]),
          have_attributes(name: :author, args: [Factrey::Ref.new(objects[2].name)]),
          have_attributes(args: [Factrey::Ref.new(objects[2].name)]), # result
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

      context "when let is nested" do
        subject { blueprint { let.foo = let.bar = 123 } }

        it "works independently (as Ruby's language specification)" do
          expect(subject.nodes.values.to_a).to match [
            have_attributes(name: :bar, args: [123]),
            have_attributes(name: :foo, args: [123]),
            have_attributes(args: [123]), # result
          ]
        end
      end
    end

    describe "#on" do
      subject do
        blueprint do
          let.user
          on.user(12, 34)
          on.user(56, hello: "world")
          on.user { let.user2 = user(78) }
        end
      end

      it "alters the node resolved by name and returns the reference to the node" do
        expect(subject.resolve_node(:user)).to have_attributes(
          args: [12, 34, 56],
          kwargs: { hello: "world" },
        )
        expect(subject.resolve_node(:user2)).to have_attributes(
          args: [78],
          parent: subject.resolve_node(:user),
        )
        expect(subject.nodes.values.last).to have_attributes(
          args: [Factrey::Ref.new(subject.resolve_node(:user).name)],
        )
      end

      context "when #on is used in another block" do
        subject do
          blueprint do
            let.user1 = user
            let.user2 = user do
              let.user3 = user
              on.user1 { let.user4 = user }
              let.user5 = user
            end
          end
        end

        it "does not affect ancestors outside block" do
          expect(subject.resolve_node(:user1)).to have_attributes(parent: nil)
          expect(subject.resolve_node(:user2)).to have_attributes(parent: nil)
          expect(subject.resolve_node(:user3)).to have_attributes(parent: subject.resolve_node(:user2))
          expect(subject.resolve_node(:user4)).to have_attributes(parent: subject.resolve_node(:user1))
          expect(subject.resolve_node(:user5)).to have_attributes(parent: subject.resolve_node(:user2))
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
          have_attributes(args: [Factrey::Ref.new(subject.nodes.values[0].name)]),
        ]
      end

      context "when #args is used without a node declaration" do
        subject { blueprint { args :foo } }

        it "fails with an error" do
          expect { subject }.to raise_error NameError
        end
      end

      context "when #args is used for a computed node declaration" do
        subject do
          blueprint do
            let.foo = 123
            on.foo(456)
          end
        end

        it "fails with an error" do
          expect { subject }.to raise_error NameError
        end
      end
    end
  end
end
