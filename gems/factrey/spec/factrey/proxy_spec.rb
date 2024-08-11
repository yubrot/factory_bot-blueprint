# frozen_string_literal: true

RSpec.describe Factrey::Proxy do
  let(:test_class) do
    Class.new do
      def foo(name = nil, *args, **kwargs, &block)
        return Factrey::Proxy.new(self, __method__) unless name

        [name, args, kwargs, block]
      end
    end
  end

  it "forwards method calls to the receiver" do
    expect(test_class.new.foo.bar(12, abc: "def") { 345 }).to match [
      :bar,
      [12],
      { abc: "def" },
      have_attributes(call: 345),
    ]
  end
end
