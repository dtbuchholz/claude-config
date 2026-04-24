#!/usr/bin/env bash
set -euo pipefail

reviewer="${1:-codex}"
project_dir="${2:-$(pwd)}"
tmp_dir="${TMPDIR:-/tmp}"
output_file="${3:-$(mktemp "$tmp_dir/agent-review-${reviewer}.XXXXXX")}"

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
tmp_prompt="$(mktemp)"
cleanup() {
  rm -f "$tmp_raw" "$tmp_out" "$tmp_prompt"
}
trap cleanup EXIT

status_summary="$(git -C "$project_dir" status --short)"
staged_diff="$(git -C "$project_dir" diff --cached --no-ext-diff)"
unstaged_diff="$(git -C "$project_dir" diff --no-ext-diff)"

{
  printf '/pr-review\n\n'
  printf 'Review the CURRENT UNCOMMITTED CHANGES in this repository.\n'
  printf 'Do not switch to the branch diff against main or prior commits unless you need brief context.\n'
  printf 'Use the working tree state below as the review scope.\n\n'
  printf 'Status (`git status --short`):\n%s\n\n' "$status_summary"
  printf 'Staged diff (`git diff --cached --no-ext-diff`):\n%s\n\n' "$staged_diff"
  printf 'Unstaged diff (`git diff --no-ext-diff`):\n%s\n' "$unstaged_diff"
} >"$tmp_prompt"

if [[ "$reviewer" == "claude" ]]; then
  if ! command -v claude >/dev/null 2>&1; then
    echo "error: claude binary not found in PATH" >&2
    exit 2
  fi

  attempt=1
  while true; do
    if (
      cd "$project_dir"
      claude --verbose --output-format stream-json -p <"$tmp_prompt"
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

  codex exec --json -C "$project_dir" <"$tmp_prompt" \
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

cp "$tmp_out" "$output_file"

echo "$output_file"
