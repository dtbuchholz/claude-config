# Rust Design Metrics Deep Dive

This reference covers using Clippy's lint system and compile-time attributes as design quality gates
— enforcing structural health beyond just catching bugs.

## Clippy Pedantic as Design Metrics

The `clippy::pedantic` lint group contains lints that enforce design quality rather than
correctness. Enabling the group as warnings and selectively denying specific lints creates a tiered
quality system:

### Tier 1: Always Deny (design errors)

These pedantic lints catch genuine design problems. Promote them to `deny`:

```toml
# Cargo.toml [workspace.lints.clippy]
needless_pass_by_value = "deny"       # Accept by reference unless ownership needed
implicit_clone = "deny"                # Make clones explicit
uninlined_format_args = "deny"         # Use `{var}` not `{}", var`
manual_let_else = "deny"              # Use `let ... else { ... }` pattern
```

### Tier 2: Warn (design smells)

Keep these as warnings — they indicate potential issues but have legitimate exceptions:

```toml
# These are warn by default via `pedantic = { level = "warn" }`
# No additional config needed for:
# - clippy::cast_possible_truncation
# - clippy::cast_sign_loss
# - clippy::missing_errors_doc
# - clippy::missing_panics_doc
```

### Tier 3: Allow (too noisy)

Disable pedantic lints that produce excessive false positives:

```toml
module_name_repetitions = "allow"    # `Config` in `config` module is fine
must_use_candidate = "allow"         # Too many false positives
missing_errors_doc = "allow"         # Useful but noisy during development
missing_panics_doc = "allow"         # Same
```

## Crate-Level Attributes as Permanent Enforcement

Crate-level attributes (`#![forbid(...)]`, `#![deny(...)]`) are **permanent gates**. Unlike CI
checks that run periodically, these enforce rules on every single compilation.

### The hierarchy

```
#![forbid(x)]  — Cannot be overridden. Not even #[allow(x)] works.
#![deny(x)]    — Errors, but can be overridden with #[allow(x)] + justification.
#![warn(x)]    — Warnings. Use for informational lints.
```

### Recommended attribute stack

```rust
// lib.rs or main.rs

// Identity-level: these define what kind of crate this is
#![forbid(unsafe_code)]           // This crate never uses unsafe
#![deny(missing_docs)]            // Every public item is documented

// Quality-level: enforced by Clippy
#![deny(clippy::all)]             // All default Clippy lints are errors
#![warn(clippy::pedantic)]        // Pedantic lints are warnings

// Correctness-level: compiler lints
#![deny(rust_2018_idioms)]        // Enforce modern Rust idioms
#![deny(unused_must_use)]         // Must handle Results and other #[must_use] types
```

### When to use `forbid` vs `deny`

| Attribute      | `forbid`                  | `deny`                             |
| -------------- | ------------------------- | ---------------------------------- |
| `unsafe_code`  | Default for most projects | Only if unsafe is genuinely needed |
| `missing_docs` | For public libraries      | For internal libraries             |
| `clippy::all`  | Never (too rigid)         | Yes — allows targeted overrides    |

## Complexity Tracking

### clippy.toml thresholds

```toml
# Cognitive complexity (default: 25, recommended: 15)
cognitive-complexity-threshold = 15

# Function length (default: 100 lines)
too-many-lines-threshold = 60

# Function arguments (default: 7)
too-many-arguments-threshold = 5

# Type complexity (default: 250)
type-complexity-threshold = 200

# Struct boolean fields (prevents "boolean blindness")
max-struct-bools = 3
```

### What cognitive complexity catches

Clippy's `cognitive_complexity` lint measures the mental effort needed to understand a function. It
counts:

- Nesting depth (each `if`, `match`, `loop` adds to complexity)
- Boolean operators in conditions
- `break`, `continue`, early returns

**Example:** A function with complexity 20+ should be refactored into smaller functions.

```rust
// ❌ High complexity — hard to reason about
fn process(data: &Data) -> Result<Output> {  // complexity: 22
    if data.is_valid() {
        match data.kind() {
            Kind::A => {
                if data.has_flag() {
                    for item in data.items() {
                        if item.meets_criteria() && !item.is_excluded() {
                            // ... deeply nested logic
                        }
                    }
                }
            }
            Kind::B => { /* ... */ }
            Kind::C => { /* ... */ }
        }
    }
    // ...
}

// ✅ Decomposed — each function is independently understandable
fn process(data: &Data) -> Result<Output> {  // complexity: 4
    data.validate()?;
    match data.kind() {
        Kind::A => process_kind_a(data),
        Kind::B => process_kind_b(data),
        Kind::C => process_kind_c(data),
    }
}
```

## Module Size Limits

Rust does not have a built-in module size limit. Enforce it with a CI script:

```bash
#!/usr/bin/env bash
# Check that no single .rs file exceeds 500 lines (excluding tests)
MAX_LINES=500
VIOLATIONS=""

for file in $(find . -name '*.rs' -not -path '*/target/*' -not -path '*/tests/*'); do
  # Count non-test lines (everything before #[cfg(test)])
  LINES=$(sed -n '1,/#\[cfg(test)\]/p' "$file" | wc -l | tr -d ' ')
  if [ "$LINES" -gt "$MAX_LINES" ]; then
    VIOLATIONS="$VIOLATIONS\n  $file: $LINES lines"
  fi
done

if [ -n "$VIOLATIONS" ]; then
  echo "Files exceeding $MAX_LINES lines (non-test):"
  echo -e "$VIOLATIONS"
  exit 1
fi
```

## Custom Lint Rules

For project-specific rules that Clippy does not cover, use
[dylint](https://github.com/trailofbits/dylint) — a framework for writing custom Rust lints:

```toml
[workspace.metadata.dylint]
libraries = [
  { git = "https://github.com/trailofbits/dylint", pattern = "examples/general/*" },
]
```

> **When to use dylint:** Only for mature projects with specific architectural rules that cannot be
> expressed with Clippy or cargo-deny. For most projects, Clippy pedantic + clippy.toml thresholds
> are sufficient.
