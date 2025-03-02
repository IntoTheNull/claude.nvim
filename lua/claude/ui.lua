-- Claude.nvim - UI module
-- Handles all UI components and window management

local ui = {}

-- Store reference to the main Claude object
local Claude -- This is used internally by the module

-- Initialize the UI module
function ui.init(claude_obj)
  Claude = claude_obj
end

-- Create main chat interface windows
function ui.create_windows(claude_obj)
  -- Get actual terminal dimensions
  local term_width = vim.o.columns
  local term_height = vim.o.lines
  
  -- Handle small screens specially
  local is_small_screen = (term_width < 100 or term_height < 30)
  
  -- Calculate dimensions based on screen size
  local win_width, max_win_height
  
  if is_small_screen then
    -- For small screens, use more of the available space
    win_width = math.floor(term_width * 0.97)  -- Use 97% of width
    max_win_height = math.floor(term_height * 0.97) -- Use 97% of height
  else
    -- For normal/large screens, maximize space usage
    win_width = math.floor(term_width * 0.98)  -- Use 98% of width
    max_win_height = math.floor(term_height * 0.98) -- Use 98% of height
  end

  -- Calculate chat and input heights to avoid overlap
  local input_height = 5 -- Fixed height for input
  local gap_between = 1 -- Gap between windows
  local total_height_with_borders = input_height + gap_between + 2 -- Add 2 for borders
  local chat_height = max_win_height - total_height_with_borders

  local row = math.floor((vim.o.lines - (chat_height + total_height_with_borders)) / 2)
  local col = math.floor((vim.o.columns - win_width) / 2)

  -- Main chat window (top section)
  claude_obj.state.buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(claude_obj.state.buffer, "bufhidden", "wipe")

  claude_obj.state.window = vim.api.nvim_open_win(claude_obj.state.buffer, true, {
    relative = "editor",
    width = win_width,
    height = chat_height,
    row = row,
    col = col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Claude ",
    title_pos = "center",
  })

  -- Input window (bottom section, separated from chat window)
  claude_obj.state.input_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(claude_obj.state.input_buffer, "bufhidden", "wipe")

  -- Position input window below the chat window with a gap
  claude_obj.state.input_window = vim.api.nvim_open_win(claude_obj.state.input_buffer, true, {
    relative = "editor",
    width = win_width,
    height = input_height,
    row = row + chat_height + gap_between + 1, -- +1 for chat window border
    col = col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Message ",
    title_pos = "center",
  })

  -- Set buffer options and keymaps
  vim.api.nvim_buf_set_option(claude_obj.state.buffer, "modifiable", false)
  vim.api.nvim_win_set_option(claude_obj.state.window, "wrap", true)
  vim.api.nvim_win_set_option(claude_obj.state.window, "linebreak", true)

  vim.api.nvim_buf_set_option(claude_obj.state.input_buffer, "modifiable", true)
  vim.api.nvim_win_set_option(claude_obj.state.input_window, "wrap", true)
  vim.api.nvim_win_set_option(claude_obj.state.input_window, "linebreak", true)

  -- Set up keymaps
  ui.setup_keymaps(claude_obj)

  -- Set up resize handling
  ui.setup_resize_handling(claude_obj)

  -- Go to insert mode in input buffer
  vim.cmd("startinsert")
end

-- Set up resize event handling
function ui.setup_resize_handling(claude_obj)
  -- Create an autocmd group for Claude resize events
  vim.cmd([[
    augroup ClaudeResize
      autocmd!
      autocmd VimResized * lua vim.schedule(function() require('claude').handle_resize() end)
    augroup END
  ]])
  
  -- Debug message
  vim.cmd('echom "Claude resize handler installed"')
end

-- Handle window resize events
function ui.handle_resize(claude_obj)
  -- Only proceed if windows are valid
  if
    not (
      claude_obj.state.window
      and vim.api.nvim_win_is_valid(claude_obj.state.window)
      and claude_obj.state.input_window
      and vim.api.nvim_win_is_valid(claude_obj.state.input_window)
    )
  then
    return
  end

  -- Get actual terminal dimensions
  local term_width = vim.o.columns
  local term_height = vim.o.lines
  
  -- Handle small screens specially
  local is_small_screen = (term_width < 100 or term_height < 30)
  
  -- Calculate dimensions based on screen size
  local win_width, max_win_height
  
  if is_small_screen then
    -- For small screens, use more of the available space
    win_width = math.floor(term_width * 0.97)  -- Use 97% of width
    max_win_height = math.floor(term_height * 0.97) -- Use 97% of height
  else
    -- For normal/large screens, maximize space usage
    win_width = math.floor(term_width * 0.98)  -- Use 98% of width
    max_win_height = math.floor(term_height * 0.98) -- Use 98% of height
  end

  -- Calculate chat and input heights
  local input_height = 5 -- Fixed height for input
  local gap_between = 1 -- Gap between windows
  local total_height_with_borders = input_height + gap_between + 2 -- Add 2 for borders
  local chat_height = max_win_height - total_height_with_borders

  local row = math.floor((vim.o.lines - (chat_height + total_height_with_borders)) / 2)
  local col = math.floor((vim.o.columns - win_width) / 2)

  -- Update chat window
  vim.api.nvim_win_set_config(claude_obj.state.window, {
    relative = "editor",
    width = win_width,
    height = chat_height,
    row = row,
    col = col,
  })

  -- Update input window
  vim.api.nvim_win_set_config(claude_obj.state.input_window, {
    relative = "editor",
    width = win_width,
    height = input_height,
    row = row + chat_height + gap_between + 1, -- +1 for chat window border
    col = col,
  })

  -- If help window is open, also resize it
  if claude_obj.state.help_window and vim.api.nvim_win_is_valid(claude_obj.state.help_window) then
    local help_width = 60
    local help_height = 14
    local help_row = math.floor((vim.o.lines - help_height) / 2)
    local help_col = math.floor((vim.o.columns - help_width) / 2)

    vim.api.nvim_win_set_config(claude_obj.state.help_window, {
      relative = "editor",
      width = help_width,
      height = help_height,
      row = help_row,
      col = help_col,
    })
  end
