# Step 08 — Dependencies + Setup Checklist

This step captures the complete dependency list and the verification checklist.

## Complete Dependency List

### Core Dev Dependencies

| Package      | Version  | Purpose                                                              |
| ------------ | -------- | -------------------------------------------------------------------- |
| `ruff`       | `>=0.8`  | Formatting + linting (replaces black, isort, flake8, pylint, bandit) |
| `mypy`       | `>=1.13` | Static type checking                                                 |
| `pre-commit` | `>=4.0`  | Git hook framework                                                   |

### Test Dependencies

| Package          | Version   | Purpose                                  |
| ---------------- | --------- | ---------------------------------------- |
| `pytest`         | `>=8.0`   | Test runner                              |
| `pytest-asyncio` | `>=0.24`  | Async test support                       |
| `pytest-cov`     | `>=6.0`   | Coverage measurement (wraps coverage.py) |
| `pytest-xdist`   | `>=3.5`   | Parallel test execution (`-n auto`)      |
| `pytest-split`   | `>=0.9`   | Test sharding for CI matrix              |
| `hypothesis`     | `>=6.100` | Property-based testing                   |

### Optional Dependencies

| Package         | Version  | Purpose                                   | When needed                        |
| --------------- | -------- | ----------------------------------------- | ---------------------------------- |
| `import-linter` | `>=2.0`  | Architecture boundary enforcement         | Monorepos or layered architectures |
| `pip-audit`     | `>=2.7`  | Dependency vulnerability scanning         | CI security gate                   |
| `radon`         | `>=6.0`  | Cyclomatic + cognitive complexity metrics | Design metrics gates               |
| `xenon`         | `>=0.9`  | Complexity threshold enforcement          | CI complexity gate                 |
| `wily`          | `>=1.25` | Complexity tracking over time             | Ratcheting strategy                |
| `mutmut`        | `>=3.0`  | Mutation testing                          | Advanced test quality              |

### Database Dependencies (if applicable)

| Package      | Version  | Purpose                |
| ------------ | -------- | ---------------------- |
| `alembic`    | `>=1.13` | Database migrations    |
| `sqlalchemy` | `>=2.0`  | ORM / database toolkit |
| `squawk-cli` | `>=1.0`  | SQL migration linting  |

## Install Commands

```bash
# Core + test dependencies
uv add --dev ruff mypy pre-commit pytest pytest-asyncio pytest-cov pytest-xdist pytest-split hypothesis

# Optional: architecture enforcement
uv add --dev import-linter

# Optional: complexity metrics
uv add --dev radon xenon wily

# Optional: database
uv add alembic sqlalchemy
uv add --dev squawk-cli

# Install pre-commit hooks
uv run pre-commit install
uv run pre-commit install --hook-type pre-push

# Make pre-push script executable
chmod +x scripts/pre-push.sh
```

## Final pyproject.toml (Complete)

After all steps, your pyproject.toml should contain these tool sections:

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
  "pytest-xdist>=3.5",
  "pytest-split>=0.9",
  "hypothesis>=6.100",
]

[tool.ruff]
# ... (from Step 02)

[tool.mypy]
# ... (from Step 03)

[tool.pytest.ini_options]
# ... (from Step 04)

[tool.coverage.run]
# ... (from Step 04)

[tool.coverage.report]
# ... (from Step 04)
```

## Final Makefile (Complete)

```makefile
.PHONY: install fmt lint type-check test coverage qa hooks clean

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

test-unit:
	uv run pytest tests/unit/ -q

test-integration:
	uv run pytest tests/integration/ -q

coverage:
	uv run pytest tests/ --cov=src --cov-report=term-missing --cov-fail-under=90

qa: lint type-check test
	@echo "All quality checks passed."

hooks:
	uv run pre-commit install
	uv run pre-commit install --hook-type pre-push

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .mypy_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .ruff_cache -exec rm -rf {} + 2>/dev/null || true
	rm -rf dist/ build/ *.egg-info htmlcov/ .coverage
```

## Setup Verification Checklist

Run each check manually to verify the full setup:

```bash
# 1. Dependencies install cleanly
make install

# 2. Formatting works
make fmt
uv run ruff format --check .    # Should pass (just formatted)

# 3. Linting works
make lint                        # Should pass

# 4. Type checking works
make type-check                  # Should pass

# 5. Tests pass
make test                        # Should pass

# 6. Coverage meets threshold
make coverage                    # Should show >=90%

# 7. Build succeeds
uv build                         # Should produce dist/

# 8. Pre-commit hooks fire on commit
git add -A
git commit -m "test: verify hooks"   # Should run all pre-commit gates

# 9. Pre-push gates fire on push
git push origin test-branch      # Should run scripts/pre-push.sh

# 10. CI pipeline passes
# Push to a PR and verify all GitHub Actions jobs are green
```

## File Summary

After completing all 8 steps, your project should have:

| File                            | Created in             |
| ------------------------------- | ---------------------- |
| `pyproject.toml`                | Steps 01-04            |
| `Makefile`                      | Step 01, updated in 08 |
| `.python-version`               | Step 01                |
| `.gitignore`                    | Step 01                |
| `src/<pkg>/__init__.py`         | Step 01                |
| `src/<pkg>/py.typed`            | Step 01                |
| `tests/conftest.py`             | Step 04                |
| `tests/unit/conftest.py`        | Step 04                |
| `tests/integration/conftest.py` | Step 04                |
| `.pre-commit-config.yaml`       | Step 05                |
| `scripts/pre-push.sh`           | Step 06                |
| `.github/workflows/ci.yml`      | Step 07                |
| `uv.lock`                       | Generated by uv sync   |

## Stop & Confirm

Confirm the full dependency list and verification checklist. If accepted, the Python quality rails
setup is complete.
