# Python Test Infrastructure

Deep dive into pytest setup, fixture architecture, Hypothesis property-based testing, coverage
enforcement, and integration test patterns. This is the Python equivalent of
`references/test-infrastructure.md`.

## 1. Why pytest

pytest is the standard Python test runner. It provides:

- Plain `assert` with automatic rewriting for detailed diffs
- Fixture dependency injection (no setUp/tearDown boilerplate)
- Markers for test categorization
- Plugin ecosystem (500+ plugins on PyPI)
- Async support via pytest-asyncio

Do not use `unittest` directly. pytest runs unittest-style tests but its native style is simpler,
more readable, and more powerful.

## 2. conftest.py Architecture

conftest.py files provide fixtures and hooks. pytest discovers them automatically at each directory
level. Fixtures defined in a conftest are available to all tests in that directory and its children.

### Layer 1: Root conftest.py

Shared across ALL tests. Keep this minimal — only fixtures and hooks that genuinely apply
everywhere.

```python
from __future__ import annotations

import os
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    from collections.abc import Generator


def pytest_configure(config: pytest.Config) -> None:
    """Register custom markers."""
    config.addinivalue_line("markers", "unit: Unit tests (fast, no I/O)")
    config.addinivalue_line("markers", "integration: Integration tests (require services)")
    config.addinivalue_line("markers", "e2e: End-to-end tests (full system)")
    config.addinivalue_line("markers", "slow: Tests that take >5 seconds")


@pytest.fixture(autouse=True)
def _clean_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    """Prevent environment variable leakage between tests."""
    for key in ("DATABASE_URL", "API_KEY", "SECRET_KEY"):
        monkeypatch.delenv(key, raising=False)


@pytest.fixture
def temp_dir(tmp_path: ...) -> ...:
    """Provide a temporary directory that's cleaned up after the test."""
    return tmp_path
```

### Layer 2: Unit conftest.py

Fixtures for fast, isolated tests. Mock external dependencies.

```python
# tests/unit/conftest.py
from __future__ import annotations

from typing import TYPE_CHECKING
from unittest.mock import AsyncMock, MagicMock

import pytest

if TYPE_CHECKING:
    from my_project.repository import UserRepository
    from my_project.service import UserService


@pytest.fixture
def mock_repository() -> AsyncMock:
    """Mock repository — no database access."""
    repo = AsyncMock(spec=UserRepository)
    repo.get_by_id.return_value = None
    return repo


@pytest.fixture
def mock_email_client() -> MagicMock:
    """Mock email client — no network access."""
    return MagicMock()


@pytest.fixture
def user_service(
    mock_repository: AsyncMock,
    mock_email_client: MagicMock,
) -> UserService:
    """Service with all dependencies mocked."""
    from my_project.service import UserService
    return UserService(repository=mock_repository, email=mock_email_client)
```

### Layer 3: Integration conftest.py

Fixtures that require real external services. Use session-scoped fixtures for expensive setup
(database connections), function-scoped for cheap teardown (transaction rollback).

```python
# tests/integration/conftest.py
from __future__ import annotations

import os
from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio


@pytest.fixture(scope="session")
def database_url() -> str:
    """Require DATABASE_URL. Skip integration tests if not set."""
    url = os.environ.get("DATABASE_URL")
    if not url:
        pytest.skip("DATABASE_URL not set — skipping integration tests")
    return url


@pytest_asyncio.fixture(scope="session")
async def engine(database_url: str) -> AsyncGenerator:
    """Session-scoped async engine. Created once for all integration tests."""
    from sqlalchemy.ext.asyncio import create_async_engine
    eng = create_async_engine(database_url)
    yield eng
    await eng.dispose()


@pytest_asyncio.fixture
async def db_session(engine: ...) -> AsyncGenerator:
    """Function-scoped session with automatic rollback.

    Each test gets a clean database state via savepoint + rollback.
    """
    from sqlalchemy.ext.asyncio import AsyncSession
    async with AsyncSession(engine, expire_on_commit=False) as session:
        async with session.begin():
            yield session
            await session.rollback()
```

## 3. Fixture Patterns

### Factory Fixtures

For tests that need many similar objects with slight variations:

```python
@pytest.fixture
def make_user():
    """Factory fixture for creating User instances with defaults."""
    def _make_user(
        name: str = "Test User",
        email: str = "test@example.com",
        active: bool = True,
        **overrides: ...,
    ) -> User:
        return User(name=name, email=email, active=active, **overrides)
    return _make_user


def test_inactive_user(make_user):
    user = make_user(active=False)
    assert not user.can_login()
```

### Parameterized Fixtures

For testing across multiple configurations:

```python
@pytest.fixture(params=["sqlite", "postgres"])
def db_backend(request: pytest.FixtureRequest) -> str:
    """Run the test once per database backend."""
    return request.param
```

### Async Fixtures

With `asyncio_mode = "auto"` in pyproject.toml, async fixtures work natively:

```python
@pytest.fixture
async def api_client() -> AsyncGenerator:
    from httpx import AsyncClient
    async with AsyncClient(base_url="http://test") as client:
        yield client
```

## 4. Hypothesis Property-Based Testing

Hypothesis generates random inputs to find edge cases you wouldn't think to test manually.

### Setup

```bash
uv add --dev hypothesis
```

### Basic Usage

```python
from hypothesis import given, settings
from hypothesis import strategies as st


@given(st.text())
def test_roundtrip_encode_decode(s: str) -> None:
    """Any string should survive encode/decode roundtrip."""
    assert s.encode("utf-8").decode("utf-8") == s


@given(st.lists(st.integers()))
def test_sort_is_idempotent(xs: list[int]) -> None:
    """Sorting twice gives the same result as sorting once."""
    assert sorted(sorted(xs)) == sorted(xs)


@given(st.integers(min_value=1, max_value=1000))
def test_positive_price_calculation(quantity: int) -> None:
    """Price should always be positive for positive quantities."""
    price = calculate_price(quantity)
    assert price > 0
```

