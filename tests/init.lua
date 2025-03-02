-- Init file for tests
-- Sets up the test environment

local M = {}

-- Setup function that runs before tests
function M.setup()
  -- Create any test environment setup here
end

-- Teardown function that runs after tests
function M.teardown()
  -- Clean up any test environment setup here
end

-- Mock the vim namespace for unit tests that don't need actual Neovim
function M.mock_vim()
  -- Save the original vim object
  local original_vim = _G.vim
  
  -- Create a mock vim namespace
  _G.vim = {
    -- Minimal mocking of frequently used functions
    api = {
      nvim_create_buf = function() return 1 end,
      nvim_buf_set_lines = function() return true end,
      nvim_buf_set_option = function() return true end,
      nvim_win_set_option = function() return true end,
      nvim_open_win = function() return 1 end,
      nvim_win_set_config = function() return true end,
      nvim_buf_is_valid = function() return true end,
      nvim_win_is_valid = function() return true end,
      nvim_win_close = function() return true end,
      nvim_echo = function() return true end,
      nvim_create_autocmd = function() return 1 end,
      nvim_create_augroup = function() return 1 end,
      nvim_get_current_win = function() return 1 end,
      nvim_set_current_win = function() return true end,
      nvim_buf_get_lines = function() return {} end,
      nvim_win_get_cursor = function() return {1, 0} end,
      nvim_win_set_cursor = function() return true end,
    },
    fn = {
      json_encode = function(data) return vim.json.encode(data) end,
      json_decode = function(data) return vim.json.decode(data) end,
      jobstart = function() return 1 end,
      setreg = function() return true end,
    },
    cmd = function() return true end,
    g = {},
    o = {
      columns = 120,
      lines = 40,
    },
    notify = function() return true end,
    log = {
      levels = {
        ERROR = 1,
        WARN = 2,
        INFO = 3,
        DEBUG = 4,
      }
    },
    json = {
      encode = function(data)
        local status, result = pcall(function()
          return vim.json.encode(data)
        end)
        if status then
          return result
        else
          return "{}"
        end
      end,
      decode = function(data)
        local status, result = pcall(function()
          return vim.json.decode(data)
        end)
        if status then
          return result
        else
          return {}
        end
      end,
    },
  }
  
  -- Return a function to restore original vim
  return function()
    _G.vim = original_vim
  end
end

return M