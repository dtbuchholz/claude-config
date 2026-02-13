# Step 07 — Git Hooks (Husky)

This step installs and configures pre-commit and pre-push hooks. These scripts include the
`# repo-quality-rails` marker used for the sentinel check.

> **Note:** These are the essential hook scripts. For full-featured versions with colored output,
> per-gate timing, and scoped package detection, see `references/pre-commit-gates.md` and
> `references/pre-push-gates.md`.

## .husky/pre-commit

```bash
#!/usr/bin/env bash
# repo-quality-rails
set -euo pipefail

# 0. Lint-staged (Prettier auto-fix on staged files)
pnpm exec lint-staged || { echo "lint-staged failed"; exit 1; }

# 1. Lockfile consistency check
STAGED_PACKAGE_JSON=$(git diff --cached --name-only -- 'package.json' 'pnpm-workspace.yaml' 'apps/**/package.json' 'packages/**/package.json' || true)
if [ -n "$STAGED_PACKAGE_JSON" ]; then
  DEPS_CHANGED=$(git diff --cached -- $STAGED_PACKAGE_JSON | grep -E '^\+.*"(dependencies|devDependencies|peerDependencies|optionalDependencies)"' || true)
  if [ -n "$DEPS_CHANGED" ]; then
    if ! git diff --cached --name-only -- 'pnpm-lock.yaml' | grep -q 'pnpm-lock.yaml'; then
      echo "pnpm-lock.yaml is not staged but package.json dependency changes are staged"
      echo "   Run: pnpm install"
      exit 1
    fi
  fi
fi

# 2. Lint affected packages (parallel with type-check)
pnpm turbo lint --filter='...[HEAD^1]' --output-logs=errors-only &
LINT_PID=$!

# 3. Type-check affected packages
pnpm turbo type-check --filter='...[HEAD^1]' --output-logs=errors-only &
TYPE_CHECK_PID=$!

# Wait for parallel checks
wait "$LINT_PID" || { echo "Lint failed"; exit 1; }
wait "$TYPE_CHECK_PID" || { echo "Type check failed"; exit 1; }

# 4. Test affected packages
pnpm turbo test --filter='...[HEAD^1]' --output-logs=errors-only || { echo "Tests failed"; exit 1; }

# 5. Secret detection
STAGED_FILES=$(git diff --cached --name-only || true)
if [ -n "$STAGED_FILES" ]; then
  SECRETS_FOUND=$(echo "$STAGED_FILES" | xargs grep -l -E "(password|secret|api[_-]?key|token|credential)\s*[:=]\s*['\"][^'\"]+['\"]" 2>/dev/null || true)
  if [ -n "$SECRETS_FOUND" ]; then
    echo "Hardcoded secrets detected:"
    echo "$SECRETS_FOUND"
    exit 1
  fi
fi

# 6. Check for 'any' types (warning only)
STAGED_TS=$(git diff --cached --name-only -- '*.ts' '*.tsx' | grep -v '.test.' | grep -v '.d.ts' || true)
if [ -n "$STAGED_TS" ]; then
  ANY_FOUND=$(echo "$STAGED_TS" | xargs grep -l ': any' 2>/dev/null || true)
  if [ -n "$ANY_FOUND" ]; then
    echo "Warning: 'any' type found in staged files"
  fi
fi

# 7. Test assertion density (warning for thin tests)
STAGED_TESTS=$(git diff --cached --name-only -- '*.test.ts' '*.test.tsx' || true)
if [ -n "$STAGED_TESTS" ]; then
  for file in $STAGED_TESTS; do
    if [ -f "$file" ]; then
      LINES=$(wc -l < "$file" | tr -d ' ')
      EXPECTS=$(grep -c 'expect(' "$file" 2>/dev/null || echo "0")
      if [ "$LINES" -gt 50 ] && [ "$EXPECTS" -lt 3 ]; then
        echo "Warning: Low assertion density in $file ($EXPECTS expects in $LINES lines)"
      fi
    fi
  done
fi

# 8. Changeset enforcement for publishable packages
STAGED_PKG_DIRS=$(git diff --cached --name-only -- 'packages/**' 'apps/**' | sed -E 's#^((packages|apps)/[^/]+)/.*#\1#' | sort -u || true)
NEEDS_CHANGESET=false

for pkg_dir in $STAGED_PKG_DIRS; do
  if [ -f "$pkg_dir/package.json" ]; then
    IS_PRIVATE=$(grep -E '"private"\s*:\s*true' "$pkg_dir/package.json" || true)
    if [ -z "$IS_PRIVATE" ]; then
      NEEDS_CHANGESET=true
    fi
  fi
done

if [ "$NEEDS_CHANGESET" = true ]; then
  CHANGESETS=$(find .changeset -name "*.md" ! -name "README.md" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CHANGESETS" -eq 0 ]; then
    echo "No changeset found but publishable package code is being committed"
    echo "   Run: pnpm changeset"
    exit 1
  fi
fi

echo "Pre-commit passed"
```

## .husky/pre-push

```bash
#!/usr/bin/env bash
# repo-quality-rails
set -euo pipefail

# Ensure local branch is not behind origin/main
git fetch origin main --quiet 2>/dev/null
BEHIND_COUNT=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
if [ "$BEHIND_COUNT" != "0" ]; then
  echo "Pre-push blocked: origin/main is $BEHIND_COUNT commit(s) ahead"
  echo "   Fix: git fetch origin main && git rebase origin/main"
  exit 1
fi

# No uncommitted changes
UNCOMMITTED=$(git status --porcelain 2>/dev/null)
if [ -n "$UNCOMMITTED" ]; then
  echo "Pre-push blocked: uncommitted changes detected"
  echo "   Fix: commit or stash changes before pushing"
  exit 1
fi

export CI=true
export TERM=dumb

# Full QA suite
pnpm format:check || { echo "Format check failed - run 'pnpm format'"; exit 1; }
pnpm lint || { echo "Lint failed"; exit 1; }
pnpm type-check || { echo "Type check failed"; exit 1; }
pnpm test:coverage || { echo "Tests or coverage failed"; exit 1; }
pnpm build || { echo "Build failed"; exit 1; }

# Integration tests if database is available
if [ -n "$DATABASE_URL" ]; then
  pnpm test:integration || { echo "Integration tests failed"; exit 1; }
fi

echo "Pre-push passed"
```

## Stop & Confirm

Confirm the hooks are installed and executable before moving to Step 08.
