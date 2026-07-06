# Standard Rust Setup

Use this as the default Rust setup. Standard mode is a practical production baseline: Cargo project
layout, rustfmt, Clippy, tests, basic hooks, lightweight CI, and agent docs. It is not the full
hardened quality-rails setup.

## Defaults

- Edition: 2021 unless the user requests newer.
- Toolchain: stable unless the repo requires nightly.
- Formatter: rustfmt.
- Linter: Clippy with `-D warnings`.
- Tests: `cargo test`.
- Hooks: lightweight shell scripts.
- CI: one lightweight job from `standard/basic-ci.md`.

## Layout

Single crate:

```text
src/main.rs or src/lib.rs
Cargo.toml
rust-toolchain.toml
rustfmt.toml
scripts/pre-commit.sh
scripts/pre-push.sh
.gitignore
```

Workspace only when requested:

```text
crates/
Cargo.toml
```

## Config

`rust-toolchain.toml`:

```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
```

`rustfmt.toml`:

```toml
edition = "2021"
max_width = 100
```

## Commands

Add a `Makefile` or document:

```bash
cargo fmt --all
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
cargo build --all-features
```

## Hooks

Pre-commit should format/check quickly:

```bash
#!/usr/bin/env bash
set -euo pipefail
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
```

Pre-push should mirror standard CI:

```bash
#!/usr/bin/env bash
set -euo pipefail
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
cargo build --all-features
```

## Verify

Run:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-features
cargo build --all-features
```
