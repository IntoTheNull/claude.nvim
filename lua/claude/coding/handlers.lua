-- Claude.nvim - Coding handlers module
-- Handles action handlers for the coding interface

local handlers = {}

-- Store reference to the coding and Claude modules
local coding
local Claude -- Used internally by module

-- Initialize the handlers module
function handlers.init(coding_obj, claude_obj)
  coding = coding_obj
  Claude = claude_obj
end

-- Handle code selection (visual selection or range command)
function handlers.handle_code_selection(coding_obj, claude_obj)
  -- SELECTION HANDLING
  -- First check for visual selection (from ClaudeCodingVisual command)
  if vim.g.claude_visual_selection and vim.g.claude_visual_selection.has_selection == 1 then
    -- Use selection data from visual mode
    coding.state.selection.has_selection = true
    coding.state.selection.start_line = vim.g.claude_visual_selection.start_line
    coding.state.selection.end_line = vim.g.claude_visual_selection.end_line

    -- Set the selected lines directly
    vim.api.nvim_buf_set_lines(coding.state.left_buffer, 0, -1, false, vim.g.claude_visual_selection.lines)

    -- Clear the global variable
    vim.g.claude_visual_selection = nil

  -- Then check for range selection (from :range ClaudeCoding command)
  elseif vim.g.claude_coding_range and vim.g.claude_coding_range.has_selection then
    -- Use range from command
    coding.state.selection.has_selection = true
    coding.state.selection.start_line = vim.g.claude_coding_range.start_line
    coding.state.selection.end_line = vim.g.claude_coding_range.end_line

    -- Set the selected lines directly
    vim.api.nvim_buf_set_lines(coding.state.left_buffer, 0, -1, false, vim.g.claude_coding_range.lines)

    -- Clear the global range variable
    vim.g.claude_coding_range = nil

  -- If no selection, use the entire buffer
  else
    -- No selection, get entire file content
    local lines = vim.api.nvim_buf_get_lines(coding.state.original_buffer, 0, -1, false)
    vim.api.nvim_buf_set_lines(coding.state.left_buffer, 0, -1, false, lines)
  end
end

-- Submit code request to Claude
function handlers.submit_request(coding_obj, claude_obj)
  -- Get code from left buffer
  local code_lines = vim.api.nvim_buf_get_lines(coding.state.left_buffer, 0, -1, false)
  local code = table.concat(code_lines, "\n")

  -- Get instruction from instruction buffer
  local instruction_lines = vim.api.nvim_buf_get_lines(coding.state.instruction_buffer, 0, -1, false)
  local instruction = table.concat(instruction_lines, "\n")

  -- Update UI to show we're waiting for a response
  vim.api.nvim_win_set_config(coding.state.right_window, { title = " Loading... " })

  -- Clear the right buffer
  vim.api.nvim_buf_set_lines(coding.state.right_buffer, 0, -1, false, { "Waiting for Claude's response..." })

  -- Call Claude API
  local success = claude_obj.api.send_code_request(claude_obj, code, instruction, function(clean_code, token_info)
    -- Store token stats if available
    if token_info then
      coding.state.token_stats.prompt_tokens = token_info.prompt_tokens or 0
      coding.state.token_stats.completion_tokens = token_info.completion_tokens or 0

      -- Update the window title to show token information
      vim.api.nvim_win_set_config(coding.state.right_window, {
        title = string.format(
          " Claude's Code [In: %d, Out: %d] ",
          coding.state.token_stats.prompt_tokens,
          coding.state.token_stats.completion_tokens
        ),
      })

      -- Show token count notification
      local token_display = string.format(
        "Tokens: %d input, %d output, %d total",
        coding.state.token_stats.prompt_tokens,
        coding.state.token_stats.completion_tokens,
        coding.state.token_stats.prompt_tokens + coding.state.token_stats.completion_tokens
      )
      vim.notify(token_display, vim.log.levels.INFO)
    else
      vim.api.nvim_win_set_config(coding.state.right_window, { title = " Claude's Code " })
    end

    -- Update the right buffer with Claude's code
    vim.schedule(function()
      vim.api.nvim_buf_set_lines(coding.state.right_buffer, 0, -1, false, vim.split(clean_code, "\n"))

      -- Apply syntax highlighting
      if coding.state.filetype and coding.state.filetype ~= "" then
        vim.api.nvim_buf_set_option(coding.state.right_buffer, "filetype", coding.state.filetype)
      end
    end)
  end)

  if not success then
    vim.api.nvim_win_set_config(coding.state.right_window, { title = " Error " })
  end
end

-- Use code from right pane as new input (iterate)
function handlers.iterate(coding_obj, claude_obj)
  -- Get code from right buffer
  local code_lines = vim.api.nvim_buf_get_lines(coding.state.right_buffer, 0, -1, false)

  -- Set it in the left buffer
  vim.api.nvim_buf_set_lines(coding.state.left_buffer, 0, -1, false, code_lines)

  -- Focus on the instruction window for next iteration
  vim.api.nvim_set_current_win(coding.state.instruction_window)

  -- Clear right buffer for next response
  vim.api.nvim_buf_set_lines(coding.state.right_buffer, 0, -1, false, { "Waiting for next iteration..." })

  -- Reset token display in the window title
  vim.api.nvim_win_set_config(coding.state.right_window, { title = " Claude's Code " })
end

-- Copy code from right pane to clipboard
function handlers.copy_to_clipboard(coding_obj, claude_obj)
  -- Get code from right buffer
  local code_lines = vim.api.nvim_buf_get_lines(coding.state.right_buffer, 0, -1, false)
  local code = table.concat(code_lines, "\n")

  -- Copy to system clipboard and unnamed register
  vim.fn.setreg("+", code)
  vim.fn.setreg('"', code)

  vim.notify("Code copied to clipboard", vim.log.levels.INFO)
end

-- Apply code from right pane to original buffer
function handlers.apply_to_original(coding_obj, claude_obj)
  -- Get code from right buffer
  local code_lines = vim.api.nvim_buf_get_lines(coding.state.right_buffer, 0, -1, false)

  -- Check if original buffer is still valid
  if coding.state.original_buffer and vim.api.nvim_buf_is_valid(coding.state.original_buffer) then
    -- If we have a selection, only replace that portion
    if coding.state.selection.has_selection then
      -- Replace only the selected range
      vim.api.nvim_buf_set_lines(
        coding.state.original_buffer,
        coding.state.selection.start_line,
        coding.state.selection.end_line,
        false,
        code_lines
      )
      vim.notify("Code applied to selected range in original buffer", vim.log.levels.INFO)
    else
      -- Replace entire buffer content
      vim.api.nvim_buf_set_lines(coding.state.original_buffer, 0, -1, false, code_lines)
      vim.notify("Code applied to original buffer", vim.log.levels.INFO)
    end
  else
    vim.notify("Original buffer no longer valid", vim.log.levels.ERROR)
  end
end

return handlers
