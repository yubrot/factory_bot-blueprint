# frozen_string_literal: true

RSpec.describe Factrey::Ref::Resolver do
  let(:resolver) { described_class.new(recursion_limit:) { mapping.fetch(_1) } }
  let(:recursion_limit) { nil }
  let(:mapping) { { foo: "hello", bar: "world" } }

  describe "#resolve" do
    include Factrey::Ref::ShorthandMethods

    subject { resolver.resolve(object) }

    parameterized(:object) do
      input { [12] }
      input { [:foo] }
      input { [:test] }
      input { [[1, 2, 3]] }
      input { [{ foo: "bar", hoge: "fuga" }] }

      it "keeps the structure of the original object" do
        expect(subject).to eq object
      end
    end

    parameterized(:object, :result) do
      input { [ref.foo, "hello"] }
      input { [ref.bar, "world"] }
      input { [[12, [ref.foo, 34, [ref(:bar), 56]]], [12, ["hello", 34, ["world", 56]]]] }
      input { [{ ref.foo => 12, 34 => [ref.bar] }, { "hello" => 12, 34 => ["world"] }] }
      input { [ref { 123 }, 123] }
      input { [ref { |foo| foo }, "hello"] }
      input { [ref { |foo, bar| "#{foo} #{bar}" }, "hello world"] }
      input { [ref { |bar, foo| "#{foo} #{bar}" }, "hello world"] }
      input { [[ref { |foo| foo }, ref { |bar| bar }], %w[hello world]] }

      it "replaces `Ref`s and `Ref::Defer`s with resolved values" do
        expect(subject).to eq result
      end
    end

    context "when the object contains an unresolvable `Ref`" do
      let(:object) { ref.unknown }

      it "propagates the exception raised by the handler" do
        expect { subject }.to raise_error KeyError
      end
    end

    context "when the recursion limit is set" do
      parameterized(:object, :recursion_limit, :result) do
        input { [ref.foo, 0, "hello"] }
        input { [ref { |bar| bar }, 0, "world"] }
        input { [[ref.foo], 0, [ref.foo]] }
        input { [[ref.foo, [ref.bar, [ref.foo]]], 1, ["hello", [ref.bar, [ref.foo]]]] }
        input { [[ref.foo, [ref.bar, [ref.foo]]], 2, ["hello", ["world", [ref.foo]]]] }
        input { [[ref.foo, [ref.bar, [ref.foo]]], 3, ["hello", ["world", ["hello"]]]] }
        input { [[ref.foo, [ref.bar, [ref.foo]]], 4, ["hello", ["world", ["hello"]]]] }
        input { [{ ref.foo => ref.bar }, 0, { ref.foo => ref.bar }] }
        input { [{ ref.foo => ref.bar }, 1, { "hello" => "world" }] }
        input { [{ ref.foo => ref.bar, [ref.bar] => [ref.foo] }, 1, { "hello" => "world", [ref.bar] => [ref.foo] }] }
        input { [{ ref.foo => ref.bar, [ref.bar] => [ref.foo] }, 2, { "hello" => "world", ["world"] => ["hello"] }] }
        input { [{ ref.foo => ref.bar, [ref.bar] => [ref.foo] }, 3, { "hello" => "world", ["world"] => ["hello"] }] }

        it "stops recursion when the limit is reached" do
          expect(subject).to eq result
        end
      end
    end
  end
end
