# Python Mutation Testing

Deep dive into mutmut setup, configuration, CI integration, and strategies for improving mutation
scores. This is the Python equivalent of `references/mutation-testing.md` (Stryker for TypeScript).

## 1. Why Mutation Testing

Coverage measures whether code executed during tests. Mutation testing measures whether tests
actually detect bugs. A test that calls a function but doesn't assert on the result gives 100%
coverage and 0% mutation kill rate.

mutmut introduces small changes (mutants) to source code — replacing `+` with `-`, `True` with
`False`, `>` with `>=` — and re-runs the test suite. If a test fails, the mutant is "killed" (good).
If all tests pass despite the change, the mutant "survived" (bad — your tests missed a real bug).

**The metric:** Mutation score = killed mutants / total mutants. Target: ≥80%.

## 2. Setup

### Install

```bash
uv add --dev mutmut
```

### Configuration

mutmut is configured in `pyproject.toml`:

```toml
[tool.mutmut]
paths_to_mutate = "src/"
tests_dir = "tests/"
runner = "python -m pytest -x -q --tb=no"
```

Configuration options:

| Option            | Default                            | Description                                         |
| ----------------- | ---------------------------------- | --------------------------------------------------- |
| `paths_to_mutate` | `"src/"`                           | Source directories to mutate                        |
| `tests_dir`       | `"tests/"`                         | Test directory                                      |
| `runner`          | `"python -m pytest -x -q --tb=no"` | Test command. `-x` stops at first failure (faster). |
| `dict_synonyms`   | `""`                               | Comma-separated list of dict-like factory names     |

### Run

```bash
# Run all mutations (can be slow — see "Incremental Mode" below)
uv run mutmut run

# View results summary
uv run mutmut results

# Show surviving mutants (the ones you need to fix)
uv run mutmut show surviving

# Show a specific mutant
uv run mutmut show 42

# Generate HTML report
uv run mutmut html
open html/index.html
```

## 3. Mutation Types

mutmut applies these mutation operators:

| Category      | Example                    | What it tests       |
| ------------- | -------------------------- | ------------------- |
| Arithmetic    | `a + b` → `a - b`          | Math logic          |
| Comparison    | `a > b` → `a >= b`         | Boundary conditions |
| Boolean       | `True` → `False`           | Flag logic          |
| Negation      | `not x` → `x`              | Conditional logic   |
| Return values | `return x` → `return None` | Return value usage  |
| String        | `"foo"` → `"XXfooXX"`      | String comparison   |
| Number        | `0` → `1`, `1` → `2`       | Numeric constants   |
| Keyword       | `break` → `continue`       | Loop control        |
| Decorator     | Remove `@decorator`        | Decorator effects   |
| Argument      | Remove default arg         | Default value usage |

## 4. Interpreting Results

After a run, mutmut reports:

```
Legend for output:
🎉 Killed mutants:   145
⏰ Timeout:            3
🤔 Suspicious:         2
🙁 Survived:          12
🔇 Skipped:            0
```

| Status     | Meaning                       | Action                                   |
| ---------- | ----------------------------- | ---------------------------------------- |
| Killed     | Test caught the mutation      | Good — no action needed                  |
| Timeout    | Mutation caused infinite loop | Usually counts as killed                 |
| Suspicious | Test passed but with warnings | Investigate — may need assertion         |
| Survived   | No test caught the mutation   | Bad — write a test or improve assertions |
| Skipped    | Mutation was excluded         | Expected for configured exclusions       |

### Analyzing Survivors

```bash
# List all surviving mutants
uv run mutmut show surviving

# Show specific mutant with context
uv run mutmut show 42
```

Each surviving mutant shows the file, line, and the change made. Common patterns:

