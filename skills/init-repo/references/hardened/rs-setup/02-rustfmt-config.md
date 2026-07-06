# Step 02 — Rustfmt Configuration

This step configures `rustfmt` for consistent, auto-applied formatting across the project.

## rustfmt.toml

Place at the workspace root. Applies to all crates automatically.

```toml
edition = "2021"
max_width = 100
tab_spaces = 4
use_field_init_shorthand = true
newline_style = "Unix"
```

> **Why these values?**
>
> - `max_width = 100` — wider than the 80-char default, matches modern monitor widths
> - `use_field_init_shorthand = true` — `Foo { bar }` instead of `Foo { bar: bar }`
> - `newline_style = "Unix"` — consistent line endings across platforms

### Nightly-only options (commented out)

Some useful options require nightly rustfmt. Document them as comments so the team knows they exist,
but do not enable them unless the project uses nightly:

```toml
# Requires nightly rustfmt (uncomment if using nightly):
# imports_granularity = "Crate"    # Merge imports from the same crate
# group_imports = "StdExternalCrate"  # Group std, external, then crate imports
# wrap_comments = true             # Wrap long comments to max_width
```

To use nightly rustfmt with stable Rust:

```bash
# Run nightly fmt without changing the project toolchain
cargo +nightly fmt
```

## Editor Integration

### VS Code (`settings.json`)

```json
{
  "[rust]": {
    "editor.defaultFormatter": "rust-lang.rust-analyzer",
    "editor.formatOnSave": true
  },
  "rust-analyzer.rustfmt.extraArgs": []
}
```

### IntelliJ / CLion

Rust plugin uses rustfmt automatically. Ensure "Reformat on save" is enabled in Settings → Tools →
Actions on Save.

## Verification

```bash
# Check formatting (exit code 1 if unformatted)
cargo fmt --check

# Apply formatting
cargo fmt

# Format a specific crate in a workspace
cargo fmt -p my-project-core
```

## Stop & Confirm

Confirm the rustfmt.toml and editor settings before moving to Step 03.
