# frozen_string_literal: true

RSpec.describe Factrey::Ref::Builder do
  describe "#method_missing" do
    it "builds Ref object" do
      expect(described_class.new.hello).to be_a Factrey::Ref
      expect(described_class.new.hello.name).to eq :hello
      expect(described_class.new.foobar.name).to eq :foobar
    end
  end
end
