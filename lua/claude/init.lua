-- Claude.nvim - Anthropic Claude Integration for Neovim
-- Main entry point that loads all modules

local Claude = {}

-- Load modules
Claude.config = require("claude.config")
Claude.utils = require("claude.utils")
Claude.api = require("claude.api")
Claude.ui = require("claude.ui")
Claude.coding = require("claude.coding")

-- State for the chat interface
Claude.state = {
  messages = {},
  buffer = nil,
  window = nil,
  input_buffer = nil,
  input_window = nil,
  help_buffer = nil,
  help_window = nil,
  loading = false,
  last_response = nil, -- Store the last assistant response for continuation
  token_stats = {
    prompt_tokens = 0,
    completion_tokens = 0,
  },
}

-- Setup function to override default config
function Claude.setup(opts)
  Claude.config = vim.tbl_deep_extend("force", Claude.config, opts or {})
  -- Initialize any components that need the config
  Claude.ui.init(Claude)
  Claude.api.init(Claude)
  Claude.coding.init(Claude)

  -- Set up commands
  Claude.setup_commands()
  -- Set up coding commands
  Claude.setup_coding_commands()
  -- Set up visual commands
  Claude.setup_visual_commands()
end

-- Main function to open the chat interface
function Claude.open()
  -- Reset state if needed
  if #Claude.state.messages == 0 then
    Claude.state.messages = {}
    Claude.state.last_response = nil
    Claude.state.token_stats = {
      prompt_tokens = 0,
      completion_tokens = 0,
    }
  end

  Claude.ui.create_windows(Claude)
  Claude.ui.display_messages(Claude)
end

-- Close all windows
function Claude.close()
  -- Remove the resize autocmd if it exists
  vim.cmd([[
    augroup ClaudeResize
      autocmd!
    augroup END
    augroup! ClaudeResize
  ]])

  if Claude.state.window and vim.api.nvim_win_is_valid(Claude.state.window) then
    vim.api.nvim_win_close(Claude.state.window, true)
  end

  if Claude.state.input_window and vim.api.nvim_win_is_valid(Claude.state.input_window) then
    vim.api.nvim_win_close(Claude.state.input_window, true)
  end

  if Claude.state.help_window and vim.api.nvim_win_is_valid(Claude.state.help_window) then
    vim.api.nvim_win_close(Claude.state.help_window, true)
  end
end

-- Handle resize events for chat interface
function Claude.handle_resize()
  if Claude and Claude.ui then
    Claude.ui.handle_resize(Claude)
  end
end

-- Handle resize events for coding interface
function Claude.handle_coding_resize()
  -- Debug message
  vim.cmd('echom "Claude handle_coding_resize triggered"')
  
  if Claude and Claude.coding and Claude.coding.ui then
    -- Check if we're in the coding interface before resizing
    if Claude.coding.state and Claude.coding.state.left_window 
       and vim.api.nvim_win_is_valid(Claude.coding.state.left_window) then
      Claude.coding.ui.handle_resize(Claude.coding, Claude)
    else
      vim.cmd('echom "Claude handle_coding_resize: windows invalid"')
    end
  else
    vim.cmd('echom "Claude handle_coding_resize: modules invalid"')
  end
end

-- Show help window
function Claude.show_help()
  Claude.ui.create_help_window(Claude)
end

-- Close help window
function Claude.close_help()
  if Claude.state.help_window and vim.api.nvim_win_is_valid(Claude.state.help_window) then
    vim.api.nvim_win_close(Claude.state.help_window, true)
    Claude.state.help_window = nil
    Claude.state.help_buffer = nil

    -- Focus back to input window
    if Claude.state.input_window and vim.api.nvim_win_is_valid(Claude.state.input_window) then
      vim.api.nvim_set_current_win(Claude.state.input_window)
      vim.cmd("startinsert")
    end
  end
end

-- Continue previous response
function Claude.continue_response()
  if not Claude.state.last_response then
    vim.notify("No previous response to continue", vim.log.levels.INFO)
    return
  end

  -- Clear input buffer and add "continue"
  vim.api.nvim_buf_set_lines(Claude.state.input_buffer, 0, -1, false, { "continue" })

  -- Submit the continue request
  Claude.submit()
end

-- Submit a message to Claude
function Claude.submit()
  -- Always show this error message even in silent mode
  local lines = vim.api.nvim_buf_get_lines(Claude.state.input_buffer, 0, -1, false)
  local content = table.concat(lines, "\n")

  if content:gsub("%s", "") == "" then
    vim.notify("Empty message, not sending", vim.log.levels.INFO)
    return
  end

  -- Clear input buffer
  vim.api.nvim_buf_set_lines(Claude.state.input_buffer, 0, -1, false, { "" })

  -- Send message to Claude
  Claude.api.send_message(Claude, content)

  -- Focus back to input window and go to insert mode
  vim.api.nvim_set_current_win(Claude.state.input_window)
  vim.cmd("startinsert")
end

-- Yank last Claude response to clipboard
function Claude.yank_last()
  if #Claude.state.messages == 0 then
    vim.notify("No messages to yank", vim.log.levels.INFO)
    return
  end

  -- Find the last assistant message
  local last_assistant_msg = nil
  for i = #Claude.state.messages, 1, -1 do
    if Claude.state.messages[i].role == "assistant" then
      last_assistant_msg = Claude.state.messages[i]
      break
    end
  end

  if last_assistant_msg then
    -- Use the system clipboard register
    vim.fn.setreg("+", last_assistant_msg.content)
    -- Also use the unnamed register for normal Vim operations
    vim.fn.setreg('"', last_assistant_msg.content)
    vim.notify("Claude response yanked to clipboard", vim.log.levels.INFO)
  else
    vim.notify("No Claude responses to yank", vim.log.levels.INFO)
  end
