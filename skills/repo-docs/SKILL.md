---
name: repo-docs
description: >
  Bootstrap or audit agent-focused repository docs using a tooling-agnostic canonical structure.
  Init mode scaffolds the canonical docs tree and AGENTS.md, populates first-pass docs from existing
  repo sources, and aligns existing docs to the canonical shape. Audit mode performs advisory checks
  on structure, freshness, coverage, and drift. Requires no external packages or CLIs.
argument-hint: "[init|audit]"
---

## Quick Reference

This skill scaffolds and maintains the canonical docs shape by hand — no package manager, preset, or
CLI is required. It works in any git repo regardless of language or stack.

### Greenfield repo

1. Create the canonical `docs/` tree manually (see `references/canonical-shape.md`)
2. Create `AGENTS.md` plus `CLAUDE.md`/`CODEX.md` symlinks
3. Write first-pass docs by hand from repo facts
4. Validate structure, naming, links, and frontmatter manually

### Existing repo with docs

1. Create any missing canonical structure
2. Migrate existing docs into the canonical layout
3. Fill gaps by hand using the canonical shape
4. Regenerate/update agent docs after migration
5. Validate manually

Migration-heavy repos should expect cleanup after init. See `references/migration.md`.

## Purpose

`repo-docs` orchestrates a consistent, agent-focused documentation layout. This skill owns the
canonical shape directly:

- canonical doc taxonomy
- frontmatter schema
- freshness conventions
- reachability/orphan expectations
- path and filename conventions

Everything is enforced by hand — the skill validates structure, naming, links, and frontmatter
through inspection rather than a deterministic linter. Keep the canonical shape defined in
`references/canonical-shape.md` as the single source of truth; do not invent a competing schema,
template path, or root-doc convention.

## References

Load these only as needed:

- `references/canonical-shape.md`
- `references/migration.md`
- `references/audit.md`

## When This Skill Applies

- `/repo-docs` or `/repo-docs init` — bootstrap or reorganize docs
- `/repo-docs audit` — advisory docs audit
- User asks to set up repo docs, create `AGENTS.md`, bootstrap docs structure, or audit repo docs

## Guard

You must be inside a git repository:

```bash
git rev-parse --is-inside-work-tree
```

If not in a git repo, stop.

## Mode Detection

- Argument `audit` -> **Audit Mode**
- Otherwise -> **Init Mode**

## Init Mode

### Step 1: Scan

Gather:

- stack and package manager
- 2-level tree
- entrypoints and major modules/packages
- existing docs and agent files
- scripts, hooks, CI
- structured env/config sources
- monorepo/service/contract signals

Recommended: use 2 parallel read-only explorer sub-agents, one for structure/stack and one for
commands/conventions. If sub-agents are unavailable, do both scans sequentially.

Scan constraints:

- no raw file dumps
- no more than roughly 2000 tokens per sub-agent
- use tables for file/script/env-var summaries
- exclude standard junk dirs (`node_modules`, `.git`, `vendor`, `__pycache__`, `dist`, `build`,
  `.next`, `.turbo`, `coverage`, `.venv`, `venv`)
- never include secret values
- do not blind-grep the whole repo for env vars; use structured sources only

### Step 2: Initialize Canonical Structure

Create the canonical structure directly using `references/canonical-shape.md`. At minimum create
`docs/INDEX.md`, the canonical taxonomy directories, and `docs/templates/`.

Init is idempotent: only create what is missing, and only reorganize existing files when the
canonical target is clear.

### Step 3: Add Optional Directories And Root Files

Create optional directories only when justified by scan signals:

- `docs/services/` for monorepo or multi-service layouts
- `docs/contracts/` for OpenAPI, protobuf, GraphQL, AsyncAPI, or similar contracts

Then create or update:

- `AGENTS.md`
- `CLAUDE.md` -> symlink to `AGENTS.md`
- `CODEX.md` -> symlink to `AGENTS.md`

If `CLAUDE.md` or `CODEX.md` already exist as real files, replace them with symlinks when safe and
report the change. Treat it as safe when the file is empty, already a symlink to `AGENTS.md`, or a
trivial stub that only points readers back to `AGENTS.md`. If the file contains real repo-specific
content, merge that content into `AGENTS.md` first or leave the file in place and report why it was
not replaced. If symlink creation fails, write stub files that point to `AGENTS.md`.

### Step 4: Populate First-Pass Docs

Fill obvious gaps from repo facts. Do not stop at an empty scaffold when the repo has enough
structured source material to support real docs.

Minimum expected outputs when signals exist:

- one explanation doc covering architecture or package relationships
- one reference doc covering commands / quality gates / release flow
- one reference doc covering implementation roots, modules, packages, or services when the repo has
  multiple major units
- one how-to doc when the repo exposes a repeatable setup or operational workflow

Requirements:

- link every created doc from `docs/INDEX.md`
- include `code_paths` where there is a clear code or config surface
- prefer `codebound` when the doc should track code/config changes
- avoid copying large README blocks verbatim
- verify that generated structural docs match the repo's actual implementation shape (for example:
  workspace units, `src/`, `app/`, `internal/`, `services/`, or `executors/`) before treating init
  as complete

### Step 5: Migrate Existing Docs

If the repo already has docs, migrate them into the canonical structure:

- add missing canonical frontmatter
- move docs into the correct taxonomy directory
- rename files to canonical filename patterns
- drop clearly obsolete non-canonical frontmatter fields
- link migrated docs from `docs/INDEX.md`

Use `git mv` for path changes. If any move fails, stop and report partial state. Emit a summary
table of actions performed.

For detailed legacy mappings, use `references/migration.md`.

### Step 6: Generate Agent Docs

Write a compact `AGENTS.md` from the post-migration repo state:

- project name and one-line description
- compact doc taxonomy table
- tech stack
- 2-level annotated tree
- key modules
- key commands
- code conventions
- environment variables when applicable
- searching examples
- agent workflow guidance

Rules:

- reference `docs/INDEX.md`, not `docs/README.md`
- reference `docs/templates/`, not `docs/_templates/`
- use snake_case field names in examples
- use `[unknown]` instead of guessing
- preserve accurate existing repo-specific guidance when updating an existing `AGENTS.md`

### Step 7: Validate

There is no deterministic linter; validate by inspection:

- structure matches the canonical taxonomy
- filenames match canonical patterns
- every curated doc is reachable from `docs/INDEX.md` (no orphans)
- frontmatter is present and coherent on all curated docs
- internal links resolve

If the repo already has markdown validators, keep them if they are useful, or scope them away from
governed `docs/` paths if they conflict with the canonical shape. Report any validation gaps
clearly.

## Audit Mode

Audit mode is read-only.

Run the advisory checks from `references/audit.md` and produce a report with:

- summary
- stale files
- code-path drift
- coverage gaps
- `AGENTS.md` drift
- missing-doc suggestions
- symlink issues
- suggested actions

After the report, stop.

## Rules

- this skill owns the canonical repo-docs shape; keep `references/canonical-shape.md` authoritative
- never define a competing docs schema, root-doc convention, or template directory
- move or reorganize existing files autonomously when the canonical target is clear; report changes
- audit mode is strictly read-only
- init is idempotent except for canonical migration and in-place updates needed to align the repo
- in repos with clear structured source material, init is not complete if `docs/` contains only
  `INDEX.md` and templates
