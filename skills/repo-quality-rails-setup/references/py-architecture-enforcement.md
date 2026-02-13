# Python Architecture Enforcement

Deep dive into import-linter boundary contracts, dependency visualization with pydeps, and circular
import detection. This is the Python equivalent of the architecture boundary enforcement in
`references/eslint-architecture.md` and `references/architecture-analysis.md`.

## 1. Why Architecture Enforcement

Without explicit rules, codebases drift toward a dependency ball of mud. A "domain" module starts
importing from the API layer. A utility package reaches into the ORM. These violations are invisible
in code review because each individual import looks reasonable — the architectural damage only shows
in aggregate.

import-linter makes dependency direction rules executable. If the domain layer imports from the API
layer, the build fails. No exceptions, no human judgment required.

## 2. import-linter Setup

### Install

```bash
uv add --dev import-linter
```

### Configuration

import-linter reads its configuration from either `.importlinter` (INI format) or `pyproject.toml`
(TOML format). The pyproject.toml approach keeps everything in one file.

```toml
# pyproject.toml

[tool.importlinter]
root_packages = ["my_project"]
```

For monorepos with multiple packages:

```toml
[tool.importlinter]
root_packages = [
    "my_project_core",
    "my_project_api",
    "my_project_worker",
]
```

### Run

```bash
# Check all contracts
uv run lint-imports

# Verbose output (shows each import checked)
uv run lint-imports --verbose

# Show only failures
uv run lint-imports 2>&1 | grep -A 5 "BROKEN"
```

## 3. Contract Types

### Layer Contracts

Layer contracts enforce a dependency hierarchy. Higher layers can import lower layers, but not the
reverse. This is the most common contract type.

```toml
[tool.importlinter:contract:layers]
name = "Application layer contract"
type = layers
layers = [
    "my_project.api",
    "my_project.service",
    "my_project.domain",
    "my_project.infrastructure",
]
```

This enforces:

- `api` can import `service`, `domain`, `infrastructure`
- `service` can import `domain`, `infrastructure`
- `domain` can import `infrastructure`
- `infrastructure` cannot import any of the above
- `domain` cannot import `service` or `api`
- `service` cannot import `api`

**Common layer structures:**

| Architecture       | Layers (top → bottom)                   |
| ------------------ | --------------------------------------- |
| Clean architecture | api → service → domain → infrastructure |
| Hexagonal          | adapters → application → domain → ports |
| Simple API         | routes → handlers → services → models   |
| CLI tool           | cli → commands → core → io              |

### Independence Contracts

Independence contracts ensure modules don't import each other at all. Use these for domain modules
that should be decoupled.

```toml
[tool.importlinter:contract:domain-independence]
name = "Domain modules are independent"
type = independence
modules = [
    "my_project.domain.users",
    "my_project.domain.orders",
    "my_project.domain.payments",
    "my_project.domain.inventory",
]
```

If `users` needs data from `orders`, the fix is a shared interface in a common module — not a direct
import.

### Forbidden Contracts

Forbidden contracts block specific imports. Use these to keep infrastructure details out of the
domain layer.

```toml
[tool.importlinter:contract:no-orm-in-domain]
name = "No ORM in domain layer"
type = forbidden
source_modules = [
    "my_project.domain",
]
forbidden_modules = [
    "sqlalchemy",
    "alembic",
    "asyncpg",
    "psycopg2",
]

[tool.importlinter:contract:no-web-in-domain]
name = "No web framework in domain"
type = forbidden
source_modules = [
    "my_project.domain",
]
forbidden_modules = [
    "fastapi",
    "starlette",
    "flask",
    "django",
]

[tool.importlinter:contract:no-domain-in-tests]
name = "Integration tests use service layer"
type = forbidden
source_modules = [
    "tests.integration",
]
forbidden_modules = [
    "my_project.domain",
]
```

### Combining Contracts

A real project typically uses all three types together:

```toml
[tool.importlinter]
root_packages = ["my_project"]

# 1. Overall layer direction
[tool.importlinter:contract:layers]
name = "Application layers"
type = layers
layers = [
    "my_project.api",
    "my_project.service",
    "my_project.domain",
    "my_project.infrastructure",
]

# 2. Domain modules don't know about each other
[tool.importlinter:contract:domain-independence]
name = "Domain independence"
type = independence
modules = [
    "my_project.domain.users",
    "my_project.domain.orders",
    "my_project.domain.payments",
]

# 3. Domain is pure — no framework imports
[tool.importlinter:contract:no-orm-in-domain]
name = "No ORM in domain"
type = forbidden
source_modules = ["my_project.domain"]
forbidden_modules = ["sqlalchemy", "alembic"]

[tool.importlinter:contract:no-web-in-domain]
name = "No web framework in domain"
type = forbidden
source_modules = ["my_project.domain"]
forbidden_modules = ["fastapi", "starlette", "flask"]
```

