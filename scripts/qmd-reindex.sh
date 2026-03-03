#!/bin/bash
# QMD re-index — invoked by launchd periodically
# Extracts conversation text, updates the QMD index, and regenerates embeddings.

set -euo pipefail

# qmd requires Node 22 (better-sqlite3 native module)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 > /dev/null 2>&1 || true

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/qmd-reindex.log"

echo "=== QMD Re-index: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"

# Extract clean text from conversation JSONL files
python3 "$HOME/.claude/scripts/extract-conversations.py" >> "$LOG_FILE" 2>&1

qmd update >> "$LOG_FILE" 2>&1
qmd embed >> "$LOG_FILE" 2>&1

echo "=== Completed: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
