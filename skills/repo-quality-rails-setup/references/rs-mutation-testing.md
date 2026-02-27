# Rust Mutation Testing Deep Dive

This reference covers mutation testing with
[cargo-mutants](https://github.com/sourcefrog/cargo-mutants) — verifying that tests actually detect
bugs, not just execute code.

## What Mutation Testing Proves

Coverage measures which lines **execute** during tests. Mutation testing measures which lines
**matter** — if you change a line and no test fails, that line is effectively untested regardless of
coverage.

```rust
// 100% coverage, but mutation testing reveals weak tests:
pub fn discount(price: f64, rate: f64) -> f64 {
    price * (1.0 - rate)  // Mutant: price * (1.0 + rate) — would any test catch this?
}

#[test]
fn test_discount() {
    let result = discount(100.0, 0.0);  // rate=0 means mutation doesn't matter!
    assert_eq!(result, 100.0);          // This test "covers" the line but doesn't verify it
}
```

## Setup

```bash
cargo install cargo-mutants
```

No configuration file needed — cargo-mutants discovers tests automatically.

## Basic Usage

```bash
# Run mutation testing on entire workspace
cargo mutants --workspace

# Run on a specific package
cargo mutants -p my-project-core

# Run on specific files
cargo mutants -- src/parser.rs

# Dry run — show what mutations would be applied without running tests
cargo mutants --list

# Show only surviving mutants (the interesting ones)
cargo mutants --workspace 2>&1 | grep -E "(MISSED|TIMEOUT)"
```

## Mutation Types

cargo-mutants applies these mutation operators:

| Operator                | What It Does                      | Example                                            |
| ----------------------- | --------------------------------- | -------------------------------------------------- |
| Replace return value    | Returns a default value           | `-> bool` returns `true` instead of computed value |
| Replace arithmetic      | Changes `+` to `-`, `*` to `/`    | `a + b` → `a - b`                                  |
| Replace comparison      | Changes `<` to `>=`, `==` to `!=` | `a < b` → `a >= b`                                 |
| Replace boolean         | Negates boolean expressions       | `flag` → `!flag`                                   |
| Remove function body    | Replaces body with default return | Function returns `Default::default()`              |
| Replace with zero/empty | Returns `0`, `""`, `Vec::new()`   | Numeric function returns `0`                       |

## `--in-diff` for PR-Scoped Testing

Run mutation testing only on lines changed in a PR — dramatically faster than full mutation testing:

```bash
# Get diff from main and run mutations only on changed lines
git diff origin/main...HEAD > changes.diff
cargo mutants --in-diff changes.diff
```

### CI Integration for PR-Scoped Mutations

```yaml
mutation-testing:
  name: Mutation Testing (PR diff)
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0 # Full history for diff
    - uses: dtolnay/rust-toolchain@stable
    - uses: Swatinem/rust-cache@v2
    - run: cargo install cargo-mutants
    - name: Run mutation tests on diff
      run: |
        git diff origin/${{ github.base_ref }}...HEAD > changes.diff
        cargo mutants --in-diff changes.diff --timeout 300
```

## Full CI Integration

For periodic full mutation testing (e.g., weekly or on main branch):

```yaml
mutation-testing-full:
  name: Full Mutation Testing
  runs-on: ubuntu-latest
  # Run weekly or on-demand, not on every PR
  if: github.event_name == 'schedule' || github.event_name == 'workflow_dispatch'
  steps:
    - uses: actions/checkout@v4
    - uses: dtolnay/rust-toolchain@stable
    - uses: Swatinem/rust-cache@v2
    - run: cargo install cargo-mutants
    - name: Run full mutation tests
      run: cargo mutants --workspace --timeout 300
    - uses: actions/upload-artifact@v4
      with:
        name: mutation-report
        path: mutants.out/
```

## Ratcheting Strategy

Mutation testing is most effective as a ratchet — you establish a baseline and ensure the mutation
score never decreases:

### Phase 1: Baseline (week 1)

```bash
# Run full mutation testing, record the results
cargo mutants --workspace > mutants-baseline.txt 2>&1

# Count surviving mutants
grep -c "MISSED" mutants-baseline.txt
# Example output: 47
```

### Phase 2: Fix high-value survivors (weeks 2-4)

Focus on surviving mutants in critical code paths:

```bash
# List surviving mutants sorted by file
cargo mutants --workspace 2>&1 | grep "MISSED" | sort
```

Write targeted tests that kill each surviving mutant.

### Phase 3: PR-scoped enforcement (ongoing)

Once the baseline is clean enough, enforce on new code via `--in-diff` in CI.

### Phase 4: Full enforcement (goal)

When the mutation score is high enough, run full mutation testing in CI and fail on any surviving
mutant in non-excluded code.

## Excluding Code from Mutations

Some code should not be mutation-tested:

```rust
// Skip mutation testing for this function
#[mutants::skip]
fn main() {
    // Entry points, logging, and pure I/O are not worth mutating
}
```

Or exclude in the command:

```bash
# Exclude specific files
cargo mutants --workspace --exclude "src/main.rs" --exclude "src/logging.rs"
```

**Rules for exclusions:**

- Entry points (`main`, CLI parsing) — pure I/O, no logic to test
- Generated code — test the generator, not the output
- FFI bindings — tested via integration tests, not unit mutations
- Never exclude business logic. If a mutation survives in business logic, write a better test.

## Interpreting Results

| Result     | Meaning                              | Action                                                   |
| ---------- | ------------------------------------ | -------------------------------------------------------- |
| `CAUGHT`   | Test suite detected the mutation     | Good — no action needed                                  |
| `MISSED`   | No test failed when mutation applied | Write a test that catches this case                      |
| `TIMEOUT`  | Tests took too long with mutation    | Usually means infinite loop — indicates a boundary issue |
| `UNVIABLE` | Mutation caused a compile error      | Expected for type-safe code — no action needed           |

**A high `UNVIABLE` count is good.** It means Rust's type system prevents many mutations from even
compiling — the compiler is doing the testing for you.
