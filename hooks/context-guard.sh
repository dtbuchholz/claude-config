#!/usr/bin/env bash
# PostToolUse hook: warns Claude when tool output is large.
#
# Claude Code hooks can't modify context retroactively, but PostToolUse
# stderr is shown to Claude. When a tool dumps a huge output into context,
# this nudges the model toward targeted approaches on subsequent calls.
#
# Fires on: Bash, Read
# Input: JSON on stdin with tool_name, tool_input, tool_output
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // ""')

# Count output size
OUTPUT_LINES=$(echo "$TOOL_OUTPUT" | wc -l)
OUTPUT_BYTES=$(echo "$TOOL_OUTPUT" | wc -c)
# Rough token estimate: ~4 chars per token
OUTPUT_TOKENS=$((OUTPUT_BYTES / 4))

# Thresholds (tunable)
LINE_THRESHOLD=200
TOKEN_THRESHOLD=2000

if [ "$OUTPUT_LINES" -gt "$LINE_THRESHOLD" ] || [ "$OUTPUT_TOKENS" -gt "$TOKEN_THRESHOLD" ]; then
  # stderr is shown to Claude on PostToolUse
  echo "⚠️ Large output: ${OUTPUT_LINES} lines, ~${OUTPUT_TOKENS} tokens consumed. To preserve context:" >&2
  echo "  • Use line ranges: Read with offset/limit, head/tail, sed -n 'X,Yp'" >&2
  echo "  • Use grep/ripgrep for specific patterns instead of full reads" >&2
  echo "  • Consider /compact with focused instructions if context is getting stale" >&2
fi

exit 0
