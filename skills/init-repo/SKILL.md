---
name: init-repo
description: Initialize a new repository with standard tooling (JS/TS or Python).
---

# Initialize Repository

Initialize a new repository with a comprehensive, production-grade tooling setup.

## When This Skill Applies

- User asks to initialize or create a new project
- User wants to set up a new repository with proper tooling
- User says "init repo" or "create project"

## Reference Configurations

### For JS/TS Projects (Monorepo with Turbo)

**Core Stack:**

- Package manager: pnpm v9.15.0+
- Monorepo: Turbo
- Language: TypeScript (strict mode)
- Linting: ESLint with comprehensive plugin suite
- Formatting: Prettier with Tailwind plugin
- Testing: Vitest
- Git hooks: Husky + lint-staged

**Directory Structure:**

```
project/
├── apps/
│   └── web/                  # Next.js app (if applicable)
├── packages/
│   ├── eslint-config/        # Shared ESLint configs
│   ├── tsconfig/             # Shared TypeScript configs
│   └── ui/                   # Shared components (if applicable)
├── .husky/
│   ├── pre-commit
│   └── pre-push
├── package.json              # Root package.json
├── pnpm-workspace.yaml
├── turbo.json
├── .prettierrc
├── .prettierignore
├── eslint.config.mjs
├── vitest.config.ts
├── .gitignore
└── tsconfig.json
```

### For Python Projects

**Core Stack:**

- Package manager: uv
- Build system: Hatchling
- Linting/Formatting: Ruff (unified)
- Type checking: MyPy
- Testing: Pytest with asyncio support
- Git hooks: pre-commit

**Directory Structure:**

```
project/
├── src/
│   └── project_name/
│       ├── __init__.py
│       └── __main__.py
├── tests/
│   ├── __init__.py
│   └── conftest.py
├── pyproject.toml           # All config in one file
├── .pre-commit-config.yaml
├── Makefile
├── .gitignore
└── .vscode/settings.json
```

## Requirements Gathering

**Ask these questions one at a time. Wait for the user's response before proceeding.**

1. **Project type** (ask first): "What type of project are you initializing?"
   - JavaScript/TypeScript (monorepo with Turbo, pnpm, ESLint, Prettier)
   - Python (uv, Ruff, MyPy, Pytest)

2. **Project name** (ask second):
   - If argument is provided, use that as the project name and skip this question
   - Otherwise ask: "What is the project name? (This will be used for the directory and package
     names)"

3. **For JS/TS only - Scope** (ask third): "What npm scope/namespace should packages use? (e.g.,
   @mycompany, @projectname, or leave blank for no scope)"

4. **For JS/TS only - Initial apps** (ask fourth): "What apps do you want to create initially?"
   - Next.js web app
   - Node.js service
   - Both
   - None (packages only)

5. **For Python only - Project type** (ask third): "What type of Python project is this?"
   - CLI application
   - Library/package
   - Service/API
   - General purpose

## Implementation: JavaScript/TypeScript

After gathering requirements, create the following:

### 1. Root Configuration Files

**package.json:**

```json
{
  "name": "PROJECT_NAME",
  "private": true,
  "packageManager": "pnpm@9.15.0",
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "lint": "turbo run lint",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,mjs,json,md,yml,yaml}\" && turbo run format",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,mjs,json,md,yml,yaml}\"",
    "type-check": "turbo run type-check",
    "test": "turbo run test",
    "test:coverage": "vitest run --coverage",
    "clean": "turbo run clean && rm -rf node_modules",
    "prepare": "husky"
  },
  "devDependencies": {
    "husky": "^9.1.0",
    "lint-staged": "^16.0.0",
    "prettier": "^3.5.0",
    "turbo": "^2.3.0",
    "typescript": "^5.0.0",
    "vitest": "^2.1.0"
  }
}
```

**pnpm-workspace.yaml:**

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

**turbo.json:**

```json
{
  "ui": "tui",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "format": {
      "cache": false
    },
    "format:check": {
      "cache": false
    },
    "type-check": {
      "dependsOn": ["^build"],
      "outputs": ["*.tsbuildinfo"]
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"]
    },
    "dev": {
      "persistent": true,
      "cache": false
    },
    "clean": {
      "cache": false
    }
  }
}
```

**.prettierrc:**

```json
{
  "semi": true,
  "singleQuote": false,
  "trailingComma": "es5",
  "tabWidth": 2,
  "printWidth": 100
}
```

**.prettierignore:**

```
**/node_modules/
**/dist/
**/.next/
**/.turbo/
pnpm-lock.yaml
**/coverage/
```

