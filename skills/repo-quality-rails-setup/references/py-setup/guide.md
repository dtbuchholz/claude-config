# Python Setup Guide (Step-by-step)

This is the staged setup runbook. **Load only one step file at a time** to avoid context bloat.
After each step, **stop and confirm** before proceeding.

## Entry Conditions

- Only use this guide for **greenfield setup** or **full quality-rails overhaul**.
- Run the **sentinel check** first (see SKILL.md). If a marker exists, do not re-run setup.

## Runbook Rules

- Ask the intake questions below and **do not start Step 01 until answered**.
- After each step: summarize changes, ask for confirmation, then proceed only on explicit approval.
- If the user wants to change scope mid-run, pause and re-confirm the intake.

## Intake Questions (stop & collect answers)

1. Single package or monorepo? (Monorepo uses uv workspaces.)
2. Application type? (CLI, library, API service, data pipeline)
3. Database + migrations? (yes/no; Alembic + SQLAlchemy, or none)
4. Publishable to PyPI? (python-semantic-release required)
5. Python version target? (3.11+, 3.12+, 3.13+)
6. CI provider? (GitHub Actions, etc.)
7. Any existing tooling we must keep? (formatter, linter, test runner)

**Stop here until the user answers.**

## Steps (load one file at a time)

1. `references/py-setup/01-project-structure.md`
2. `references/py-setup/02-ruff-config.md`
3. `references/py-setup/03-mypy-strict.md`
4. `references/py-setup/04-pytest-config.md`
5. `references/py-setup/05-pre-commit-hooks.md`
6. `references/py-setup/06-pre-push-script.md`
7. `references/py-setup/07-ci-pipeline.md`
8. `references/py-setup/08-dependencies-and-checklist.md`

## Optional Modules (load only if the user opts in)

- `references/py-design-metrics.md`
- `references/py-mutation-testing.md`
- `references/py-architecture-enforcement.md`
- `references/design-metrics.md` (cross-language, includes Python section)
- `references/refactoring-playbook.md` (cross-language)

## Deep Dives (only if needed)

- `references/py-test-infrastructure.md`
- `references/database-safety.md` (cross-language, includes Alembic)
- `references/code-duplication.md` (cross-language)