end

-- Scroll up in chat window
function Claude.scroll_up()
  if Claude.state.window and vim.api.nvim_win_is_valid(Claude.state.window) then
    local current_pos = vim.api.nvim_win_get_cursor(Claude.state.window)
    if current_pos[1] > 1 then
      vim.api.nvim_win_set_cursor(Claude.state.window, { current_pos[1] - 1, current_pos[2] })
    end
  end
end

-- Scroll down in chat window
function Claude.scroll_down()
  if Claude.state.window and vim.api.nvim_win_is_valid(Claude.state.window) then
    local current_pos = vim.api.nvim_win_get_cursor(Claude.state.window)
    local line_count = vim.api.nvim_buf_line_count(Claude.state.buffer)
    if current_pos[1] < line_count then
      vim.api.nvim_win_set_cursor(Claude.state.window, { current_pos[1] + 1, current_pos[2] })
    end
  end
end

-- Coding interface functions (delegated to coding module)
function Claude.create_coding_interface()
  Claude.coding.create_interface(Claude)
end

function Claude.close_coding_interface()
  Claude.coding.close_interface(Claude)
end

function Claude.submit_code_request()
  Claude.coding.submit_request(Claude)
end

function Claude.iterate_code()
  Claude.coding.iterate(Claude)
end

function Claude.copy_code_to_clipboard()
  Claude.coding.copy_to_clipboard(Claude)
end

function Claude.apply_to_original()
  Claude.coding.apply_to_original(Claude)
end

function Claude.cycle_coding_focus()
  Claude.coding.cycle_focus(Claude)
end

function Claude.show_coding_help()
  Claude.coding.show_help(Claude)
end

-- Add a function to handle visual mode selection
function Claude.coding_visual()
  -- Just call create_coding_interface, which will check for g:claude_visual_selection
  Claude.create_coding_interface()
end

-- Initialize commands
function Claude.setup_commands()
  vim.api.nvim_create_user_command("Claude", function()
    Claude.open()
  end, {})

  vim.api.nvim_create_user_command("ClaudeSubmitLine", function()
    local line = vim.api.nvim_get_current_line()
    Claude.state.messages = {}
    Claude.state.last_response = nil
    Claude.api.send_message(Claude, line, function(response)
      vim.fn.setreg('"', response)
      Claude.state.last_response = response
      if not Claude.config.silent then
        vim.notify("Claude response copied to clipboard", vim.log.levels.INFO)
      end
    end)
  end, {})

  vim.api.nvim_create_user_command("ClaudeSubmitRange", function(opts)
    local start_line = opts.line1
    local end_line = opts.line2
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    local content = table.concat(lines, "\n")

    Claude.state.messages = {}
    Claude.state.last_response = nil
    Claude.api.send_message(Claude, content, function(response)
      vim.fn.setreg('"', response)
      Claude.state.last_response = response
      if not Claude.config.silent then
        vim.notify("Claude response copied to clipboard", vim.log.levels.INFO)
      end
    end)
  end, { range = true })

  vim.api.nvim_create_user_command("ClaudeContinue", function()
    Claude.continue_response()
  end, {})
end

-- Register the coding commands
function Claude.setup_coding_commands()
  -- Add command that properly handles range selection
  vim.api.nvim_create_user_command("ClaudeCoding", function(opts)
    -- Store the range information
    if opts.range ~= 0 then -- Check if range was provided
      local start_line = opts.line1 - 1 -- Convert to 0-indexed
      local end_line = opts.line2

      -- Get the selected lines
      local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)

      vim.g.claude_coding_range = {
        lines = lines,
        start_line = start_line,
        end_line = end_line,
        has_selection = true,
      }
    else
      vim.g.claude_coding_range = nil
    end

    -- Open the coding interface
    Claude.create_coding_interface()
  end, { range = true })
  
  -- Add a direct resize command for testing
  vim.api.nvim_create_user_command("ClaudeCodingResize", function()
    if Claude and Claude.coding and Claude.coding.ui then
      Claude.coding.ui.handle_resize(Claude.coding, Claude)
      vim.api.nvim_echo({{"Manual resize triggered", "Normal"}}, true, {})
    else
      vim.api.nvim_echo({{"Coding interface not active", "WarningMsg"}}, true, {})
    end
  end, {})
end

-- Create a dedicated visual mode command
function Claude.setup_visual_commands()
  -- Create Vimscript functions to handle visual selection
  vim.cmd([[
    function! GetVisualSelection()
      let [line_start, column_start] = getpos("'<")[1:2]
      let [line_end, column_end] = getpos("'>")[1:2]
      let lines = getline(line_start, line_end)
      
      if len(lines) == 0
        return ['', 0, 0]
      endif
      
      " Adjust first and last line for column selection
      if &selection ==# 'exclusive'
        let column_end -= 1
      endif
      
      return [lines, line_start, line_end]
    endfunction

    function! ClaudeCodingVisual()
      let [lines, start_line, end_line] = GetVisualSelection()
      if start_line == 0
        echo "No selection made"
        return
      endif
      
      " Store selection info in a global Vim variable
      let g:claude_visual_selection = {
        \ 'lines': lines, 
        \ 'start_line': start_line - 1, 
        \ 'end_line': end_line,
        \ 'has_selection': 1
        \ }
      
      " Call your Lua function to open the coding interface
      lua require('claude').coding_visual()
    endfunction
    
    " Create a visual-mode command
    command! -range ClaudeCodingVisual call ClaudeCodingVisual()
    
    " Set up a mapping for visual mode
    vnoremap <leader>cc :ClaudeCodingVisual<CR>
  ]])
end

return Claude
