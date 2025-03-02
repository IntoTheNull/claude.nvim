-- Claude.nvim - Coding UI module
-- Handles UI components for the coding interface

local ui = {}

-- Store reference to the coding and Claude modules
local coding
local Claude

-- Initialize the UI module
function ui.init(coding_obj, claude_obj)
  coding = coding_obj
  Claude = claude_obj
end

-- Create the UI windows for the coding interface
function ui.create_interface_windows(coding_obj, claude_obj)
  -- Get actual terminal dimensions
  local term_width = vim.o.columns
  local term_height = vim.o.lines
  
  -- Handle small screens specially
  local is_small_screen = (term_width < 100 or term_height < 30)
  
  -- Calculate dimensions based on screen size
  local win_width, win_height, panel_width, code_panel_height, instruction_panel_height
  
  if is_small_screen then
    -- For small screens, use more of the available space and smaller proportions
    win_width = math.floor(term_width * 0.97)  -- Use 97% of width
    win_height = math.floor(term_height * 0.97) -- Use 97% of height
    
    -- Calculate minimum viable heights
    local min_code_height = 10 -- Minimum reasonable code panel height
    local min_instruction_height = 3 -- Minimum instruction height
    
    -- Ensure code panels have at least the minimum height
    code_panel_height = math.max(min_code_height, math.floor(win_height * 0.82))
    
    -- Ensure instruction panel has at least the minimum height
    instruction_panel_height = math.max(min_instruction_height, 
      math.min(5, win_height - code_panel_height - 4)) -- -4 for borders and gap
    
    -- Make sure panels fit within the window
    if (code_panel_height + instruction_panel_height + 4) > win_height then
      code_panel_height = win_height - instruction_panel_height - 4
    end
    
    -- Adjust panel width for small screens
    panel_width = math.floor((win_width - 2) / 2)
  else
    -- For normal/large screens, maximize space usage
    win_width = math.floor(term_width * 0.98)  -- Use 98% of width
    win_height = math.floor(term_height * 0.98) -- Use 98% of height
    
    panel_width = math.floor((win_width - 4) / 2) -- Subtract 4 for spacing between panels
    code_panel_height = math.floor(win_height * 0.85) -- 85% for code panels
    instruction_panel_height = 5 -- Smaller fixed height for instructions
  end
  
  local instruction_panel_top_margin = 2 -- Gap
  local instruction_row_position = code_panel_height + instruction_panel_top_margin
  
  -- Center the windows
  local row = math.floor((term_height - win_height) / 2)
  local col = math.floor((term_width - win_width) / 2)
  
  -- Calculate panel positions
  local right_panel_col = col + panel_width + (is_small_screen and 2 or 4)
  
  -- Debug info using safer approach
  local log_msg = string.format("Creating coding UI with dims: %dx%d, panels: %dx%d, instr: %d", 
    win_width, win_height, panel_width, code_panel_height, instruction_panel_height)
  vim.api.nvim_echo({{log_msg, "Normal"}}, true, {})

  -- Create left buffer (input code)
  coding.state.left_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(coding.state.left_buffer, "bufhidden", "wipe")
  if coding.state.filetype and coding.state.filetype ~= "" then
    vim.api.nvim_buf_set_option(coding.state.left_buffer, "filetype", coding.state.filetype)
  end

  -- Create left window
  coding.state.left_window = vim.api.nvim_open_win(coding.state.left_buffer, true, {
    relative = "editor",
    width = panel_width,
    height = code_panel_height,
    row = row,
    col = col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Original Code ",
    title_pos = "center",
  })

  -- Create right buffer (Claude's code response)
  coding.state.right_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(coding.state.right_buffer, "bufhidden", "wipe")
  if coding.state.filetype and coding.state.filetype ~= "" then
    vim.api.nvim_buf_set_option(coding.state.right_buffer, "filetype", coding.state.filetype)
  end

  -- Create right window with gap between left window
  coding.state.right_window = vim.api.nvim_open_win(coding.state.right_buffer, false, {
    relative = "editor",
    width = panel_width,
    height = code_panel_height,
    row = row,
    col = right_panel_col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Claude's Code ",
    title_pos = "center",
  })

  -- Create instruction buffer and window (below both panels)
  coding.state.instruction_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(coding.state.instruction_buffer, "bufhidden", "wipe")

  coding.state.instruction_window = vim.api.nvim_open_win(coding.state.instruction_buffer, false, {
    relative = "editor",
    width = win_width,
    height = instruction_panel_height,
    row = row + instruction_row_position,
    col = col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Instructions for Claude ",
    title_pos = "center",
  })

  -- Set up default instruction text
  local default_instruction = "Refactor this code to make it more efficient and maintainable."
  vim.api.nvim_buf_set_lines(coding.state.instruction_buffer, 0, -1, false, { default_instruction })

  -- Set options for windows
  vim.api.nvim_win_set_option(coding.state.left_window, "wrap", false)
  vim.api.nvim_win_set_option(coding.state.right_window, "wrap", false)
  vim.api.nvim_win_set_option(coding.state.instruction_window, "wrap", true)

  -- Add text offset to ensure content is visible
  vim.wo[coding.state.left_window].signcolumn = "no"
  vim.wo[coding.state.right_window].signcolumn = "no"

  -- Set up resize handling - Do this AFTER all windows are created
  ui.setup_resize_handling(coding_obj, claude_obj)
  
  -- Force an initial resize to ensure proper layout
  vim.api.nvim_echo({{"Triggering initial resize", "Normal"}}, true, {})
  vim.schedule(function()
    ui.handle_resize(coding_obj, claude_obj)
  end)
end

-- Set up resize event handling for coding interface
function ui.setup_resize_handling(coding_obj, claude_obj)
  -- Store references directly in setup_resize_handling's closure
  local stored_coding = coding_obj
  local stored_claude = claude_obj
  
  -- Create autocmd through API instead of vim.cmd
  local augroup = vim.api.nvim_create_augroup("ClaudeCodingResize", { clear = true })
  
  vim.api.nvim_create_autocmd("VimResized", {
    group = augroup,
    callback = function()
      vim.schedule(function()
        -- Safety check
        if stored_coding and stored_claude and ui.handle_resize then
          -- Call resize directly with stored references
          ui.handle_resize(stored_coding, stored_claude)
        end
      end)
    end,
  })
  
  -- Debug message using safer approach
  vim.api.nvim_echo({{"Claude Coding resize handler installed (API version)", "Normal"}}, true, {})
end

-- Handle resize events for coding interface
function ui.handle_resize(coding_obj, claude_obj)
  -- Use pcall to safely handle errors
  local status, err = pcall(function()
    -- Print debug message using safer approach
    local dims_msg = string.format("Claude Coding resize triggered with dims: %dx%d", vim.o.columns, vim.o.lines)
    vim.api.nvim_echo({{dims_msg, "Normal"}}, true, {})
    
    -- Make sure coding is valid and has a state field
    if not (coding_obj and coding_obj.state) then
      vim.api.nvim_echo({{"Claude Coding resize: invalid coding object", "WarningMsg"}}, true, {})
      return
    end
    
    -- Use coding_obj's state instead of global coding
    local coding_state = coding_obj.state
    
    -- Only proceed if windows are valid
    if
      not (
        coding_state.left_window
        and vim.api.nvim_win_is_valid(coding_state.left_window)
        and coding_state.right_window
        and vim.api.nvim_win_is_valid(coding_state.right_window)
        and coding_state.instruction_window
        and vim.api.nvim_win_is_valid(coding_state.instruction_window)
      )
    then
      vim.api.nvim_echo({{"Claude Coding resize: windows invalid", "WarningMsg"}}, true, {})
      return
    end
  
  -- First, save contents and cursor positions
  local left_lines = vim.api.nvim_buf_get_lines(coding_state.left_buffer, 0, -1, false)
  local right_lines = vim.api.nvim_buf_get_lines(coding_state.right_buffer, 0, -1, false)
  local instruction_lines = vim.api.nvim_buf_get_lines(coding_state.instruction_buffer, 0, -1, false)
  
  local left_cursor = vim.api.nvim_win_get_cursor(coding_state.left_window)
  local current_win = vim.api.nvim_get_current_win()
  
  -- Get actual terminal dimensions
  local term_width = vim.o.columns
  local term_height = vim.o.lines
  
  -- Handle small screens specially
  local is_small_screen = (term_width < 100 or term_height < 30)
  
  -- Calculate dimensions based on screen size
  local win_width, win_height, panel_width, code_panel_height, instruction_panel_height
  
  if is_small_screen then
    -- For small screens, use more of the available space and smaller proportions
    win_width = math.floor(term_width * 0.97)  -- Use 97% of width
    win_height = math.floor(term_height * 0.97) -- Use 97% of height
    
    -- Calculate minimum viable heights
    local min_code_height = 10 -- Minimum reasonable code panel height
    local min_instruction_height = 3 -- Minimum instruction height
    
    -- Ensure code panels have at least the minimum height
    code_panel_height = math.max(min_code_height, math.floor(win_height * 0.82))
    
    -- Ensure instruction panel has at least the minimum height
    instruction_panel_height = math.max(min_instruction_height, 
      math.min(5, win_height - code_panel_height - 4)) -- -4 for borders and gap
    
    -- Make sure panels fit within the window
    if (code_panel_height + instruction_panel_height + 4) > win_height then
      code_panel_height = win_height - instruction_panel_height - 4
    end
    
    -- Adjust panel width for small screens
    panel_width = math.floor((win_width - 2) / 2)
  else
    -- For normal/large screens, maximize space usage
    win_width = math.floor(term_width * 0.98)  -- Use 98% of width
    win_height = math.floor(term_height * 0.98) -- Use 98% of height
    
    panel_width = math.floor((win_width - 4) / 2) -- Subtract 4 for spacing between panels
    code_panel_height = math.floor(win_height * 0.85) -- 85% for code panels
    instruction_panel_height = 5 -- Smaller fixed height for instructions
  end
  
  local instruction_panel_top_margin = 2 -- Gap
  local instruction_row_position = code_panel_height + instruction_panel_top_margin
  
  -- Center the windows
  local row = math.floor((term_height - win_height) / 2)
  local col = math.floor((term_width - win_width) / 2)
  
  -- Calculate panel positions
  local right_panel_col = col + panel_width + (is_small_screen and 2 or 4)
  
  -- Log calculated dimensions using safer approach
  local log_msg = string.format("Dimensions: term=%dx%d, win=%dx%d, panels=%dx%d, instr=%d", 
    term_width, term_height, win_width, win_height, panel_width, code_panel_height, instruction_panel_height)
  vim.api.nvim_echo({{log_msg, "Normal"}}, true, {})
  
  -- Close existing windows
  if vim.api.nvim_win_is_valid(coding_state.left_window) then
    vim.api.nvim_win_close(coding_state.left_window, true)
  end
  
  if vim.api.nvim_win_is_valid(coding_state.right_window) then
    vim.api.nvim_win_close(coding_state.right_window, true)
  end
  
  if vim.api.nvim_win_is_valid(coding_state.instruction_window) then
    vim.api.nvim_win_close(coding_state.instruction_window, true)
  end
  
  -- Create new windows with correct sizes
  -- Left window
  coding_state.left_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(coding_state.left_buffer, "bufhidden", "wipe")
  if coding_state.filetype and coding_state.filetype ~= "" then
    vim.api.nvim_buf_set_option(coding_state.left_buffer, "filetype", coding_state.filetype)
  end
  
  coding_state.left_window = vim.api.nvim_open_win(coding_state.left_buffer, false, {
    relative = "editor",
    width = panel_width,
    height = code_panel_height,
    row = row,
    col = col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Original Code ",
    title_pos = "center",
  })
  
  -- Right window
  coding_state.right_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(coding_state.right_buffer, "bufhidden", "wipe")
  if coding_state.filetype and coding_state.filetype ~= "" then
    vim.api.nvim_buf_set_option(coding_state.right_buffer, "filetype", coding_state.filetype)
  end
  
  coding_state.right_window = vim.api.nvim_open_win(coding_state.right_buffer, false, {
    relative = "editor",
    width = panel_width,
    height = code_panel_height,
    row = row,
    col = right_panel_col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Claude's Code ",
    title_pos = "center",
  })
  
  -- Instruction window
  coding_state.instruction_buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(coding_state.instruction_buffer, "bufhidden", "wipe")
  
  coding_state.instruction_window = vim.api.nvim_open_win(coding_state.instruction_buffer, false, {
    relative = "editor",
    width = win_width,
    height = instruction_panel_height,
    row = row + instruction_row_position,
    col = col,
    style = "minimal",
    border = claude_obj.config.window.border,
    title = " Instructions for Claude ",
    title_pos = "center",
  })
  
  -- Restore content
  vim.api.nvim_buf_set_lines(coding_state.left_buffer, 0, -1, false, left_lines)
  vim.api.nvim_buf_set_lines(coding_state.right_buffer, 0, -1, false, right_lines)
  vim.api.nvim_buf_set_lines(coding_state.instruction_buffer, 0, -1, false, instruction_lines)
  
  -- Restore cursor position
  if left_cursor then
    pcall(vim.api.nvim_win_set_cursor, coding_state.left_window, left_cursor)
  end
  
  -- Set options for windows
  vim.api.nvim_win_set_option(coding_state.left_window, "wrap", false)
  vim.api.nvim_win_set_option(coding_state.right_window, "wrap", false)
  vim.api.nvim_win_set_option(coding_state.instruction_window, "wrap", true)
  
  -- Add text offset to ensure content is visible
  vim.wo[coding_state.left_window].signcolumn = "no"
  vim.wo[coding_state.right_window].signcolumn = "no"
  
  -- Set up keymaps for the new windows/buffers
  ui.setup_keymaps(coding_obj, claude_obj)
  
  -- Try to restore focus to the window that had it
  if current_win == coding_state.left_window then
    vim.api.nvim_set_current_win(coding_state.left_window)
  elseif current_win == coding_state.right_window then
    vim.api.nvim_set_current_win(coding_state.right_window)
  elseif current_win == coding_state.instruction_window then
    vim.api.nvim_set_current_win(coding_state.instruction_window)
  end
  
  vim.api.nvim_echo({{"Claude Coding resize complete", "Normal"}}, true, {})
  end) -- End of pcall function
  
  -- Handle any errors that occurred during resize
  if not status then
    vim.api.nvim_echo({{"Claude Coding resize error: " .. tostring(err), "ErrorMsg"}}, true, {})
  end
end

-- Set up keymaps for the coding interface
function ui.setup_keymaps(coding_obj, claude_obj)
  -- Universal keymaps
  local buffers = { coding.state.left_buffer, coding.state.right_buffer, coding.state.instruction_buffer }

  for _, buffer in ipairs(buffers) do
    -- Submit instruction to Claude
    vim.api.nvim_buf_set_keymap(
      buffer,
      "n",
      "<C-s>",
      ":lua require('claude').submit_code_request()<CR>",
      { noremap = true, silent = true }
    )

    -- Also add Enter in normal mode for instruction buffer to submit
    if buffer == coding.state.instruction_buffer then
      vim.api.nvim_buf_set_keymap(
        buffer,
        "n",
        "<CR>",
        ":lua require('claude').submit_code_request()<CR>",
        { noremap = true, silent = true }
      )

      -- Also add Ctrl+Enter in insert mode for instruction buffer
      vim.api.nvim_buf_set_keymap(
        buffer,
        "i",
        "<C-Enter>",
        "<Esc>:lua require('claude').submit_code_request()<CR>",
        { noremap = true, silent = true }
      )
    end

    -- Close coding interface
    vim.api.nvim_buf_set_keymap(
      buffer,
      "n",
      "q",
      ":lua require('claude').close_coding_interface()<CR>",
      { noremap = true, silent = true }
    )

    -- Use right code as new input
    vim.api.nvim_buf_set_keymap(
      buffer,
      "n",
      "<C-i>",
      ":lua require('claude').iterate_code()<CR>",
      { noremap = true, silent = true }
    )

    -- Copy right code to clipboard
    vim.api.nvim_buf_set_keymap(
      buffer,
      "n",
      "<C-y>",
      ":lua require('claude').copy_code_to_clipboard()<CR>",
      { noremap = true, silent = true }
    )

    -- Replace code in original buffer
    vim.api.nvim_buf_set_keymap(
      buffer,
      "n",
      "<C-a>",
      ":lua require('claude').apply_to_original()<CR>",
      { noremap = true, silent = true }
    )

    -- Switch between panels
    vim.api.nvim_buf_set_keymap(
      buffer,
      "n",
      "<Tab>",
      ":lua require('claude').cycle_coding_focus()<CR>",
      { noremap = true, silent = true }
    )

    -- Help window access
    vim.api.nvim_buf_set_keymap(
      buffer,
      "n",
      claude_obj.config.keymaps.help,
      ":lua require('claude').show_coding_help()<CR>",
      { noremap = true, silent = true }
    )
  end
end

-- Close the coding interface windows
function ui.close_interface(coding_obj, claude_obj)
  -- Remove the resize autocmd using the API
  pcall(vim.api.nvim_del_augroup_by_name, "ClaudeCodingResize")
  
  -- Debug message using safer approach
  vim.api.nvim_echo({{"Claude Coding interface closing", "Normal"}}, true, {})

  -- Close all windows
  if coding.state.left_window and vim.api.nvim_win_is_valid(coding.state.left_window) then
    vim.api.nvim_win_close(coding.state.left_window, true)
  end

  if coding.state.right_window and vim.api.nvim_win_is_valid(coding.state.right_window) then
    vim.api.nvim_win_close(coding.state.right_window, true)
  end

  if coding.state.instruction_window and vim.api.nvim_win_is_valid(coding.state.instruction_window) then
    vim.api.nvim_win_close(coding.state.instruction_window, true)
  end

  -- Return to original window if it's still valid
  if coding.state.original_window and vim.api.nvim_win_is_valid(coding.state.original_window) then
    vim.api.nvim_set_current_win(coding.state.original_window)
  end

  -- Reset state
  coding.state = {
    left_buffer = nil,
    left_window = nil,
    right_buffer = nil,
    right_window = nil,
    instruction_buffer = nil,
    instruction_window = nil,
    original_window = nil,
    original_buffer = nil,
    filetype = nil,
    selection = {
      start_line = nil,
      end_line = nil,
      has_selection = false,
    },
    token_stats = {
      prompt_tokens = 0,
      completion_tokens = 0,
    },
  }
end

-- Cycle focus between panels
function ui.cycle_focus(coding_obj, claude_obj)
  local current_win = vim.api.nvim_get_current_win()

  if current_win == coding.state.left_window then
    vim.api.nvim_set_current_win(coding.state.instruction_window)
  elseif current_win == coding.state.instruction_window then
    vim.api.nvim_set_current_win(coding.state.right_window)
  elseif current_win == coding.state.right_window then
    vim.api.nvim_set_current_win(coding.state.left_window)
  else
    -- If we're somehow in a different window, go to left
    vim.api.nvim_set_current_win(coding.state.left_window)
  end
end

-- Show help window for coding interface
function ui.show_help(coding_obj, claude_obj)
  Claude.ui.create_coding_help_window(claude_obj)
end

return ui