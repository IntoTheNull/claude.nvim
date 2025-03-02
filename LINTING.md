# Linting for Claude.nvim

This document provides guidance on linting the codebase for Claude.nvim using `luacheck`.

## Installation

To install luacheck:

### Via LuaRocks
```bash
luarocks install luacheck
```

### Via Homebrew (macOS)
```bash
brew install luacheck
```

### Via Package Manager
```bash
# Debian/Ubuntu
apt-get install lua-check

# Arch Linux
pacman -S luacheck
```

## Running Luacheck

From the root of the project:

```bash
luacheck .
```

## Known Issues

There are several warnings about unused `Claude` variables in the codebase. These are expected and can be safely ignored, as these module variables are used internally by the modules.

Files with this warning:
- api.lua
- coding/handlers.lua
- coding/init.lua
- ui.lua

## Luacheck Configuration

The project includes a `.luacheckrc` file with the following settings:

- Globals: `vim` is predefined to avoid Neovim API warnings
- Line length: 120 characters max
- Ignores common whitespace issues for better focus on code quality issues

## Common Issues and Fixes

### 1. Unused Arguments

If a function parameter is intentionally unused:
```lua
function module.function(used_param, _unused_param)
  -- Using _ prefix indicates intentionally unused
end
```

### 2. Long Lines

For long lines, split them logically:
```lua
-- Bad
local very_long_line = some_function_with_many_parameters(param1, param2, param3, param4, param5, param6)

-- Good
local very_long_line = some_function_with_many_parameters(
  param1, param2, param3, 
  param4, param5, param6
)
```

### 3. Module Variables

When module variables appear unused but are actually used internally:
```lua
-- Add a comment to clarify intent
local ModuleReference -- Used internally by the module
```

## Integration with Neovim

You can add luacheck as a linter in your Neovim setup using plugins like:

- `null-ls`
- `nvim-lint` 
- `syntastic`

## CI Integration

A GitHub workflow is included to run linting checks automatically on pull requests. This workflow ignores the known module variable warnings.