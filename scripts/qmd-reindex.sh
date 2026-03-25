#!/bin/bash
# QMD re-index — invoked by launchd periodically
# Extracts conversation text, updates the QMD index, and regenerates embeddings.

set -euo pipefail

QMD="qmd"

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/qmd-reindex.log"

echo "=== QMD Re-index: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"

# Extract clean text from conversation JSONL files
python3 "$HOME/.claude/scripts/extract-conversations.py" >> "$LOG_FILE" 2>&1

"$QMD" update >> "$LOG_FILE" 2>&1
"$QMD" embed >> "$LOG_FILE" 2>&1

echo "=== Completed: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
