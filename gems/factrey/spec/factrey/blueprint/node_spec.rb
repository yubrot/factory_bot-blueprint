# frozen_string_literal: true

RSpec.describe Factrey::Blueprint::Node do
  let(:node) { described_class.new(:foo, Factrey::Blueprint::Type.new(:user) { nil }) }

  describe "#anonymous?" do
    subject { node.anonymous? }

    context "when the node is named" do
      it { is_expected.to be false }
    end

    context "when the node is not named" do
      let(:node) { described_class.new(nil, Factrey::Blueprint::Type.new(:user) { nil }) }

      it { is_expected.to be true }
    end
  end

  describe "#result?" do
    subject { node.result? }

    context "when the node name does not match the result" do
      it { is_expected.to be false }
    end

    context "when the node name meatches the result" do
      let(:node) { described_class.computed(Factrey::Blueprint::Node::RESULT_NAME, 123) }

      it { is_expected.to be true }
    end
  end

  describe "#to_ref" do
    subject { node.to_ref }

    it { is_expected.to eq Factrey::Ref.new(:foo) }
  end

  describe "#alias_ref" do
    subject { node.alias_ref }

    context "when the node does not work as an alias" do
      it { is_expected.to be_nil }
    end

    context "when the node works as an alias" do
      let(:node) { described_class.computed(:foo, Factrey::Ref.new(:bar)) }

      it { is_expected.to eq Factrey::Ref.new(:bar) }
    end
  end

  describe "#type_annotated_name" do
    subject { node.type_annotated_name }

    it "returns the name with the type annotation" do
      expect(subject).to eq "foo(user)"
    end
  end
end
