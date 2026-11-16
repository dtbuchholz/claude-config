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
packet_script="$HOME/.claude/scripts/review-packet.sh"
if [[ ! -x "$packet_script" ]]; then
  echo "error: shared packet builder not found: $packet_script" >&2
  exit 2
fi

tmp_raw="$(mktemp)"
tmp_out="$(mktemp)"
tmp_prompt="$(mktemp)"
packet_root="$(mktemp -d "$tmp_dir/agent-review-packet.XXXXXX")"
cleanup() {
  rm -f "$tmp_raw" "$tmp_out" "$tmp_prompt"
  chmod -R u+w "$packet_root" 2>/dev/null || true
  rm -rf "${packet_root:?}"
}
trap cleanup EXIT

# Shared builder: staged, unstaged, and untracked files; lockfiles excluded and listed.
packet_meta="$("$packet_script" build "$project_dir" --uncommitted --out-dir "$packet_root/packet")"
packet_value() { printf '%s\n' "$packet_meta" | sed -n "s/^$1=//p"; }
packet_path="$(packet_value packet)"
packet_sha="$(packet_value sha256)"
packet_bytes="$(packet_value bytes)"
status_summary="$(git -C "$project_dir" status --short)"

{
  printf '/pr-review\n\n'
  printf 'Review the CURRENT UNCOMMITTED CHANGES in this repository (staged, unstaged, and untracked files).\n'
  printf 'Do not switch to the branch diff against main or prior commits unless you need brief context.\n'
  printf 'The frozen diff packet below is the review scope.\n\n'
  printf 'Status (`git status --short`):\n%s\n\n' "$status_summary"
  if [[ -s "$packet_root/packet/excluded-files.tsv" ]]; then
    printf 'Excluded from review (reason, path):\n%s\n\n' "$(cat "$packet_root/packet/excluded-files.tsv")"
  fi
  if [[ "$packet_bytes" -le 24000 ]]; then
    printf 'Diff to review:\n```diff\n%s\n```\n' "$(cat "$packet_path")"
  else
    printf 'Diff to review: read %s (%s bytes). First run `shasum -a 256 %s` and confirm it equals %s; if it does not, reply only PACKET HASH MISMATCH.\n' \
      "$packet_path" "$packet_bytes" "$packet_path" "$packet_sha"
  fi
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
