# Step 06 — Pre-Push Script

This step creates the pre-push hook — the last gate before code leaves the developer's machine. It
mirrors CI exactly so developers are never surprised by remote failures.

**Key design decision:** Clippy runs here because it requires compilation. Pre-push is where the
full verification suite runs, including everything too slow for pre-commit.

## scripts/pre-push.sh

```bash
#!/usr/bin/env bash
# init-repo-hardened
set -euo pipefail

echo "=== PRE-PUSH: Running full verification ==="

# ── GATE 1: Stale branch check ──────────────────────────────
echo "--- [1/10] Checking branch freshness ---"
git fetch origin main --quiet 2>/dev/null || true
BEHIND=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)
if [ "$BEHIND" -gt 0 ]; then
  echo "origin/main is $BEHIND commits ahead. Rebase before pushing."
  echo "  Fix: git fetch origin main && git rebase origin/main"
  exit 1
fi

# ── GATE 2: Clean working tree ──────────────────────────────
echo "--- [2/10] Checking working tree ---"
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Uncommitted changes detected. Commit or stash before pushing."
  exit 1
fi

# ── GATE 3: Format check ────────────────────────────────────
echo "--- [3/10] Format check ---"
cargo fmt --check || {
  echo "Formatting check failed. Run: cargo fmt"
  exit 1
}

# ── GATE 4: Clippy ───────────────────────────────────────────
echo "--- [4/10] Clippy ---"
cargo clippy --workspace --all-targets -- -D warnings || {
  echo "Clippy failed. Fix lint errors before pushing."
  exit 1
}

# ── GATE 5: Tests ────────────────────────────────────────────
echo "--- [5/10] Tests ---"
cargo test --workspace || {
  echo "Tests failed."
  exit 1
}

# ── GATE 6: Build ────────────────────────────────────────────
echo "--- [6/10] Build ---"
cargo build --workspace || {
  echo "Build failed."
  exit 1
}

# ── GATE 7: Coverage (conditional) ───────────────────────────
echo "--- [7/10] Coverage ---"
if command -v cargo-tarpaulin &>/dev/null; then
  cargo tarpaulin --workspace --fail-under 80 --ignore-tests --out stdout 2>&1 \
    | tail -5 || {
    echo "Coverage below 80% threshold."
    exit 1
  }
else
  echo "Skipping (cargo-tarpaulin not installed)"
fi

# ── GATE 8: Supply chain audit (conditional) ─────────────────
echo "--- [8/10] Dependency audit ---"
if command -v cargo-deny &>/dev/null; then
  cargo deny check || {
    echo "cargo-deny check failed. Review dependency issues."
    exit 1
  }
else
  echo "Skipping (cargo-deny not installed)"
fi

# ── GATE 9: Documentation (conditional) ─────────────────────
echo "--- [9/10] Documentation ---"
if [ "${CHECK_DOCS:-false}" = "true" ]; then
  RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps || {
    echo "Documentation build failed."
    exit 1
  }
else
  echo "Skipping (set CHECK_DOCS=true to enable)"
fi

# ── GATE 10: Integration tests (conditional) ─────────────────
echo "--- [10/10] Integration tests ---"
if [ -n "${DATABASE_URL:-}" ]; then
  cargo test --workspace --test '*' -- --ignored || {
    echo "Integration tests failed."
    exit 1
  }
else
  echo "Skipping (DATABASE_URL not set)"
fi

echo "=== PRE-PUSH: All checks passed ==="
```

## Gate Design

| Gate                  | Required?   | Why Conditional?                     |
| --------------------- | ----------- | ------------------------------------ |
| 1. Stale branch       | Yes         | —                                    |
| 2. Clean tree         | Yes         | —                                    |
| 3. Format             | Yes         | —                                    |
| 4. Clippy             | Yes         | —                                    |
| 5. Tests              | Yes         | —                                    |
| 6. Build              | Yes         | —                                    |
| 7. Coverage           | Conditional | Requires `cargo-tarpaulin` installed |
| 8. Dependency audit   | Conditional | Requires `cargo-deny` installed      |
| 9. Documentation      | Conditional | Opt-in via `CHECK_DOCS=true`         |
| 10. Integration tests | Conditional | Requires `DATABASE_URL`              |

**Required gates (1-6)** always run and block the push on failure. **Conditional gates (7-10)**
degrade gracefully — they skip with a message if the tool or environment is not available. CI always
has all tools installed, so these gates are authoritative there.

## Gate Ordering Rationale

1. **Stale branch + clean tree first** — abort immediately before expensive work
2. **Format before Clippy** — format errors produce noisy Clippy output
3. **Clippy before tests** — type/lint errors cause test failures; fix the cause first
4. **Tests before build** — tests catch logic bugs; build confirms compilation
5. **Coverage after tests** — only meaningful if tests pass
6. **Dependency audit late** — network-dependent, independent of code quality
7. **Docs and integration last** — optional, slowest gates

## Installation

Same symlink approach as pre-commit (Step 05):

```bash
make install-hooks
```

Which runs:

```bash
ln -sf ../../scripts/pre-push.sh .git/hooks/pre-push
chmod +x scripts/pre-push.sh
```

## Stop & Confirm

Confirm the pre-push script and gate structure before moving to Step 07.
