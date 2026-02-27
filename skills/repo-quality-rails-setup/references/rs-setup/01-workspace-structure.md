# Step 01 — Workspace Structure

This step establishes the project layout, Cargo configuration, and toolchain pinning.

## Single Crate Layout

```
my-project/
  src/
    lib.rs          # or main.rs for binaries
  tests/
    integration/    # Integration tests
  scripts/
    pre-commit.sh
    pre-push.sh
  Cargo.toml
  Cargo.lock
  rust-toolchain.toml
  rustfmt.toml
  clippy.toml
  Makefile
  .gitignore
```

### Cargo.toml (single crate)

```toml
[package]
name = "my-project"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"  # MSRV — adjust to intake answer
# Uncomment for crates.io publishing:
# description = "..."
# license = "MIT OR Apache-2.0"
# repository = "https://github.com/org/my-project"

[dependencies]

[dev-dependencies]

[lints.clippy]
all = { level = "deny", priority = -1 }
pedantic = { level = "warn", priority = -1 }
```

## Workspace Layout

```
my-project/
  crates/
    api/            # Binary crate
      src/
        main.rs
      Cargo.toml
    core/           # Library crate
      src/
        lib.rs
      Cargo.toml
  tests/
    integration/    # Workspace-level integration tests
  scripts/
    pre-commit.sh
    pre-push.sh
  Cargo.toml        # Workspace root
  Cargo.lock
  rust-toolchain.toml
  rustfmt.toml
  clippy.toml
  Makefile
  .gitignore
```

### Cargo.toml (workspace root)

```toml
[workspace]
resolver = "2"
members = [
  "crates/*",
]

[workspace.package]
version = "0.1.0"
edition = "2021"
rust-version = "1.75"  # MSRV — adjust to intake answer
# license = "MIT OR Apache-2.0"
# repository = "https://github.com/org/my-project"

[workspace.dependencies]
# Pin shared dependency versions here. Crates reference them with:
#   dep-name = { workspace = true }
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["full"] }
thiserror = "2"
tracing = "0.1"

[workspace.lints.clippy]
all = { level = "deny", priority = -1 }
pedantic = { level = "warn", priority = -1 }
```

### Crate Cargo.toml (example: `crates/core`)

```toml
[package]
name = "my-project-core"
version.workspace = true
edition.workspace = true
rust-version.workspace = true

[dependencies]
serde = { workspace = true }
thiserror = { workspace = true }

[dev-dependencies]

[lints]
workspace = true
```

### Crate Cargo.toml (example: `crates/api`)

```toml
[package]
name = "my-project-api"
version.workspace = true
edition.workspace = true
rust-version.workspace = true

[dependencies]
my-project-core = { path = "../core" }
tokio = { workspace = true }
tracing = { workspace = true }

[dev-dependencies]

[lints]
workspace = true
```

## rust-toolchain.toml

```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
```

> **Why pin the toolchain?** This ensures every developer and CI uses the same compiler version.
> Change `channel` to a specific version (e.g., `"1.82.0"`) for maximum reproducibility, or keep
> `"stable"` if you always want the latest.

## Makefile

```makefile
.PHONY: install-hooks fmt lint test build clean

install-hooks:
	@echo "Installing git hooks..."
	@ln -sf ../../scripts/pre-commit.sh .git/hooks/pre-commit
	@ln -sf ../../scripts/pre-push.sh .git/hooks/pre-push
	@chmod +x scripts/pre-commit.sh scripts/pre-push.sh
	@echo "Git hooks installed."

fmt:
	cargo fmt

lint:
	cargo clippy --workspace --all-targets -- -D warnings

test:
	cargo test --workspace

build:
	cargo build --workspace

clean:
	cargo clean
```

> **Why a Makefile?** Rust projects don't have a package-manager hook framework like Husky or
> pre-commit. A Makefile with an `install-hooks` target is the standard approach — it creates
> symlinks from `.git/hooks/` to version-controlled scripts in `scripts/`.

## .gitignore

```gitignore
# Build artifacts
/target/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.*
!.env.example

# Coverage
*.profraw
lcov.info
tarpaulin-report.html
coverage/
```

## After Setup

```bash
# Initialize git (if not already)
git init

# Install hooks
make install-hooks

# Verify toolchain
rustup show
cargo --version
```

## Stop & Confirm

Confirm the workspace layout, Cargo.toml files, and toolchain config before moving to Step 02.
