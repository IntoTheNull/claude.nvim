-- Tests for the coding module (coding/init.lua)

local test_helpers = require('tests.init')
local coding = require('claude.coding')

describe('Coding module', function()
  -- Mock vim before tests
  local restore_vim
  local Claude
  
  before_each(function()
    restore_vim = test_helpers.mock_vim()
    
    -- Create a mock Claude object
    Claude = {
      utils = {
        get_api_key = function() return "test-api-key" end,
        create_message = function(role, content) 
          return {role = role, content = content} 
        end,
        process_code_response = function(response)
          return response:gsub("```[%w_]*%s*\n(.-)\n```", "%1")
        end
      },
      api = {
        send_code_request = function(_, code, instruction, callback)
          -- Mock API response
          callback("processed code", {
            prompt_tokens = 100,
            completion_tokens = 200
          })
          return true
        end
      },
      state = {
        messages = {},
        original_buffer = 1,
        original_window = 1
      },
      config = {
        window = {
          width = 0.8,
          height = 0.8,
          border = "rounded"
        },
        keymaps = {
          help = "<C-h>"
        }
      }
    }
    
    -- Reset coding module state
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
    
    -- Initialize the coding module
    coding.init(Claude)
  end)
  
  after_each(function()
    restore_vim()
  end)
  
  describe('create_interface', function()
    it('should initialize coding interface state', function()
      -- Mock UI functions
      local original_ui = coding.ui
      local create_windows_called = false
      
      coding.ui = {
        init = function() end,
        create_interface_windows = function() create_windows_called = true end,
        setup_keymaps = function() end
      }
      
      -- Mock handlers
      local original_handlers = coding.handlers
      local handle_selection_called = false
      
      coding.handlers = {
        init = function() end,
        handle_code_selection = function() handle_selection_called = true end
      }
      
      -- Call create_interface
      coding.create_interface(Claude)
      
      -- Restore original modules
      coding.ui = original_ui
      coding.handlers = original_handlers
      
      -- Check that interface was created
      assert.is_true(create_windows_called)
      assert.is_true(handle_selection_called)
    end)
  end)
  
  describe('submit_request', function()
    it('should send code to API and update UI', function()
      -- Setup test state
      coding.state.left_buffer = 1
      coding.state.instruction_buffer = 2
      
      -- Mock required functions
      local original_api = vim.api
      
      vim.api.nvim_buf_get_lines = function(buf_id, _, _, _)
        if buf_id == 1 then
          return {"function test() {", "  return 'hello';", "}"}
        else
          return {"Refactor this code"}
        end
      end
      
      vim.api.nvim_buf_set_lines = function() end
      vim.api.nvim_win_is_valid = function() return true end
      
      -- Call submit_request
      coding.submit_request(Claude)
      
      -- Restore original functions
      vim.api = original_api
      
      -- Check that state was updated
      assert.are.equal(100, coding.state.token_stats.prompt_tokens)
      assert.are.equal(200, coding.state.token_stats.completion_tokens)
    end)
  end)
  
  describe('apply_to_original', function()
    it('should apply code changes to the original buffer', function()
      -- Setup test state
      coding.state = {
        right_buffer = 1,
        original_buffer = 2,
        original_window = 2,
        selection = {
          has_selection = true,
          start_line = 0,
          end_line = 3
        }
      }
      
      -- Mock required functions
      local original_api = vim.api
      local lines_set = nil
      local original_restored = false
      
      vim.api.nvim_buf_get_lines = function() 
        return {"modified code line 1", "modified code line 2"} 
      end
      
      vim.api.nvim_buf_set_lines = function(buf_id, start_line, end_line, _, lines)
        if buf_id == 2 then
          lines_set = lines
          assert.are.equal(0, start_line)
          assert.are.equal(3, end_line)
        end
      end
      
      vim.api.nvim_set_current_win = function(win_id)
        if win_id == 2 then
          original_restored = true
        end
      end
      
      vim.api.nvim_win_is_valid = function() return true end
      vim.api.nvim_buf_is_valid = function() return true end
      
      -- Call apply_to_original
      coding.apply_to_original(Claude)
      
      -- Restore original functions
      vim.api = original_api
      
      -- Check that code was applied
      assert.are.same({"modified code line 1", "modified code line 2"}, lines_set)
      assert.is_true(original_restored)
    end)
  end)
  
  describe('copy_to_clipboard', function()
    it('should copy code to clipboard', function()
      -- Setup test state
      coding.state.right_buffer = 1
      
      -- Mock required functions
      local original_api = vim.api
      local original_fn = vim.fn
      local clipboard_content = nil
      
      vim.api.nvim_buf_get_lines = function() 
        return {"code line 1", "code line 2"} 
      end
      
      vim.fn.setreg = function(_, content)
        clipboard_content = content
      end
      
      -- Call copy_to_clipboard
      coding.copy_to_clipboard(Claude)
      
      -- Restore original functions
      vim.api = original_api
      vim.fn = original_fn
      
      -- Check that code was copied
      assert.are.equal("code line 1\ncode line 2", clipboard_content)
    end)
  end)
end)