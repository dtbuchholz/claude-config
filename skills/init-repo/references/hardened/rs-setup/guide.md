# Rust Project Setup Guide (Step-by-step)

This is the staged setup runbook for Rust projects. **Load only one step file at a time** to avoid
context bloat. After each step, **stop and confirm** before proceeding.

## Entry Conditions

- Only use this guide for **greenfield setup** or **full quality-rails overhaul**.
- Run the **sentinel check** first (see SKILL.md). If a marker exists, do not re-run setup.

## Runbook Rules

- Ask the intake questions below and **do not start Step 01 until answered**.
- After each step: summarize changes, ask for confirmation, then proceed only on explicit approval.
- If the user wants to change scope mid-run, pause and re-confirm the intake.

## Intake Questions (stop & collect answers)

1. **Single crate or workspace?** (single binary/library, or multi-crate workspace with shared code)
2. **Crate types?** (binary, library, or both — e.g., `api` binary + `core` library)
3. **Unsafe code needed?** (If no, we enforce `#![forbid(unsafe_code)]` globally)
4. **Minimum Supported Rust Version (MSRV)?** (e.g., `1.75`, or "latest stable" if no constraint)
5. **Publishable to crates.io?** (affects Cargo.toml metadata and CI publish steps)
6. **Database / external services?** (affects integration test setup)
7. **CI provider?** (GitHub Actions assumed — confirm or specify alternative)
8. **Any existing tooling to preserve?** (build scripts, feature flags, etc.)

**Stop here until the user answers.**

## Steps (load one file at a time)

1. `references/hardened/rs-setup/01-workspace-structure.md`
2. `references/hardened/rs-setup/02-rustfmt-config.md`
3. `references/hardened/rs-setup/03-clippy-config.md`
4. `references/hardened/rs-setup/04-testing-config.md`
5. `references/hardened/rs-setup/05-git-hooks.md`
6. `references/hardened/rs-setup/06-pre-push-script.md`
7. `references/hardened/rs-setup/07-ci-pipeline.md`
8. `references/hardened/rs-setup/08-dependencies-and-checklist.md`

## Deep Dives (load only if the user opts in)

| Reference                                                    | When to Read                                         |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| `references/hardened/gates/rs-test-infrastructure.md`        | Property-based testing, nextest, coverage deep dive  |
| `references/hardened/modules/rs-design-metrics.md`           | Clippy pedantic as design metrics, complexity limits |
| `references/hardened/modules/rs-architecture-enforcement.md` | cargo-deny, visibility, feature flag architecture    |
| `references/hardened/modules/rs-mutation-testing.md`         | cargo-mutants setup and CI integration               |
