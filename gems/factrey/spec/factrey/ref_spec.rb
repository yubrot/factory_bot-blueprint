# frozen_string_literal: true

RSpec.describe Factrey::Ref do
  describe "#==" do
    it "is determined by name equivalence" do
      expect(described_class.new(:foo)).to eq described_class.new(:foo) # rubocop:disable RSpec/IdenticalEqualityAssertion
      expect(described_class.new(:foo)).not_to eq described_class.new(:bar)
    end
  end

  describe "#hash" do
    it "is computed by name" do
      expect(described_class.new(:foo).hash).to eq described_class.new(:foo).hash # rubocop:disable RSpec/IdenticalEqualityAssertion
      expect(described_class.new(:foo).hash).not_to eq described_class.new(:bar).hash
    end
  end
end