end

-- Set up keymaps for chat interface
function ui.setup_keymaps(claude_obj)
  -- Set keymaps for input buffer
  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "n",
    claude_obj.config.keymaps.close,
    ":lua require('claude').close()<CR>",
    { noremap = true, silent = true }
  )

  -- Add 'q' to close the interface
  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "n",
    claude_obj.config.keymaps.quit,
    ":lua require('claude').close()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.buffer,
    "n",
    claude_obj.config.keymaps.quit,
    ":lua require('claude').close()<CR>",
    { noremap = true, silent = true }
  )

  -- Continue response keymap
  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "n",
    claude_obj.config.keymaps.continue,
    ":lua require('claude').continue_response()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "i",
    claude_obj.config.keymaps.continue,
    "<Esc>:lua require('claude').continue_response()<CR>",
    { noremap = true, silent = true }
  )

  -- Help keymap for both buffers
  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "n",
    claude_obj.config.keymaps.help,
    ":lua require('claude').show_help()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "i",
    claude_obj.config.keymaps.help,
    "<Esc>:lua require('claude').show_help()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.buffer,
    "n",
    claude_obj.config.keymaps.help,
    ":lua require('claude').show_help()<CR>",
    { noremap = true, silent = true }
  )

  -- Add additional keymaps for submitting
  -- Primary submit keymap (Ctrl+Enter)
  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "n",
    claude_obj.config.keymaps.submit,
    ":lua require('claude').submit()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "i",
    claude_obj.config.keymaps.submit,
    "<Esc>:lua require('claude').submit()<CR>",
    { noremap = true, silent = true }
  )

  -- Add regular Enter in normal mode as an additional submit option
  vim.api.nvim_buf_set_keymap(
    claude_obj.state.input_buffer,
    "n",
    "<CR>",
    ":lua require('claude').submit()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.buffer,
    "n",
    claude_obj.config.keymaps.yank_last,
    ":lua require('claude').yank_last()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.buffer,
    "n",
    claude_obj.config.keymaps.scroll_up,
    ":lua require('claude').scroll_up()<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    claude_obj.state.buffer,
    "n",
    claude_obj.config.keymaps.scroll_down,
    ":lua require('claude').scroll_down()<CR>",
    { noremap = true, silent = true }
  )
end

-- Display all messages in the chat window
function ui.display_messages(claude_obj)
  if not claude_obj.state.buffer or not vim.api.nvim_buf_is_valid(claude_obj.state.buffer) then
    return
  end

  vim.api.nvim_buf_set_option(claude_obj.state.buffer, "modifiable", true)

  local lines = {}
  for _, msg in ipairs(claude_obj.state.messages) do
    local role_display = msg.role == "user" and "You: " or "Claude: "

    -- Split message content into lines
    local content_lines = {}
    for line in string.gmatch(msg.content, "[^\r\n]+") do
      table.insert(content_lines, line)
    end

    -- Add role header
    table.insert(lines, role_display)

    -- Add message content with indentation
    for _, line in ipairs(content_lines) do
      table.insert(lines, "  " .. line)
    end

    -- Add a separator
    table.insert(lines, "")
  end

  vim.api.nvim_buf_set_lines(claude_obj.state.buffer, 0, -1, false, lines)

  -- Set buffer filetype to markdown to enable syntax highlighting
  vim.api.nvim_buf_set_option(claude_obj.state.buffer, "filetype", "markdown")
  vim.api.nvim_buf_set_option(claude_obj.state.buffer, "modifiable", false)

  -- Scroll to bottom
  local line_count = vim.api.nvim_buf_line_count(claude_obj.state.buffer)
  vim.api.nvim_win_set_cursor(claude_obj.state.window, { line_count, 0 })
end

