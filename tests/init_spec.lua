-- Tests for the main Claude.nvim module (init.lua)

local test_helpers = require('tests.init')
local Claude = require('claude')

describe('Claude.nvim module', function()
  -- Mock vim before tests
  local restore_vim
  
  before_each(function()
    restore_vim = test_helpers.mock_vim()
    
    -- Reset Claude's state for each test
    Claude.state = {
      messages = {},
      buffer = nil,
      window = nil,
      input_buffer = nil,
      input_window = nil,
      help_buffer = nil,
      help_window = nil,
      loading = false,
      last_response = nil,
      token_stats = {
        prompt_tokens = 0,
        completion_tokens = 0,
      },
    }
  end)
  
  after_each(function()
    restore_vim()
  end)
  
  describe('setup', function()
    it('should override default config with user config', function()
      -- Save original config
      local original_config = vim.deepcopy(Claude.config)
      
      -- Call setup with custom config
      Claude.setup({
        model = "custom-model",
        max_tokens = 2000,
        temperature = 0.9,
        window = {
          width = 0.9,
        }
      })
      
      -- Check that config was updated
      assert.are.equal("custom-model", Claude.config.model)
      assert.are.equal(2000, Claude.config.max_tokens)
      assert.are.equal(0.9, Claude.config.temperature)
      assert.are.equal(0.9, Claude.config.window.width)
      
      -- Other config values should remain default
      assert.are.equal(1.0, Claude.config.top_p)
      assert.are.equal(30000, Claude.config.timeout_ms)
      
      -- Restore original config for other tests
      Claude.config = original_config
    end)
  end)
  
  describe('open', function()
    it('should initialize state and create windows', function()
      -- Mock UI functions
      local original_ui = Claude.ui
      local create_windows_called = false
      local display_messages_called = false
      
      Claude.ui = {
        init = function() end,
        create_windows = function() create_windows_called = true end,
        display_messages = function() display_messages_called = true end,
      }
      
      -- Call open function
      Claude.open()
      
      -- Restore original UI
      Claude.ui = original_ui
      
      -- Check that UI functions were called
      assert.is_true(create_windows_called)
      assert.is_true(display_messages_called)
    end)
  end)
  
  describe('submit', function()
    it('should add user message to state and call API', function()
      -- Setup mock buffers and API
      Claude.state.input_buffer = 1
      Claude.state.input_window = 1
      
      -- Mock required functions
      local original_api = vim.api
      local original_api_module = Claude.api
      
      vim.api.nvim_buf_get_lines = function() return {"Test message"} end
      vim.api.nvim_buf_set_lines = function() end
      vim.api.nvim_set_current_win = function() end
      
      local api_called = false
      Claude.api = {
        init = function() end,
        send_message = function(_, content)
          assert.are.equal("Test message", content)
          api_called = true
        end
      }
      
      -- Call submit
      Claude.submit()
      
      -- Restore original functions
      vim.api = original_api
      Claude.api = original_api_module
      
      -- Check that API was called
      assert.is_true(api_called)
    end)
    
    it('should not submit empty messages', function()
      -- Setup mock buffers and API
      Claude.state.input_buffer = 1
      
      -- Mock required functions
      local original_api = vim.api
      local original_api_module = Claude.api
      
      vim.api.nvim_buf_get_lines = function() return {""} end
      
      local api_called = false
      Claude.api = {
        send_message = function() api_called = true end
      }
      
      -- Call submit
      Claude.submit()
      
      -- Restore original functions
      vim.api = original_api
      Claude.api = original_api_module
      
      -- Check that API was not called for empty message
      assert.is_false(api_called)
    end)
  end)
  
  describe('yank_last', function()
    it('should copy the last assistant message to clipboard', function()
      -- Setup test messages
      Claude.state.messages = {
        { role = "user", content = "Hello" },
        { role = "assistant", content = "Hi there!" },
        { role = "user", content = "How are you?" },
        { role = "assistant", content = "I'm doing well!" }
      }
      
      -- Mock required functions
      local original_fn = vim.fn
      local yanked_content = nil
      
      vim.fn.setreg = function(_, content)
        yanked_content = content
      end
      
      -- Call yank_last
      Claude.yank_last()
      
      -- Restore original functions
      vim.fn = original_fn
      
      -- Check that the last assistant message was yanked
      assert.are.equal("I'm doing well!", yanked_content)
    end)
    
    it('should handle no messages gracefully', function()
      -- Setup empty messages
      Claude.state.messages = {}
      
      -- Mock required functions
      local original_fn = vim.fn
      local original_notify = vim.notify
      
      local notify_called = false
      vim.notify = function() notify_called = true end
      
      -- Call yank_last
      Claude.yank_last()
      
      -- Restore original functions
      vim.fn = original_fn
      vim.notify = original_notify
      
      -- Check that notification was shown
      assert.is_true(notify_called)
    end)
  end)
end)