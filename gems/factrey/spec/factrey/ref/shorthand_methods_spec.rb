# frozen_string_literal: true

RSpec.describe Factrey::Ref::ShorthandMethods do
  include described_class

  describe "#ref" do
    context "with an argument" do
      subject { ref(:foo) }

      it "returns a Ref instance" do
        expect(subject).to eq Factrey::Ref.new(:foo)
      end
    end

    context "without any argument" do
      subject { ref }

      it "returns a Ref::Builder instance" do
        # We cannot use be_a Factrey::Ref::Builder since it is derived from BasicObject
        expect(subject.bar).to eq Factrey::Ref.new(:bar)
      end
    end

    context "with a block argument" do
      subject { ref { |foo, bar| foo + bar } }

      it "returns a Ref::Defer instance" do
        expect(subject).to be_a Factrey::Ref::Defer
      end
    end

    context "with ambiguous arguments" do
      subject { ref(:foo) { |foo, bar| foo + bar } }

      it "is denied" do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end
end