## 4. Handling Contract Violations

When import-linter finds a violation, the output looks like:

```
my_project.domain.users is not allowed to import my_project.service.email

  my_project.domain.users (line 5)
    -> my_project.service.email
```

### Fix Strategies

| Violation                                | Fix                                                                |
| ---------------------------------------- | ------------------------------------------------------------------ |
| Domain imports service                   | Define an interface (Protocol) in domain, implement in service     |
| Domain imports ORM                       | Use plain dataclasses in domain, map to/from ORM in infrastructure |
| Sibling domain modules import each other | Extract shared types to a common module or use events              |
| Tests import wrong layer                 | Restructure test to use the correct entry point                    |

### Interface Pattern (Dependency Inversion)

When the domain needs to send email but can't import the email service:

```python
# my_project/domain/ports.py (interface, lives in domain)
from typing import Protocol

class EmailSender(Protocol):
    async def send(self, to: str, subject: str, body: str) -> None: ...


# my_project/service/email.py (implementation, lives in service)
from my_project.domain.ports import EmailSender

class SmtpEmailSender:
    async def send(self, to: str, subject: str, body: str) -> None:
        # actual SMTP logic
        ...


# my_project/domain/users.py (uses interface, not implementation)
from my_project.domain.ports import EmailSender

class UserService:
    def __init__(self, email: EmailSender) -> None:
        self._email = email

    async def register(self, email: str) -> None:
        # ... create user ...
        await self._email.send(email, "Welcome", "...")
```

## 5. Dependency Visualization with pydeps

pydeps generates SVG dependency graphs from Python packages.

### Install

```bash
uv add --dev pydeps
```

pydeps requires Graphviz to be installed:

```bash
# macOS
brew install graphviz

# Ubuntu/Debian
sudo apt-get install graphviz

# Fedora
sudo dnf install graphviz
```

### Usage

```bash
# Full dependency graph
uv run pydeps src/my_project -o deps.svg --no-show

# Clustered by package (recommended)
uv run pydeps src/my_project --cluster --no-show -o deps-clustered.svg

# Limit depth to avoid noise
uv run pydeps src/my_project --cluster --max-bacon=2 --no-show -o deps-shallow.svg

# Internal dependencies only (exclude third-party)
uv run pydeps src/my_project --no-show --only my_project -o deps-internal.svg

# Show cycles (most valuable for architecture review)
uv run pydeps src/my_project --show-cycles --no-show -o deps-cycles.svg
```

### CI Integration

Generate and upload as a PR artifact:

```yaml
# In .github/workflows/ci.yml
- name: Generate dependency graph
  run: |
    sudo apt-get install -y graphviz
    uv run pydeps src/my_project --cluster --no-show -o deps.svg
- uses: actions/upload-artifact@v4
  with:
    name: dependency-graph
    path: deps.svg
```

### Reading Dependency Graphs

Look for these patterns in the generated SVG:

| Pattern                                        | What it means                        | Action                                               |
| ---------------------------------------------- | ------------------------------------ | ---------------------------------------------------- |
| Arrows pointing "up" (against layer direction) | Layer violation                      | Fix with dependency inversion                        |
| Bidirectional arrows between modules           | Circular dependency                  | Extract shared interface                             |
| Single module with many incoming arrows        | High fan-in (heavily depended upon)  | OK if it's a core module; investigate if it's a leaf |
| Single module with many outgoing arrows        | High fan-out (depends on everything) | Likely a God module; split responsibilities          |
| Clusters with no arrows between them           | Well-isolated modules                | Good architecture                                    |

## 6. Circular Import Detection

Circular imports cause `ImportError` at runtime or subtle bugs where modules see partially
initialized state. Detect them early.

### With pydeps

```bash
# List cycles
uv run pydeps src/my_project --show-cycles 2>&1 | grep "cycle"
```

### With Ruff

Ruff catches some circular import patterns:

```toml
# Already enabled in Step 02's rule set:
# PLC0415: import-outside-toplevel
# This rule flags imports inside functions, which is a common
# workaround for circular imports — and a sign the architecture needs fixing.
```

### With a Custom Script

