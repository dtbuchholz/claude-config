# Rust Architecture Enforcement Deep Dive

This reference covers cargo-deny, Rust's visibility system, feature flag architecture, and
dependency graph analysis — the tools for enforcing architectural boundaries in Rust projects.

## cargo-deny: Supply Chain Auditing

[cargo-deny](https://embarkstudios.github.io/cargo-deny/) is a comprehensive dependency auditing
tool that checks licenses, security advisories, duplicate crate versions, and dependency sources. It
is the Rust equivalent of `npm audit` + `license-checker` + import boundary checking combined.

### `deny.toml` (full config)

```toml
# deny.toml — place at workspace root

[graph]
# Targets to check (all by default)
targets = []
# Exclude specific crates from all checks
exclude = []

# ── Advisories ───────────────────────────────────────────────
[advisories]
# Reject crates with known security vulnerabilities
vulnerability = "deny"
# Reject crates that have been yanked from crates.io
yanked = "deny"
# Reject crates with unmaintained advisories
unmaintained = "warn"
# Reject crates with unsound advisories
unsound = "deny"
# Advisory IDs to ignore (with justification)
ignore = [
  # Example: "RUSTSEC-2024-XXXX",  # reason for ignoring
]

# ── Licenses ─────────────────────────────────────────────────
[licenses]
# Confidence threshold for license detection
confidence-threshold = 0.8
# Allow only these licenses
allow = [
  "MIT",
  "Apache-2.0",
  "BSD-2-Clause",
  "BSD-3-Clause",
  "ISC",
  "Unicode-3.0",
  "Unicode-DFS-2016",
  "Zlib",
  "CC0-1.0",
  "BSL-1.0",
  "OpenSSL",
]
# Deny copyleft licenses in production dependencies
deny = [
  "GPL-2.0",
  "GPL-3.0",
  "AGPL-3.0",
]

# Exceptions for specific crates (with justification)
exceptions = [
  # Example:
  # { name = "some-crate", allow = ["MPL-2.0"] },
]

# ── Bans ─────────────────────────────────────────────────────
[bans]
# Reject multiple versions of the same crate (indicates version conflicts)
multiple-versions = "warn"
# Reject wildcard dependencies
wildcards = "deny"
# Highlight specific dependency trees
highlight = "all"

# Deny specific crates entirely
deny = [
  # Example: ban deprecated or problematic crates
  # { name = "openssl", wrappers = ["openssl-sys"] },
]

# Allow specific duplicate versions (with justification)
skip = [
  # Example: { name = "some-crate", version = "=1.0" },
]

# ── Sources ──────────────────────────────────────────────────
[sources]
# Only allow crates from crates.io (no unknown registries or git dependencies)
unknown-registry = "deny"
unknown-git = "deny"
# Allow specific git sources
allow-git = [
  # "https://github.com/org/private-crate",
]
```

### Running cargo-deny

```bash
# Check everything
cargo deny check

# Check specific categories
cargo deny check advisories
cargo deny check licenses
cargo deny check bans
cargo deny check sources

# Generate a license summary
cargo deny list

# Initialize a new deny.toml with defaults
cargo deny init
```

### CI Integration

Use the official GitHub Action:

```yaml
- uses: EmbarkStudios/cargo-deny-action@v2
  # Optionally configure:
  # with:
  #   command: check
  #   arguments: --all-features
```

## Rust Visibility System

Rust's visibility modifiers are **compile-time architecture enforcement**. Unlike runtime import
checking (eslint-plugin-boundaries, import-linter), Rust prevents invalid access at compilation.

### Visibility levels

```rust
pub fn public()          // Visible everywhere
pub(crate) fn internal() // Visible within this crate only
pub(super) fn parent()   // Visible to parent module only
fn private()             // Visible within this module only (default)
```

### Architecture patterns with visibility

```rust
// crates/core/src/lib.rs
pub mod domain;       // Public API — other crates can use this
pub(crate) mod util;  // Internal — only this crate can access

// crates/core/src/domain/mod.rs
pub struct User { ... }          // Part of the public API
pub(crate) fn validate(u: &User) // Internal helper
```

### `pub(crate)` as the default

For internal crates (not published to crates.io), default to `pub(crate)` instead of `pub`. Only use
`pub` for items that genuinely need to be accessible from other crates:

```rust
// ❌ Over-exposed — every function is public
pub fn helper() { ... }

// ✅ Restricted — only callable within this crate
pub(crate) fn helper() { ... }
```

Clippy lint to enforce this:

```toml
# clippy.toml — no built-in lint for this yet
# Use code review to enforce pub(crate) defaults
```

## Feature Flag Architecture

Cargo features enable conditional compilation. Use them for optional functionality,
platform-specific code, and dependency management.

### Defining features

```toml
[features]
default = ["json"]
json = ["dep:serde_json"]
yaml = ["dep:serde_yaml"]
full = ["json", "yaml"]

# No-default-features disables json
# --all-features enables everything
```

### Using features in code

```rust
#[cfg(feature = "json")]
pub mod json {
    pub fn parse(input: &str) -> Result<Value, Error> {
        serde_json::from_str(input).map_err(Error::Json)
    }
}

#[cfg(feature = "yaml")]
pub mod yaml {
    pub fn parse(input: &str) -> Result<Value, Error> {
        serde_yaml::from_str(input).map_err(Error::Yaml)
    }
}
```

### CI feature matrix

Test all feature combinations in CI:

```yaml
strategy:
  matrix:
    features:
      - "" # no default features
      - "--features json"
      - "--features yaml"
      - "--all-features"
steps:
  - run: cargo test --no-default-features ${{ matrix.features }}
```

### Feature flag rules

1. **Features must be additive.** Enabling a feature should never remove functionality.
2. **No `cfg(not(feature = "..."))`.** This creates negative features, which are confusing.
3. **Test with `--no-default-features` in CI.** Ensures the crate compiles without defaults.
4. **Use `dep:` syntax** for optional dependencies to avoid implicit feature names.

## Dependency Graph Visualization

### cargo-depgraph

```bash
cargo install cargo-depgraph

# Generate DOT graph
cargo depgraph --workspace-only | dot -Tpng > deps.png

# Focus on a specific crate
cargo depgraph --focus my-project-core | dot -Tpng > core-deps.png
```

### cargo tree

Built-in dependency tree inspection:

```bash
# Full dependency tree
cargo tree

# Show why a crate is included
cargo tree --invert --package openssl

# Find duplicate versions
cargo tree --duplicates

# Show features enabled for each dependency
cargo tree --format "{p} {f}"
```

## Workspace Dependency Rules

### Centralized version management

All shared dependency versions belong in `[workspace.dependencies]`:

```toml
# Root Cargo.toml
[workspace.dependencies]
serde = { version = "1", features = ["derive"] }
tokio = { version = "1", features = ["full"] }
```

```toml
# Crate Cargo.toml — inherits version from workspace
[dependencies]
serde = { workspace = true }
tokio = { workspace = true }
```

### Preventing version drift

cargo-deny's `[bans]` section with `multiple-versions = "warn"` (or `"deny"` for strict enforcement)
catches cases where two crates in the workspace depend on different versions of the same transitive
dependency.

### Internal crate dependency rules

```
crates/api    → can depend on → crates/core
crates/core   → cannot depend on → crates/api (circular dependency)
```

Cargo enforces this automatically — circular dependencies are a compile error. For more nuanced
rules (e.g., "crate A can depend on crate B but not crate C"), use cargo-deny's `[bans]`:

```toml
[bans]
deny = [
  # Prevent api crate from depending on test utilities
  { name = "my-project-test-utils", wrappers = [] },
]
```
