# Python Design Metrics

Complexity metrics, architecture boundaries, and design health enforcement for Python projects. This
is the Python equivalent of the ESLint-based design metrics in `references/design-metrics.md`.

## 1. Complexity Analysis with Radon

Radon computes cyclomatic complexity, maintainability index, and raw metrics for Python code.

### Install

```bash
uv add --dev radon
```

### Cyclomatic Complexity

```bash
# Show complexity for all functions/methods
uv run radon cc src/ -s -a

# Show only complex functions (C or worse)
uv run radon cc src/ -n C

# JSON output for CI
uv run radon cc src/ -j
```

Complexity grades:

| Grade | Score | Meaning                           |
| ----- | ----- | --------------------------------- |
| A     | 1-5   | Simple, low risk                  |
| B     | 6-10  | Moderate, manageable              |
| C     | 11-15 | Complex, refactor candidate       |
| D     | 16-20 | Very complex, should refactor     |
| E     | 21-30 | Untestable, must refactor         |
| F     | 31+   | Error-prone, refactor immediately |

**Quality gate threshold: Block on grade C or worse (complexity > 10).**

### Maintainability Index

```bash
# Show maintainability index
uv run radon mi src/ -s

# Show only low-maintainability files
uv run radon mi src/ -n B
```

Grades: A (20+), B (10-19), C (0-9). Block on grade C.

### Cognitive Complexity

Radon also supports cognitive complexity (how hard a function is to understand, as opposed to how
many paths it has):

```bash
uv run radon cc src/ --total-average
```

## 2. Threshold Enforcement with Xenon

Xenon wraps radon and exits non-zero when thresholds are exceeded. Use it as a CI gate.

### Install

```bash
uv add --dev xenon
```

### Usage

```bash
# Fail if any function exceeds complexity grade B (>10)
# Fail if any module average exceeds grade A (>5)
# Fail if any module total exceeds grade B (>10)
uv run xenon src/ --max-absolute B --max-modules A --max-average A
```

### CI Integration

```yaml
# In .github/workflows/ci.yml, add to lint-and-typecheck job:
- name: Complexity check
  run: uv run xenon src/ --max-absolute B --max-modules A --max-average A
```

### Pre-Push Integration

Add to `scripts/pre-push.sh` after the type check:

```bash
# CHECK 6.5: Complexity check
section "CHECK 6.5: Complexity check"
timer_start
if uv run xenon src/ --max-absolute B --max-modules A --max-average A 2>&1; then
  pass "CHECK 6.5: Complexity OK" "$(timer_stop)"
else
  timer_stop >/dev/null
  fail "CHECK 6.5: Complexity threshold exceeded. Fix: uv run radon cc src/ -n C"
fi
```

## 3. Complexity Tracking with Wily

Wily tracks complexity metrics over time, showing whether the codebase is getting simpler or more
complex with each commit.

### Install

```bash
uv add --dev wily
```

### Build Baseline

```bash
# Index the last 50 commits
uv run wily build src/ -n 50
```

### View Trends

```bash
# Show complexity trend for a file
uv run wily report src/my_project/service.py

# Show diff against previous revision
uv run wily diff src/ -r HEAD~1

# Rank files by complexity
uv run wily rank src/ --threshold 10
```

### Ratcheting Strategy

Wily enables a ratcheting approach: complexity can only go down, never up.

```bash
# In CI, fail if complexity increased compared to the merge base
MERGE_BASE=$(git merge-base HEAD origin/main)
uv run wily diff src/ -r "$MERGE_BASE" --no-detail || {
  echo "Complexity increased compared to main. Refactor before merging."
  exit 1
}
```

## 4. Pylint Design Rules as Gates

Pylint's design checker enforces structural limits. While Ruff covers most pylint rules via the `PL`
category, some design-specific rules benefit from explicit thresholds.

These are already configured in Step 02 (Ruff config) via `[tool.ruff.lint.pylint]`:

```toml
[tool.ruff.lint.pylint]
max-args = 7          # PLR0913: Too many arguments
max-branches = 12     # PLR0912: Too many branches
max-returns = 6       # PLR0911: Too many return statements
max-statements = 50   # PLR0915: Too many statements
max-locals = 15       # PLR0914: Too many local variables
```

