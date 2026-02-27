# Step 03 — Clippy & Compile-Time Quality Gates

This step configures Clippy linting and compile-time quality attributes. In Rust, **the compiler IS
the type checker** — there is no separate type-checking step like `tsc --noEmit` or `mypy`. Clippy
extends the compiler's static analysis with hundreds of additional lint checks.

## Why No Separate Type-Check Step?

In TypeScript, you run `tsc` for type checking and ESLint for linting — two separate tools. In Rust,
`cargo clippy` runs the full compiler (type checking, borrow checking, lifetime analysis) **plus**
Clippy's lint passes in a single invocation. Running `cargo check` separately would be redundant —
Clippy already does everything `cargo check` does and more.

## Crate-Level Attributes

Add these to the top of every `lib.rs` or `main.rs`. They are **compile-time quality gates** — the
compiler enforces them on every build, not just in CI.

### For library crates (`lib.rs`)

```rust
#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(clippy::all)]
#![warn(clippy::pedantic)]
```

### For binary crates (`main.rs`)

```rust
#![forbid(unsafe_code)]
#![deny(clippy::all)]
#![warn(clippy::pedantic)]
```

> **Why `forbid` vs `deny`?**
>
> - `forbid(unsafe_code)` — cannot be overridden with `#[allow]` anywhere in the crate. Use this
>   when the project does not need unsafe code (per intake answer).
> - `deny(missing_docs)` — fails compilation if public items lack documentation. Use for libraries;
>   optional for binaries.
> - `deny(clippy::all)` — treats all default Clippy warnings as errors.
> - `warn(clippy::pedantic)` — surfaces additional design quality hints without blocking.
>
> If the project **needs** unsafe code, downgrade to `#![deny(unsafe_code)]` and require
> `// SAFETY: ...` comments on every `unsafe` block.

### Workspace-level lint configuration (Cargo.toml)

When using a workspace, configure lints in the root `Cargo.toml` and inherit them:

```toml
# Root Cargo.toml
[workspace.lints.clippy]
all = { level = "deny", priority = -1 }
pedantic = { level = "warn", priority = -1 }
# Pedantic overrides — disable specific pedantic lints that are too noisy:
module_name_repetitions = "allow"
must_use_candidate = "allow"
missing_errors_doc = "allow"
missing_panics_doc = "allow"
```

```toml
# Each crate's Cargo.toml
[lints]
workspace = true
```

> **Crate attributes vs Cargo.toml lints:** Both work. Crate attributes (`#![forbid(...)]`) are
> visible at the top of every source file — developers see the rules immediately. Cargo.toml
> `[lints]` centralizes configuration. Use **both**: `forbid(unsafe_code)` and `deny(missing_docs)`
> as crate attributes (these are identity-level declarations), and Clippy lint groups in
> `[workspace.lints.clippy]` (these are tuning knobs).

## clippy.toml

Place at the workspace root for Clippy-specific thresholds:

```toml
# Maximum cognitive complexity per function (default: 25)
cognitive-complexity-threshold = 15

# Maximum number of function arguments (default: 7)
too-many-arguments-threshold = 5

# Maximum number of lines per function (default: 100)
too-many-lines-threshold = 60

# Maximum type complexity (default: 250)
type-complexity-threshold = 200

# Maximum number of struct fields (default: 8)
max-struct-bools = 3

# Allow common names in single-char variable usage
allowed-idents-below-min-chars = ["x", "y", "z", "i", "j", "n", "k", "v"]
```

## Running Clippy

```bash
# Standard check — all targets (lib, bins, tests, examples, benches)
cargo clippy --workspace --all-targets -- -D warnings

# Fix auto-fixable lints
cargo clippy --workspace --fix --allow-dirty

# Check with specific feature flags
cargo clippy --workspace --all-features -- -D warnings
```

## Common Pedantic Overrides

When `clippy::pedantic` produces false positives, override specific lints with justification:

```rust
// In a function where the cast is known-safe:
#[allow(clippy::cast_possible_truncation)] // value is bounded to u16 range by validation above
fn to_port(value: u32) -> u16 {
    value as u16
}
```

**Rule:** Every `#[allow(clippy::...)]` must have a comment explaining why it is safe to suppress.
Bare `#[allow]` without justification is an anti-pattern.

## Stop & Confirm

Confirm the crate attributes, Cargo.toml lint configuration, and clippy.toml thresholds before
moving to Step 04.