### Custom Strategies for Domain Types

```python
from hypothesis import strategies as st

# Strategy for valid email addresses
emails = st.from_regex(r"[a-z]{3,10}@[a-z]{3,8}\.(com|org|net)", fullmatch=True)

# Strategy for domain objects
users = st.builds(
    User,
    name=st.text(min_size=1, max_size=100),
    email=emails,
    age=st.integers(min_value=0, max_value=150),
)

# Composite strategy for complex objects
@st.composite
def orders(draw: st.DrawFn) -> Order:
    user = draw(users)
    items = draw(st.lists(st.builds(OrderItem), min_size=1, max_size=10))
    return Order(user=user, items=items)
```

### Settings Profiles

```python
from hypothesis import settings, Phase, HealthCheck

# CI profile: more examples, longer deadline
settings.register_profile(
    "ci",
    max_examples=1000,
    deadline=None,
    suppress_health_check=[HealthCheck.too_slow],
)

# Dev profile: fast feedback
settings.register_profile(
    "dev",
    max_examples=50,
    deadline=200,
)

# Load from environment
settings.load_profile(os.getenv("HYPOTHESIS_PROFILE", "dev"))
```

### Stateful Testing

Test sequences of API calls, not just individual operations:

```python
from hypothesis.stateful import RuleBasedStateMachine, rule, initialize

class UserServiceStateMachine(RuleBasedStateMachine):
    """Test that the user service maintains invariants across operations."""

    @initialize()
    def setup(self) -> None:
        self.service = UserService()
        self.known_users: set[str] = set()

    @rule(name=st.text(min_size=1, max_size=50))
    def create_user(self, name: str) -> None:
        user = self.service.create(name)
        self.known_users.add(user.id)
        assert self.service.count() == len(self.known_users)

    @rule()
    def list_users(self) -> None:
        users = self.service.list_all()
        assert len(users) == len(self.known_users)

TestUserService = UserServiceStateMachine.TestCase
```

## 5. Coverage Enforcement and Anti-Gaming

### Configuration (pyproject.toml)

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
  "\\.\\.\\.",
]
```

### Anti-Gaming Rules

1. **No source paths in `omit`** — the pre-commit hook blocks this.
2. **`pragma: no cover` requires justification** — bare pragmas should be flagged in review.
3. **Branch coverage enabled** — `branch = true` catches untested conditional paths.
4. **Ratcheting** — coverage threshold only goes up, never down. When you reach 92%, update
   `fail_under = 92`.

### Coverage Commands

```bash
# Run with coverage
uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=90

# Generate HTML report
uv run pytest --cov=src --cov-report=html

# Check coverage without running tests (if .coverage exists)
uv run coverage report --fail-under=90
```

## 6. Assertion Density Enforcement

Tests with too few assertions may execute code without verifying behavior. This conftest hook warns
on low assertion density:

```python
# tests/conftest.py (add to root conftest)
import ast
from pathlib import Path

import pytest


def pytest_collection_modifyitems(
    session: pytest.Session, config: pytest.Config, items: list[pytest.Item]
) -> None:
    """Warn about test files with low assertion density."""
    seen_files: set[Path] = set()
    for item in items:
        fspath = Path(item.fspath) if hasattr(item, "fspath") else None
        if fspath and fspath not in seen_files and fspath.suffix == ".py":
            seen_files.add(fspath)
            source = fspath.read_text()
            tree = ast.parse(source)
            asserts = sum(1 for node in ast.walk(tree) if isinstance(node, ast.Assert))
            functions = sum(
                1 for node in ast.walk(tree)
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
                and node.name.startswith("test_")
            )
            if functions > 0 and asserts / functions < 1.5:
                print(
                    f"  ⚠ Low assertion density in {fspath.name}: "
                    f"{asserts} asserts / {functions} tests = "
                    f"{asserts / functions:.1f} (target: ≥1.5)"
                )
```

## 7. Integration Test Patterns

### testcontainers for Disposable Services

```bash
uv add --dev testcontainers
```

```python
import pytest
from testcontainers.postgres import PostgresContainer


@pytest.fixture(scope="session")
def postgres():
    """Spin up a Postgres container for the test session."""
    with PostgresContainer("postgres:16") as pg:
        yield pg


@pytest.fixture(scope="session")
def database_url(postgres) -> str:
    return postgres.get_connection_url()
```

### Async HTTP Testing

```python
from httpx import ASGITransport, AsyncClient


@pytest.fixture
async def client(app) -> AsyncGenerator:
    """Test client that hits the ASGI app directly (no network)."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


async def test_health_check(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
```

## 8. What Runs Where

| Check                | Pre-commit       | Pre-push        | CI             |
| -------------------- | ---------------- | --------------- | -------------- |
| Ruff format          | ✓ (staged files) | ✓ (full repo)   | ✓              |
| Ruff check           | ✓ (staged files) | ✓ (full repo)   | ✓              |
| MyPy                 | ✓ (full)         | ✓ (full)        | ✓              |
| pytest (unit)        | —                | ✓               | ✓ (sharded)    |
| pytest (integration) | —                | ✓ (if DB)       | ✓ (if DB)      |
| Coverage threshold   | —                | ✓               | ✓              |
| Hypothesis           | —                | ✓ (dev profile) | ✓ (ci profile) |
| Secret detection     | ✓                | —               | —              |
| Build verification   | —                | ✓               | ✓              |
| pip-audit            | —                | —               | ✓              |
