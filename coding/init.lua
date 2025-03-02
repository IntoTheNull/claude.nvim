-- Claude.nvim - Coding interface module
-- Provides a specialized UI for code generation and refinement

-- Load sub-modules
local ui = require("claude.coding.ui")
local handlers = require("claude.coding.handlers")

local coding = {}

-- Store reference to main Claude object
local Claude

-- State for the coding interface
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
  -- Store selection range for targeted replacement
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

-- Initialize the coding module
function coding.init(claude_obj)
  Claude = claude_obj
  ui.init(coding, claude_obj)
  handlers.init(coding, claude_obj)
end

-- Create the coding UI with left (input) and right (output) panes
function coding.create_interface(claude_obj)
  -- Save the current window and buffer
  coding.state.original_window = vim.api.nvim_get_current_win()
  coding.state.original_buffer = vim.api.nvim_get_current_buf()

  -- Get current buffer's filetype for syntax highlighting
  coding.state.filetype = vim.api.nvim_buf_get_option(coding.state.original_buffer, "filetype")

  -- Create the UI components
  ui.create_interface_windows(coding, claude_obj)

  -- Set up keymaps for the coding interface
  ui.setup_keymaps(coding, claude_obj)

  -- Initialize the selection state
  coding.state.selection = {
    start_line = nil,
    end_line = nil,
    has_selection = false,
  }

  -- Handle code selection - Visual selection or range command
  handlers.handle_code_selection(coding, claude_obj)

  -- Focus on the instruction window
  vim.api.nvim_set_current_win(coding.state.instruction_window)
end

-- Close the coding interface
function coding.close_interface(claude_obj)
  ui.close_interface(coding, claude_obj)
end

-- Submit code request to Claude
function coding.submit_request(claude_obj)
  handlers.submit_request(coding, claude_obj)
end

-- Use code from right pane as new input (iterate)
function coding.iterate(claude_obj)
  handlers.iterate(coding, claude_obj)
end

-- Copy code from right pane to clipboard
function coding.copy_to_clipboard(claude_obj)
  handlers.copy_to_clipboard(coding, claude_obj)
end

-- Apply code from right pane to original buffer
function coding.apply_to_original(claude_obj)
  handlers.apply_to_original(coding, claude_obj)
end

-- Cycle focus between panels
function coding.cycle_focus(claude_obj)
  ui.cycle_focus(coding, claude_obj)
end

-- Show help window for coding interface
function coding.show_help(claude_obj)
  ui.show_help(coding, claude_obj)
end

return coding
