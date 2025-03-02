# Claude.nvim

A Neovim plugin that integrates with Anthropic's Claude AI model directly in your editor, providing AI-powered assistance for your coding workflows.


## Features

- **Interactive Chat Interface**: Communicate with Claude within Neovim
- **Code-Specific Interface**: Send code for refactoring, optimization, or explanation
- **Visual Selection Support**: Select code and send it to Claude with a simple command
- **Direct Code Application**: Apply Claude's suggestions directly to your buffer
- **Response Continuation**: Continue Claude's responses when they get truncated
- **Token Usage Monitoring**: Track your API usage with built-in token counters
- **Adaptive UI**: Interface adapts to window size for optimal screen usage

## Requirements

- Neovim 0.7.0 or later
- An Anthropic API key (Claude API access)
- `curl` installed on your system

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'IntoTheNull/claude.nvim',
  config = function()
    require('claude').setup({
      -- Your configuration here (see Configuration section)
    })
  end,
  -- Add keymaps in the keys table (LazyVim style)
  keys = {
    -- Chat interface
    { "<leader>ac", "<cmd>Claude<cr>", desc = "Open Claude Chat" },
    -- Coding interface
    { "<leader>ar", 
      ":<C-u>ClaudeCoding<CR>", 
      mode = "v", 
      desc = "Refactor with Claude" 
    },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'IntoTheNull/claude.nvim',
  config = function()
    require('claude').setup({
      -- Your configuration here
    })
    
    -- Add keymaps manually
    vim.api.nvim_set_keymap('v', '<leader>ar', ':<C-u>ClaudeCoding<CR>', 
      { noremap = true, silent = true, desc = "Refactor with Claude" })
    vim.api.nvim_set_keymap('n', '<leader>ac', '<cmd>Claude<cr>', 
      { noremap = true, silent = true, desc = "Open Claude Chat" })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'IntoTheNull/claude.nvim'

" Set up keymaps in your vimrc after plugin loads
vnoremap <leader>ar :<C-u>ClaudeCoding<CR>
nnoremap <leader>ac :Claude<CR>
```

## Configuration

Add the following to your Neovim configuration:

```lua
require('claude').setup({
  -- Command to retrieve your API key (required)
  -- SECURITY NOTE: This should be a command that fetches from a secure store
  -- rather than hardcoding the key directly in your config
  api_key_cmd = "cat ~/.config/claude/api_key.txt",

  -- Model selection (optional)
  model = "claude-3-7-sonnet-20250219", -- Default to the latest model

  -- Token limits (optional)
  max_tokens = 4000,

  -- Model parameters (optional)
  temperature = 0.7,
  top_p = 1.0,

  -- UI customization (optional)
  window = {
    -- These sizes are now relative maximums (98% on large screens, 97% on small)
    width = 0.8,  -- Base percentage of window width
    height = 0.8, -- Base percentage of window height
    border = "rounded", -- Border style: "none", "single", "double", "rounded"
  },

  -- Keybindings (optional)
  keymaps = {
    close = "<C-c>",
    submit = "<C-CR>",
    yank_last = "<C-y>",
    scroll_up = "<C-k>",
    scroll_down = "<C-j>",
    help = "<C-h>",
    quit = "q",
    continue = "<C-u>",
  },

  -- Behavior options
  silent = false,          -- Set to true to disable popup notifications
  show_token_count = true, -- Show token usage information
})
```

## Usage

### Chat Interface

Open the chat interface with:

```
:Claude
```

Or use your configured keymap (e.g., `<leader>ac`).

In the chat interface:
- Type your message in the input field
- Send with `<C-CR>` (Ctrl+Enter) or `Enter` in normal mode
- Close with `<C-c>` or `q`
- Copy Claude's last response with `<C-y>`
- Navigate chat history with `<C-k>` (up) and `<C-j>` (down)
- Get help with `<C-h>`
- Continue a previous response with `<C-u>` or by typing "continue" and pressing Enter

### Coding Interface

1. Select code in visual mode and use:
   ```
   :ClaudeCoding
   ```
   
   Or use your configured visual mode keymap (e.g., `<leader>ar`).

2. Enter instructions for Claude in the bottom panel
3. Press `<C-s>` or `Enter` (in normal mode) to submit

Key bindings in the coding interface:
- `<C-s>`: Submit code for processing
- `<C-i>`: Use Claude's output as new input (iterate)
- `<C-y>`: Copy Claude's code to clipboard
- `<C-a>`: Apply code to original buffer
- `<Tab>`: Cycle focus between panels
- `<C-h>`: Show help window
- `q`: Close coding interface

### Additional Commands

- `:ClaudeSubmitLine`: Submit current line to Claude and copy response to clipboard
- `:ClaudeSubmitRange`: Submit selected range to Claude and copy response to clipboard
- `:ClaudeContinue`: Continue the previous response
- `:ClaudeCodingResize`: Manual trigger for resizing the coding interface

## Examples

### Chat with Claude

1. Run `:Claude` or press your chat keymap (e.g., `<leader>ac`)
2. Ask a question: "Explain the difference between promises and async/await in JavaScript."
3. Press `<C-CR>` to send

### Refactor Code

1. Select code in visual mode
2. Press your refactor keymap (e.g., `<leader>ar`)
3. Enter an instruction: "Refactor this code to use async/await instead of callbacks"
4. Press `<C-s>` to submit
5. Review the output and press `<C-a>` to apply changes to your original buffer

### API Integration

```lua
-- Access Claude programmatically
local claude = require('claude')

-- Send a message and handle the response
claude.api.send_message(claude, "Explain the visitor pattern", function(response)
  print(response)
end)
```

## Development

### Linting

The project includes a linting configuration for `luacheck`:

```bash
# Run the linter
./scripts/lint.sh
```

See [LINTING.md](./LINTING.md) for more details.

### Testing

The project includes a comprehensive test suite using Plenary.nvim:

```bash
# Run the tests
./scripts/run_tests.sh
```

See [TESTING.md](./TESTING.md) for more details on writing and running tests.

## Troubleshooting

### API Key Issues

If you see "Failed to get API key" errors:

1. Check that your `api_key_cmd` returns a valid API key
2. Ensure there are no extra newlines or whitespace in the key
3. Verify your API key has permissions for the model you're using

### UI Display Problems

If the interface doesn't resize properly:

1. Try the `:ClaudeCodingResize` command to manually trigger resize
2. Check for conflicts with other UI plugins

### Keybinding Issues

If keybindings aren't working:

1. Check for mapping conflicts with `:verbose map <key>`
2. Ensure your terminal supports the key combinations
3. Try using the commands directly (e.g., `:Claude` instead of the keymap)


## Security

For security considerations, see [SECURITY.md](./SECURITY.md).

## License

MIT

## Acknowledgements

- [Anthropic](https://anthropic.com/) for creating Claude
- All contributors to this project