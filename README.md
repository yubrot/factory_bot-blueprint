# FactoryBot::Blueprint

[![](https://badge.fury.io/rb/factory_bot-blueprint.svg)](https://badge.fury.io/rb/factory_bot-blueprint)
[![](https://github.com/yubrot/factory_bot-blueprint/actions/workflows/main.yml/badge.svg)](https://github.com/yubrot/factory_bot-blueprint/actions/workflows/main.yml)

`factory_bot-blueprint` is a FactoryBot extension for building structured objects using a declarative DSL.

We recommend using this gem only when it's really necessary. [factory_bot-with](https://github.com/yubrot/factory_bot-with), a lightweight gem that shares the same philosophy, is also available and worth considering.

## Installation

FactoryBot::Blueprint provides three gems.

- `factrey` - core implementation of the declarative DSL (FactoryBot independent)
- `factory_bot-blueprint` - the main gem
- `factory_bot-blueprint-rspec` - helper to make `factory_bot-blueprint` easier to use in RSpec

If you use RSpec, it is recommended (but not required) to install `factory_bot-blueprint-rspec`.

```sh
# at Gemfile
gem "factory_bot-blueprint-rspec"
```

## Usage (`factory_bot-blueprint`)

This document assumes an understanding of FactoryBot. You can learn about FactoryBot in [the factory_bot book](https://thoughtbot.github.io/factory_bot/).

### Getting started

The entry point of this gem is [`FactoryBot::Blueprint.plan`](https://rubydoc.info/gems/factory_bot-blueprint/FactoryBot/Blueprint#plan-class_method). You can pass a block to this method, in which you describe the plan for creating objects in DSL.

```ruby
bp = FactoryBot::Blueprint.plan { user(name: "John") }
```

In the DSL, each method call, except for certain reserved keywords, corresponds to the creation of an object. The above example creates an object of type `user`. The type is automatically defined from the FactoryBot's pre-defined factory of the same name:

```ruby
FactoryBot.define do
  # This factory corresponds to the `user` type
  factory :user
end
```

The result of `FactoryBot::Blueprint.plan` is called a **blueprint**. Blueprints represent a plan for creating a set of objects, which can be passed to [`FactoryBot::Blueprint.create`](https://rubydoc.info/gems/factory_bot-blueprint/FactoryBot/Blueprint#create-class_method) or [`FactoryBot::Blueprint.build`](https://rubydoc.info/gems/factory_bot-blueprint/FactoryBot/Blueprint#build-class_method) to create the actual set of objects. (these methods are corresponding to `FactoryBot.build` and `FactoryBot.create` respectively). Method call arguments (ex. `name: "John"`) are passed to the FactoryBot's `build` or `create` method.

```ruby
FactoryBot::Blueprint.build(bp) # or FactoryBot::Blueprint.create
#=>
#{:_anon_9ea309fe2cd1 => #<User name="John">,
# :_result_ => #<User name="John">}
```

As you can see, the creation result is a `Hash`, and objects are given random names start with `_anon_`. It is also notice that the `:_result_` (`Factrey::Blueprint::Node::RESULT_NAME`) holds the DSL code block result.

The DSL, described in detail below, supports declaring multiple objects and naming.

```ruby
# FactoryBot::Blueprint.build can also take a DSL code block directly
FactoryBot::Blueprint.build do
  let.kevin = user(name: "Kevin")
  user(name: "User 1")
  user(name: "User 2")
end
#=>
#{:kevin => #<User name="Kevin">,
# :_anon_d3461b354de6 => #<User name="Kevin">,
# :_anon_ee5f94e77718 => #<User name="User 1">,
# :_anon_2a70dd71bdac => #<User name="User 2">,
# :_result_ => #<User name="User 2">}
```

Optionally you can use a shortcut method by including `FactoryBot::Blueprint::Methods`.

```ruby
# If you are using RSpec, you can configure the same way as FactoryBot::Syntax::Methods:
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include FactoryBot::Blueprint::Methods
end

# You can use `bp` in your spec files
RSpec.describe "something" do
  before do
    bp.create do
      user(name: "Kevin")
      user(name: "User 1")
      user(name: "User 2")
    end
  end
end
```

### The Blueprint DSL

This section will go through the primary features of the Blueprint DSL. All DSL APIs can be found in the [`factrey` API Doc](https://rubydoc.info/gems/factrey/Factrey/DSL).

#### Objects, references, and tree structures

For example, with these factories:

```ruby
FactoryBot.define do
  factory(:author)
  factory(:blog) { author }
  factory(:blog_article) { blog }
end
```

You can create an author, a blog, and three articles in plain FactoryBot like this:

```ruby
author = FactoryBot.create(:author, name: "John")
blog = FactoryBot.create(:blog, name: "John's Blog", author:)
FactoryBot.create(:blog_article, title: "Article 1", blog:)
FactoryBot.create(:blog_article, title: "Article 2", blog:)
FactoryBot.create(:blog_article, title: "Article 3", blog:)
```

This can be rewritten in FactoryBot::Blueprint as follows:

```ruby
objects = FactoryBot::Blueprint.create do
  let.author = author(name: "John")
  let.blog = blog(name: "John's Blog", author: ref.author)
  blog_article(title: "Article 1", blog: ref.blog)
  blog_article(title: "Article 2", blog: ref.blog)
  blog_article(title: "Article 3", blog: ref.blog)
end
objects => { author:, blog: }
```

It's not that interesting, but

- By using the notation `let.name =`, you can declare a named node.
- You can refer to nodes in the DSL with the notation `ref.name`.

From here, several simplifications can be made.

First, we can use simplify `let.name = name(...)` to `let.name(...)`.

```ruby
objects = FactoryBot::Blueprint.create do
  let.author(name: "John")
  let.blog(name: "John's Blog", author: ref.author)
  blog_article(title: "Article 1", blog: ref.blog)
  blog_article(title: "Article 2", blog: ref.blog)
  blog_article(title: "Article 3", blog: ref.blog)
end
objects => { author:, blog: }
```

Next, **object declarations can take a block**. Within the block, objects can be declared in the same way, but if a proper association can be made here from the object in the block to the parent object [^1], **this gem will automatically add references to them**:

[^1]: or some proper ancestor object

```ruby
objects = FactoryBot::Blueprint.create do
  let.author(name: "John") do
    let.blog(name: "John's Blog") do    # adds { author: ref.author }
      blog_article(title: "Article 1")  # adds { blog: ref.blog }
      blog_article(title: "Article 2")  # adds { blog: ref.blog }
      blog_article(title: "Article 3")  # adds { blog: ref.blog }
    end
  end
end
objects => { author:, blog: }
```

This auto-reference will work automatically for any association of any traits in the FactoryBot's factory definition. [^2] [^3]

[^2]: Except [inline associations](https://thoughtbot.github.io/factory_bot/associations/inline-definition.html). It seems that it is difficult to support this
[^3]: See [blueprint_spec.rb](./gems/factory_bot-blueprint/spec/factory_bot/blueprint_spec.rb) (together with [factories.rb](./gems/factory_bot-blueprint/spec/factories.rb)) for detailed behavior

Finally, we can omit part of the object name based on the ancestor objects.

```ruby
objects = FactoryBot::Blueprint.create do
  let.author(name: "John") do
    let.blog(name: "John's Blog") do
      article(title: "Article 1")  # We have a `blog` in the ancestors, so we can omit `blog_`
      article(title: "Article 2")
      article(title: "Article 3")
    end
  end
end
objects => { author:, blog: }
```

#### Extending the existing blueprints

`FactoryBot::Blueprint.plan` (and `.build` and `.create`) optionally takes a blueprint as an argument. In this case, instead of creating a new blueprint, **the passed blueprint is extended**.

```ruby
bp = FactoryBot::Blueprint.plan { user(name: "Some User") }
FactoryBot::Blueprint.plan(bp) { user(name: "More User") }
FactoryBot::Bluepirnt.build(bp)
#=>
#{:_anon_e1f15f805023 => #<User name="Some User">,
# :_anon_b26e69c8d36b => #<User name="More User">,
# :_result_ => #<User name="Some User">}
```

Notice that the `:_result_` is not overwritten when extending the blueprint.

It is also possible to add arguments and child objects to the existing object declaration in the blueprint, by `on.name` notation.

```ruby
bp = FactoryBot::Blueprint.plan do
  let.user(name: "John") do
    let.blog(name: "John's Blog") do
      article(title: "Article 1")
      article(title: "Article 2")
    end
  end
end

FactoryBot::Blueprint.build(bp) do
  on.blog(category: "Daily log") do  # adds an argument (category: "Daily log")
    article(title: "New article")    # adds an article
  end
end
#=>
#{:user => #<User name="John">,
# :blog => #<Blog title="John's Blog", category="Daily log", user=...>,
# ...
# :_result_ => #<User name="John">}
```

#### External references

In the DSL, method calls are interpreted as object declarations.

```ruby
def user_id = 123
def bp = FactoryBot::Blueprint.plan { user(id: user_id) } # ERROR: Unknown type: user_id
```

To avoid this, you can use the `ext:` option to refer to it as `ext` from the DSL. [^4]

[^4]: Or you can use local variables alternatively

```ruby
def user_id = 123
def bp = FactoryBot::Blueprint.plan(ext: self) { user(id: ext.user_id) }
```

#### Extending the DSL itself

TODO

### RSpec helper methods (provided by `factory_bot-blueprint-rspec`)

When trying to use FactoryBot::Blueprint on RSpec, the following patterns are frequent.

```ruby
# 1. define a blueprint
let(:blog_blueprint) do
  FactoryBot::Blueprint.plan(ext: self) do
    blog(title: "Daily log") do
      let.article(title: "Article 1") { let.comment(text: "foo") }
      article(title: "Article 2")
      article(title: "Article 3")
    end
  end
end

# 2. build (or create) it
let(:blog_blueprint_instance) { FactoryBot::Blueprint.build(blog_blueprint) }

# 3. define the result and each named object using let
let(:blog) { blog_blueprint_instance[:_result_] }
let(:article) { blog_blueprint_instance[:article] }
let(:comment) { blog_blueprint_instance[:comment] }
```

`factory_bot-blueprint-rspec` gem provides an all-in-one helper method `letbp` to do this.

```ruby
# Define a blog, an article, and a comment from the instance of the blueprint described in the block
letbp(:blog, %i[article comment]).build do
  blog(title: "Daily log") do
    let.article(title: "Article 1") { let.comment(text: "foo") }
    article(title: "Article 2")
    article(title: "Article 3")
  end
end
```

Yon can also use `letbp(...).inherit` to extend `super()` blueprint.

```ruby
RSpec.describe "something" do
  letbp(:blog, %i[article]).create do
    blog(title: "Daily log") do
      let.article(title: "Article 1")
      article(title: "Article 2")
      article(title: "Article 3")
    end
  end

  context "with some comments on the article 1" do
    letbp(:blog).inherit do
      on.article do
        comment(text: "Comment 1")
        comment(text: "Comment 2")
      end
    end
  end
end
```

## Development

```sh
git clone https://github.com/yubrot/factory_bot-blueprint
cd gems/factory_bot-blueprint
bin/setup
bundle exec rake --tasks
bundle exec rake
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yubrot/factory_bot-blueprint. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/yubrot/factory_bot-blueprint/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FactoryBot::Blueprint project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/yubrot/factory_bot-blueprint/blob/main/CODE_OF_CONDUCT.md).
