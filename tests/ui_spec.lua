-- Tests for ui.lua module

local test_helpers = require('tests.init')
local ui = require('claude.ui')

describe('UI module', function()
  -- Mock vim before tests
  local restore_vim
  local Claude
  
  before_each(function()
    restore_vim = test_helpers.mock_vim()
    
    -- Create a mock Claude object
    Claude = {
      state = {
        messages = {},
        buffer = 1,
        window = 1,
        input_buffer = 2,
        input_window = 2,
        help_buffer = nil,
        help_window = nil,
        loading = false,
        token_stats = {
          prompt_tokens = 0,
          completion_tokens = 0
        }
      },
      config = {
        window = {
          width = 0.8,
          height = 0.8,
          border = "rounded"
        },
        keymaps = {
          close = "<C-c>",
          submit = "<C-Enter>",
          yank_last = "<C-y>",
          scroll_up = "<C-k>",
          scroll_down = "<C-j>",
          help = "<C-h>",
          quit = "q",
          continue = "<C-u>"
        },
        show_token_count = true
      }
    }
    
    -- Initialize the UI module
    ui.init(Claude)
  end)
  
  after_each(function()
    restore_vim()
  end)
  
  describe('create_windows', function()
    it('should create chat windows with correct configuration', function()
      -- Mock window creation functions
      local original_api = vim.api
      local buffers_created = 0
      local windows_created = 0
      
      vim.api.nvim_create_buf = function()
        buffers_created = buffers_created + 1
        return buffers_created
      end
      
      vim.api.nvim_open_win = function()
        windows_created = windows_created + 1
        return windows_created
      end
      
      -- Call the function
      ui.create_windows(Claude)
      
      -- Restore original API
      vim.api = original_api
      
      -- Check that windows and buffers were created
      assert.are.equal(2, buffers_created)  -- Chat and input buffers
      assert.are.equal(2, windows_created)  -- Chat and input windows
    end)
  end)
  
  describe('display_messages', function()
    it('should format messages correctly for display', function()
      -- Set up test messages
      Claude.state.messages = {
        { role = "user", content = "Hello Claude" },
        { role = "assistant", content = "Hello! How can I help you today?" }
      }
      
      -- Mock required functions
      local original_api = vim.api
      local lines_set = {}
      
      vim.api.nvim_buf_is_valid = function() return true end
      vim.api.nvim_buf_set_option = function() end
      vim.api.nvim_buf_set_lines = function(_, _, _, _, lines)
        lines_set = lines
      end
      vim.api.nvim_buf_line_count = function() return #lines_set end
      vim.api.nvim_win_set_cursor = function() end
      
      -- Call the function
      ui.display_messages(Claude)
      
      -- Restore original API
      vim.api = original_api
      
      -- Check that messages were formatted correctly
      assert.is_true(#lines_set > 0)
      
      -- There should be lines for each message (role + content + separator)
      local user_role_line_found = false
      local assistant_role_line_found = false
      
      for _, line in ipairs(lines_set) do
        if line == "You: " then
          user_role_line_found = true
        elseif line == "Claude: " then
          assistant_role_line_found = true
        end
      end
      
      assert.is_true(user_role_line_found)
      assert.is_true(assistant_role_line_found)
    end)
  end)
  
  describe('update_loading_status', function()
    it('should update window title based on loading state', function()
      -- Mock required functions
      local original_api = vim.api
      local title_set = nil
      
      vim.api.nvim_win_is_valid = function() return true end
      vim.api.nvim_win_set_config = function(_, config)
        title_set = config.title
      end
      
      -- Test loading state
      ui.update_loading_status(Claude, true)
      assert.are.equal(" Claude (Loading...) ", title_set)
      
      -- Test idle state
      ui.update_loading_status(Claude, false)
      assert.are.equal(" Claude ", title_set)
      
      -- Test with token stats
      Claude.state.token_stats.prompt_tokens = 100
      Claude.state.token_stats.completion_tokens = 200
      ui.update_loading_status(Claude, false)
      assert.are.equal(" Claude [In: 100, Out: 200] ", title_set)
      
      -- Restore original API
      vim.api = original_api
    end)
  end)
  
  describe('handle_resize', function()
    it('should recalculate window dimensions on resize', function()
      -- Mock required functions
      local original_api = vim.api
      local config_updates = {}
      
      vim.api.nvim_win_is_valid = function() return true end
      vim.api.nvim_win_set_config = function(win_id, config)
        config_updates[win_id] = config
      end
      
      -- Call the function
      ui.handle_resize(Claude)
      
      -- Restore original API
      vim.api = original_api
      
      -- Check that window configs were updated
      assert.is_not_nil(config_updates[1])  -- Chat window
      assert.is_not_nil(config_updates[2])  -- Input window
      
      -- Check that dimensions were calculated correctly
      assert.is_not_nil(config_updates[1].width)
      assert.is_not_nil(config_updates[1].height)
      assert.is_not_nil(config_updates[2].width)
      assert.is_not_nil(config_updates[2].height)
    end)
  end)
end)