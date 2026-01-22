#!/bin/bash
# Platform-agnostic notification script for Claude Code hooks
# Usage: notify.sh "title" "message"

TITLE="${1:-Claude Code}"
MESSAGE="${2:-Notification}"

# macOS: use terminal-notifier if available
if command -v terminal-notifier &> /dev/null; then
    terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound default
    exit 0
fi

# macOS fallback: use osascript
if command -v osascript &> /dev/null; then
    osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
    exit 0
fi

# Linux: use notify-send if available
if command -v notify-send &> /dev/null; then
    notify-send "$TITLE" "$MESSAGE"
    exit 0
fi

# No notification tool available - silent exit (not an error)
exit 0
