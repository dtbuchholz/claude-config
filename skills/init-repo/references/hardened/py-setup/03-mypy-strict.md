# Step 03 — MyPy Strict Mode

This step configures MyPy for strict type checking. MyPy catches type errors before runtime — wrong
argument types, missing return values, None-safety violations, and more.

All configuration lives in `pyproject.toml`.

## Base Configuration

```toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_configs = true
warn_unreachable = true
show_error_codes = true
pretty = true

# Paths
mypy_path = "src"
packages = ["my_project"]    # Replace with your package name
```

`strict = true` enables all of these flags at once:

- `disallow_any_generics` — no bare `list`, must be `list[str]`
- `disallow_untyped_defs` — every function must have type annotations
- `disallow_untyped_calls` — can't call untyped functions from typed code
- `disallow_incomplete_defs` — partial annotations are not allowed
- `check_untyped_defs` — type-check function bodies even without annotations
- `no_implicit_optional` — `def f(x: str = None)` is an error; use `str | None`
- `warn_redundant_casts` — unnecessary `cast()` calls
- `warn_unused_ignores` — `# type: ignore` on lines that don't need it
- `strict_equality` — comparing incompatible types is an error

## Per-Module Overrides

Third-party libraries without type stubs need overrides. Be specific — never blanket-ignore:

```toml
[[tool.mypy.overrides]]
module = [
  "some_untyped_lib.*",
  "another_lib.submodule",
]
ignore_missing_imports = true

# For libraries that have partial stubs
[[tool.mypy.overrides]]
module = "partially_typed_lib.*"
disallow_untyped_defs = false
```

## Type Stub Management

Install type stubs for common libraries:

```bash
uv add --dev types-requests types-pyyaml types-redis types-toml
```

Common stubs:

| Library         | Stub package            |
| --------------- | ----------------------- |
| requests        | `types-requests`        |
| PyYAML          | `types-pyyaml`          |
| redis           | `types-redis`           |
| toml            | `types-toml`            |
| python-dateutil | `types-python-dateutil` |
| ujson           | `types-ujson`           |
| setuptools      | `types-setuptools`      |

For libraries with bundled types (FastAPI, Pydantic, SQLAlchemy 2.0+, httpx), no stub package is
needed — they ship `py.typed` markers.

## Integration with Ruff's TCH Rules

Ruff's `TCH` rules move imports that are only used in type annotations behind `TYPE_CHECKING`:

```python
from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Sequence
    from pathlib import Path

def process(items: Sequence[str], output: Path) -> None:
    ...
```

This reduces runtime import overhead. MyPy handles `TYPE_CHECKING` blocks correctly — the imports
are visible to the type checker but not executed at runtime.

## Common Error Patterns and Fixes

### 1. Missing return type

```python
# Error: Function is missing a return type annotation
def get_name(user):
    return user.name

# Fix:
def get_name(user: User) -> str:
    return user.name
```

### 2. Optional without explicit None check

```python
# Error: Item "None" of "str | None" has no attribute "upper"
def greet(name: str | None) -> str:
    return name.upper()

# Fix:
def greet(name: str | None) -> str:
    if name is None:
        return "Hello"
    return name.upper()
```

### 3. Incompatible types in assignment

```python
# Error: Incompatible types in assignment (expression has type "int", variable has type "str")
result: str = 42

# Fix: Use the correct type
result: int = 42
```

### 4. Untyped decorator

```python
# Error: Untyped decorator makes function untyped
from functools import wraps

# Fix: Use ParamSpec for typed decorators
from typing import ParamSpec, TypeVar
from collections.abc import Callable

P = ParamSpec("P")
T = TypeVar("T")

def my_decorator(func: Callable[P, T]) -> Callable[P, T]:
    @wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        return func(*args, **kwargs)
    return wrapper
```

## Monorepo Configuration

For uv workspaces, configure MyPy at the root to see all packages:

```toml
[tool.mypy]
python_version = "3.12"
strict = true
mypy_path = ["packages/core/src", "packages/api/src", "packages/worker/src"]
packages = ["core", "api", "worker"]
```

Or run MyPy per-package from CI:

```bash
uv run mypy packages/core/src/core
uv run mypy packages/api/src/api
```

## Verification

```bash
# Type-check the project
uv run mypy src/

# Type-check with verbose output
uv run mypy src/ --show-error-context

# Check a specific file
uv run mypy src/my_project/service.py

# Show what mypy inferred for a symbol
uv run mypy src/ --show-column-numbers
```

## Stop & Confirm

Confirm the MyPy configuration and per-module overrides before moving to Step 04 (pytest config).
