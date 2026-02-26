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
# Match "git push" or "git <flags> push" (e.g. git -C /path push)
# but not "push" inside quoted strings (e.g. git commit -m "fix push")
echo "$COMMAND" | grep -qE "git\s+(-[A-Za-z]\s+\S+\s+)*push(\s|$)" || exit 0

# If pushing all branches, block (could include protected)
echo "$COMMAND" | grep -qE -- "\s--all(\s|$)" && {
    echo "BLOCKED: Push with --all not allowed (may include protected branches). Use PRs." >&2
    exit 2
}

# If command explicitly references a protected branch, block
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

# If we're currently on a protected branch, block plain git push
# (plain push would push current branch to its upstream)
# Respect -C <dir> so we check the correct repo (e.g. worktrees)
GIT_C_ARGS=""
if [[ "$COMMAND" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
    GIT_C_ARGS="-C ${BASH_REMATCH[1]}"
fi
CURRENT_BRANCH=$(git $GIT_C_ARGS rev-parse --abbrev-ref HEAD 2>/dev/null || true)
for branch in $PROTECTED_BRANCHES; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
        echo "BLOCKED: You're on '$branch'. Create a feature branch + PR." >&2
        exit 2
    fi
done

exit 0
