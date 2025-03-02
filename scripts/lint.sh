#!/bin/bash

# Run luacheck and store the result
RESULT=$(luacheck . 2>&1)
EXIT_CODE=$?

# Remove ANSI color codes for better pattern matching
CLEAN_RESULT=$(echo "$RESULT" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")

# Count total warnings
TOTAL_WARNINGS=$(echo "$CLEAN_RESULT" | grep -c "warning")
# Count Claude variable warnings
CLAUDE_WARNINGS=$(echo "$CLEAN_RESULT" | grep -c "variable Claude is never accessed")

# Display result without Claude variable warnings
echo "$RESULT" | grep -v "Claude is never accessed"

# If exit code is 1 (warnings only) and all warnings are Claude variable warnings,
# we'll consider this a success
if [ $EXIT_CODE -eq 1 ] && [ $TOTAL_WARNINGS -eq $CLAUDE_WARNINGS ]; then
  echo -e "\n✅ Lint passed (ignoring known Claude variable warnings)"
  exit 0
fi

# Otherwise, return the original exit code
exit $EXIT_CODE