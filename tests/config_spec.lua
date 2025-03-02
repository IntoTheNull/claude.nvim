-- Tests for config.lua module

local test_helpers = require('tests.init')
local config = require('claude.config')

describe('Config module', function()
  -- Mock vim before tests
  local restore_vim
  
  before_each(function()
    restore_vim = test_helpers.mock_vim()
  end)
  
  after_each(function()
    restore_vim()
  end)
  
  it('should have default configuration values', function()
    -- Check default model
    assert.are.equal("claude-3-7-sonnet-20250219", config.model)
    
    -- Check default token limits
    assert.are.equal(4000, config.max_tokens)
    
    -- Check default temperature
    assert.are.equal(0.7, config.temperature)
    
    -- Check default top_p
    assert.are.equal(1.0, config.top_p)
    
    -- Check default timeout
    assert.are.equal(30000, config.timeout_ms)
    
    -- Check UI settings
    assert.are.equal(0.8, config.window.width)
    assert.are.equal(0.8, config.window.height)
    
    -- Check keymaps
    assert.are.equal("<C-c>", config.keymaps.close)
    assert.are.equal("<C-Enter>", config.keymaps.submit)
    assert.are.equal("<C-y>", config.keymaps.yank_last)
    assert.are.equal("<C-k>", config.keymaps.scroll_up)
    assert.are.equal("<C-j>", config.keymaps.scroll_down)
    assert.are.equal("<C-h>", config.keymaps.help)
    assert.are.equal("q", config.keymaps.quit)
    assert.are.equal("<C-u>", config.keymaps.continue)
    
    -- Check behavior options
    assert.is_false(config.silent)
    assert.is_true(config.show_token_count)
  end)
end)