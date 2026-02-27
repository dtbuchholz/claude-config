#!/bin/bash
# Claude Code PreToolUse hook — run gitleaks before commit/push
#
# Intercepts git commit and git push commands. Runs gitleaks to scan for
# secrets in staged changes (commit) or outgoing commits (push).
#
# Exit codes:
#   0 = allow the operation
#   2 = block the operation (secrets found)

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[ -z "$COMMAND" ] && exit 0

# Determine mode: commit or push
MODE=""
if echo "$COMMAND" | grep -qE "git\s+(-[A-Za-z]\s+\S+\s+)*commit(\s|$)"; then
  MODE="commit"
elif echo "$COMMAND" | grep -qE "git\s+(-[A-Za-z]\s+\S+\s+)*push(\s|$)"; then
  MODE="push"
fi

[ -z "$MODE" ] && exit 0

# Allow bypass via environment variable
if [ "${SKIP_GITLEAKS:-0}" = "1" ]; then
  exit 0
fi

# Allow bypass when explicitly prefixed in command (PreToolUse may not inherit env assignment)
if echo "$COMMAND" | grep -qE '(^|[[:space:]])SKIP_GITLEAKS=1([[:space:]]|$)'; then
  exit 0
fi

# Require gitleaks
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "BLOCKED: gitleaks is required for secret scanning. Install: brew install gitleaks" >&2
  exit 2
fi

# Extract -C <dir> if present (for worktrees)
GIT_DIR="."
if [[ "$COMMAND" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  GIT_DIR="${BASH_REMATCH[1]}"
fi

if [ "$MODE" = "commit" ]; then
  # Scan staged changes
  if git -C "$GIT_DIR" diff --cached --quiet 2>/dev/null; then
    exit 0  # nothing staged
  fi

  if gitleaks git --staged --redact --no-banner "$GIT_DIR" >/dev/null 2>&1; then
    exit 0
  fi

  echo "BLOCKED: gitleaks found potential secrets in staged changes." >&2
  echo "Review with: gitleaks git --staged --redact -v" >&2
  exit 2
fi

if [ "$MODE" = "push" ]; then
  # Scan outgoing commits
  UPSTREAM=$(git -C "$GIT_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)

  if [ -n "$UPSTREAM" ]; then
    COUNT=$(git -C "$GIT_DIR" rev-list --count "$UPSTREAM..HEAD" 2>/dev/null || echo "0")
    [ "$COUNT" = "0" ] && exit 0  # nothing to push

    if gitleaks git --redact --no-banner --log-opts="$UPSTREAM..HEAD" "$GIT_DIR" >/dev/null 2>&1; then
      exit 0
    fi
  else
    # No upstream — scan last 50 commits
    if gitleaks git --redact --no-banner --log-opts="--max-count=50 HEAD" "$GIT_DIR" >/dev/null 2>&1; then
      exit 0
    fi
  fi

  echo "BLOCKED: gitleaks found potential secrets in outgoing commits." >&2
  echo "Review with: gitleaks git --redact -v" >&2
  exit 2
fi