| Surviving mutation         | What it means                    | Fix                             |
| -------------------------- | -------------------------------- | ------------------------------- |
| `return x` → `return None` | Test doesn't assert return value | Add assertion on return value   |
| `a > b` → `a >= b`         | No boundary test                 | Add test for exact boundary     |
| `True` → `False`           | Flag not tested                  | Test both branches of the flag  |
| `"error"` → `"XXerrorXX"`  | Error message not checked        | Assert on error message content |
| `x + 1` → `x - 1`          | Arithmetic not verified          | Assert on computed value        |

## 5. Incremental Mode

Full mutation runs are slow (minutes to hours for large codebases). Use incremental mode for
day-to-day development.

### Run Only on Changed Files

```bash
# Mutate only files changed vs main
CHANGED=$(git diff --name-only origin/main -- 'src/*.py' | tr '\n' ',')
if [ -n "$CHANGED" ]; then
  uv run mutmut run --paths-to-mutate "$CHANGED"
fi
```

### Use the Cache

mutmut caches results in `.mutmut-cache`. Subsequent runs only test new or changed mutants:

```bash
# First run: tests all mutants (slow)
uv run mutmut run

# After code changes: only tests affected mutants (fast)
uv run mutmut run
```

### Scope to a Single Module

```bash
# Mutate only a specific module
uv run mutmut run --paths-to-mutate src/my_project/service.py
```

## 6. Combining with Hypothesis

Hypothesis property-based tests are excellent mutant killers. A single Hypothesis test can kill
dozens of mutants because it generates hundreds of inputs that exercise edge cases.

```python
from hypothesis import given
from hypothesis import strategies as st


# This ONE test kills mutants for:
# - arithmetic operator changes
# - boundary condition changes
# - return value changes
# - off-by-one errors
@given(
    price=st.decimals(min_value=0, max_value=10000, places=2),
    quantity=st.integers(min_value=1, max_value=1000),
    discount=st.decimals(min_value=0, max_value=1, places=2),
)
def test_order_total_properties(price, quantity, discount):
    total = calculate_total(price, quantity, discount)

    # Property: total is never negative
    assert total >= 0

    # Property: total without discount >= total with discount
    total_no_discount = calculate_total(price, quantity, 0)
    assert total_no_discount >= total

    # Property: total scales linearly with quantity
    double_total = calculate_total(price, quantity * 2, discount)
    assert double_total == total * 2
```

**Strategy:** Write Hypothesis tests for core business logic first. They provide both high coverage
and high mutation kill rates with minimal test code.

## 7. Threshold Enforcement

### CI Gate

```bash
#!/bin/bash
# scripts/mutation-check.sh

set -euo pipefail

THRESHOLD="${MUTATION_THRESHOLD:-80}"

uv run mutmut run --CI 2>&1 | tee mutmut-output.txt

# Parse results
KILLED=$(grep -oP '🎉 Killed mutants:\s+\K\d+' mutmut-output.txt || echo 0)
TIMEOUT=$(grep -oP '⏰ Timeout:\s+\K\d+' mutmut-output.txt || echo 0)
SURVIVED=$(grep -oP '🙁 Survived:\s+\K\d+' mutmut-output.txt || echo 0)

TOTAL=$((KILLED + TIMEOUT + SURVIVED))
if [ "$TOTAL" -eq 0 ]; then
  echo "No mutants generated."
  exit 0
fi

SCORE=$(( (KILLED + TIMEOUT) * 100 / TOTAL ))
echo "Mutation score: ${SCORE}% (threshold: ${THRESHOLD}%)"

if [ "$SCORE" -lt "$THRESHOLD" ]; then
  echo "FAIL: Mutation score ${SCORE}% is below threshold ${THRESHOLD}%."
  echo "Run 'uv run mutmut show surviving' to see untested mutations."
  exit 1
fi
```

### Ratcheting

Like coverage, the mutation threshold should only go up:

```bash
# After reaching 85%, update the threshold
MUTATION_THRESHOLD=85 bash scripts/mutation-check.sh
```

