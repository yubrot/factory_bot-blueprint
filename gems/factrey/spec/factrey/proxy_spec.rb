# frozen_string_literal: true

RSpec.describe Factrey::Proxy do
  let(:test_class) do
    Class.new do
      def foo(prefix, name = nil, *args, **kwargs, &block)
        return Factrey::Proxy.new(self, __method__, prefix) unless name

        [prefix, name, args, kwargs, block]
      end
    end
  end

  it "forwards method calls to the receiver" do
    expect(test_class.new.foo(12).bar(34, abc: "def") { 345 }).to match [
      12,
      :bar,
      [34],
      { abc: "def" },
      have_attributes(call: 345),
    ]
  end
end
