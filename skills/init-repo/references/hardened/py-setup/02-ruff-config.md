# Step 02 — Ruff Configuration

This step configures Ruff as the single tool for both formatting and linting. Ruff replaces
Prettier, ESLint, isort, flake8, pylint, and bandit — with 10-100x faster execution.

All configuration lives in `pyproject.toml`.

## Formatting

```toml
[tool.ruff]
target-version = "py312"    # Match your .python-version
line-length = 100
src = ["src", "tests"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
docstring-code-format = true
```

## Linting — Full Rule Set

This is the prescriptive rule set. Every category is included for a reason.

```toml
[tool.ruff.lint]
select = [
  # Core
  "E",      # pycodestyle errors
  "W",      # pycodestyle warnings
  "F",      # pyflakes (unused imports, undefined names)
  "I",      # isort (import ordering)
  "N",      # pep8-naming (class/function/variable naming conventions)
  "UP",     # pyupgrade (modernize syntax for target Python version)

  # Bug prevention
  "B",      # flake8-bugbear (common bug patterns, opinionated design)
  "SIM",    # flake8-simplify (unnecessary complexity)
  "PIE",    # flake8-pie (misc. lint rules)
  "RUF",    # ruff-specific rules (ambiguous chars, unused noqa, etc.)
  "PERF",   # perflint (performance anti-patterns)

  # Security
  "S",      # flake8-bandit (security issues: hardcoded passwords, SQL injection, etc.)

  # Type safety
  "TCH",    # flake8-type-checking (move imports behind TYPE_CHECKING)
  "FBT",    # flake8-boolean-trap (boolean positional args are confusing)
  "A",      # flake8-builtins (shadowing built-in names)

  # Code quality
  "C4",     # flake8-comprehensions (unnecessary list/dict/set comprehensions)
  "C90",    # mccabe (cyclomatic complexity)
  "DTZ",    # flake8-datetimez (naive datetime usage)
  "T20",    # flake8-print (leftover print statements)
  "ARG",    # flake8-unused-arguments
  "ERA",    # eradicate (commented-out code)
  "COM",    # flake8-commas (trailing commas)
  "RSE",    # flake8-raise (unnecessary exception parens)
  "RET",    # flake8-return (unnecessary return/else after return)
  "TID",    # flake8-tidy-imports (relative import bans, etc.)

  # Pylint subset
  "PL",     # pylint rules: PLR (refactor), PLC (convention), PLE (error), PLW (warning)

  # Testing
  "PT",     # flake8-pytest-style (consistent pytest patterns)
]

ignore = [
  # These conflict with Ruff's formatter or are too noisy
  "E501",     # line-too-long (handled by formatter)
  "COM812",   # missing-trailing-comma (conflicts with formatter)

  # Intentional relaxations
  "S101",     # assert used (we use assert in production for invariants; tests need it)
  "PLR0913",  # too-many-arguments (sometimes unavoidable)
  "PLR2004",  # magic-value-comparison (too noisy for constants in tests)
]
```

### Why each category matters

| Category    | Replaces               | Key catches                                               |
| ----------- | ---------------------- | --------------------------------------------------------- |
| `E`/`W`/`F` | pycodestyle + pyflakes | Syntax errors, undefined names, unused imports            |
| `I`         | isort                  | Import order inconsistency                                |
| `N`         | pep8-naming            | `camelCase` functions, lowercase class names              |
| `UP`        | pyupgrade              | Old-style string formatting, unnecessary `typing` imports |
| `B`         | flake8-bugbear         | Mutable default args, except too broad, assert False      |
| `S`         | bandit                 | Hardcoded passwords, `eval()`, insecure `pickle`          |
| `TCH`       | —                      | Imports only needed for type hints waste runtime          |
| `T20`       | —                      | Leftover `print()` in production code                     |
| `C90`       | mccabe                 | Functions too complex to maintain                         |
| `PL`        | pylint                 | Too many branches, too many locals, duplicate keys        |
| `PT`        | —                      | `assertEqual` in pytest (use plain `assert`)              |

## Per-File Ignores

Tests need different rules than production code:

```toml
[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = [
  "S101",     # assert is fine in tests
  "ARG",      # unused function args (fixtures)
  "FBT",      # boolean args fine in test helpers
  "PLR2004",  # magic values fine in assertions
  "S106",     # hardcoded passwords fine in test fixtures
]
"scripts/**/*.py" = [
  "T20",      # print is fine in scripts
]
"**/conftest.py" = [
  "ARG",      # unused args are fixtures
]
```

## Complexity Threshold

```toml
[tool.ruff.lint.mccabe]
max-complexity = 10
```

Functions exceeding complexity 10 must be refactored. This is a hard gate — not a suggestion.

## Import Ordering

```toml
[tool.ruff.lint.isort]
known-first-party = ["my_project"]    # Replace with your package name
force-single-line = false
lines-after-imports = 2
```

For monorepos, list all workspace packages:

```toml
[tool.ruff.lint.isort]
known-first-party = ["core", "api", "worker"]
```

## Pylint Thresholds

```toml
[tool.ruff.lint.pylint]
max-args = 7
max-branches = 12
max-returns = 6
max-statements = 50
max-locals = 15
```

## Bandit (Security) Configuration

```toml
[tool.ruff.lint.flake8-bandit]
check-typed-exception = true
```

Ruff's `S` rules cover the most critical bandit checks:

- `S101`: assert in production (ignored — we allow it)
- `S102`: exec() usage
- `S103`: bad file permissions
- `S104`: binding to all interfaces
- `S105`-`S107`: hardcoded passwords/secrets
- `S108`: insecure temp file
- `S110`: try/except/pass
- `S301`: pickle usage
- `S311`: pseudo-random for crypto
- `S324`: insecure hash
- `S506`: unsafe YAML load

## Verification

```bash
# Format all files
uv run ruff format .

# Check formatting (CI mode)
uv run ruff format --check .

# Lint all files
uv run ruff check .

# Lint with auto-fix
uv run ruff check --fix .

# Show specific rule explanation
uv run ruff rule S105
```

## Stop & Confirm

Confirm the Ruff rule set and per-file ignores before moving to Step 03 (MyPy strict mode).
