# Step 04 — Testing Configuration

This step establishes testing conventions, integration test structure, and coverage tooling.

## Unit Tests

Rust's built-in test framework uses `#[test]` attributes. Unit tests live in the same file as the
code they test, inside a `#[cfg(test)]` module:

```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn test_add_negative() {
        assert_eq!(add(-1, 1), 0);
    }

    #[test]
    #[should_panic(expected = "overflow")]
    fn test_add_overflow() {
        let _ = add(i32::MAX, 1);
    }
}
```

### Conventions

- **One `#[cfg(test)] mod tests` per file.** Do not create separate test files for unit tests.
- **Test function names:** `test_<function_name>_<scenario>` — e.g., `test_parse_empty_input`.
- **Use `assert_eq!` and `assert_ne!`** for value comparisons (better error messages than
  `assert!`).
- **Use `#[should_panic]`** for expected panics, with `expected = "..."` substring match.
- **Use `Result<(), Error>` return** for tests that use `?` operator instead of unwrap chains.

```rust
#[test]
fn test_parse_config() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_str("key=value")?;
    assert_eq!(config.get("key"), Some("value"));
    Ok(())
}
```

## Integration Tests

Integration tests live in a top-level `tests/` directory. Each file is compiled as a separate crate
— it can only access the public API.

```
tests/
  integration/
    mod.rs           # Re-exports test modules
    api_tests.rs
    storage_tests.rs
  common/
    mod.rs           # Shared test utilities and fixtures
```

### `tests/common/mod.rs` (shared helpers)

```rust
use std::sync::Once;

static INIT: Once = Once::new();

/// Initialize shared test state (e.g., tracing subscriber, database pool).
/// Safe to call from any integration test — runs exactly once.
pub fn setup() {
    INIT.call_once(|| {
        // Initialize tracing, database, etc.
    });
}

/// Create a temporary directory for test artifacts.
pub fn temp_dir() -> tempfile::TempDir {
    tempfile::tempdir().expect("failed to create temp directory")
}
```

### `tests/integration/api_tests.rs`

```rust
mod common;

use my_project_core::Config;

#[test]
fn test_config_roundtrip() {
    common::setup();
    let config = Config::new();
    let serialized = config.to_string();
    let deserialized = Config::from_str(&serialized).unwrap();
    assert_eq!(config, deserialized);
}
```

## Async Tests

For async code (tokio, etc.), use `#[tokio::test]`:

```rust
#[tokio::test]
async fn test_fetch_data() {
    let result = fetch_data("https://example.com").await;
    assert!(result.is_ok());
}
```

Add `tokio` as a dev-dependency with the `macros` and `rt` features:

```toml
[dev-dependencies]
tokio = { version = "1", features = ["macros", "rt-multi-thread"] }
```

## Coverage with cargo-tarpaulin

[cargo-tarpaulin](https://github.com/xd009642/tarpaulin) is the most widely used Rust coverage tool.

```bash
# Install
cargo install cargo-tarpaulin

# Run with threshold enforcement
cargo tarpaulin --workspace --fail-under 80 --out html --out lcov

# Exclude test code from coverage metrics
cargo tarpaulin --workspace --fail-under 80 --ignore-tests

# Generate lcov for CI upload
cargo tarpaulin --workspace --out lcov --output-dir coverage/
```

### Coverage threshold: 80%

Rust community convention is 80% coverage (vs 90% for TypeScript/Python). Reasons:

- Rust's type system catches many bugs that tests would catch in dynamic languages
- Trait implementations, derive macros, and generated code inflate uncovered lines
- The borrow checker eliminates entire categories of null/dangling-pointer bugs

### Alternative: cargo-llvm-cov

For LLVM-based instrumentation coverage (more accurate, requires nightly or specific setup):

```bash
cargo install cargo-llvm-cov

# Generate coverage report
cargo llvm-cov --workspace --fail-under-lines 80

# Generate lcov output for CI
cargo llvm-cov --workspace --lcov --output-path coverage/lcov.info
```

> **Which to use?** Start with `cargo-tarpaulin` — it works on stable Rust and has simpler setup.
> Switch to `cargo-llvm-cov` if you need more accurate branch coverage or faster execution on large
> codebases.

## cargo-nextest (Optional)

[cargo-nextest](https://nexte.st/) is a faster test runner with better output, parallelism, and
retry support:

```bash
cargo install cargo-nextest

# Run tests (drop-in replacement for cargo test)
cargo nextest run --workspace

# With retries for flaky tests
cargo nextest run --workspace --retries 2

# JUnit XML output for CI
cargo nextest run --workspace --profile ci
```

### `.config/nextest.toml`

```toml
[profile.default]
retries = 0
slow-timeout = { period = "60s", terminate-after = 2 }

[profile.ci]
retries = 2
fail-fast = false
```

> **Note:** cargo-nextest does not support doc-tests. Run `cargo test --doc` separately if you have
> doc-tests.

## Stop & Confirm

Confirm the test structure, coverage tool choice, and threshold before moving to Step 05.
