---
name: repo-quality-rails-setup
description: >
  Full repo-quality rails setup/overhaul for TypeScript monorepos, Python projects, and any software
  project. Use ONLY when the user explicitly asks for a complete quality rails setup, a greenfield
  repo baseline with all gates, or a full overhaul of quality infrastructure. Do NOT use this for
  incremental improvements (e.g., "add linting", "add hooks", "set up CI") unless the user confirms
  they want the entire rails system.
---

# Repo Quality Rails Setup

This skill sets up deterministic, ungameable quality infrastructure that prevents broken code from
advancing through any stage of the development pipeline. The philosophy: every quality check is a
hard gate that blocks forward progress when violated. Warnings are for things humans should notice;
errors are for things the system must enforce.

## How This Skill Works

### Entry Check: Existing Setup (Sentinel)

Before doing anything, check for an existing repo-quality-rails marker. This prevents re-running
setup and burning context on a repo that is already configured.

**Sentinel markers (check in order, stop at first match):**

- **TypeScript/Husky mode**: `.husky/pre-push` or `.husky/pre-commit` contains
  `# repo-quality-rails`
- **Python/pre-commit mode**: `.pre-commit-config.yaml` contains `# repo-quality-rails` AND
  `pyproject.toml` exists
- **Universal/pre-commit mode**: `.pre-commit-config.yaml` contains `# repo-quality-rails`

**If a marker exists:**

- Do **not** re-run setup.
- Switch to audit/maintenance mode (verify gates, update versions, add optional modules).

**If no marker exists:**

- Proceed with setup and add the marker line during hook/config creation.

There are three modes based on what the repo needs:

1. **TypeScript monorepo** (prescriptive): Exact tools, exact configs, exact rules. Use the
   step-by-step guide at `references/ts-setup/guide.md` and load one step file at a time. The
   consolidated single-file reference is `references/typescript-monorepo.md` (only if requested).

2. **Python** (prescriptive): Exact tools (uv, Ruff, MyPy, pytest, pre-commit), exact configs, exact
   rules. Use the step-by-step guide at `references/py-setup/guide.md` and load one step file at a
   time.

3. **Any language** (architectural): Same gate structure and hook infrastructure, but with guidance
   on choosing equivalent tools. Read `references/universal-gates.md`.

Both modes share the same three-layer enforcement model:

```
Layer 1: Pre-commit     -> Fast feedback on staged files (seconds)
Layer 2: Pre-push       -> Full verification before code leaves the machine (minutes)
Layer 3: CI             -> Authoritative verification on clean infrastructure (minutes)
```

The rule: **if CI would reject it, a local gate should have caught it first.** Developers should
never be surprised by CI failures. The pre-push hook mirrors CI exactly.

## Decision: TypeScript, Python, or Universal?

Before doing anything, determine the repo's primary language and structure:

- If the repo has `tsconfig.json` or `package.json` with TypeScript dependencies -> **TypeScript
  mode**
- If setting up a new project and the user wants TypeScript -> **TypeScript mode**
- If the repo has `pyproject.toml` with Python source code -> **Python mode**
- If setting up a new project and the user wants Python -> **Python mode**
- Otherwise -> **Universal mode**

For TypeScript mode, also determine:

- **Monorepo or single-package?** Look for `pnpm-workspace.yaml`, `lerna.json`, `turbo.json`, or
  multiple `package.json` files. If monorepo, the full setup applies. If single-package, skip the
  Turbo orchestration and workspace-specific boundary rules.

## The Three Layers

### Layer 1: Pre-Commit Gates

Pre-commit gates run on staged files only and must complete in seconds. Their job is immediate
feedback on the code being committed.

**Hard failures** (block the commit):

1. **Auto-formatting** - Fix formatting on staged files automatically (Prettier for TS)
2. **Linting** - Static analysis on affected packages
3. **Type checking** - Type safety on affected packages
4. **Secret detection** - Scan for hardcoded credentials
5. **Stub/mock file detection** - Prevent test doubles in production code
6. **Lock file sync** - Ensure dependency lock file matches manifests
7. **Migration safety** - Lint SQL migrations for dangerous patterns (if applicable)
8. **Changeset enforcement** - Require version bump coordination for publishable packages
9. **Coverage gaming prevention** - Block attempts to exclude source files from coverage metrics
10. **Documentation location enforcement** - Keep docs in designated locations

