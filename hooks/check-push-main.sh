#!/bin/bash
# Claude Code PreToolUse hook to block pushes to protected branches
#
# Exit codes:
#   0 = allow the operation
#   2 = block the operation

PROTECTED_BRANCHES="main master"

# Read tool input from stdin
INPUT=$(cat)

# Extract the command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# If no command, allow
[ -z "$COMMAND" ] && exit 0

# Only check git push commands
echo "$COMMAND" | grep -qE "git\s+push" || exit 0

for branch in $PROTECTED_BRANCHES; do
    # Block patterns:
    #   git push origin main
    #   git push -u origin main
    #   git push --set-upstream origin main
    #   git push origin HEAD:main
    #   git push origin feature:main
    #   git push main (implicit origin)
    if echo "$COMMAND" | grep -qE "(origin\s+|origin\s+[^:]+:)$branch(\s|$)|\s$branch(\s|$)"; then
        echo "BLOCKED: Push to '$branch' not allowed. Use a feature branch + PR." >&2
        exit 2
    fi
done

exit 0
