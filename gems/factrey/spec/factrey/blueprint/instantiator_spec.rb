# frozen_string_literal: true

RSpec.describe Factrey::Blueprint::Instantiator do
  def factory = ->(type, context, *args, **kwargs) { [context[:build_strategy], type.name, *args, kwargs] }
  def ref = Factrey::Ref::Builder.new

  let(:author) { Factrey::Blueprint::Type.new(:author, &factory) }
  let(:guest_author) { Factrey::Blueprint::Type.new(:guest_author, compatible_types: :author, &factory) }
  let(:blog) { Factrey::Blueprint::Type.new(:blog, auto_references: :author, &factory) }
  let(:post) { Factrey::Blueprint::Type.new(:post, auto_references: :blog, &factory) }
  let(:comment) { Factrey::Blueprint::Type.new(:comment, auto_references: { post: :post, user: :commentor }, &factory) }

  describe "Factrey::Blueprint#instantiate" do
    subject { blueprint.instantiate(context) }

    let(:blueprint) { Factrey::Blueprint.new }
    let(:context) { { build_strategy: :create } }

    context "with an empty blueprint" do
      it "creates no objects" do
        expect(subject).to eq({})
      end
    end

    context "with single node" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author, args: [1, :hello], kwargs: { hoge: "fuga" }))
      end

      it "creates objects" do
        expect(subject).to eq(foo: [:create, :author, 1, :hello, { hoge: "fuga" }])
      end
    end

    context "with single computed node" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.computed(:foo, 123))
      end

      it "creates objects" do
        expect(subject).to eq(foo: 123)
      end
    end

    context "with multiple nodes" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author))
        blueprint.add_node(Factrey::Blueprint::Node.new(:bar, blog))
      end

      it "creates objects" do
        expect(subject).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :blog, {}],
        )
      end
    end

    context "with references" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author, args: [ref.bar]))
        blueprint.add_node(Factrey::Blueprint::Node.new(:bar, blog))
      end

      it "creates objects" do
        expect(subject).to eq(
          bar: [:create, :blog, {}],
          foo: [:create, :author, subject[:bar], {}],
        )
      end
    end

    context "with more complex references" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author, kwargs: { follows: [] }))
        blueprint.add_node(Factrey::Blueprint::Node.new(:bar, author, kwargs: { follows: [ref.foo] }))
        blueprint.add_node(Factrey::Blueprint::Node.new(:baz, author, kwargs: { follows: [ref.foo, ref.bar] }))
      end

      it "creates objects" do
        expect(subject).to eq(
          foo: [:create, :author, { follows: [] }],
          bar: [:create, :author, { follows: [subject[:foo]] }],
          baz: [:create, :author, { follows: [subject[:foo], subject[:bar]] }],
        )
      end
    end

    context "with circular references" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author, args: [ref.bar]))
        blueprint.add_node(Factrey::Blueprint::Node.new(:bar, blog, args: [ref.foo]))
      end

      it "fails" do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context "with missing references" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author, args: [ref.bar]))
      end

      it "fails" do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context "with auto references" do
      before do
        foo = blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author))
        bar = blueprint.add_node(Factrey::Blueprint::Node.new(:bar, blog, parent: foo))
        blueprint.add_node(Factrey::Blueprint::Node.new(:baz, post, parent: bar))
      end

      it "creates objects with auto references" do
        expect(subject).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :blog, { author: subject[:foo] }],
          baz: [:create, :post, { blog: subject[:bar] }],
        )
      end
    end

    context "with auto references and multiple candidates in ancestors" do
      before do
        foo = blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author))
        bar = blueprint.add_node(Factrey::Blueprint::Node.new(:bar, author, parent: foo))
        blueprint.add_node(Factrey::Blueprint::Node.new(:baz, blog, parent: bar))
      end

      it "creates objects with auto references and the nearest ancestor is selected" do
        expect(subject).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :author, {}],
          baz: [:create, :blog, { author: subject[:bar] }],
        )
      end
    end

    context "with auto references and compatible types" do
      before do
        foo = blueprint.add_node(Factrey::Blueprint::Node.new(:foo, guest_author))
        blueprint.add_node(Factrey::Blueprint::Node.new(:bar, blog, parent: foo))
      end

      it "creates objects with auto references and compatible types are also considered" do
        expect(subject).to eq(
          foo: [:create, :guest_author, {}],
          bar: [:create, :blog, { author: subject[:foo] }],
        )
      end
    end

    context "with auto references and explicit arguments" do
      before do
        blueprint.add_node(Factrey::Blueprint::Node.new(:foo, author))
        bar = blueprint.add_node(Factrey::Blueprint::Node.new(:bar, author))
        blueprint.add_node(Factrey::Blueprint::Node.new(:baz, blog, parent: bar, kwargs: { author: ref.foo }))
      end

      it "creates objects and explicit arguments take precedence" do
        expect(subject).to eq(
          foo: [:create, :author, {}],
          bar: [:create, :author, {}],
          baz: [:create, :blog, { author: subject[:foo] }],
        )
      end
    end
  end
end
