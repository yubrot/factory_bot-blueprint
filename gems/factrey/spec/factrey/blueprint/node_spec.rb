# frozen_string_literal: true

RSpec.describe Factrey::Blueprint::Node do
  let(:node) { described_class.new(:foo, Factrey::Blueprint::Type.new(:user) { nil }) }

  describe "#root?" do
    subject { node.root? }

    context "when the node has no ancestors" do
      it { is_expected.to be true }
    end

    context "when the node has ancestors" do
      let(:node) { described_class.new(:bar, Factrey::Blueprint::Type.new(:blog) { nil }, ancestors: [super()]) }

      it { is_expected.to be false }
    end
  end

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

  describe "#type_annotated_name" do
    subject { node.type_annotated_name }

    it "returns the name with the type annotation" do
      expect(subject).to eq "foo(user)"
    end
  end
end
