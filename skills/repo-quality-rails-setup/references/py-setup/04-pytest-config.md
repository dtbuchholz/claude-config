# Step 04 — Pytest Configuration

This step configures pytest as the test runner, establishes test directory structure, and sets up
the conftest.py architecture.

All configuration lives in `pyproject.toml`.

## pytest Configuration

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
asyncio_mode = "auto"
markers = [
  "unit: Unit tests (fast, no I/O)",
  "integration: Integration tests (require external services)",
  "e2e: End-to-end tests (full system)",
  "slow: Tests that take >5 seconds",
]
filterwarnings = [
  "error",                          # Treat all warnings as errors
  "ignore::DeprecationWarning",     # Except deprecation warnings from deps
]
addopts = [
  "--strict-markers",               # Fail on unregistered markers
  "--strict-config",                # Fail on config errors
  "-ra",                            # Show summary of all non-passing tests
  "--tb=short",                     # Shorter tracebacks
]
```

## Coverage Configuration

```toml
[tool.coverage.run]
source = ["src"]
branch = true
omit = [
  "tests/*",
  "*/migrations/*",
  "*/__main__.py",
]

[tool.coverage.report]
fail_under = 90
show_missing = true
skip_covered = true
exclude_lines = [
  "pragma: no cover",
  "if TYPE_CHECKING:",
  'if __name__ == "__main__"',
  "@overload",
  "raise NotImplementedError",
  "\\.\\.\\.",                      # Ellipsis in abstract methods/protocols
  "pass",                           # Empty method bodies
]

[tool.coverage.html]
directory = "htmlcov"
```

### Coverage anti-gaming

The `omit` list MUST NOT contain source directories. The pre-commit hook (Step 05) detects attempts
to add source paths to `omit` or new entries to `exclude_lines` and blocks the commit.

Legitimate exclusions:

- `tests/*` — test code is not production code
- `*/migrations/*` — auto-generated migration files
- `*/__main__.py` — entry point boilerplate

Everything else must be covered or have a `pragma: no cover` comment with justification.

## Test Directory Structure

```
tests/
  __init__.py
  conftest.py                # Root fixtures (shared across all tests)
  unit/
    __init__.py
    conftest.py              # Unit-specific fixtures (mocks, factories)
    test_service.py
    test_models.py
  integration/
    __init__.py
    conftest.py              # Integration fixtures (database, API clients)
    test_repository.py
    test_api_client.py
  e2e/
    __init__.py
    conftest.py              # E2E fixtures (full app setup)
    test_workflow.py
```

## conftest.py Architecture

### Root conftest.py

Shared fixtures and hooks available to ALL tests:

```python
from __future__ import annotations

import pytest


@pytest.fixture(autouse=True)
def _reset_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    """Ensure tests don't leak environment variables."""
    monkeypatch.delenv("DATABASE_URL", raising=False)


@pytest.fixture
def sample_data() -> dict[str, str]:
    """Reusable test data shared across test types."""
    return {"name": "test", "value": "example"}
```

### Unit conftest.py

Fixtures for fast, isolated tests:

```python
from __future__ import annotations

from typing import TYPE_CHECKING
from unittest.mock import AsyncMock

import pytest

if TYPE_CHECKING:
    from my_project.service import MyService


@pytest.fixture
def mock_repository() -> AsyncMock:
    """Mock repository for unit testing service logic."""
    return AsyncMock()


@pytest.fixture
def service(mock_repository: AsyncMock) -> MyService:
    """Service instance with mocked dependencies."""
    from my_project.service import MyService
    return MyService(repository=mock_repository)
```

### Integration conftest.py

Fixtures that require real external services:

```python
from __future__ import annotations

import os
from collections.abc import AsyncGenerator

import pytest


@pytest.fixture(scope="session")
def database_url() -> str:
    """Require DATABASE_URL for integration tests."""
    url = os.environ.get("DATABASE_URL")
    if not url:
        pytest.skip("DATABASE_URL not set")
    return url


@pytest.fixture
async def db_session(database_url: str) -> AsyncGenerator[..., None]:
    """Database session with automatic rollback after each test."""
    # Setup: create session with savepoint
    # ... your ORM session setup ...
    yield session
    # Teardown: rollback to savepoint
    await session.rollback()
```

## Running Tests

```bash
# All tests
uv run pytest

# Unit tests only
uv run pytest tests/unit/

# By marker
uv run pytest -m unit
uv run pytest -m "not integration"
uv run pytest -m "integration and not slow"

# With coverage
uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=90

# Verbose for debugging
uv run pytest -vv --tb=long tests/unit/test_service.py::test_specific

# Parallel execution (requires pytest-xdist)
uv run pytest -n auto
```

## pytest-asyncio Setup

For async code, configure auto mode so you don't need `@pytest.mark.asyncio` on every test:

```python
# pyproject.toml already has: asyncio_mode = "auto"

# Tests can use async directly:
async def test_async_operation(service: MyService) -> None:
    result = await service.process()
    assert result.status == "success"
```

## Assertion Patterns

Use plain `assert` statements — pytest rewrites them to show detailed diffs on failure:

```python
# Good: plain assert (pytest shows full diff)
assert result == expected
assert len(items) == 3
assert "error" in response.text
assert all(item.valid for item in items)

# Good: custom message for non-obvious assertions
assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"

# Bad: unittest-style (less readable, no pytest magic)
self.assertEqual(result, expected)  # Don't do this
```

## Stop & Confirm

Confirm the pytest configuration, directory structure, and conftest architecture before moving to
Step 05 (pre-commit hooks).
