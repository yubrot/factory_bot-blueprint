# frozen_string_literal: true

RSpec.describe Factrey::Blueprint::Instantiator do
  def factory = ->(type, context, *args, **kwargs) { [context[:strategy], type.name, *args, kwargs] }
  def ref = Factrey::Ref::Builder.new

  let(:author) { Factrey::Blueprint::Type.new(:author, &factory) }
  let(:guest_author) { Factrey::Blueprint::Type.new(:guest_author, compatible_types: :author, &factory) }
  let(:blog) { Factrey::Blueprint::Type.new(:blog, auto_references: :author, &factory) }
  let(:post) { Factrey::Blueprint::Type.new(:post, auto_references: :blog, &factory) }
  let(:comment) { Factrey::Blueprint::Type.new(:comment, auto_references: { post: :post, user: :commentor }, &factory) }

  describe "Factrey::Blueprint#instantiate" do
    subject { blueprint.instantiate(context) }

    let(:blueprint) { Factrey::Blueprint.new }
    let(:context) { { strategy: :create } }

    context "with an empty blueprint" do
      it "creates no objects" do
        expect(subject).to eq([nil, {}])
      end
    end

    context "with single node" do
      before do
        blueprint.add_node(:foo, author, args: [1, :hello], kwargs: { hoge: "fuga" })
      end

      it "creates objects" do
        expect(subject[0]).to be_nil
        expect(subject[1]).to eq(foo: [:create, :author, 1, :hello, { hoge: "fuga" }])
      end
    end

    context "with single node and result" do
      before do
        blueprint.add_node(:foo, author, args: [1, :hello], kwargs: { hoge: "fuga" })
        blueprint.define_result(ref.foo)
      end

      it "creates objects and computes the result" do
        expect(subject[0]).to eq(subject[1][:foo])
      end
    end

    context "with multiple nodes" do
      before do
        blueprint.add_node(:foo, author)
        blueprint.add_node(:bar, blog)
      end

      it "creates objects" do
        expect(subject[1]).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :blog, {}],
        )
      end
    end

    context "with references" do
      before do
        blueprint.add_node(:foo, author, args: [ref.bar])
        blueprint.add_node(:bar, blog)
      end

      it "creates objects" do
        expect(subject[1]).to eq(
          bar: [:create, :blog, {}],
          foo: [:create, :author, subject[1][:bar], {}],
        )
      end
    end

    context "with more complex references" do
      before do
        blueprint.add_node(:foo, author, kwargs: { follows: [] })
        blueprint.add_node(:bar, author, kwargs: { follows: [ref.foo] })
        blueprint.add_node(:baz, author, kwargs: { follows: [ref.foo, ref.bar] })
      end

      it "creates objects" do
        expect(subject[1]).to eq(
          foo: [:create, :author, { follows: [] }],
          bar: [:create, :author, { follows: [subject[1][:foo]] }],
          baz: [:create, :author, { follows: [subject[1][:foo], subject[1][:bar]] }],
        )
      end
    end

    context "with circular references" do
      before do
        blueprint.add_node(:foo, author, args: [ref.bar])
        blueprint.add_node(:bar, blog, args: [ref.foo])
      end

      it "fails" do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context "with missing references" do
      before do
        blueprint.add_node(:foo, author, args: [ref.bar])
      end

      it "fails" do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context "with auto references" do
      before do
        foo = blueprint.add_node(:foo, author)
        bar = blueprint.add_node(:bar, blog, ancestors: [foo])
        blueprint.add_node(:baz, post, ancestors: [foo, bar])
      end

      it "creates objects with auto references" do
        expect(subject[1]).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :blog, { author: subject[1][:foo] }],
          baz: [:create, :post, { blog: subject[1][:bar] }],
        )
      end
    end

    context "with auto references and multiple candidates in ancestors" do
      before do
        foo = blueprint.add_node(:foo, author)
        bar = blueprint.add_node(:bar, author, ancestors: [foo])
        blueprint.add_node(:baz, blog, ancestors: [foo, bar])
      end

      it "creates objects with auto references and the nearest ancestor is selected" do
        expect(subject[1]).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :author, {}],
          baz: [:create, :blog, { author: subject[1][:bar] }],
        )
      end
    end

    context "with auto references and compatible types" do
      before do
        foo = blueprint.add_node(:foo, guest_author)
        blueprint.add_node(:bar, blog, ancestors: [foo])
      end

      it "creates objects with auto references and compatible types are also considered" do
        expect(subject[1]).to eq(
          foo: [:create, :guest_author, {}],
          bar: [:create, :blog, { author: subject[1][:foo] }],
        )
      end
    end

    context "with auto references and explicit arguments" do
      before do
        blueprint.add_node(:foo, author)
        bar = blueprint.add_node(:bar, author)
        blueprint.add_node(:baz, blog, ancestors: [bar], kwargs: { author: ref.foo })
      end

      it "creates objects and explicit arguments take precedence" do
        expect(subject[1]).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :author, {}],
          baz: [:create, :blog, { author: subject[1][:foo] }],
        )
      end
    end
  end
end
