## [Unreleased]

- Added: Added `:build_stubbed` build strategy support
- Added: Added `FactoryBot::Blueprint::Methods`
- Added: Added `letbp_it_be`, a `let_it_be` version of `letbp`
- **Changed**: `letbp` syntax changed to `letbp(...).<build_strategy>`
- **Changed**: Dropped out Ruby 3.1 support
- **Removed**: Removed `let_blueprint`, `let_blueprint_build` and their variants, use `letbp` options instead

## [0.4.0] - 2024/08/13

- Added: `let` notation now accepts any computed values, e.g., `let.foo = [user(1), user(2)]`
- Added: Added support for abbreviating object names based on ancestor objects, e.g., `blog { blog_article }` to `blog { article }`
- **Changed**: Changed `let` notation syntax from `let(:name).object` to `let.name = object`
- **Changed**: Removed `let_default_name`; now `let` uses the method name as the default name
- **Changed**: Blueprint result values are now also represented as a single node

## [0.3.0] - 2024/07/30

- Added `let!` version methods to RSpec helpers

## [0.2.0] - 2024/07/29

- Added: Blocks passed to `DSL#node` takes a reference to the created node
- **Changed**: `DSL#node` returns a reference to the created node instead of the node itself
- **Changed**: `Blueprint#instantiate` now returns a pair of the result and the created objects
- **Changed**: Removed `Blueprint#representative_node`: use `Blueprint#result` instead
- **Changed**: Removed `:representative` option in `let_blueprint_build` and `let_blueprint_create`: use `:result` option instead
- Fixed: `DSL#args` was incorrectly accepting blocks

## [0.1.0] - 2024-07-23

- Initial release
