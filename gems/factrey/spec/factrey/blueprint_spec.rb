# frozen_string_literal: true

RSpec.describe Factrey::Blueprint do
  let(:ty_a) { Factrey::Blueprint::Type.new(:ty_a) { nil } }
  let(:ty_b) { Factrey::Blueprint::Type.new(:ty_b) { nil } }
  let(:blueprint) do
    blueprint = described_class.new
    blueprint.add_node(Factrey::Blueprint::Node.new(:foo, ty_a))
    bar = blueprint.add_node(Factrey::Blueprint::Node.new(:bar, ty_a))
    blueprint.add_node(
      Factrey::Blueprint::Node.new(:baz, ty_b, parent: bar, args: [1, 2], kwargs: { hello: "world" }),
    )
    blueprint
  end

  describe "#dup" do
    subject { blueprint.dup }

    it "duplicates the blueprint" do
      expect(subject).to have_attributes(
        nodes: {
          foo: have_attributes(
            name: :foo,
            type: ty_a,
            parent: nil,
            args: [],
            kwargs: {},
          ),
          bar: have_attributes(
            name: :bar,
            type: ty_a,
            parent: nil,
            args: [],
            kwargs: {},
          ),
          baz: have_attributes(
            name: :baz,
            type: ty_b,
            parent: subject.nodes[:bar],
            args: [1, 2],
            kwargs: { hello: "world" },
          ),
        },
      )
      expect(subject.nodes[:foo]).not_to eq(blueprint.nodes[:foo])
      expect(subject.nodes[:bar]).not_to eq(blueprint.nodes[:bar])
      expect(subject.nodes[:baz]).not_to eq(blueprint.nodes[:baz])
    end
  end

  describe "#add_node" do
    skip "is covered by the Factrey::DSL spec"
  end

  describe "#resolve_node" do
    skip "is also covered by the Factrey::DSL spec"
  end

  describe "#instantiate" do
    skip "is covered by the Factrey::Blueprint::Instantiator spec"
  end
end
