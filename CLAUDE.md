# Claude.nvim Development Guidelines

## Commands
- Test: None found, implement tests
- Lint: None found, consider adding a linter like luacheck
- Build: None required (Lua plugin)

## Code Style
- **Indentation**: 2 spaces
- **Naming**:
  - Functions: snake_case (e.g., `get_api_key`)
  - Variables: snake_case (e.g., `original_buffer`)
  - Modules: snake_case (e.g., `utils.lua`)
  - Objects: PascalCase (e.g., `Claude.state`)
- **Imports**: Use `require("claude.submodule")` pattern
- **Tables**: Initialize with `{}`
- **Error handling**: Use `vim.notify` with appropriate log levels
- **Function structure**: Use `object.function_name = function(params)` pattern
- **Comments**: Document functions and modules with preceding comments
- **Strings**: Use double quotes when embedding single quotes
- **Conditionals**: Place then/do on same line as if/for

## Module Organization
- Keep related functionality in dedicated modules
- Export functions via a module table
- Initialize dependencies via init() functions