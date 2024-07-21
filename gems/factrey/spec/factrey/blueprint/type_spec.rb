# frozen_string_literal: true

RSpec.describe Factrey::Blueprint::Type do
  describe "#initialize" do
    subject { described_class.new(name, compatible_types:, auto_references:, &factory) }

    context "with valid arguments" do
      parameterized(:name, :compatible_types, :auto_references, :factory, :matcher) do
        input { [:type, :foo, {}, -> {}, have_attributes(compatible_types: Set[:type, :foo])] }
        input { [:type, [], %i[foo bar], -> {}, have_attributes(auto_references: { foo: :foo, bar: :bar })] }
        input { [:type, [], :foo, -> {}, have_attributes(auto_references: { foo: :foo })] }

        it "does some input conversionst" do
          expect(subject).to matcher
        end
      end
    end

    context "with invalid arguments" do
      parameterized(:name, :compatible_types, :auto_references, :factory, :error) do
        input { ["type", [], {}, -> {}, TypeError] }
        input { [:type, "foo", [], -> {}, TypeError] }
        input { [:type, [], "foo", -> {}, TypeError] }
        input { [:type, [], { "foo" => :bar }, -> {}, TypeError] }
        input { [:type, [], { foo: "bar" }, -> {}, TypeError] }
        input { [:type, [], {}, nil, ArgumentError] }

        it "validates arguments" do
          expect { subject }.to raise_error(error)
        end
      end
    end
  end
end
