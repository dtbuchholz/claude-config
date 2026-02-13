# Step 06 — Pre-Push Script

This step creates the pre-push gate script. The pre-push hook is the last line of defense before
code leaves the developer's machine. It runs the full verification suite that mirrors CI.

The script lives at `scripts/pre-push.sh` and is invoked by the pre-commit framework's pre-push
stage (configured in Step 05).

## Design Principles

- **Mirror CI exactly** — if it passes locally, it passes in CI. No surprises.
- **Scoped runs for speed** — in monorepos, only check packages with changes.
- **Full run on main** — pushing to main always runs the complete suite.
- **Graceful degradation** — integration tests only run if DATABASE_URL is available.
- **Clear diagnostics** — each check prints timing and, on failure, the exact fix command.
- **Never bypass** — `--no-verify` is forbidden. Fix the issue, do not skip the gate.

## Gate Summary

| #   | Gate                   | Scope        | Conditional                |
| --- | ---------------------- | ------------ | -------------------------- |
| 1   | Remote main not ahead  | Branch       | Always                     |
| 2   | No uncommitted changes | Working tree | Always                     |
| 3   | Environment setup      | N/A          | Always                     |
| 4   | Format check           | Full         | Always                     |
| 5   | Lint                   | Full         | Always                     |
| 6   | Type check             | Full         | Always                     |
| 7   | Tests with coverage    | Full         | Always                     |
| 8   | Build verification     | Full         | Always                     |
| 9   | Architecture check     | Full         | If import-linter installed |
| 10  | Integration tests      | Full         | If DATABASE_URL set        |
| 11  | Migration check        | Full         | If Alembic configured      |

## Complete Script: scripts/pre-push.sh

```bash
#!/usr/bin/env bash
# repo-quality-rails: Python pre-push verification
# This script is invoked by the pre-commit framework's pre-push stage.
# It mirrors the CI pipeline exactly.
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Colors and helpers
# ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass()    { echo -e "${GREEN}✓${NC} $1 ${CYAN}(${2}s)${NC}"; }
fail()    { echo -e "${RED}✗${NC} $1"; ERRORS+=("$1"); }
info()    { echo -e "${CYAN}→${NC} $1"; }
section() { echo -e "\n${BOLD}── $1 ──${NC}"; }

ERRORS=()
SECONDS_TOTAL=0

timer_start() { SECONDS=0; }
timer_stop()  { local elapsed=$SECONDS; SECONDS_TOTAL=$((SECONDS_TOTAL + elapsed)); echo "$elapsed"; }

# ─────────────────────────────────────────────────────────────
# CHECK 1: Remote main not ahead
# ─────────────────────────────────────────────────────────────
section "CHECK 1: Remote main not ahead"
timer_start

MAIN_BRANCH="main"
if ! git rev-parse --verify "origin/$MAIN_BRANCH" >/dev/null 2>&1; then
  MAIN_BRANCH="master"
fi

git fetch origin "$MAIN_BRANCH" --quiet 2>/dev/null || true
BEHIND=$(git rev-list --count "HEAD..origin/$MAIN_BRANCH" 2>/dev/null || echo 0)
if [ "$BEHIND" -gt 0 ]; then
  fail "CHECK 1: origin/$MAIN_BRANCH is $BEHIND commits ahead. Rebase: git fetch origin $MAIN_BRANCH && git rebase origin/$MAIN_BRANCH"
else
  pass "CHECK 1: Branch is up to date with origin/$MAIN_BRANCH" "$(timer_stop)"
fi

# ─────────────────────────────────────────────────────────────
# CHECK 2: No uncommitted changes
# ─────────────────────────────────────────────────────────────
section "CHECK 2: No uncommitted changes"
timer_start

if ! git diff --quiet || ! git diff --cached --quiet; then
  fail "CHECK 2: Uncommitted changes detected. Commit or stash before pushing."
else
  pass "CHECK 2: Working tree clean" "$(timer_stop)"
fi

# ─────────────────────────────────────────────────────────────
# CHECK 3: Environment setup
# ─────────────────────────────────────────────────────────────
section "CHECK 3: Environment setup"

if [ -z "${DATABASE_URL:-}" ] && [ -f .env.local ]; then
  export DATABASE_URL=$(grep '^DATABASE_URL=' .env.local | cut -d'=' -f2- || true)
fi
export CI=true
export TERM=dumb

info "DATABASE_URL: ${DATABASE_URL:+set}${DATABASE_URL:-not set}"

# ─────────────────────────────────────────────────────────────
# CHECK 4: Format check
# ─────────────────────────────────────────────────────────────
section "CHECK 4: Format check"
timer_start

if uv run ruff format --check . >/dev/null 2>&1; then
  pass "CHECK 4: Formatting OK" "$(timer_stop)"
else
  timer_stop >/dev/null
  fail "CHECK 4: Format check failed. Fix: uv run ruff format ."
fi

# ─────────────────────────────────────────────────────────────
# CHECK 5: Lint
# ─────────────────────────────────────────────────────────────
section "CHECK 5: Lint"
timer_start

if uv run ruff check . 2>&1; then
  pass "CHECK 5: Lint OK" "$(timer_stop)"
else
  timer_stop >/dev/null
  fail "CHECK 5: Lint failed. Fix: uv run ruff check --fix ."
fi

# ─────────────────────────────────────────────────────────────
# CHECK 6: Type check
# ─────────────────────────────────────────────────────────────
section "CHECK 6: Type check"
timer_start

if uv run mypy src/ 2>&1; then
  pass "CHECK 6: Type check OK" "$(timer_stop)"
else
  timer_stop >/dev/null
  fail "CHECK 6: MyPy failed. Fix: uv run mypy src/"
fi

# ─────────────────────────────────────────────────────────────
# CHECK 7: Tests with coverage
# ─────────────────────────────────────────────────────────────
section "CHECK 7: Tests with coverage"
timer_start

if uv run pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=90 -q 2>&1; then
  pass "CHECK 7: Tests + coverage OK" "$(timer_stop)"
else
  timer_stop >/dev/null
  fail "CHECK 7: Tests or coverage threshold failed. Fix: uv run pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=90"
fi

# ─────────────────────────────────────────────────────────────
# CHECK 8: Build verification
# ─────────────────────────────────────────────────────────────
section "CHECK 8: Build verification"
timer_start

if uv build --quiet 2>&1; then
  pass "CHECK 8: Build OK" "$(timer_stop)"
  rm -rf dist/  # Clean up build artifacts
else
  timer_stop >/dev/null
  fail "CHECK 8: Build failed. Fix: uv build"
fi

# ─────────────────────────────────────────────────────────────
# CHECK 9: Architecture check (conditional)
# ─────────────────────────────────────────────────────────────
if uv run python -c "import importlib_metadata; importlib_metadata.version('import-linter')" 2>/dev/null || \
   uv run python -c "import importlib.metadata; importlib.metadata.version('import-linter')" 2>/dev/null; then
  section "CHECK 9: Architecture boundaries"
  timer_start

  if uv run lint-imports 2>&1; then
    pass "CHECK 9: Architecture OK" "$(timer_stop)"
  else
    timer_stop >/dev/null
    fail "CHECK 9: Import boundary violation. Fix: uv run lint-imports"
  fi
else
  info "CHECK 9: Skipped (import-linter not installed)"
fi

# ─────────────────────────────────────────────────────────────
# CHECK 10: Integration tests (conditional)
# ─────────────────────────────────────────────────────────────
if [ -n "${DATABASE_URL:-}" ]; then
  section "CHECK 10: Integration tests"
  timer_start

  if uv run pytest tests/integration/ -q 2>&1; then
    pass "CHECK 10: Integration tests OK" "$(timer_stop)"
  else
    timer_stop >/dev/null
    fail "CHECK 10: Integration tests failed. Fix: uv run pytest tests/integration/ -v"
  fi
else
  info "CHECK 10: Skipped (DATABASE_URL not set)"
fi

# ─────────────────────────────────────────────────────────────
# CHECK 11: Migration check (conditional)
# ─────────────────────────────────────────────────────────────
if [ -f "alembic.ini" ] || [ -d "migrations" ]; then
  section "CHECK 11: Migration check"
  timer_start

  if uv run alembic check 2>&1; then
    pass "CHECK 11: Migrations OK" "$(timer_stop)"
  else
    timer_stop >/dev/null
    fail "CHECK 11: Pending migrations. Fix: uv run alembic revision --autogenerate -m 'description'"
  fi
else
  info "CHECK 11: Skipped (no Alembic config)"
fi

# ─────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}── Summary ──${NC}"
echo -e "Total time: ${CYAN}${SECONDS_TOTAL}s${NC}"

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo -e "${RED}${#ERRORS[@]} check(s) failed:${NC}"
  for err in "${ERRORS[@]}"; do
    echo -e "  ${RED}✗${NC} $err"
  done
  echo ""
  echo -e "${RED}Push blocked.${NC} Fix the issues above and try again."
  exit 1
else
  echo -e "${GREEN}All checks passed.${NC}"
fi
```

