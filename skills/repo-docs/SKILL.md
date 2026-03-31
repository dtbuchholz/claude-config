---
name: repo-docs
description: >
  Bootstrap or audit agent-focused repository docs using Recall's canonical repo-docs governance
  profile. Init mode scaffolds the canonical docs structure, AGENTS.md, and AGENT-LEARNINGS.md,
  populates first-pass canonical docs from existing repo sources, and aligns repo docs to the
  canonical structure. When a Node-compatible package-manager path exists, init also installs and
  runs the docs governance preset for deterministic lint enforcement. Audit mode performs
  higher-order advisory checks above deterministic docs lint.
argument-hint: "[init|audit]"
---

## Quick Reference

Two tracks:

- **Governance-enhanced**: Node/package-manager path exists; use the preset and `docs:lint`
- **Standalone scaffold**: use the same canonical shape, but without the preset or deterministic
  lint

**Greenfield repo**

| Governance-enhanced                                                        | Standalone scaffold                                         |
| -------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Install if needed: `<install-command> @recallnet/docs-governance-preset`   | Create canonical `docs/` tree manually                      |
| `<cli-command-prefix> recall-docs-governance init --profile repo-docs`     | Create `AGENTS.md` and `AGENT-LEARNINGS.md`                 |
| `<cli-command-prefix> recall-docs-governance populate --profile repo-docs` | Write first-pass docs by hand using the canonical shape     |
| Generate/update `AGENTS.md`, `AGENT-LEARNINGS.md`, `CLAUDE.md`, `CODEX.md` | Validate structure, naming, links, and frontmatter manually |
| Run `docs:lint` and fix violations                                         | Report that deterministic lint is not installed             |

**Existing repo with docs**

| Governance-enhanced                                                                     | Standalone scaffold                             |
| --------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Install if needed: `<install-command> @recallnet/docs-governance-preset`                | Create missing canonical structure manually     |
| `<cli-command-prefix> recall-docs-governance init --profile repo-docs`                  | Migrate existing docs into canonical layout     |
| Migrate existing docs into canonical layout                                             | Fill gaps by hand using the canonical shape     |
| `<cli-command-prefix> recall-docs-governance populate --profile repo-docs` to fill gaps | Generate/update agent docs after migration      |
| Generate/update agent docs after migration                                              | Validate manually                               |
| Run `docs:lint` and fix or report violations                                            | Report that deterministic lint is not installed |

Migration-heavy repos should expect validator cleanup and possible policy migration after init. See
`references/migration.md`.

## Purpose

`repo-docs` is the orchestrator.

`remark-ai` owns the machine-readable profile:

- canonical doc taxonomy
- frontmatter schema
- freshness rules
- reachability/orphan rules
- path and filename enforcement

This skill must not define a competing schema, template path, or root-doc convention. When the
preset cannot be installed, scaffold the same canonical shape without claiming deterministic
enforcement.

## References

Load these only as needed:

- `references/canonical-shape.md`
- `references/migration.md`
- `references/audit.md`

## When This Skill Applies

- `/repo-docs` or `/repo-docs init` — bootstrap or reorganize docs
- `/repo-docs audit` — advisory docs audit above deterministic lint
- User asks to set up repo docs, create `AGENTS.md`, bootstrap docs governance, or audit repo docs

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
- scripts, hooks, CI, validator config
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

### Step 2: Choose Mode And Commands

Use **governance-enhanced mode** when the repo already has a viable Node/package-manager path, or
when the user explicitly wants one for docs governance.

Use **standalone scaffold mode** when no viable Node/package-manager path exists or the repo should
not gain one just for docs governance.

In governance-enhanced mode, detect package manager with this precedence:

1. lockfile or `packageManager` field
2. existing `package.json` scripts
3. default to `pnpm` if the repo is Node-based but ambiguous

Derive concrete command forms:

| Package Manager | Install Command  | CLI Command Prefix | Script Command |
| --------------- | ---------------- | ------------------ | -------------- |
| `pnpm`          | `pnpm add -D`    | `pnpm exec`        | `pnpm`         |
| `npm`           | `npm install -D` | `npx`              | `npm run`      |
| `yarn`          | `yarn add -D`    | `yarn`             | `yarn`         |
| `bun`           | `bun add -d`     | `bunx`             | `bun run`      |

### Step 3: Initialize Canonical Structure

In governance-enhanced mode:

1. If `@recallnet/docs-governance-preset` is not already in package metadata, install it:

   ```bash
   <install-command> @recallnet/docs-governance-preset
   ```

2. Run init in all governance-enhanced cases:

   ```bash
   <cli-command-prefix> recall-docs-governance init --profile repo-docs
   ```

Important upgrade rule for already-governed repos:

