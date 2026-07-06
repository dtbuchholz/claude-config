# Starter Rust Setup

Use this for the lightest Rust scaffold. Starter mode is commands-only: no git hooks and no CI.

## Create

- `Cargo.toml`
- `.gitignore`
- `src/main.rs` for binaries or `src/lib.rs` for libraries
- `tests/` only when integration tests are useful

## Baseline

Use the current stable Rust toolchain unless the user requests a specific MSRV.

Recommended `Cargo.toml` fields:

```toml
[package]
name = "PROJECT_NAME"
version = "0.1.0"
edition = "2021"
```

Recommended `.gitignore`:

```gitignore
/target/
.env
.env.*
```

Track `Cargo.lock` for binary applications and workspaces. For libraries, follow the repo's
preference; if the user wants to omit it, add `Cargo.lock` to `.gitignore` explicitly.

## Commands

Document these commands in `README.md`:

```bash
cargo fmt
cargo clippy -- -D warnings
cargo test
```

## Verify

Run:

```bash
cargo fmt --check
cargo clippy -- -D warnings
cargo test
```
