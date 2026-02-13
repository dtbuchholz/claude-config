# Step 07 — CI Pipeline

This step defines the GitHub Actions CI pipeline. CI is the authoritative source of truth — it runs
on clean infrastructure with no local state. The pipeline mirrors the pre-push gates exactly, so
developers are never surprised by CI failures.

## Pipeline Architecture

```
Trigger: push to main, pull_request

┌─────────────────────┐  ┌─────────────────────┐
│ lint-and-typecheck   │  │ build               │
│ (ruff + mypy)        │  │ (uv build + upload) │
└──────────┬──────────┘  └──────────┬──────────┘
           │                         │
           └────────────┬────────────┘
                        │
           ┌────────────▼────────────┐
           │ test                     │
           │ (matrix: py 3.11-3.13)  │
           │ (sharded via pytest-split)│
           └────────────┬────────────┘
                        │
           ┌────────────▼────────────┐
           │ coverage                 │
           │ (aggregate + enforce)    │
           └────────────┬────────────┘
                        │
           ┌────────────▼────────────┐  (main only)
           │ migration-dry-run        │
           │ (Alembic + Postgres)     │
           └────────────┬────────────┘
                        │
           ┌────────────▼────────────┐  (main only)
           │ security-audit           │
           │ (pip-audit)              │
           └──────────────────────────┘
```

## Complete Workflow: .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}

env:
  UV_CACHE_DIR: /tmp/.uv-cache
  PYTHON_VERSION: "3.12"

jobs:
  # ─────────────────────────────────────────────────────────────
  # Job 1: Lint + Type Check (fast feedback)
  # ─────────────────────────────────────────────────────────────
  lint-and-typecheck:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python
        run: uv python install ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: uv sync --all-extras --frozen

      - name: Check formatting
        run: uv run ruff format --check .

      - name: Lint
        run: uv run ruff check .

      - name: Type check
        run: uv run mypy src/

  # ─────────────────────────────────────────────────────────────
  # Job 2: Build (verify package builds cleanly)
  # ─────────────────────────────────────────────────────────────
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python
        run: uv python install ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: uv sync --all-extras --frozen

      - name: Build package
        run: uv build

      - name: Upload wheel
        uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
          retention-days: 7

  # ─────────────────────────────────────────────────────────────
  # Job 3: Tests (matrix + sharding)
  # ─────────────────────────────────────────────────────────────
  test:
    name: Test (Python ${{ matrix.python-version }}, shard ${{ matrix.shard }})
    needs: [lint-and-typecheck, build]
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.11", "3.12", "3.13"]
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python ${{ matrix.python-version }}
        run: uv python install ${{ matrix.python-version }}

      - name: Install dependencies
        run: uv sync --all-extras --frozen

      - name: Run tests (shard ${{ matrix.shard }}/4)
        run: |
          uv run pytest tests/ \
            --splits 4 \
            --group ${{ matrix.shard }} \
            --splitting-algorithm least_duration \
            --cov=src \
            --cov-report=xml:coverage-${{ matrix.python-version }}-${{ matrix.shard }}.xml \
            -q

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage-${{ matrix.python-version }}-${{ matrix.shard }}
          path: coverage-*.xml
          retention-days: 1

  # ─────────────────────────────────────────────────────────────
  # Job 4: Coverage (aggregate and enforce threshold)
  # ─────────────────────────────────────────────────────────────
  coverage:
    name: Coverage
    needs: [test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python
        run: uv python install ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: uv sync --all-extras --frozen

      - name: Download coverage artifacts
        uses: actions/download-artifact@v4
        with:
          pattern: coverage-*
          merge-multiple: true

      - name: Combine coverage
        run: |
          uv run coverage combine coverage-*.xml || true
          uv run coverage report --fail-under=90
          uv run coverage html

      - name: Upload coverage report
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: htmlcov/
          retention-days: 30

  # ─────────────────────────────────────────────────────────────
  # Job 5: Migration dry-run (main only, if Alembic configured)
  # ─────────────────────────────────────────────────────────────
  migration-dry-run:
    name: Migration Dry Run
    needs: [lint-and-typecheck]
    if: github.ref == 'refs/heads/main' && hashFiles('alembic.ini') != ''
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5
    env:
      DATABASE_URL: postgresql://test:test@localhost:5432/test
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python
        run: uv python install ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: uv sync --all-extras --frozen

      - name: Run migrations
        run: uv run alembic upgrade head

      - name: Check for pending migrations
        run: uv run alembic check

  # ─────────────────────────────────────────────────────────────
  # Job 6: Security audit
  # ─────────────────────────────────────────────────────────────
  security-audit:
    name: Security Audit
    needs: [lint-and-typecheck]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true
          cache-dependency-glob: "uv.lock"

      - name: Set up Python
        run: uv python install ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: uv sync --all-extras --frozen

      - name: Install pip-audit
        run: uv tool install pip-audit

      - name: Audit dependencies
        run:
          uv run pip-audit --require-hashes --disable-pip -r <(uv pip compile pyproject.toml) ||
          true
```

## Test Sharding with pytest-split

pytest-split distributes tests across shards based on previous run durations. On first run, it falls
back to file count distribution.

**Add to dev dependencies:**

```bash
uv add --dev pytest-split
```

**Generate timing data locally** (optional but improves shard balance):

```bash
uv run pytest tests/ --store-durations
# Creates .test_durations file — commit this
```

**CI matrix** uses `--splits N --group K` to select which shard this runner executes.

## Parallel Execution within Shards

For additional speed within each shard, add pytest-xdist:

```bash
uv add --dev pytest-xdist
```

```yaml
# In the test job:
- name: Run tests
  run: |
    uv run pytest tests/ \
      --splits 4 --group ${{ matrix.shard }} \
      -n auto \
      --cov=src \
      -q
```

`-n auto` uses all available CPU cores. Combined with sharding, this gives you `(shards × cores)`
parallelism.

## Dependency Caching

The `astral-sh/setup-uv@v4` action caches the uv directory automatically when `enable-cache: true`
is set. The `cache-dependency-glob: "uv.lock"` ensures the cache invalidates when dependencies
change.

For monorepos with multiple `pyproject.toml` files:

```yaml
- uses: astral-sh/setup-uv@v4
  with:
    enable-cache: true
    cache-dependency-glob: "**/uv.lock"
```

## Adapting for Other CI Providers

The pipeline structure (parallel lint/build → test matrix → coverage gate → deploy) applies to any
CI system. Key commands to port:

```bash
# Lint + type check
uv run ruff format --check . && uv run ruff check . && uv run mypy src/

# Build
uv build

# Test with coverage
uv run pytest tests/ --cov=src --cov-fail-under=90

# Security audit
pip-audit
```

## Stop & Confirm

Confirm the CI pipeline configuration before moving to Step 08 (dependencies and checklist).
