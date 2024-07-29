## [Unreleased]

## [0.2.0] - 2024/07/29

- Added: Blocks passed to `DSL#node` takes a reference to the created node
- **Changed**: `DSL#node` returns a reference to the created node instead of the node itself
- **Changed**: `Blueprint#instantiate` now returns a pair of the result and the created objects
- **Changed**: Removed `Blueprint#representative_node`: use `Blueprint#result` instead
- **Changed**: Removed `:representative` option in `let_blueprint_build` and `let_blueprint_create`: use `:result` option instead
- Fixed: `DSL#args` was incorrectly accepting blocks

## [0.1.0] - 2024-07-23

- Initial release
