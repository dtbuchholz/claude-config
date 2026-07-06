# Standard Python Setup

Use this as the default Python setup. Standard mode is a practical production baseline: `uv`, Ruff,
type checking, Pytest, basic hooks, lightweight CI, and agent docs. It is not the full hardened
quality-rails setup.

## Defaults

- Package manager: `uv`.
- Project layout: `src/`.
- Formatter/linter: Ruff.
- Type checker: MyPy unless the repo already uses Pyright.
- Tests: Pytest.
- Hooks: pre-commit.
- CI: one lightweight job from `standard/basic-ci.md`.

## Layout

```text
src/<project_name>/
tests/
pyproject.toml
.pre-commit-config.yaml
Makefile
.gitignore
```

## `pyproject.toml` Baseline

```toml
[project]
name = "PROJECT_NAME"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[dependency-groups]
dev = [
  "mypy>=1.13",
  "pytest>=8",
  "pytest-cov>=5",
  "ruff>=0.8",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
```

## Commands

Use a `Makefile` with:

```makefile
.PHONY: install fmt fmt-check lint type-check test check

install:
	uv sync

fmt:
	uv run ruff format .
	uv run ruff check --fix .

fmt-check:
	uv run ruff format --check .

lint:
	uv run ruff check .

type-check:
	uv run mypy src

test:
	uv run pytest

check: fmt-check lint type-check test
```

## Hooks

Install pre-commit with staged formatting and a pre-push full check:

```yaml
repos:
  - repo: local
    hooks:
      - id: ruff-format
        name: ruff format
        entry: uv run ruff format
        language: system
        types: [python]
        stages: [pre-commit]
      - id: ruff-fix
        name: ruff fix
        entry: uv run ruff check --fix
        language: system
        types: [python]
        stages: [pre-commit]
      - id: check
        name: make check
        entry: make check
        language: system
        pass_filenames: false
        stages: [pre-push]
```

## Verify

Run:

```bash
uv sync
make check
```
