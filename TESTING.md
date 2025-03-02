# Testing Claude.nvim

This document provides guidance on testing the Claude.nvim plugin.

## Test Suite Overview

The test suite for Claude.nvim uses the [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) framework, a popular testing framework for Neovim plugins. The tests are organized by module:

- `utils_spec.lua` - Tests for utility functions
- `config_spec.lua` - Tests for configuration handling
- `api_spec.lua` - Tests for API interaction
- `ui_spec.lua` - Tests for UI components
- `init_spec.lua` - Tests for the main module
- `coding_spec.lua` - Tests for the coding interface

## Running Tests

### Using the Test Script

The easiest way to run tests is using the provided script:

```bash
./scripts/run_tests.sh
```

This script will:
1. Check if Plenary.nvim is installed
2. Temporarily install Plenary.nvim if needed
3. Run the tests with appropriate configuration

### Manual Testing

You can also run tests manually with Neovim:

```bash
nvim --headless \
  -c "lua require('plenary.test_harness').test_directory('./tests/', {minimal_init = './tests/minimal_init.vim'})" \
  -c "qa!"
```

## Writing Tests

### Test Structure

Tests follow the BDD-style format provided by Plenary:

```lua
describe("Module name", function()
  before_each(function()
    -- Setup code
  end)
  
  after_each(function()
    -- Teardown code
  end)
  
  describe("function_name", function()
    it("should do something specific", function()
      -- Test code
      assert.are.equal(expected, actual)
    end)
  end)
end)
```

### Mocking Vim API

The test suite includes helpers for mocking the Vim API in `tests/init.lua`:

```lua
local test_helpers = require('tests.init')
local restore_vim = test_helpers.mock_vim()

-- Your test code here

restore_vim() -- Restore the original vim global
```

### Assertions

Plenary provides several assertion functions:

- `assert.are.equal(expected, actual)` - Checks equality
- `assert.are.same(expected, actual)` - Deep comparison for tables
- `assert.is_true(value)` - Checks if value is true
- `assert.is_false(value)` - Checks if value is false
- `assert.is_nil(value)` - Checks if value is nil
- `assert.has_error(function)` - Checks if function throws an error

## CI Integration

The test suite is integrated with GitHub Actions. Tests run automatically on pull requests to ensure code quality.

## Adding New Tests

When adding new functionality:

1. Create a new test file in the `tests/` directory if needed
2. Follow the existing patterns for test organization
3. Ensure tests are independent and don't rely on global state
4. Mock external dependencies when possible
5. Run the full test suite before submitting changes

## Debugging Tests

For debugging failing tests:

1. Run individual test files:
   ```bash
   nvim --headless -c "lua require('plenary.test_harness').test_directory('./tests/specific_test.lua', {minimal_init = './tests/minimal_init.vim'})" -c "qa!"
   ```

2. Add print statements using `vim.api.nvim_echo()` which works in headless mode:
   ```lua
   vim.api.nvim_echo({{message, "Normal"}}, true, {})
   ```