For deeper analysis, use a script that builds the import graph and finds strongly connected
components:

```python
#!/usr/bin/env python3
"""Find circular imports in a Python package."""
from __future__ import annotations

import ast
import sys
from collections import defaultdict
from pathlib import Path


def find_imports(file_path: Path, root_package: str) -> list[str]:
    """Extract internal imports from a Python file."""
    try:
        tree = ast.parse(file_path.read_text())
    except SyntaxError:
        return []

    imports = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                if alias.name.startswith(root_package):
                    imports.append(alias.name)
        elif isinstance(node, ast.ImportFrom) and node.module:
            if node.module.startswith(root_package):
                imports.append(node.module)
    return imports


def find_cycles(graph: dict[str, list[str]]) -> list[list[str]]:
    """Find all cycles using DFS."""
    visited: set[str] = set()
    path: list[str] = []
    path_set: set[str] = set()
    cycles: list[list[str]] = []

    def dfs(node: str) -> None:
        if node in path_set:
            cycle_start = path.index(node)
            cycles.append(path[cycle_start:] + [node])
            return
        if node in visited:
            return
        visited.add(node)
        path.append(node)
        path_set.add(node)
        for neighbor in graph.get(node, []):
            dfs(neighbor)
        path.pop()
        path_set.discard(node)

    for node in graph:
        dfs(node)
    return cycles


def main(src_dir: str, root_package: str) -> None:
    graph: dict[str, list[str]] = defaultdict(list)
    src_path = Path(src_dir)

    for py_file in src_path.rglob("*.py"):
        module = str(py_file.relative_to(src_path.parent)).replace("/", ".").removesuffix(".py")
        if module.endswith(".__init__"):
            module = module.removesuffix(".__init__")
        imports = find_imports(py_file, root_package)
        graph[module].extend(imports)

    cycles = find_cycles(graph)
    if cycles:
        print(f"Found {len(cycles)} circular import(s):")
        for cycle in cycles:
            print(f"  {'  →  '.join(cycle)}")
        sys.exit(1)
    else:
        print("No circular imports found.")


if __name__ == "__main__":
    main("src", sys.argv[1] if len(sys.argv) > 1 else "my_project")
```

## 7. Pre-Push and CI Integration

### Pre-Push (already in Step 06)

The pre-push script includes import-linter as CHECK 9 (conditional on installation):

```bash
# CHECK 9: Architecture boundaries
if command -v lint-imports &>/dev/null || uv run lint-imports --help &>/dev/null 2>&1; then
  section "CHECK 9: Architecture boundaries"
  timer_start
  if uv run lint-imports 2>&1; then
    pass "CHECK 9: Architecture contracts OK" "$(timer_stop)"
  else
    timer_stop >/dev/null
    fail "CHECK 9: Architecture contract violated. Fix: uv run lint-imports --verbose"
  fi
fi
```

### CI

```yaml
# In .github/workflows/ci.yml, add to lint-and-typecheck job:
- name: Architecture boundaries
  run: uv run lint-imports
  if: hashFiles('.importlinter') != '' || contains(hashFiles('pyproject.toml'), 'importlinter')
```

## 8. Monorepo Boundaries

For monorepos with multiple packages managed by uv workspaces:

```toml
# Root pyproject.toml
[tool.importlinter]
root_packages = [
    "core",
    "api",
    "worker",
    "shared",
]

# Packages can only depend on shared, not on each other
[tool.importlinter:contract:package-independence]
name = "Packages are independent"
type = independence
modules = [
    "api",
    "worker",
]

# Both api and worker can use core + shared
[tool.importlinter:contract:package-layers]
name = "Package dependency direction"
type = layers
layers = [
    "api | worker",
    "core",
    "shared",
]
```

The pipe syntax (`api | worker`) means both modules occupy the same layer — they can import from
layers below but not from each other (the independence contract handles that separately).

## 9. Incremental Adoption

For existing codebases, adopt architecture enforcement gradually:

1. **Visualize first.** Run pydeps to understand the current dependency structure.
2. **Start with forbidden contracts.** Block the most egregious violations (ORM in domain, framework
   in domain). These are usually few and high-impact.
3. **Add layer contracts.** Start with a coarse 2-layer split (application vs infrastructure).
   Tighten as violations are fixed.
4. **Add independence contracts last.** These are the strictest and require the most refactoring.

Each step should be a separate PR with the contract and the fixes for any existing violations. Don't
add a contract that immediately fails — fix the violations first, then add the contract to prevent
regression.
