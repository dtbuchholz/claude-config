#!/bin/bash
# Claude Code PreToolUse hook to block edits to sensitive files
#
# Exit codes:
#   0 = allow the operation
#   2 = block the operation

# Read tool input from stdin
INPUT=$(cat)

# Extract the file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# If no file path, allow
[ -z "$FILE_PATH" ] && exit 0

# Get just the filename
FILENAME=$(basename "$FILE_PATH")

# Block .env files EXCEPT .env.example and .env.sample
if [[ "$FILENAME" =~ ^\.env ]]; then
    if [[ "$FILENAME" == ".env.example" || "$FILENAME" == ".env.sample" ]]; then
        exit 0
    fi
    echo "BLOCKED: Editing '$FILENAME' not allowed (contains secrets)." >&2
    exit 2
fi

# Block lockfiles
case "$FILENAME" in
    package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lockb)
        echo "BLOCKED: Editing lockfile '$FILENAME' not allowed." >&2
        exit 2
        ;;
esac

# Block .git directory
if [[ "$FILE_PATH" == *"/.git/"* ]]; then
    echo "BLOCKED: Editing files in .git/ not allowed." >&2
    exit 2
fi

exit 0
