#!/bin/bash

# This script runs the test suite for Claude.nvim
# It requires Plenary.nvim to be installed

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if Plenary.nvim is available
if [ ! -d "${HOME}/.local/share/nvim/site/pack/packer/start/plenary.nvim" ] && \
   [ ! -d "${HOME}/.local/share/nvim/site/pack/vendor/start/plenary.nvim" ] && \
   [ ! -d "${HOME}/.config/nvim/plugged/plenary.nvim" ] && \
   [ ! -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/plenary.nvim" ]; then
  echo "Plenary.nvim not found. Installing temporarily for testing..."
  TMP_PLENARY_DIR="/tmp/plenary.nvim"
  
  if [ ! -d "$TMP_PLENARY_DIR" ]; then
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim.git "$TMP_PLENARY_DIR"
  fi
  
  PLENARY_PATH="$TMP_PLENARY_DIR"
else
  # Try to find Plenary.nvim from common installation locations
  if [ -d "${HOME}/.local/share/nvim/site/pack/packer/start/plenary.nvim" ]; then
    PLENARY_PATH="${HOME}/.local/share/nvim/site/pack/packer/start/plenary.nvim"
  elif [ -d "${HOME}/.local/share/nvim/site/pack/vendor/start/plenary.nvim" ]; then
    PLENARY_PATH="${HOME}/.local/share/nvim/site/pack/vendor/start/plenary.nvim"
  elif [ -d "${HOME}/.config/nvim/plugged/plenary.nvim" ]; then
    PLENARY_PATH="${HOME}/.config/nvim/plugged/plenary.nvim"
  elif [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/plenary.nvim" ]; then
    PLENARY_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/plenary.nvim"
  fi
fi

# Run tests with plenary test runner
nvim --headless \
  -c "lua package.path = '${PROJECT_ROOT}/?.lua;${PROJECT_ROOT}/?/init.lua;' .. package.path" \
  -c "lua package.path = '${PLENARY_PATH}/lua/?.lua;${PLENARY_PATH}/lua/?/init.lua;' .. package.path" \
  -c "lua require('plenary.test_harness').test_directory('${PROJECT_ROOT}/tests/', {minimal_init = '${PROJECT_ROOT}/tests/minimal_init.vim'})" \
  -c "qa!"

# Return the exit code from nvim
exit $?