**eslint.config.mjs:**

```javascript
import baseConfig from "@SCOPE/eslint-config/base";

export default [
  ...baseConfig,
  {
    ignores: ["**/node_modules/**", "**/dist/**", "**/.next/**", "**/coverage/**"],
  },
];
```

**lint-staged.config.mjs:**

```javascript
export default {
  "**/*.{ts,tsx,js,jsx,mjs,cjs}": ["prettier --write"],
  "**/*.{json,md,yml,yaml}": ["prettier --write"],
};
```

### 2. Shared TypeScript Config Package

Create `packages/tsconfig/` with:

**base.json:**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "incremental": true,
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "isolatedModules": true,
    "skipLibCheck": true
  }
}
```

### 3. Shared ESLint Config Package

Create `packages/eslint-config/` with base.js containing:

- @eslint/js
- typescript-eslint
- eslint-plugin-import-x
- eslint-config-prettier

### 4. Husky Hooks

**.husky/pre-commit:**

```bash
pnpm lint-staged
```

**.husky/pre-push:**

```bash
pnpm format:check && pnpm lint && pnpm type-check && pnpm test
```

### 5. Vitest Config

**vitest.config.ts:**

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
  },
});
```

## Implementation: Python

After gathering requirements, create the following:

### 1. pyproject.toml

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "PROJECT_NAME"
version = "0.1.0"
description = "PROJECT_DESCRIPTION"
readme = "README.md"
requires-python = ">=3.10"
dependencies = []

[project.optional-dependencies]
dev = [
    "mypy>=1.8.0",
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.0.0",
]

[dependency-groups]
dev = [
    "pre-commit>=4.0.0",
    "ruff>=0.8.0",
]

[project.scripts]
# PROJECT_NAME = "src.PROJECT_NAME.__main__:main"

[tool.ruff]
line-length = 100
target-version = "py310"

[tool.ruff.format]
quote-style = "double"

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]

[tool.mypy]
python_version = "3.10"
warn_return_any = true
warn_unused_configs = true
ignore_missing_imports = true

[tool.pytest.ini_options]
pythonpath = ["."]
testpaths = ["tests"]
```

### 2. .pre-commit-config.yaml

```yaml
repos:
  - repo: local
    hooks:
      - id: ruff-fix
        name: ruff fix
        entry: uv run ruff check --fix
        language: system
        types: [python]
        stages: [pre-commit]

      - id: ruff-format
        name: ruff format
        entry: uv run ruff format
        language: system
        types: [python]
        stages: [pre-commit]

      - id: ruff-check
        name: ruff check
        entry: uv run ruff format --check .
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: ruff-lint
        name: ruff lint
        entry: uv run ruff check .
        language: system
        pass_filenames: false
        stages: [pre-push]

      - id: pytest
        name: pytest
        entry: uv run pytest tests/ -q
        language: system
        pass_filenames: false
        stages: [pre-push]
```

### 3. Makefile

```makefile
.PHONY: install fmt fmt-check lint lint-fix check test coverage run

install:
	uv sync

fmt:
	uv run ruff format .

fmt-check:
	uv run ruff format --check .

lint:
	uv run ruff check .

lint-fix:
	uv run ruff check --fix .

check: fmt-check lint

test:
	uv run pytest tests/ -v

coverage:
	uv run pytest tests/ --cov=src --cov-report=html

type-check:
	uv run mypy src/
```

### 4. .vscode/settings.json

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "charliermarsh.ruff",
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit",
      "source.organizeImports": "explicit"
    }
  },
  "ruff.path": ["uv", "run", "ruff"]
}
```

### 5. Source Structure

Create `src/project_name/__init__.py` and `src/project_name/__main__.py` with basic entry point.

### 6. Test Structure

Create `tests/__init__.py` and `tests/conftest.py` with pytest fixtures.

## Finalization Steps

After creating all files:

1. **Initialize git**: `git init`
2. **Install dependencies**:
   - JS/TS: `pnpm install`
   - Python: `uv sync`
3. **Set up hooks**:
   - JS/TS: Husky installs automatically via prepare script
   - Python: `uv run pre-commit install && uv run pre-commit install --hook-type pre-push`
4. **Verify setup**:
   - JS/TS: `pnpm type-check && pnpm lint`
   - Python: `make check && make type-check`

## Output

Provide a summary of:

1. What was created
2. How to get started (install, run, test)
3. Key commands available
4. Next steps for customization

Begin by asking the FIRST requirement question only.
