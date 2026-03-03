#!/bin/bash
# QMD re-index — invoked by launchd periodically
# Updates the QMD index and regenerates embeddings for new/changed files.

set -euo pipefail

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/qmd-reindex.log"

echo "=== QMD Re-index: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"

qmd update >> "$LOG_FILE" 2>&1
qmd embed >> "$LOG_FILE" 2>&1

echo "=== Completed: $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
