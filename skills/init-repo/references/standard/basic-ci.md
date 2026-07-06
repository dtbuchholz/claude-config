# Standard Basic CI

Use this for `standard` mode only. It is intentionally lighter than hardened CI: one job, one
language, and the same commands a developer runs locally.

## GitHub Actions Shape

Create `.github/workflows/ci.yml` when GitHub Actions is the chosen provider.

### JS/TS

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: pnpm
      - run: pnpm install --frozen-lockfile
      - run: pnpm format:check
      - run: pnpm lint
      - run: pnpm run --if-present type-check
      - run: pnpm test
```

### Python

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: uv sync
      - run: make check
```

### Rust

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt, clippy
      - run: cargo fmt --all -- --check
      - run: cargo clippy --all-targets --all-features -- -D warnings
      - run: cargo test --all-features
      - run: cargo build --all-features
```

## Rules

- Keep this job small and predictable.
- Do not add service containers, deployment, matrix builds, mutation testing, or architecture gates
  in standard mode.
- If the repo needs multi-job CI or production-grade gate parity, switch to hardened mode.
