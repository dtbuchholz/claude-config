#!/bin/bash
# QMD re-index — invoked by launchd periodically
# Extracts conversation text, updates the QMD index, and regenerates embeddings.

set -euo pipefail

NODE_BIN_DIR="$HOME/.nvm/versions/node/v24.7.0/bin"
export PATH="$NODE_BIN_DIR:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

QMD="$NODE_BIN_DIR/qmd"
if [[ ! -x "$QMD" ]]; then
  QMD="$(command -v qmd || true)"
fi
if [[ -z "$QMD" ]]; then
  echo "qmd not found on PATH=$PATH" >&2
  exit 127
fi

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/qmd-reindex.log"

echo "=== QMD Re-index: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"
echo "Using QMD: $("$QMD" --version)" >> "$LOG_FILE"

# Extract clean text from conversation JSONL files
python3 "$HOME/.claude/scripts/extract-conversations.py" >> "$LOG_FILE" 2>&1

"$QMD" update >> "$LOG_FILE" 2>&1
"$QMD" embed >> "$LOG_FILE" 2>&1

echo "=== Completed: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
