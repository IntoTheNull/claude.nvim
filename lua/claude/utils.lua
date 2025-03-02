-- Claude.nvim - Utility functions

local utils = {}

-- Get API key from command specified in config
function utils.get_api_key(config)
  if not config.api_key_cmd then
    vim.notify("Claude.nvim: API key command not configured", vim.log.levels.ERROR)
    return nil
  end

  local handle = io.popen(config.api_key_cmd)
  if not handle then
    vim.notify("Claude.nvim: Failed to run API key command", vim.log.levels.ERROR)
    return nil
  end

  local api_key = handle:read("*a"):gsub("%s+", "")
  handle:close()

  if api_key == "" then
    vim.notify("Claude.nvim: API key is empty", vim.log.levels.ERROR)
    return nil
  end

  return api_key
end

-- Create a message object with role and content
function utils.create_message(role, content)
  return {
    role = role,
    content = content,
  }
end

-- Check if the user is asking to continue a response
function utils.is_continue_request(content)
  return content:lower():match("^%s*continue%s*$") or content:lower():match("^%s*more%s*$")
end

-- Process Claude's response to extract just the code
function utils.process_code_response(response)
  -- Check if response has markdown code blocks
  local _, _, code = response:find("```[%w_]*%s*\n(.-)\n```")

  if code then
    -- Found code block, extract it
    return code
  else
    -- No code block, assume the entire response is code
    -- Remove any non-code elements if they exist
    local clean_response = response:gsub("^%s*Here's the code:%s*", "")
    clean_response = clean_response:gsub("^%s*```[%w_]*%s*", "")
    clean_response = clean_response:gsub("%s*```%s*$", "")

    return clean_response
  end
end

return utils
