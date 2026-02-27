# Rust Test Infrastructure Deep Dive

This reference covers advanced testing patterns beyond the basics in Step 04.

## Property-Based Testing with proptest

[proptest](https://github.com/proptest-rs/proptest) generates random inputs to find edge cases that
hand-written tests miss. It is the Rust equivalent of QuickCheck/Hypothesis.

### Setup

```toml
[dev-dependencies]
proptest = "1"
```

### Basic Usage

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_roundtrip_serialization(input in "\\PC*") {
        let encoded = encode(&input);
        let decoded = decode(&encoded).unwrap();
        prop_assert_eq!(input, decoded);
    }

    #[test]
    fn test_add_commutative(a in -1000i32..1000, b in -1000i32..1000) {
        prop_assert_eq!(add(a, b), add(b, a));
    }
}
```

### Custom Strategies

```rust
use proptest::prelude::*;

fn valid_email() -> impl Strategy<Value = String> {
    (
        "[a-z]{1,10}",   // local part
        "[a-z]{1,5}",    // domain
        prop_oneof!["com", "org", "net"],
    )
        .prop_map(|(local, domain, tld)| format!("{local}@{domain}.{tld}"))
}

proptest! {
    #[test]
    fn test_parse_email(email in valid_email()) {
        let parsed = Email::parse(&email).unwrap();
        prop_assert!(!parsed.local_part().is_empty());
    }
}
```

### Persistence

proptest saves failing cases to `proptest-regressions/` files. **Commit these files** — they ensure
known edge cases are always re-tested:

```gitignore
# Do NOT gitignore these:
# proptest-regressions/
```

## cargo-nextest In Depth

### Why nextest over `cargo test`?

| Feature             | `cargo test`        | `cargo-nextest`     |
| ------------------- | ------------------- | ------------------- |
| Test isolation      | Shared process      | Per-test process    |
| Parallelism         | Thread-level        | Process-level       |
| Retries             | No                  | Built-in            |
| Output              | Captured on failure | Streamed + captured |
| JUnit XML           | No                  | Built-in            |
| Slow test detection | No                  | Built-in            |

### Configuration: `.config/nextest.toml`

```toml
[profile.default]
retries = 0
slow-timeout = { period = "60s", terminate-after = 2 }
fail-fast = true

[profile.ci]
retries = 2
fail-fast = false
# JUnit XML for CI reporting
junit = { path = "target/nextest/ci/junit.xml" }

[profile.default.junit]
path = "target/nextest/default/junit.xml"
```

### Usage

```bash
# Run all tests
cargo nextest run --workspace

# Run specific tests
cargo nextest run --workspace -E 'test(parse)'

# Run with CI profile
cargo nextest run --workspace --profile ci

# List tests without running
cargo nextest list --workspace
```

> **Caveat:** nextest does not support doc-tests (`///` examples). Run `cargo test --doc` separately
> in CI.

## Coverage Deep Dive

### cargo-tarpaulin vs cargo-llvm-cov

| Feature      | cargo-tarpaulin | cargo-llvm-cov                                      |
| ------------ | --------------- | --------------------------------------------------- |
| Rust channel | Stable          | Stable (with llvm-tools)                            |
| Mechanism    | ptrace-based    | LLVM instrumentation                                |
| Accuracy     | Good            | Better (branch-level)                               |
| Speed        | Moderate        | Faster on large projects                            |
| Platform     | Linux only      | Linux, macOS, Windows                               |
| Setup        | `cargo install` | `cargo install` + `rustup component add llvm-tools` |

### cargo-tarpaulin advanced usage

```bash
# Exclude specific files or modules
cargo tarpaulin --workspace --fail-under 80 \
  --ignore-tests \
  --exclude-files "*/generated/*" \
  --exclude-files "*/migrations/*"

# Output multiple formats
cargo tarpaulin --workspace --out html --out lcov --out xml \
  --output-dir coverage/

# Run only specific test binary
cargo tarpaulin --workspace --test integration_tests
```

### cargo-llvm-cov advanced usage

```bash
# Install prerequisites
rustup component add llvm-tools
cargo install cargo-llvm-cov

# Generate HTML report
cargo llvm-cov --workspace --html --output-dir coverage/

# Branch coverage
cargo llvm-cov --workspace --branch --fail-under-lines 80

# Coverage for specific tests
cargo llvm-cov --workspace --test integration -- --ignored

# Show uncovered lines in terminal
cargo llvm-cov --workspace --text | head -100
```

### CI Coverage Upload

```yaml
# GitHub Actions with tarpaulin
- run: cargo tarpaulin --workspace --fail-under 80 --out xml
- uses: actions/upload-artifact@v4
  with:
    name: coverage
    path: cobertura.xml

# GitHub Actions with llvm-cov
- run: cargo llvm-cov --workspace --lcov --output-path lcov.info
- uses: actions/upload-artifact@v4
  with:
    name: coverage
    path: lcov.info
```

## Benchmarking with criterion

[criterion](https://github.com/bheisler/criterion.rs) provides statistical benchmarking with
regression detection.

### Setup

```toml
[dev-dependencies]
criterion = { version = "0.5", features = ["html_reports"] }

[[bench]]
name = "my_benchmark"
harness = false
```

### Benchmark file: `benches/my_benchmark.rs`

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use my_project::process;

fn bench_process(c: &mut Criterion) {
    let input = generate_test_input(1000);
    c.bench_function("process_1000", |b| {
        b.iter(|| process(black_box(&input)))
    });
}

fn bench_process_scaling(c: &mut Criterion) {
    let mut group = c.benchmark_group("process_scaling");
    for size in [100, 1000, 10000] {
        let input = generate_test_input(size);
        group.bench_with_input(
            criterion::BenchmarkId::from_parameter(size),
            &input,
            |b, input| b.iter(|| process(black_box(input))),
        );
    }
    group.finish();
}

criterion_group!(benches, bench_process, bench_process_scaling);
criterion_main!(benches);
```

### Running benchmarks

```bash
# Run all benchmarks
cargo bench

# Run specific benchmark
cargo bench -- process_1000

# Compare against baseline
cargo bench -- --save-baseline main
# ... make changes ...
cargo bench -- --baseline main
```

> **Note:** Benchmarks are NOT part of pre-push or CI gates by default. They are for developer use
> during optimization work.

## Test Fixtures and Helpers

### `tests/common/mod.rs` Pattern

```rust
use std::sync::Once;

static INIT: Once = Once::new();

pub fn setup() {
    INIT.call_once(|| {
        // One-time global setup
        tracing_subscriber::fmt::init();
    });
}

pub struct TestFixture {
    pub temp_dir: tempfile::TempDir,
    // Add shared state here
}

impl TestFixture {
    pub fn new() -> Self {
        setup();
        Self {
            temp_dir: tempfile::tempdir().expect("create temp dir"),
        }
    }
}

impl Drop for TestFixture {
    fn drop(&mut self) {
        // Cleanup runs automatically
    }
}
```

### Using fixtures in tests

```rust
mod common;

#[test]
fn test_with_fixture() {
    let fixture = common::TestFixture::new();
    let path = fixture.temp_dir.path().join("test.txt");
    std::fs::write(&path, "hello").unwrap();
    // temp_dir is cleaned up when fixture drops
}
```

### `#[ignore]` for slow tests

Mark integration tests or tests requiring external services with `#[ignore]`:

```rust
#[test]
#[ignore = "requires database"]
fn test_database_migration() {
    // ...
}
```

Run ignored tests explicitly:

```bash
cargo test -- --ignored           # Only ignored tests
cargo test -- --include-ignored   # All tests including ignored
```
