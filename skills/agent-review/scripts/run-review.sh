#!/usr/bin/env bash
set -euo pipefail

reviewer="${1:-codex}"
project_dir="${2:-$(pwd)}"
output_file="${3:-$project_dir/.agent-review/review-$(date +%Y%m%d-%H%M%S)-${reviewer}.md}"

if [[ "$reviewer" != "claude" && "$reviewer" != "codex" ]]; then
  echo "error: reviewer must be 'claude' or 'codex'" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 2
fi

if [[ ! -d "$project_dir/.git" ]] && ! git -C "$project_dir" rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: project_dir is not a git repo: $project_dir" >&2
  exit 2
fi

if [[ -z "$(git -C "$project_dir" status --porcelain)" ]]; then
  echo "error: no local changes to review in $project_dir" >&2
  exit 2
fi

mkdir -p "$(dirname "$output_file")"
tmp_raw="$(mktemp)"
tmp_out="$(mktemp)"
cleanup() {
  rm -f "$tmp_raw" "$tmp_out"
}
trap cleanup EXIT

review_prompt=$(
  cat <<'PROMPT'
You are an independent code reviewer operating in a fresh context.

Run a comprehensive PR-style review of the CURRENT UNCOMMITTED CHANGES in this repository.
Use the same rigor as /pr-review:
- prioritize real bugs, regressions, security issues, and missing tests
- avoid style-only nits unless they impact maintainability
- focus on changed lines and changed behavior

Output constraints:
- Output ONLY the final markdown report (no status updates, no process narration)
- Keep findings concrete and actionable

Output format:
# Review Findings

## High
- ...

## Medium
- ...

## Low
- ...

## Open Questions
- ...

## Suggested Actions
- ...

If no significant issues exist, state that explicitly and explain residual risks.
PROMPT
)

if [[ "$reviewer" == "claude" ]]; then
  if ! command -v claude >/dev/null 2>&1; then
    echo "error: claude binary not found in PATH" >&2
    exit 2
  fi

  attempt=1
  while true; do
    if (
      cd "$project_dir"
      claude --verbose --output-format stream-json -p "$review_prompt"
    ) >"$tmp_raw" 2>&1; then
      break
    fi

    if grep -qi 'overloaded' "$tmp_raw" && [[ $attempt -lt 3 ]]; then
      sleep $((attempt * 3))
      attempt=$((attempt + 1))
      continue
    fi

    echo "error: claude reviewer failed" >&2
    cat "$tmp_raw" >&2
    exit 3
  done

  jq -r '
      if .type == "assistant" then
        (.message.content[]? | if .type == "text" then .text else empty end)
      else empty end
    ' \
    "$tmp_raw" \
    | sed '/^[[:space:]]*$/N;/^\n$/D' >"$tmp_out"
else
  if ! command -v codex >/dev/null 2>&1; then
    echo "error: codex binary not found in PATH" >&2
    exit 2
  fi

  codex exec --json -C "$project_dir" "$review_prompt" \
    | jq -r '
      if .type == "item.completed" and .item.type == "agent_message" then
        .item.text
      else empty end
    ' >"$tmp_out"
fi

if [[ ! -s "$tmp_out" ]]; then
  echo "error: reviewer output was empty" >&2
  exit 3
fi

if grep -q '^# Review Findings' "$tmp_out"; then
  awk 'BEGIN{emit=0} /^# Review Findings/{emit=1} emit{print}' "$tmp_out" >"$output_file"
else
  cp "$tmp_out" "$output_file"
fi

echo "$output_file"
