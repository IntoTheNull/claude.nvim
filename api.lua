-- Claude.nvim - API interaction module
-- Handles communication with the Claude API

local api = {}

-- Store reference to the main Claude object
local Claude -- This is actually used internally by the module

-- Initialize the API module
function api.init(claude_obj)
  Claude = claude_obj
end

-- Send a message to Claude API
function api.send_message(claude_obj, content, callback)
  local api_key = claude_obj.utils.get_api_key(claude_obj.config)
  if not api_key then
    vim.notify("Claude.nvim: Failed to get API key", vim.log.levels.ERROR)
    return
  end

  claude_obj.state.loading = true
  claude_obj.ui.update_loading_status(claude_obj, true)

  -- Check if this is a continuation request
  local is_continuation = claude_obj.utils.is_continue_request(content)

  if is_continuation and claude_obj.state.last_response then
    -- Add a system message to request continuation
    table.insert(
      claude_obj.state.messages,
      claude_obj.utils.create_message("user", "Please continue your previous response.")
    )
    -- Display the continuation request in the UI
    claude_obj.ui.display_messages(claude_obj)
  else
    -- Add message to local state as normal request
    table.insert(claude_obj.state.messages, claude_obj.utils.create_message("user", content))
    claude_obj.ui.display_messages(claude_obj)
  end

  -- Only print debug info if not in silent mode
  if not claude_obj.config.silent then
    print("Sending message to Claude API...")
  end

  -- Format messages for API request
  local formatted_messages = {}
  for _, msg in ipairs(claude_obj.state.messages) do
    table.insert(formatted_messages, {
      role = msg.role,
      content = msg.content,
    })
  end

  local request_data = {
    model = claude_obj.config.model,
    max_tokens = claude_obj.config.max_tokens,
    temperature = claude_obj.config.temperature,
    top_p = claude_obj.config.top_p,
    messages = formatted_messages,
  }

  -- Convert to JSON for the API request
  local request_json = vim.fn.json_encode(request_data)

  -- Only print debug info if not in silent mode
  if not claude_obj.config.silent then
    print("Request data: " .. vim.inspect(request_data))
  end

  local curl_cmd = {
    "curl",
    "-s",
    "-X",
    "POST",
    "https://api.anthropic.com/v1/messages",
    "-H",
    "Content-Type: application/json",
    "-H",
    "x-api-key: " .. api_key,
    "-H",
    "anthropic-version: 2023-06-01",
    "-d",
    request_json,
  }

  -- Only print debug info if not in silent mode
  if not claude_obj.config.silent then
    print("Executing curl command...")
  end

  local job_id = vim.fn.jobstart(curl_cmd, {
    on_stdout = function(_, data, _)
      if data and #data > 0 and data[1] ~= "" then
        -- Only print debug info if not in silent mode
        if not claude_obj.config.silent then
          print("Received response from API")
        end

        local response_text = table.concat(data, "\n")
        local success, response = pcall(vim.fn.json_decode, response_text)

        if not success then
          vim.notify("Claude.nvim: Failed to parse response: " .. response_text, vim.log.levels.ERROR)
          return
        end

        if response and response.content and #response.content > 0 then
          local message_content = response.content[1].text

          -- Store token usage if available
          if response.usage then
            claude_obj.state.token_stats.prompt_tokens = response.usage.input_tokens or 0
            claude_obj.state.token_stats.completion_tokens = response.usage.output_tokens or 0
          end

          -- Store the last response for continuation feature
          claude_obj.state.last_response = message_content

          -- For continuation, append the new content to the last assistant message
          if
            is_continuation
            and #claude_obj.state.messages >= 2
            and claude_obj.state.messages[#claude_obj.state.messages - 1].role == "assistant"
          then
            -- Remove the "please continue" message from the display
            table.remove(claude_obj.state.messages)
            -- Append to previous message
            local last_msg = claude_obj.state.messages[#claude_obj.state.messages]
            last_msg.content = last_msg.content .. "\n\n" .. message_content
          else
            -- Add as new message
            table.insert(claude_obj.state.messages, claude_obj.utils.create_message("assistant", message_content))
          end

          claude_obj.ui.display_messages(claude_obj)

          -- Show token count if enabled
          if claude_obj.config.show_token_count then
            local token_info = string.format(
              "Tokens: %d input, %d output, %d total",
              claude_obj.state.token_stats.prompt_tokens,
              claude_obj.state.token_stats.completion_tokens,
              claude_obj.state.token_stats.prompt_tokens + claude_obj.state.token_stats.completion_tokens
            )
            vim.notify(token_info, vim.log.levels.INFO)
          end

          if callback then
            -- Silent callback, no popup notification
            callback(message_content)
          end
        else
          vim.notify("Claude.nvim: Empty or invalid response: " .. vim.inspect(response), vim.log.levels.ERROR)
        end
      end

      claude_obj.state.loading = false
      claude_obj.ui.update_loading_status(claude_obj, false)
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 and data[1] ~= "" then
        local error_msg = table.concat(data, "\n")
        vim.notify("Claude.nvim Error: " .. error_msg, vim.log.levels.ERROR)
      end

      claude_obj.state.loading = false
      claude_obj.ui.update_loading_status(claude_obj, false)
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })

  if job_id <= 0 then
    vim.notify("Claude.nvim: Failed to start curl job", vim.log.levels.ERROR)
    claude_obj.state.loading = false
    claude_obj.ui.update_loading_status(claude_obj, false)
  end
end

-- Send a code request to Claude API
function api.send_code_request(claude_obj, code, instruction, callback)
  local api_key = claude_obj.utils.get_api_key(claude_obj.config)
  if not api_key then
    vim.notify("Claude.nvim: Failed to get API key", vim.log.levels.ERROR)
    return false
  end

  -- Create prompt that emphasizes returning only code
  local prompt = string.format(
    [[
I need help with the following code:

```%s
%s
```

%s

IMPORTANT: Please respond with ONLY the modified code. Do not include markdown formatting 
(no triple backticks), explanation text, or anything else outside the actual code. 
Any explanations should be added as proper code comments within the code itself.
]],
    claude_obj.coding.state.filetype or "",
    code,
    instruction
  )

  -- Format message for API request
  local request_data = {
    model = claude_obj.config.model,
    max_tokens = claude_obj.config.max_tokens,
    temperature = claude_obj.config.temperature,
    top_p = claude_obj.config.top_p,
    messages = {
      { role = "user", content = prompt },
    },
  }

  -- Convert to JSON for the API request
  local request_json = vim.fn.json_encode(request_data)

  local curl_cmd = {
    "curl",
    "-s",
    "-X",
    "POST",
    "https://api.anthropic.com/v1/messages",
    "-H",
    "Content-Type: application/json",
    "-H",
    "x-api-key: " .. api_key,
    "-H",
    "anthropic-version: 2023-06-01",
    "-d",
    request_json,
  }

  local job_id = vim.fn.jobstart(curl_cmd, {
    on_stdout = function(_, data, _)
      if data and #data > 0 and data[1] ~= "" then
        local response_text = table.concat(data, "\n")
        local success, response = pcall(vim.fn.json_decode, response_text)

        if not success then
          vim.notify("Claude.nvim: Failed to parse response: " .. response_text, vim.log.levels.ERROR)
          return
        end

        if response and response.content and #response.content > 0 then
          local message_content = response.content[1].text

          -- Process the response to extract just the code
          local clean_code = claude_obj.utils.process_code_response(message_content)

          -- Extract token information
          local token_info = nil
          if response.usage then
            token_info = {
              prompt_tokens = response.usage.input_tokens or 0,
              completion_tokens = response.usage.output_tokens or 0,
            }

            -- Show token count
            local token_display = string.format(
              "Tokens: %d input, %d output, %d total",
              token_info.prompt_tokens,
              token_info.completion_tokens,
              token_info.prompt_tokens + token_info.completion_tokens
            )
            vim.notify(token_display, vim.log.levels.INFO)
          end

          -- Call callback with the processed code and token info
          if callback then
            callback(clean_code, token_info)
          end
        else
          vim.notify("Claude.nvim: Empty or invalid response", vim.log.levels.ERROR)
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 and data[1] ~= "" then
        local error_msg = table.concat(data, "\n")
        vim.notify("Claude.nvim Error: " .. error_msg, vim.log.levels.ERROR)
      end
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  })

  if job_id <= 0 then
    vim.notify("Claude.nvim: Failed to start curl job", vim.log.levels.ERROR)
    return false
  end

  return true
end

return api
