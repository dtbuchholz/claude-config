---
name: init-repo
description: >
  Initialize or audit a repository with starter, standard, hardened, or audit setup modes for
  JavaScript/TypeScript, Python, and Rust. Standard mode is the default. Hardened mode is the
  migrated quality-rails path and must only be used when explicitly requested.
argument-hint: "[starter|standard|hardened|audit] [js|ts|python|rust]"
---

# Init Repo

Set up or audit repository scaffolding and quality infrastructure. This skill is the single entry
point for new repo initialization, practical repo baselines, and full quality-rails hardening.

## Modes

| Mode       | Default? | Mutates? | Purpose                                                                   |
| ---------- | -------- | -------- | ------------------------------------------------------------------------- |
| `starter`  | no       | yes      | Minimal commands-only scaffold. No hooks, no CI, no monorepo assumptions. |
| `standard` | yes      | yes      | Practical production baseline with scripts, basic hooks, basic CI, docs.  |
| `hardened` | no       | yes      | Full quality rails with three-layer gates and optional advanced modules.  |
| `audit`    | no       | no       | Read-only inspection that recommends starter/standard/hardened deltas.    |

Use `standard` when the user says only `/init-repo`, "initialize this repo", or "create a project"
and does not name a mode.

Use `hardened` only when the user explicitly asks for hardened, quality rails, full gates, a full
quality overhaul, or equivalent. Do not silently apply hardened behavior for routine setup requests.

## Language Detection

Determine the language before loading setup references:

- JS/TS: `package.json`, `tsconfig.json`, or the user asks for JavaScript/TypeScript.
- Python: `pyproject.toml`, `setup.py`, `requirements.txt`, or the user asks for Python.
- Rust: `Cargo.toml`, `rust-toolchain.toml`, or the user asks for Rust.

If multiple languages are present, choose the primary language from the user's request. If that is
ambiguous, inspect the repo structure and package manifests before asking.

## Intake

Ask only for details that cannot be discovered from the repo or command arguments.

Required intake for all mutating modes:

1. Project name, unless already clear from the directory or user prompt.
2. Language, unless detected.
3. New repo versus existing repo baseline.

Additional standard/hardened intake:

- JS/TS: single package or monorepo, apps/packages to include, npm scope if publishable.
- Python: CLI, library, API/service, data pipeline, or general purpose; target Python version.
- Rust: binary, library, or workspace; target edition/MSRV when relevant.
- CI provider if the repo does not already imply one.

## Reference Loading

Load only the references needed for the selected mode and language.

### Starter

- JS/TS: `references/starter/js.md`
- Python: `references/starter/python.md`
- Rust: `references/starter/rust.md`

### Standard

- JS/TS: `references/standard/js.md`
- Python: `references/standard/python.md`
- Rust: `references/standard/rust.md`
- Basic CI: `references/standard/basic-ci.md`
- Agent docs: `references/agent-configuration.md`

### Hardened

Run the sentinel check first:

```bash
rg -n "# (init-repo-hardened|repo-quality-rails)" .husky .pre-commit-config.yaml scripts 2>/dev/null || true
```

If a marker exists, do not re-run setup. Switch to audit/maintenance behavior and report the
existing rails.

Load the language guide:

- JS/TS: `references/hardened/ts-setup/guide.md`
- Python: `references/hardened/py-setup/guide.md`
- Rust: `references/hardened/rs-setup/guide.md`

Then load one step file at a time as directed by the guide. Optional modules live under
`references/hardened/modules/` and are loaded only if the user opts in.

### Audit

Use `references/audit.md`. Audit mode is read-only: do not create, edit, move, delete, install, or
format files.

## Implementation Rules

- Preserve existing tool choices in existing repos unless the selected mode requires replacement and
  the user agreed to it.
- Do not add starter hooks or CI. Hooks begin at standard.
- Standard mode should keep CI lightweight: one job that runs the repo's format/check/lint/test
  commands.
- Hardened mode should preserve quality-rails parity across JS/TS, Python, and Rust.
- Keep agent documentation limited to `AGENTS.md`, optional `CLAUDE.md`, and optional `CODEX.md`.
- Do not introduce company-specific package scopes or retired organization names.
- After mutating setup, run the mode's verification commands and report anything that could not run.

## Output

For setup modes, summarize:

1. Mode and language selected.
2. Files and commands added or updated.
3. Verification run and result.
4. Next commands for the user.

For audit mode, summarize:

1. Detected language and current setup tier.
2. Missing starter/standard/hardened elements.
3. Recommended next step.
