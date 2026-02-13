# Step 05 — Pre-Commit Hooks

This step sets up the pre-commit framework with all quality gates. Pre-commit hooks run on staged
files and must complete in seconds. Their job is immediate feedback on the code being committed.

## Install pre-commit

```bash
uv add --dev pre-commit
uv run pre-commit install
uv run pre-commit install --hook-type pre-push
```

## Complete .pre-commit-config.yaml

This is the full configuration. It uses a mix of remote hooks (maintained by the community) and
local hooks (using the project's own tool versions via `uv run`).

```yaml
# repo-quality-rails
# Pre-commit configuration for Python quality gates
# Install: uv run pre-commit install && uv run pre-commit install --hook-type pre-push

default_stages: [pre-commit]

repos:
  # ─────────────────────────────────────────────────────────────
  # Remote hooks: file hygiene
  # ─────────────────────────────────────────────────────────────
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-json
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ["--maxkb=500"]
      - id: debug-statements          # Catches breakpoint(), pdb.set_trace()
      - id: detect-private-key

  # ─────────────────────────────────────────────────────────────
  # Remote hooks: secret detection
  # ─────────────────────────────────────────────────────────────
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.2
    hooks:
      - id: gitleaks

  # ─────────────────────────────────────────────────────────────
  # Local hooks: Python quality gates (use project's tool versions)
  # ─────────────────────────────────────────────────────────────
  - repo: local
    hooks:
      # Gate 0: Auto-format staged files
      - id: ruff-format
        name: "Gate 0: Ruff format"
        entry: uv run ruff format
        language: system
        types: [python]

      # Gate 1: Lint with auto-fix
      - id: ruff-check
        name: "Gate 1: Ruff check"
        entry: uv run ruff check --fix
        language: system
        types: [python]

      # Gate 2: Type checking
      - id: mypy
        name: "Gate 2: MyPy type check"
        entry: uv run mypy
        language: system
        types: [python]
        pass_filenames: false
        args: ["src/"]

      # Gate 3: Stub file detection
      # Prevent test doubles from leaking into production code
      - id: no-stubs-in-src
        name: "Gate 3: No stub/mock files in src/"
        entry: bash -c 'STUBS=$(echo "$@" | tr " " "\n" | grep -E "^src/.*/(stub|stubs|mock|mocks|fake|fakes)\\.py$" || true); if [ -n "$STUBS" ]; then echo "Stub/mock files in src/:" && echo "$STUBS" && exit 1; fi'
        language: system
        types: [python]

      # Gate 4: Lock file sync
      # If pyproject.toml changed, uv.lock must also be staged
      - id: lock-file-sync
        name: "Gate 4: uv.lock sync check"
        entry: bash -c 'STAGED=$(git diff --cached --name-only); if echo "$STAGED" | grep -q "pyproject.toml" && ! echo "$STAGED" | grep -q "uv.lock"; then echo "pyproject.toml changed but uv.lock not staged. Run: uv sync && git add uv.lock"; exit 1; fi'
        language: system
        pass_filenames: false
        always_run: true

      # Gate 5: Coverage gaming prevention
      # Block attempts to exclude source files from coverage
      - id: no-coverage-gaming
        name: "Gate 5: Coverage gaming prevention"
        entry: bash -c 'for f in "$@"; do if echo "$f" | grep -qE "(pyproject\\.toml|setup\\.cfg|\\.coveragerc)$"; then DIFF=$(git diff --cached -- "$f"); if echo "$DIFF" | grep -qE "^\\+.*(omit|exclude).*src/"; then echo "Blocked: adding source paths to coverage exclusions in $f"; exit 1; fi; fi; done'
        language: system
        pass_filenames: true
        always_run: false
        types: [file]

      # Gate 6: Migration naming convention (if Alembic)
      # Ensures migration files follow naming pattern
      - id: migration-naming
        name: "Gate 6: Migration file naming"
        entry: bash -c 'for f in "$@"; do if echo "$f" | grep -qE "migrations/versions/.*\\.py$"; then BASE=$(basename "$f"); if ! echo "$BASE" | grep -qE "^[0-9a-f]+_.*\\.py$"; then echo "Migration file does not follow naming convention: $f"; exit 1; fi; fi; done'
        language: system
        types: [python]

  # ─────────────────────────────────────────────────────────────
  # Local hooks: Warnings (inform but don't block)
  # ─────────────────────────────────────────────────────────────
  - repo: local
    hooks:
      # Warning: print() detection
      # Ruff T20 catches this in lint, but this warns even if T20 is ignored
      - id: warn-print-statements
        name: "Warning: print() in source"
        entry: bash -c 'PRINTS=$(grep -rn "^\s*print(" "$@" | grep -v "# noqa" || true); if [ -n "$PRINTS" ]; then echo "⚠ print() statements found (consider removing):" && echo "$PRINTS"; fi; exit 0'
        language: system
        types: [python]
        files: "^src/"

      # Warning: type: ignore without explanation
      - id: warn-type-ignore
        name: "Warning: bare type: ignore"
        entry: bash -c 'IGNORES=$(grep -rn "# type: ignore$" "$@" || true); if [ -n "$IGNORES" ]; then echo "⚠ Bare type: ignore found (add specific error code):" && echo "$IGNORES"; fi; exit 0'
        language: system
        types: [python]

      # Warning: Low assertion density in tests
      - id: warn-assertion-density
        name: "Warning: Low assertion density"
        entry: bash -c 'for f in "$@"; do LINES=$(wc -l < "$f"); ASSERTS=$(grep -c "assert " "$f" || echo 0); if [ "$LINES" -gt 20 ] && [ "$ASSERTS" -lt 2 ]; then echo "⚠ Low assertion density in $f ($ASSERTS asserts in $LINES lines)"; fi; done; exit 0'
        language: system
        types: [python]
        files: "^tests/"

  # ─────────────────────────────────────────────────────────────
  # Pre-push hooks (Layer 2 — full verification)
  # ─────────────────────────────────────────────────────────────
  - repo: local
    hooks:
      - id: pre-push-gates
        name: "Pre-push: Full verification"
        entry: bash scripts/pre-push.sh
        language: system
        pass_filenames: false
        always_run: true
        stages: [pre-push]
```

## Gate Summary

| #   | Gate              | Type    | What it catches                           |
| --- | ----------------- | ------- | ----------------------------------------- |
| 0   | Ruff format       | Hard    | Inconsistent formatting                   |
| 1   | Ruff check        | Hard    | Lint violations, bugs, security issues    |
| 2   | MyPy              | Hard    | Type errors                               |
| 3   | Stub detection    | Hard    | Test doubles in production code           |
| 4   | Lock file sync    | Hard    | pyproject.toml / uv.lock drift            |
| 5   | Coverage gaming   | Hard    | Source paths added to coverage exclusions |
| 6   | Migration naming  | Hard    | Non-standard Alembic migration filenames  |
| —   | print() detection | Warning | Leftover debug prints                     |
| —   | type: ignore      | Warning | Bare type: ignore without error code      |
| —   | Assertion density | Warning | Tests with too few assertions             |

## Conditional Gates

**Gate 6 (Migration naming)** only activates when files matching `migrations/versions/*.py` are
staged. If your project doesn't use Alembic, this gate is effectively a no-op.

Remove it entirely if your project has no database:

```yaml
# Delete the migration-naming hook block if not using Alembic
```

## Sentinel Marker

The first line of `.pre-commit-config.yaml` contains `# repo-quality-rails`. This is the sentinel
marker that SKILL.md checks to detect an existing setup. Do not remove it.

## Verification

```bash
# Install hooks
uv run pre-commit install
uv run pre-commit install --hook-type pre-push

# Run all pre-commit hooks against all files (not just staged)
uv run pre-commit run --all-files

# Run a specific hook
uv run pre-commit run ruff-format --all-files
uv run pre-commit run mypy --all-files
uv run pre-commit run gitleaks --all-files

# Test a commit to verify hooks fire
git add -A && git commit -m "test: verify hooks"
```

## Stop & Confirm

Confirm the pre-commit configuration and gate list before moving to Step 06 (pre-push script).
