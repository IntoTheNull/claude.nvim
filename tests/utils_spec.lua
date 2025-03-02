-- Tests for utils.lua module

local test_helpers = require('tests.init')
local utils = require('claude.utils')

describe('Utils module', function()
  -- Mock vim before tests
  local restore_vim
  
  before_each(function()
    restore_vim = test_helpers.mock_vim()
  end)
  
  after_each(function()
    restore_vim()
  end)
  
  describe('get_api_key', function()
    it('should return nil when api_key_cmd is not configured', function()
      local config = {}
      assert.is_nil(utils.get_api_key(config))
    end)
    
    it('should return api key when command succeeds', function()
      -- Mock the io.popen function
      local original_popen = io.popen
      io.popen = function()
        return {
          read = function() return "test-api-key" end,
          close = function() return true end
        }
      end
      
      local config = { api_key_cmd = "echo test-api-key" }
      local result = utils.get_api_key(config)
      
      -- Restore original io.popen
      io.popen = original_popen
      
      assert.are.equal("test-api-key", result)
    end)
  end)
  
  describe('create_message', function()
    it('should create a message object with role and content', function()
      local message = utils.create_message("user", "test message")
      assert.are.same({
        role = "user",
        content = "test message"
      }, message)
    end)
  end)
  
  describe('is_continue_request', function()
    it('should return true for "continue" messages', function()
      assert.is_true(utils.is_continue_request("continue"))
      assert.is_true(utils.is_continue_request("  continue  "))
      assert.is_true(utils.is_continue_request("CONTINUE"))
    end)
    
    it('should return true for "more" messages', function()
      assert.is_true(utils.is_continue_request("more"))
      assert.is_true(utils.is_continue_request("  more  "))
      assert.is_true(utils.is_continue_request("MORE"))
    end)
    
    it('should return false for other messages', function()
      assert.is_false(utils.is_continue_request("hello"))
      assert.is_false(utils.is_continue_request("continue typing"))
      assert.is_false(utils.is_continue_request("more info"))
    end)
  end)
  
  describe('process_code_response', function()
    it('should extract code from markdown code blocks', function()
      local response = [[
Here's the code:

```lua
function test()
  return "hello"
end
```

Hope this helps!
]]
      
      local result = utils.process_code_response(response)
      assert.are.equal("function test()\n  return \"hello\"\nend", result)
    end)
    
    it('should handle responses without code blocks', function()
      local response = "function test() { return 'hello'; }"
      local result = utils.process_code_response(response)
      assert.are.equal(response, result)
    end)
    
    it('should clean responses with common prefixes', function()
      local response = "Here's the code: function test() { return 'hello'; }"
      local result = utils.process_code_response(response)
      assert.are.equal("function test() { return 'hello'; }", result)
    end)
  end)
end)