# Step 07 — CI Pipeline

This step configures GitHub Actions with a three-tier parallel pipeline that mirrors the pre-push
gates on clean infrastructure.

## Pipeline Architecture

```
                    ┌─────────────────┐
                    │   Trigger: PR    │
                    │   or push to     │
                    │   main           │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │  Tier 1a:  │  │  Tier 1b:  │  │  Tier 1c:  │
     │  Format    │  │  Clippy    │  │  Test       │
     │            │  │            │  │             │
     └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
           │               │               │
           └───────────────┼───────────────┘
                           ▼
                  ┌────────────────┐
                  │  Tier 2:       │
                  │  Build         │
                  └───────┬────────┘
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
     ┌──────────┐  ┌───────────┐  ┌──────────┐
     │ Tier 3a: │  │ Tier 3b:  │  │ Tier 3c: │
     │ Coverage │  │ cargo-deny│  │ cargo doc│
     └──────────┘  └───────────┘  └──────────┘
```

**Why three tiers?**

- Tier 1 runs fast checks in parallel — fail fast on format/lint/test errors
- Tier 2 builds only if Tier 1 passes — no point building broken code
- Tier 3 runs expensive/optional checks that depend on a passing build

## `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  CARGO_TERM_COLOR: always
  RUSTFLAGS: -D warnings

jobs:
  # ── Tier 1: Fast parallel checks ──────────────────────────
  fmt:
    name: Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt
      - run: cargo fmt --check

  clippy:
    name: Clippy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - uses: Swatinem/rust-cache@v2
      - run: cargo clippy --workspace --all-targets -- -D warnings

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo test --workspace

  # ── Tier 2: Build ─────────────────────────────────────────
  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [fmt, clippy, test]
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo build --workspace --release

  # ── Tier 3: Extended checks (parallel) ────────────────────
  coverage:
    name: Coverage
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo install cargo-tarpaulin
      - run: cargo tarpaulin --workspace --fail-under 80 --ignore-tests --out xml
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: cobertura.xml

  deny:
    name: Dependency Audit
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4
      - uses: EmbarkStudios/cargo-deny-action@v2

  docs:
    name: Documentation
    runs-on: ubuntu-latest
    needs: [build]
    env:
      RUSTDOCFLAGS: -D warnings
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo doc --workspace --no-deps

  # ── MSRV Check (optional) ─────────────────────────────────
  msrv:
    name: MSRV
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@master
        with:
          # Read MSRV from rust-toolchain.toml or Cargo.toml rust-version
          toolchain: "1.75" # ← Match the rust-version from Cargo.toml
          components: clippy
      - uses: Swatinem/rust-cache@v2
      - run: cargo check --workspace
      - run: cargo test --workspace
```

## Key CI Decisions

### `Swatinem/rust-cache@v2`

Caches the `target/` directory and cargo registry. Reduces build times from 5-10 minutes to 1-2
minutes on subsequent runs. Uses a hash of `Cargo.lock` as the cache key.

### `dtolnay/rust-toolchain@stable`

Installs the Rust toolchain via rustup. More reliable and faster than the deprecated
`actions-rs/toolchain`. Supports `components` for rustfmt/clippy.

### `EmbarkStudios/cargo-deny-action@v2`

Runs `cargo deny check` with built-in caching. Checks licenses, advisories, bans, and sources. No
need to install cargo-deny manually.

### `RUSTFLAGS: -D warnings`

Set at the workflow level to treat all warnings as errors in CI. This ensures code that compiles
locally with warnings will fail in CI.

### MSRV Job

Only runs on PRs (not pushes to main). Uses the specific MSRV version from `Cargo.toml` to verify
the crate compiles on the minimum supported version.

## Stop & Confirm

Confirm the CI pipeline structure and action versions before moving to Step 08.
