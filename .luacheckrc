-- Global objects
globals = {
  "vim",
}

-- Don't report unused self arguments of methods
self = false

-- Maximum line length
max_line_length = 120

-- Exclude third-party modules
exclude_files = {
  "lua/vendor/**/*.lua"
}

-- General ignore rules for all files
ignore = {
  -- Whitespace issues
  "611", -- Line contains only whitespace
  "612", -- Line contains trailing whitespace
  "613", -- Trailing whitespace in a string
  "614", -- Trailing whitespace in a comment
  
  -- Unused variables
  "211/Claude", -- Ignore unused Claude variable in all files
  "212", -- Unused arguments in all files
  
  -- Other
  "581", -- operator order warning
}