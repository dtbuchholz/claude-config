#!/bin/bash
# Memory rollup — invoked by launchd weekly
# Runs Claude non-interactively to review and consolidate memory files.

set -euo pipefail

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/memory-rollup.log"

# Load environment (API keys)
ENV_FILE="$HOME/.claude/scripts/openrouter.conf"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

echo "=== Memory Rollup: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"

/opt/homebrew/bin/claude \
  --dangerously-skip-permissions \
  -p "/memory-rollup" \
  >> "$LOG_FILE" 2>&1

echo "=== Completed: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