Track the threshold in the CI workflow:

```yaml
env:
  MUTATION_THRESHOLD: 80 # Ratchet: only increase this number
```

## 8. CI Integration

### GitHub Actions

Mutation testing is slow, so run it separately from the main CI pipeline — either on a schedule or
as an optional check.

```yaml
# .github/workflows/mutation.yml
name: Mutation Testing

on:
  schedule:
    - cron: "0 6 * * 1" # Weekly on Monday at 6am
  workflow_dispatch: {} # Manual trigger

concurrency:
  group: mutation-${{ github.ref }}
  cancel-in-progress: true

jobs:
  mutmut:
    runs-on: ubuntu-latest
    timeout-minutes: 60

    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
        with:
          enable-cache: true

      - name: Install dependencies
        run: uv sync --all-extras

      - name: Run mutation testing
        run: bash scripts/mutation-check.sh
        env:
          MUTATION_THRESHOLD: 80

      - name: Generate HTML report
        if: always()
        run: uv run mutmut html

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: mutation-report
          path: html/
```

### PR-Scoped Mutation Testing

For PRs, only mutate changed files to keep the check fast:

```yaml
# Add to .github/workflows/ci.yml as an optional job
mutation-check:
  runs-on: ubuntu-latest
  timeout-minutes: 30
  if: github.event_name == 'pull_request'

  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    - uses: astral-sh/setup-uv@v4
      with:
        enable-cache: true

    - name: Install dependencies
      run: uv sync --all-extras

    - name: Get changed Python files
      id: changed
      run: |
        FILES=$(git diff --name-only origin/main -- 'src/**/*.py' | tr '\n' ',')
        echo "files=$FILES" >> "$GITHUB_OUTPUT"

    - name: Run mutation testing on changed files
      if: steps.changed.outputs.files != ''
      run: |
        uv run mutmut run --paths-to-mutate "${{ steps.changed.outputs.files }}"
        uv run mutmut results
```

## 9. Excluding Code from Mutation

Some code legitimately doesn't need mutation testing:

```python
# pragma: no mutate — third-party callback signature, not our logic
def on_event(self, event: Event) -> None:
    self.handler.process(event)
```

mutmut respects `# pragma: no mutate` comments. Use sparingly and with justification, same as
`# pragma: no cover`.

For configuration-level exclusions:

```toml
[tool.mutmut]
paths_to_mutate = "src/"
# Exclude generated code and migrations
paths_to_exclude = [
    "src/my_project/generated/",
    "src/my_project/migrations/",
]
```

## 10. Improving Mutation Score

### Priority Order

1. **Write property-based tests** for core business logic (highest kill rate per test).
2. **Add boundary assertions** — test `>` vs `>=`, `==` vs `!=`.
3. **Assert return values** — every function call in a test should have its result checked.
4. **Test error paths** — ensure exceptions are raised with correct types and messages.
5. **Test default values** — verify behavior when optional arguments are omitted.

### Quick Wins

| Surviving mutation         | One-line fix                                                     |
| -------------------------- | ---------------------------------------------------------------- |
| `return x` → `return None` | `assert result == expected_value`                                |
| `True` → `False`           | `assert obj.is_active is True` (not just `assert obj.is_active`) |
| `>` → `>=`                 | Add test case for the exact boundary value                       |
| `+ 1` → `- 1`              | Assert on the exact numeric result                               |
| Remove decorator           | Test that the decorator's effect is present                      |

### What Not to Chase

Don't try to kill every mutant. Some mutations are equivalent (the change doesn't affect behavior)
or test trivial code. Focus on:

- Business logic mutations (high value)
- Security-relevant mutations (authentication, authorization)
- Data integrity mutations (calculations, transformations)

Ignore:

- Logging mutations (changing log message strings)
- Comment-like code (docstrings, debug prints)
- Equivalent mutants (changes that produce identical behavior)