**Warnings** (inform but don't block): 11. **Console.log detection** - Flag forgotten debug
statements 12. **`any` type detection** - Flag type safety gaps (TS only) 13. **Test assertion
density** - Flag tests with too few assertions

Read `references/pre-commit-gates.md` for implementation details.

### Layer 2: Pre-Push Gates

Pre-push gates run the full verification suite. They mirror CI exactly so developers are never
surprised by remote failures.

**Sequence:**

1. Check remote main is not ahead (prevent merge conflicts)
2. Check for uncommitted changes (prevent dirty-state false positives)
3. Detect changed packages and scope checks (monorepo optimization)
4. Format check
5. Lint (scoped to changed packages)
6. SQL migration linting (if database package changed)
7. Type check (scoped to changed packages)
8. Unit tests with coverage (scoped)
9. Build all (verifies compilation)
10. Integration tests (if database available)
11. Schema drift detection (if database available)

Read `references/pre-push-gates.md` for implementation details.

### Layer 3: CI Pipeline

CI runs on clean infrastructure with no local state. It is the authoritative source of truth.

**Parallel jobs:**

- Lint + type-check
- Build (with artifact upload)
- Migration dry-run (against fresh database container)
- Unit tests (sharded across N workers)
- Test coverage (after unit tests pass)

**Sequential gates (main branch only):**

- Production migration (after all checks pass)
- Post-deploy smoke tests

Read `references/ci-pipeline.md` for implementation details.

## Design Quality

Beyond catching broken code, quality gates can enforce design health — preventing the gradual
erosion that turns clean codebases into unmaintainable ones. These gates measure structural
properties of the code and fail when thresholds are exceeded. **These are optional modules** — only
load them if the user explicitly opts in.

**Design metrics as gates.** Cognitive complexity, fan-in/fan-out coupling, file and function size
limits, export surface area, dependency depth, and circular dependency detection — all enforced as
hard failures in pre-commit or pre-push hooks. Read `references/design-metrics.md` for thresholds
and ESLint rule configurations.

**Mutation testing.** Coverage only measures whether lines executed during tests. Mutation testing
verifies tests actually _detect_ bugs by introducing small changes (mutants) and checking that at
least one test fails. This is the ultimate test quality gate — a codebase with 95% coverage but weak
assertions will have a low mutation score. Read `references/mutation-testing.md` for Stryker setup
and ratcheting strategy.

**Architecture analysis.** Dependency graph visualization with graph metrics (instability,
abstractness, distance from main sequence), API surface tracking across versions, and architecture
erosion detection via baseline comparison. Read `references/architecture-analysis.md` for tooling
and CI integration.

**Refactoring playbook.** When inheriting an existing codebase, you need an assessment strategy:
churn-times-complexity priority algorithm, ratcheting thresholds that only tighten, and strangler
fig patterns for incremental migration. Read `references/refactoring-playbook.md` for assessment
scripts and step-by-step workflows.

**Design principles as rules.** Error taxonomy enforcement (no stringly-typed errors), Result
pattern for expected failures, interface-first design, CQS, and immutability by default — encoded as
deterministic ESLint rules that fail the build. Read `references/design-patterns-as-rules.md` for
rule definitions and examples.

| Reference                                | When to read                                             |
| ---------------------------------------- | -------------------------------------------------------- |
| `references/design-metrics.md`           | Setting up complexity, coupling, and size limit gates    |
| `references/mutation-testing.md`         | Setting up Stryker or equivalent mutation testing        |
| `references/architecture-analysis.md`    | Dependency graph analysis, API surface tracking          |
| `references/refactoring-playbook.md`     | Assessing and incrementally improving existing codebases |
| `references/design-patterns-as-rules.md` | Encoding design principles as enforceable lint rules     |

## TypeScript Monorepo: Step-by-step (Preferred)

Start with `references/ts-setup/guide.md` and load **one step file at a time**.

| Step file                                              | What It Covers                                       |
| ------------------------------------------------------ | ---------------------------------------------------- |
| `references/ts-setup/01-workspace-structure.md`        | Workspace layout, pnpm-workspace.yaml, .npmrc        |
| `references/ts-setup/02-package-patterns.md`           | Library/app/config package patterns                  |
| `references/ts-setup/03-turbo-pipeline.md`             | turbo.json task graph                                |
| `references/ts-setup/04-tsconfig-and-exports.md`       | Shared tsconfig + exports pattern                    |
| `references/ts-setup/05-root-package-json.md`          | Root scripts + devDependencies                       |
| `references/ts-setup/06-tooling-configs.md`            | Prettier, lint-staged, Vitest, jscpd, squawk configs |
| `references/ts-setup/07-git-hooks.md`                  | Husky pre-commit + pre-push                          |
| `references/ts-setup/08-changesets.md`                 | Changeset setup + usage                              |
| `references/ts-setup/09-dependencies-and-checklist.md` | Dependency list + setup checklist                    |

### Consolidated Reference (only if requested)

| Reference                           | What It Covers                                  |
| ----------------------------------- | ----------------------------------------------- |
| `references/typescript-monorepo.md` | Single-file full reference for the entire setup |

### Deep Dives (optional)

| Reference                           | What It Covers                                       |
| ----------------------------------- | ---------------------------------------------------- |
| `references/eslint-architecture.md` | Shared ESLint config, boundary rules, custom rules   |
| `references/test-infrastructure.md` | Vitest setup, coverage thresholds, assertion density |
| `references/pre-commit-gates.md`    | Husky + lint-staged + custom gate scripts            |
| `references/pre-push-gates.md`      | Full verification pipeline                           |
| `references/ci-pipeline.md`         | GitHub Actions / CI service configuration            |
| `references/database-safety.md`     | Migration linting, schema drift, SQL safety          |
| `references/changeset-workflow.md`  | Version management for publishable packages          |
| `references/code-duplication.md`    | Copy-paste detection and enforcement                 |

## Python: Step-by-step

Start with `references/py-setup/guide.md` and load **one step file at a time**.

| Step file                                              | What It Covers                                          |
| ------------------------------------------------------ | ------------------------------------------------------- |
| `references/py-setup/01-project-structure.md`          | Project layout, pyproject.toml, uv workspaces, Makefile |
| `references/py-setup/02-ruff-config.md`                | Complete Ruff rule set (formatting + linting)           |
| `references/py-setup/03-mypy-strict.md`                | MyPy strict mode, per-module overrides, stubs           |
| `references/py-setup/04-pytest-config.md`              | pytest config, conftest architecture, fixtures          |
| `references/py-setup/05-pre-commit-hooks.md`           | pre-commit framework with all quality gates             |
| `references/py-setup/06-pre-push-script.md`            | Full pre-push verification script                       |
| `references/py-setup/07-ci-pipeline.md`                | GitHub Actions: lint, build, test matrix, coverage      |
| `references/py-setup/08-dependencies-and-checklist.md` | Dependency list + setup verification checklist          |

### Deep Dives (optional)

| Reference                                   | What It Covers                                     |
| ------------------------------------------- | -------------------------------------------------- |
| `references/py-test-infrastructure.md`      | pytest deep dive, Hypothesis, coverage anti-gaming |
| `references/py-design-metrics.md`           | radon, xenon, wily, pylint design rules as gates   |
| `references/py-architecture-enforcement.md` | import-linter boundary contracts                   |
| `references/py-mutation-testing.md`         | mutmut setup and CI integration                    |

## Universal Mode: Any Language

For repos that are not TypeScript or Python, read `references/universal-gates.md` which maps every
quality gate to its language-agnostic equivalent and provides guidance on tool selection.

## Agent Configuration

Quality gates enforce code standards mechanically. Agent configuration ensures AI agents working in
the repo follow team standards from their first interaction. This step sets up AGENTS.md (cross-tool
agent instructions), CLAUDE.md (Claude Code import), skill symlinks, knowledge capture, and
optionally Atlas MCP for team context.

**When to set up:** After the three-layer gate infrastructure is in place. Agent instructions
reference the hooks ("never `--no-verify`"), so hooks should exist first.

**How:** Configure agent standards as part of the quality rails setup.

Read `references/agent-configuration.md` for the complete setup procedure, file structure, and
instructions for existing repos.

| Reference                           | When to read                                           |
| ----------------------------------- | ------------------------------------------------------ |
| `references/agent-configuration.md` | Setting up AGENTS.md, CLAUDE.md, skills, and Atlas MCP |

## Anti-Gaming Philosophy

The most important design principle: **quality gates must be ungameable.** This means:

1. **No `--no-verify`** - Hooks cannot be bypassed. If they fail, fix the underlying issue.
2. **No coverage exclusions for source files** - The pre-commit hook detects attempts to add source
   files to coverage.exclude and blocks the commit.
3. **No disabling lint rules without explanation** - ESLint comments require descriptions.
4. **No stub files in production** - Detected and blocked at commit time.
5. **No shadow imports** - Package boundaries are enforced by lint rules.
6. **No manual database changes** - All schema changes go through the migration pipeline.
7. **Warnings exist for human judgment** - But errors are non-negotiable.

The goal is not to make developers' lives harder. It's to make broken code impossible to ship by
accident. Every gate that exists prevents a class of bugs that has actually happened.
