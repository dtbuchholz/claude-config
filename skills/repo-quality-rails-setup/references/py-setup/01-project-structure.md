# Step 01 — Project Structure

This step establishes the Python project layout, pyproject.toml configuration, and workspace
structure for monorepos.

## Single-Package Layout

```
my-project/
  src/
    my_project/
      __init__.py
      __main__.py          # Entry point (python -m my_project)
      py.typed              # PEP 561 marker for type stubs
  tests/
    __init__.py
    conftest.py            # Root fixtures
    unit/
      __init__.py
    integration/
      __init__.py
  scripts/
    pre-push.sh            # Pre-push gate script (Step 06)
  pyproject.toml           # Single source of truth for all config
  Makefile                 # Developer-friendly task aliases
  .pre-commit-config.yaml  # Git hooks (Step 05)
  .gitignore
  .python-version          # Pin Python version (e.g., 3.12)
  uv.lock                  # Dependency lock file (committed)
```

## Monorepo Layout (uv workspaces)

```
my-project/
  packages/
    core/
      src/core/
        __init__.py
        py.typed
      tests/
      pyproject.toml
    api/
      src/api/
        __init__.py
      tests/
      pyproject.toml
    worker/
      src/worker/
        __init__.py
      tests/
      pyproject.toml
  scripts/
    pre-push.sh
  pyproject.toml           # Root: workspace definition + shared dev deps
  Makefile
  .pre-commit-config.yaml
  .gitignore
  .python-version
  uv.lock
```

## pyproject.toml (Single Package)

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[project.optional-dependencies]
dev = [
  "ruff>=0.8",
  "mypy>=1.13",
  "pre-commit>=4.0",
]
test = [
  "pytest>=8.0",
  "pytest-asyncio>=0.24",
  "pytest-cov>=6.0",
  "hypothesis>=6.100",
]

# Tool configs added in subsequent steps (02-04)
```

## pyproject.toml (Monorepo Root)

```toml
[project]
name = "my-project-workspace"
version = "0.0.0"
requires-python = ">=3.12"

[tool.uv.workspace]
members = ["packages/*"]

[tool.uv]
dev-dependencies = [
  "ruff>=0.8",
  "mypy>=1.13",
  "pre-commit>=4.0",
  "pytest>=8.0",
  "pytest-asyncio>=0.24",
  "pytest-cov>=6.0",
  "hypothesis>=6.100",
  "import-linter>=2.0",
]
```

## pyproject.toml (Monorepo Package)

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "core"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[tool.hatch.build.targets.wheel]
packages = ["src/core"]
```

Packages reference each other via path dependencies:

```toml
[project]
name = "api"
dependencies = [
  "core",
]

[tool.uv.sources]
core = { workspace = true }
```

## Makefile

```makefile
.PHONY: install fmt lint type-check test coverage qa clean

install:
	uv sync --all-extras

fmt:
	uv run ruff format .
	uv run ruff check --fix .

lint:
	uv run ruff check .

type-check:
	uv run mypy src/

test:
	uv run pytest tests/ -q

coverage:
	uv run pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=90

qa: fmt lint type-check test
	@echo "All quality checks passed."

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .mypy_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .ruff_cache -exec rm -rf {} + 2>/dev/null || true
	rm -rf dist/ build/ *.egg-info
```

## .gitignore

```gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/
dist/
build/
*.egg

# Virtual environments
.venv/

# Type checking
.mypy_cache/

# Testing
.pytest_cache/
.coverage
htmlcov/

# Linting
.ruff_cache/

# IDE
.idea/
.vscode/
*.swp
*.swo

# Environment
.env
.env.local
.env.*.local

# OS
.DS_Store
Thumbs.db
```

## .python-version

```
3.12
```

This file is read by uv, pyenv, and other tools to ensure consistent Python versions across the
team.

## uv Installation

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment and install dependencies
uv sync --all-extras

# Verify
uv run python --version
uv run ruff --version
uv run mypy --version
uv run pytest --version
```

## Stop & Confirm

Confirm the project layout and pyproject.toml structure before moving to Step 02 (Ruff config).
