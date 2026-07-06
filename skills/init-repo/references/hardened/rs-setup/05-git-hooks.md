# Step 05 — Git Hooks (Pre-Commit)

This step creates the pre-commit hook script. In Rust projects, hooks are shell scripts in
`scripts/` symlinked into `.git/hooks/` via `make install-hooks` (see Step 01).

**Key design decision:** Clippy is **NOT** in pre-commit. Clippy requires full compilation, which
takes 10-60+ seconds depending on project size. That is too slow for a commit hook. Clippy runs in
pre-push (Step 06) instead. Pre-commit is limited to fast operations: formatting, lock file sync,
and secret detection.

## scripts/pre-commit.sh

```bash
#!/usr/bin/env bash
# init-repo-hardened
set -euo pipefail

echo "=== PRE-COMMIT ==="

# ── GATE 1: Auto-format staged .rs files and re-stage ───────
STAGED_RS=$(git diff --cached --name-only --diff-filter=ACM | grep '\.rs$' || true)
if [ -n "$STAGED_RS" ]; then
  echo "--- Formatting staged Rust files ---"
  echo "$STAGED_RS" | xargs cargo fmt --
  echo "$STAGED_RS" | while read -r file; do
    if [ -f "$file" ]; then
      git add "$file"
    fi
  done
fi

# ── GATE 2: Cargo.lock sync check ───────────────────────────
CARGO_TOML_CHANGED=$(git diff --cached --name-only | grep -E '(^|/)Cargo\.toml$' || true)
if [ -n "$CARGO_TOML_CHANGED" ]; then
  LOCK_STAGED=$(git diff --cached --name-only | grep -E '(^|/)Cargo\.lock$' || true)
  if [ -z "$LOCK_STAGED" ]; then
    # Check if Cargo.lock actually needs updating
    cargo check --workspace 2>/dev/null
    if ! git diff --quiet -- Cargo.lock 2>/dev/null; then
      echo "Cargo.toml changed but Cargo.lock is not staged."
      echo "  Fix: cargo check && git add Cargo.lock"
      exit 1
    fi
  fi
fi

# ── GATE 3: Secret detection ────────────────────────────────
STAGED_DIFF=$(git diff --cached -U0)
SECRETS=$(echo "$STAGED_DIFF" \
  | grep -inE '^\+.*(password|secret|api[_-]?key|token|credential|private[_-]?key)\s*[:=]\s*["\x27][^"\x27]{8,}' \
  | grep -v '^\+\+\+' \
  | grep -v '\.test\.' \
  | grep -v 'tests/' \
  | grep -v '\.example' \
  | grep -v '\.template' \
  | grep -v 'placeholder' \
  | grep -v 'CHANGE_ME' \
  | grep -v 'your_.*_here' \
  || true)

if [ -n "$SECRETS" ]; then
  echo "Possible secrets detected in staged changes:"
  echo "$SECRETS" | head -10
  echo "NEVER commit real credentials to the repository."
  exit 1
fi

# ── GATE 4: No TODO/FIXME in new code (warning only) ────────
TODO_LINES=$(echo "$STAGED_DIFF" \
  | grep -inE '^\+.*(TODO|FIXME|HACK|XXX)' \
  | grep -v '^\+\+\+' \
  || true)
if [ -n "$TODO_LINES" ]; then
  echo "Warning: TODO/FIXME found in staged changes (not blocking):"
  echo "$TODO_LINES" | head -5
fi

echo "=== PRE-COMMIT PASSED ==="
```

## What Is NOT in Pre-Commit (and Why)

| Check          | Why not pre-commit?                 | Where instead? |
| -------------- | ----------------------------------- | -------------- |
| `cargo clippy` | Requires full compilation (10-60s+) | Pre-push       |
| `cargo test`   | Can take minutes                    | Pre-push       |
| `cargo build`  | Requires full compilation           | Pre-push       |
| `cargo-deny`   | Network calls for advisory DB       | Pre-push       |

The philosophy: pre-commit runs in **under 3 seconds**. If it takes longer, developers will bypass
it. `cargo fmt` on staged files is fast because it only parses — it does not compile.

## Installation

The Makefile target (from Step 01) creates the symlink:

```bash
make install-hooks
```

This runs:

```bash
ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x scripts/pre-commit.sh
```

> **Why symlinks?** The script lives in `scripts/` and is version-controlled. The symlink in
> `.git/hooks/` points to it. When the script is updated via git pull, the hook updates
> automatically. No `husky install` or `pre-commit install` step needed.

## Sentinel Marker

The `# init-repo-hardened` comment on line 2 of the script is the sentinel marker. The skill's entry
check (SKILL.md) looks for this marker to detect an existing setup. Do not remove it.

## Stop & Confirm

Confirm the pre-commit script and installation method before moving to Step 06.