- bumping `@recallnet/docs-governance-preset` alone does **not** rewrite committed governance files
- rerun `init` or explicitly migrate `docs/docs-policy.json`, `docs/docs-frontmatter.schema.json`,
  and `.remarkrc.mjs` when the canonical profile gains new policy sections or rules
- do not assume a dependency bump alone refreshes taxonomy or other checked-in policy content

In standalone scaffold mode:

- create the canonical structure directly using `references/canonical-shape.md`
- at minimum create `docs/INDEX.md`, the canonical taxonomy directories, and `docs/templates/`
- do **not** create `.remarkrc.mjs`, `docs/docs-policy.json`, `docs/docs-frontmatter.schema.json`,
  or `docs:lint` scripts unless the preset is actually installed

### Step 4: Add Optional Directories And Root Files

Create optional directories only when justified by scan signals:

- `docs/services/` for monorepo or multi-service layouts
- `docs/contracts/` for OpenAPI, protobuf, GraphQL, AsyncAPI, or similar contracts

Then create or update:

- `AGENTS.md`
- `AGENT-LEARNINGS.md`
- `CLAUDE.md` -> symlink to `AGENTS.md`
- `CODEX.md` -> symlink to `AGENTS.md`

If `CLAUDE.md` or `CODEX.md` already exist as real files, replace them with symlinks when safe and
report the change. If symlink creation fails, write stub files that point to `AGENTS.md`.

### Step 5: Populate First-Pass Docs

In governance-enhanced mode, run:

```bash
<cli-command-prefix> recall-docs-governance populate --profile repo-docs
```

`populate` uses gap-fill semantics: it skips docs that already exist and only creates missing ones.

Then, in either mode, fill any remaining obvious gaps from repo facts. Do not stop at an empty
scaffold when the repo has enough structured source material to support real docs.

Minimum expected outputs when signals exist:

- one explanation doc covering architecture or package relationships
- one reference doc covering commands / quality gates / release flow
- one reference doc covering modules, packages, or services when the repo has multiple major units
- one how-to doc when the repo exposes a repeatable setup or operational workflow

Requirements:

- link every created doc from `docs/INDEX.md`
- include `code_paths` where there is a clear code or config surface
- prefer `codebound` when the doc should track code/config changes
- avoid copying large README blocks verbatim

### Step 6: Migrate Existing Docs

If the repo already has docs, migrate them into the canonical structure:

- add missing canonical frontmatter
- move docs into the correct taxonomy directory
- rename files to canonical filename patterns
- drop clearly obsolete non-canonical frontmatter fields
- link migrated docs from `docs/INDEX.md`

Use `git mv` for path changes. If any move fails, stop and report partial state. Emit a summary
table of actions performed.

For detailed legacy mappings and upgrade caveats, use `references/migration.md`.

### Step 7: Generate Agent Docs

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

If `AGENT-LEARNINGS.md` is missing, create:

```markdown
# Agent Learnings

Durable directives from agent sessions. Newest first. Long investigations belong in
`docs/observations/`, not here.

---

<!-- Entries below, newest first -->
```

Entry shape:

- `Insight`
- `Detail`
- `Directive`
- `Action`
- `Context`

### Step 8: Validate

In governance-enhanced mode:

```bash
<script-command> docs:lint
```

`docs:lint` reads the repo's committed governance files from disk. If a preset upgrade introduces
new canonical policy structure, rerun `init` or migrate the policy before treating failures as
package-install-only issues.

If lint fails:

- fix deterministic docs issues that are in scope
- otherwise report the blockers clearly and stop

If the repo already has markdown validators, retire them or scope them away from governed `docs/`
paths so `docs:lint` is the authoritative check for curated docs.

In standalone scaffold mode:

- do not invent a fake `docs:lint`
- validate structure, naming, rooted links, and frontmatter coherence manually
- report explicitly that deterministic lint is not installed in this repo

## Audit Mode

Audit mode is read-only.

If `docs:lint` is available, run it first and treat it as the source of truth for:

- schema/frontmatter
- taxonomy/path/filename
- freshness
- reachability/orphans
- broken markdown links

If `docs:lint` is unavailable, state that clearly and continue with advisory-only checks.

Then run the advisory checks from `references/audit.md` and produce a report with:

- summary
- `docs:lint` findings
- stale files
- code-path drift
- coverage gaps
- learnings promotion candidates
- `AGENTS.md` drift
- missing-doc suggestions
- symlink issues
- suggested actions

After the report, stop.

## Rules

- `remark-ai` owns the canonical repo-docs profile; this skill orchestrates it
- never define a competing docs schema, root-doc convention, or template directory
- standalone scaffold mode must still use the same canonical shape
- move or reorganize existing files autonomously when the canonical target is clear; report changes
- audit mode is strictly read-only
- init is idempotent except for canonical migration and in-place updates needed to align the repo
- in repos with clear structured source material, init is not complete if `docs/` contains only
  `INDEX.md`, policy/schema files, and templates
