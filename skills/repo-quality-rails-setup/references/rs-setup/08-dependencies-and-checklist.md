# Step 08 — Dependencies & Setup Checklist

This step captures the complete tool dependency list and the recommended setup order.

## Toolchain Components (via rustup)

These are installed automatically by `rust-toolchain.toml`:

| Component | Purpose                     |
| --------- | --------------------------- |
| `rustfmt` | Code formatting             |
| `clippy`  | Linting and static analysis |

Verify with:

```bash
rustup component list --installed
```

## cargo-install Tools

Install these for the full quality gate suite:

| Tool              | Install Command                 | Purpose                                        | Required?   |
| ----------------- | ------------------------------- | ---------------------------------------------- | ----------- |
| `cargo-tarpaulin` | `cargo install cargo-tarpaulin` | Code coverage                                  | Recommended |
| `cargo-deny`      | `cargo install cargo-deny`      | License, advisory, and dependency auditing     | Recommended |
| `cargo-nextest`   | `cargo install cargo-nextest`   | Faster test runner with better output          | Optional    |
| `cargo-mutants`   | `cargo install cargo-mutants`   | Mutation testing                               | Optional    |
| `cargo-llvm-cov`  | `cargo install cargo-llvm-cov`  | LLVM-based coverage (alternative to tarpaulin) | Optional    |

### One-liner install (recommended tools)

```bash
cargo install cargo-tarpaulin cargo-deny
```

### One-liner install (all tools)

```bash
cargo install cargo-tarpaulin cargo-deny cargo-nextest cargo-mutants
```

## Quick Setup Checklist

1. **Initialize the repo:**

   ```bash
   mkdir my-project && cd my-project
   git init
   cargo init  # or cargo init --lib for a library
   ```

2. **Create workspace structure** (if workspace — see Step 01):

   ```bash
   mkdir -p crates/core/src crates/api/src scripts tests/integration
   ```

3. **Create config files** at root:
   - `rust-toolchain.toml` (Step 01)
   - `rustfmt.toml` (Step 02)
   - `clippy.toml` (Step 03)
   - `Makefile` (Step 01)
   - `.gitignore` (Step 01)

4. **Add crate-level attributes** to each `lib.rs` / `main.rs` (Step 03):

   ```rust
   #![forbid(unsafe_code)]
   #![deny(missing_docs)]
   #![deny(clippy::all)]
   #![warn(clippy::pedantic)]
   ```

5. **Create hook scripts** (Steps 05-06):

   ```bash
   # Create scripts
   # scripts/pre-commit.sh (Step 05)
   # scripts/pre-push.sh (Step 06)
   chmod +x scripts/*.sh
   ```

6. **Install hooks:**

   ```bash
   make install-hooks
   ```

7. **Install recommended tools:**

   ```bash
   cargo install cargo-tarpaulin cargo-deny
   ```

8. **Create CI pipeline** (Step 07):

   ```bash
   mkdir -p .github/workflows
   # Create .github/workflows/ci.yml (Step 07)
   ```

9. **Create cargo-deny config** (if using cargo-deny):

   ```bash
   cargo deny init
   # Edit deny.toml — see references/rs-architecture-enforcement.md
   ```

10. **Verify everything works:**

    ```bash
    cargo fmt --check
    cargo clippy --workspace --all-targets -- -D warnings
    cargo test --workspace
    cargo build --workspace
    ```

## Verification Commands

Run these to confirm the setup is complete and all gates pass:

```bash
# Format check
cargo fmt --check

# Lint check
cargo clippy --workspace --all-targets -- -D warnings

# Tests
cargo test --workspace

# Build
cargo build --workspace

# Coverage (if installed)
cargo tarpaulin --workspace --fail-under 80 --ignore-tests

# Dependency audit (if installed)
cargo deny check

# Pre-commit hook (manual trigger)
bash scripts/pre-commit.sh

# Pre-push hook (manual trigger)
bash scripts/pre-push.sh
```

## Stop & Confirm

Confirm the full dependency list and setup checklist. If accepted, the staged setup is complete.
