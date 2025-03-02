-- Claude.nvim - Configuration module
-- Contains default settings and configuration

local config = {
  -- API settings
  api_key_cmd = nil, -- Command to retrieve your API key (REQUIRED)
  model = "claude-3-7-sonnet-20250219", -- Default model
  
  -- Response settings
  max_tokens = 4000, -- Maximum tokens in Claude's response
  temperature = 0.7, -- Higher = more creative, Lower = more deterministic
  top_p = 1.0, -- Nucleus sampling parameter
  timeout_ms = 30000, -- API timeout (30 seconds)
  
  -- Keymaps
  keymaps = {
    close = "<C-c>", -- Close interface
    submit = "<C-Enter>", -- Submit message/code
    yank_last = "<C-y>", -- Copy Claude's response
    scroll_up = "<C-k>", -- Scroll up in chat window
    scroll_down = "<C-j>", -- Scroll down in chat window
    help = "<C-h>", -- Show help
    quit = "q", -- Quit interface
    continue = "<C-u>", -- Continue response
  },
  
  -- UI settings
  window = {
    border = "rounded", -- Options: "none", "single", "double", "rounded"
                        -- or custom border array as shown in the README
    width = 0.8, -- Base percentage of window width
    height = 0.8, -- Base percentage of window height
  },
  
  -- Behavior options
  silent = false, -- false = enable popup notifications for API responses
  show_token_count = true, -- Show token usage information
}

return config