## Making the Script Executable

```bash
chmod +x scripts/pre-push.sh
```

## Monorepo Scoping

For monorepos with uv workspaces, add package change detection after CHECK 3. This scopes checks to
changed packages for speed:

```bash
# After CHECK 3, before CHECK 4:
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
  FULL_RUN=1
  info "Pushing to $CURRENT_BRANCH: full verification"
else
  CHANGED_FILES=$(git diff --name-only "origin/$MAIN_BRANCH...HEAD" 2>/dev/null || git diff --name-only HEAD~1)
  CHANGED_PACKAGES=$(echo "$CHANGED_FILES" | grep "^packages/" | cut -d'/' -f2 | sort -u || true)

  if echo "$CHANGED_FILES" | grep -qE "^(pyproject\.toml|uv\.lock|\.pre-commit|\.github)"; then
    FULL_RUN=1
    info "Root config changed: full verification"
  elif [ -z "$CHANGED_PACKAGES" ]; then
    info "No package changes detected. Quick pass."
    exit 0
  else
    FULL_RUN=0
    info "Changed packages: $CHANGED_PACKAGES"
  fi
fi
```

Then scope each check:

```bash
# Instead of: uv run pytest tests/
# Use:
if [ "$FULL_RUN" = "1" ]; then
  uv run pytest tests/
else
  for pkg in $CHANGED_PACKAGES; do
    uv run pytest "packages/$pkg/tests/" -q
  done
fi
```

## Verification

```bash
# Test the script directly
bash scripts/pre-push.sh

# Test via git push (will trigger pre-commit's pre-push stage)
git push origin feature-branch
```

## Stop & Confirm

Confirm the pre-push script and gate sequence before moving to Step 07 (CI pipeline).
