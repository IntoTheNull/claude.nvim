-- Tests for api.lua module

local test_helpers = require('tests.init')
local api = require('claude.api')

describe('API module', function()
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
        is_continue_request = function(content)
          return content == "continue" or content == "more"
        end,
        process_code_response = function(response)
          return response:gsub("```[%w_]*%s*\n(.-)\n```", "%1")
        end
      },
      ui = {
        update_loading_status = function() end,
        display_messages = function() end
      },
      state = {
        messages = {},
        loading = false,
        last_response = nil,
        token_stats = {
          prompt_tokens = 0,
          completion_tokens = 0
        }
      },
      config = {
        model = "test-model",
        max_tokens = 1000,
        temperature = 0.5,
        top_p = 1.0,
        silent = false
      },
      coding = {
        state = {
          filetype = "lua"
        }
      }
    }
    
    -- Initialize the API module
    api.init(Claude)
  end)
  
  after_each(function()
    restore_vim()
  end)
  
  describe('send_message', function()
    it('should update state when sending a message', function()
      local callback_called = false
      local callback = function() callback_called = true end
      
      -- Mock API call
      local original_fn = vim.fn
      vim.fn = {
        jobstart = function() return 1 end,
        json_encode = function() return '{}' end
      }
      
      -- Send a test message
      api.send_message(Claude, "test message", callback)
      
      -- Restore original function
      vim.fn = original_fn
      
      -- Check that state was updated
      assert.is_true(Claude.state.loading)
      assert.are.equal(1, #Claude.state.messages)
      assert.are.equal("user", Claude.state.messages[1].role)
      assert.are.equal("test message", Claude.state.messages[1].content)
    end)
    
    it('should handle continuation requests differently', function()
      -- Set up state for continuation
      Claude.state.last_response = "Previous response"
      
      -- Mock API call
      local original_fn = vim.fn
      vim.fn = {
        jobstart = function() return 1 end,
        json_encode = function() return '{}' end
      }
      
      -- Send a continuation message
      api.send_message(Claude, "continue")
      
      -- Restore original function
      vim.fn = original_fn
      
      -- Check that state was updated for continuation
      assert.is_true(Claude.state.loading)
      assert.are.equal(1, #Claude.state.messages)
      assert.are.equal("user", Claude.state.messages[1].role)
      assert.are.equal("Please continue your previous response.", Claude.state.messages[1].content)
    end)
  end)
  
  describe('send_code_request', function()
    it('should format code requests correctly', function()
      local callback_called = false
      local callback = function() callback_called = true end
      
      -- Mock API call
      local original_fn = vim.fn
      vim.fn = {
        jobstart = function() return 1 end,
        json_encode = function(data) 
          -- Check that the message is formatted correctly
          assert.are.equal("test-model", data.model)
          assert.are.equal(1, #data.messages)
          assert.are.equal("user", data.messages[1].role)
          -- The prompt should contain the code and instruction
          assert.is_true(data.messages[1].content:find("test code") ~= nil)
          assert.is_true(data.messages[1].content:find("test instruction") ~= nil)
          return '{}' 
        end
      }
      
      -- Send a code request
      local result = api.send_code_request(Claude, "test code", "test instruction", callback)
      
      -- Restore original function
      vim.fn = original_fn
      
      -- Check that the request was sent
      assert.is_true(result)
    end)
  end)
end)