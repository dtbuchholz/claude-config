# TypeScript Monorepo Setup Guide (Step-by-step)

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

1. Monorepo? (This guide assumes pnpm workspaces + Turbo.)
2. Apps to include? (Next.js web, Node API, etc.)
3. Shared packages to include? (core-domain, database, ui, testing, etc.)
4. Database package + migrations? (yes/no; which database)
5. Publishable packages? (changesets required)
6. npm scope (e.g., `@myorg`)
7. CI provider (GitHub Actions, etc.)
8. Any existing tooling we must keep? (formatter, linter, test runner)

**Stop here until the user answers.**

## Steps (load one file at a time)

1. `references/ts-setup/01-workspace-structure.md`
2. `references/ts-setup/02-package-patterns.md`
3. `references/ts-setup/03-turbo-pipeline.md`
4. `references/ts-setup/04-tsconfig-and-exports.md`
5. `references/ts-setup/05-root-package-json.md`
6. `references/ts-setup/06-tooling-configs.md`
7. `references/ts-setup/07-git-hooks.md`
8. `references/ts-setup/08-changesets.md`
9. `references/ts-setup/09-dependencies-and-checklist.md`

## Optional Modules (load only if the user opts in)

- `references/design-metrics.md`
- `references/mutation-testing.md`
- `references/architecture-analysis.md`
- `references/refactoring-playbook.md`
- `references/design-patterns-as-rules.md`

## Deep Dives (only if needed)

- `references/eslint-architecture.md`
- `references/test-infrastructure.md`
- `references/database-safety.md`
- `references/code-duplication.md`
