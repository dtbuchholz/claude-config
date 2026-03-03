#!/bin/bash
# QMD launcher that survives Node version switching (e.g. nvm 22 vs 24).
# Usage: ~/.codex/scripts/qmd.sh <qmd args>

set -euo pipefail

add_candidate() {
  local p="$1"
  if [ -n "$p" ] && [ -x "$p" ]; then
    CANDIDATES+=("$p")
  fi
}

declare -a CANDIDATES=()

# 1) Explicit override
if [ -n "${QMD_BIN:-}" ]; then
  add_candidate "$QMD_BIN"
fi

# 2) Preferred node version override
if [ -n "${QMD_NODE_VERSION:-}" ]; then
  add_candidate "$HOME/.nvm/versions/node/v${QMD_NODE_VERSION}/bin/qmd"
  add_candidate "$HOME/.nvm/versions/node/${QMD_NODE_VERSION}/bin/qmd"
fi

# 3) Current PATH
if command -v qmd >/dev/null 2>&1; then
  add_candidate "$(command -v qmd)"
fi

# 4) NVM installs (newest first)
if [ -d "$HOME/.nvm/versions/node" ]; then
  while IFS= read -r bin; do
    add_candidate "$bin"
  done < <(find "$HOME/.nvm/versions/node" -path '*/bin/qmd' 2>/dev/null | sort -r)
fi

# 5) Common system locations
add_candidate "/opt/homebrew/bin/qmd"
add_candidate "/usr/local/bin/qmd"

# De-duplicate while preserving order
declare -a UNIQ=()
if [ "${#CANDIDATES[@]}" -gt 0 ]; then
  for c in "${CANDIDATES[@]}"; do
    skip=0
    if [ "${#UNIQ[@]}" -gt 0 ]; then
      for u in "${UNIQ[@]}"; do
        [ "$u" = "$c" ] && skip=1 && break
      done
    fi
    [ "$skip" -eq 0 ] && UNIQ+=("$c")
  done
fi

if [ "${#UNIQ[@]}" -gt 0 ]; then
for bin in "${UNIQ[@]}"; do
  bindir="$(dirname "$bin")"
  # Ensure matching node for this qmd script is first in PATH.
  if PATH="$bindir:$PATH" "$bin" --help >/dev/null 2>&1; then
    PATH="$bindir:$PATH" exec "$bin" "$@"
  fi
done
fi

echo "No working qmd binary found." >&2
echo "Install suggestion: make qmd-install" >&2
echo "Or set QMD_BIN=/absolute/path/to/qmd" >&2
exit 127