Additional design rules enforced by Ruff's `PL` category:

- `PLR0911`: Too many return statements
- `PLR0912`: Too many branches
- `PLR0913`: Too many arguments
- `PLR0914`: Too many local variables
- `PLR0915`: Too many statements
- `PLR0916`: Too many boolean expressions
- `PLW0120`: Else clause on loop without break

## 5. Architecture Boundaries with import-linter

import-linter enforces dependency direction rules between packages and layers.

### Install

```bash
uv add --dev import-linter
```

### Configuration (.importlinter)

Create `.importlinter` at the repo root:

```ini
[importlinter]
root_packages =
    my_project

[importlinter:contract:layers]
name = Layer contract
type = layers
layers =
    my_project.api
    my_project.service
    my_project.domain
    my_project.infrastructure
# api can import service, service can import domain, etc.
# But domain CANNOT import api or service.

[importlinter:contract:domain-independence]
name = Domain independence
type = independence
modules =
    my_project.domain.users
    my_project.domain.orders
    my_project.domain.payments
# No domain module can import another domain module directly.

[importlinter:contract:no-orm-in-domain]
name = No ORM in domain
type = forbidden
source_modules =
    my_project.domain
forbidden_modules =
    sqlalchemy
    alembic
```

### Contract Types

| Type           | What it enforces                                             |
| -------------- | ------------------------------------------------------------ |
| `layers`       | Module A can import B, B can import C, but C cannot import A |
| `independence` | Listed modules cannot import each other                      |
| `forbidden`    | Source modules cannot import from forbidden modules          |

### Run

```bash
uv run lint-imports

# Verbose output
uv run lint-imports --verbose
```

### Pre-Push Integration

Already included in Step 06 as CHECK 9. import-linter runs only if installed.

## 6. Dependency Visualization with pydeps

pydeps generates dependency graphs as SVG images.

### Install

```bash
uv add --dev pydeps
```

### Usage

```bash
# Generate dependency graph
uv run pydeps src/my_project --cluster --max-bacon=2 -o deps.svg

# Show only internal dependencies
uv run pydeps src/my_project --no-show --noshow-deps --cluster -o internal-deps.svg
```

### CI Integration

Generate and upload as artifact for review:

```yaml
- name: Generate dependency graph
  run: uv run pydeps src/my_project --cluster -o deps.svg --no-show
- uses: actions/upload-artifact@v4
  with:
    name: dependency-graph
    path: deps.svg
```

## 7. Circular Import Detection

Ruff and pylint catch circular imports:

```toml
# Already in the Ruff rule set (Step 02):
# PLC0415: import-outside-toplevel (helps avoid circular imports)
# Ruff detects some circular patterns via import analysis
```

For deeper analysis, use pydeps:

```bash
# Show cycles
uv run pydeps src/my_project --show-cycles
```

## 8. Putting It All Together

### Recommended Gate Sequence

| Gate                    | Tool          | Threshold            | Where         |
| ----------------------- | ------------- | -------------------- | ------------- |
| Cyclomatic complexity   | xenon         | max-absolute B (≤10) | Pre-push + CI |
| Maintainability index   | radon mi      | grade ≥ B (≥10)      | CI            |
| Function length         | Ruff PLR0915  | ≤50 statements       | Pre-commit    |
| Function args           | Ruff PLR0913  | ≤7 args              | Pre-commit    |
| Branch count            | Ruff PLR0912  | ≤12 branches         | Pre-commit    |
| Architecture boundaries | import-linter | All contracts pass   | Pre-push + CI |
| Complexity trend        | wily diff     | No increase vs main  | CI            |

### Quick Start

```bash
# Install all design metric tools
uv add --dev radon xenon wily import-linter pydeps

# Build wily baseline
uv run wily build src/ -n 50

# Run all checks
uv run xenon src/ --max-absolute B --max-modules A --max-average A
uv run lint-imports
uv run wily diff src/ -r HEAD~1
```
