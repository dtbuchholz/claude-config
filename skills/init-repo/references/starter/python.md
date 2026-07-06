# Starter Python Setup

Use this for the lightest Python scaffold. Starter mode is commands-only: no git hooks, no CI, no
packaging complexity beyond a working `uv` project.

## Create

- `pyproject.toml`
- `.gitignore`
- `src/<project_name>/__init__.py`
- `tests/test_smoke.py`

## `pyproject.toml` Baseline

Use `uv` and Ruff:

```toml
[project]
name = "PROJECT_NAME"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[dependency-groups]
dev = [
  "pytest>=8",
  "ruff>=0.8",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
```

## Commands

Add a small `Makefile` or document these commands in `README.md`:

```bash
uv sync
uv run ruff format .
uv run ruff check .
uv run pytest
```

## Verify

Run:

```bash
uv sync
uv run ruff format --check .
uv run ruff check .
uv run pytest
```