-- Update window title with loading status and token info
function ui.update_loading_status(claude_obj, is_loading)
  if not claude_obj.state.window or not vim.api.nvim_win_is_valid(claude_obj.state.window) then
    return
  end

  local title = is_loading and " Claude (Loading...) " or " Claude "

  -- Add token info to title if available and not loading
  if
    not is_loading
    and claude_obj.config.show_token_count
    and (claude_obj.state.token_stats.prompt_tokens > 0 or claude_obj.state.token_stats.completion_tokens > 0)
  then
    title = string.format(
      " Claude [In: %d, Out: %d] ",
      claude_obj.state.token_stats.prompt_tokens,
      claude_obj.state.token_stats.completion_tokens
    )
  end

  vim.api.nvim_win_set_config(claude_obj.state.window, { title = title })
end

-- Create help window for chat interface
function ui.create_help_window(claude_obj)
  if claude_obj.state.help_window and vim.api.nvim_win_is_valid(claude_obj.state.help_window) then
    vim.api.nvim_win_close(claude_obj.state.help_window, true)
    claude_obj.state.help_window = nil
    claude_obj.state.help_buffer = nil
    return
  end

  local width = 60
  local height = 14 -- Increased height for new keybindings

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  claude_obj.state.help_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(claude_obj.state.help_buffer, "bufhidden", "wipe")

  claude_obj.state.help_window = vim.api.nvim_open_win(claude_obj.state.help_buffer, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Claude.nvim Help ",
    title_pos = "center",
  })

  local help_lines = {
    "Claude.nvim Keybindings:",
    "",
    "  " .. claude_obj.config.keymaps.submit .. "      - Submit message",
    "  " .. claude_obj.config.keymaps.close .. "      - Close Claude interface",
    "  " .. claude_obj.config.keymaps.quit .. "        - Quit Claude interface",
    "  " .. claude_obj.config.keymaps.yank_last .. "      - Yank last Claude response to clipboard",
    "  " .. claude_obj.config.keymaps.scroll_up .. "      - Scroll chat window up",
    "  " .. claude_obj.config.keymaps.scroll_down .. "      - Scroll chat window down",
    "  " .. claude_obj.config.keymaps.help .. "      - Toggle this help window",
    "  " .. claude_obj.config.keymaps.continue .. "      - Continue last response",
    "",
    "You can also type 'continue' and press Enter to continue the last response",
    "",
    "Press any key to close this help window",
  }

  vim.api.nvim_buf_set_lines(claude_obj.state.help_buffer, 0, -1, false, help_lines)
  vim.api.nvim_buf_set_option(claude_obj.state.help_buffer, "modifiable", false)

  -- Close help window when any key is pressed
  local close_keys = { "<Esc>", "<CR>", "<Space>" }
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(
      claude_obj.state.help_buffer,
      "n",
      key,
      ":lua require('claude').close_help()<CR>",
      { noremap = true, silent = true }
    )
  end

  -- Also make any other key close the help window
  vim.cmd([[
      augroup ClaudeHelpClose
        autocmd!
        autocmd BufLeave <buffer> lua require('claude').close_help()
      augroup END
    ]])
end

-- Create help window for coding interface
function ui.create_coding_help_window(claude_obj)
  local width = 60
  local height = 12

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local help_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(help_buffer, "bufhidden", "wipe")

  local help_window = vim.api.nvim_open_win(help_buffer, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Claude Coding Help ",
    title_pos = "center",
  })

  local help_lines = {
    "Claude Coding Interface Keybindings:",
    "",
    "  <C-s>        - Submit code for processing",
    "  <C-i>        - Use Claude's output as new input (iterate)",
    "  <C-y>        - Copy Claude's code to clipboard",
    "  <C-a>        - Apply code to original buffer",
    "  <Tab>        - Cycle focus between panels",
    "  " .. claude_obj.config.keymaps.help .. "      - Show this help window",
    "  q            - Close coding interface",
    "",
    "Press any key to close this help window",
  }

  vim.api.nvim_buf_set_lines(help_buffer, 0, -1, false, help_lines)
  vim.api.nvim_buf_set_option(help_buffer, "modifiable", false)

  -- Close help window when any key is pressed
  local window_id = help_window

  vim.api.nvim_buf_set_keymap(
    help_buffer,
    "n",
    "<Esc>",
    ":lua vim.api.nvim_win_close(" .. window_id .. ", true)<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    help_buffer,
    "n",
    "<CR>",
    ":lua vim.api.nvim_win_close(" .. window_id .. ", true)<CR>",
    { noremap = true, silent = true }
  )

  vim.api.nvim_buf_set_keymap(
    help_buffer,
    "n",
    "<Space>",
    ":lua vim.api.nvim_win_close(" .. window_id .. ", true)<CR>",
    { noremap = true, silent = true }
  )

  -- Close on buffer leave
  vim.cmd("autocmd BufLeave <buffer=" .. help_buffer .. "> lua vim.api.nvim_win_close(" .. window_id .. ", true)")
end

return ui
