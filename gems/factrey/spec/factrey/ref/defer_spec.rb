# frozen_string_literal: true

RSpec.describe Factrey::Ref::Defer do
  describe "#initialize" do
    it "accepts only fixed positional arguments for its block" do
      expect { described_class.new { |foo:, bar:| foo + bar } }.to raise_error ArgumentError
      expect { described_class.new { |*_args| 0 } }.to raise_error ArgumentError
      expect { described_class.new { |foo, bar| foo + bar } }.not_to raise_error
    end
  end

  describe "#refs" do
    subject { defer.refs }

    let(:defer) { described_class.new { |foo, bar| foo + bar } }

    it "returns dependencies as references" do
      expect(subject).to eq [Factrey::Ref.new(:foo), Factrey::Ref.new(:bar)]
    end
  end
end
