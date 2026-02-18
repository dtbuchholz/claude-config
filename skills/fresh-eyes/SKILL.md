---
name: fresh-eyes
description: >
  Walk through a repo as a brand-new developer: read docs, verify setup, run every command, and
  report what's broken. Use when the user asks to test the onboarding experience, verify docs
  accuracy, or do a "fresh eyes" review after building something.
---

# Fresh Eyes Review

Pretend you have never seen this repo before. Your job is to follow the documented developer
experience exactly as written and report every place it breaks, lies, or confuses.

## When to Use

- After building a feature, to verify the repo still makes sense to a newcomer
- Before a release, to catch stale docs or broken setup steps
- When onboarding docs are created or updated
- When the user asks you to "test the DX" or "pretend you're a new developer"

## Procedure

Work through these phases in order. Each phase produces a pass/fail checklist. Do not skip ahead — a
new developer can't run tests if install failed.

### Phase 1: Read the docs

Read the README top-to-bottom. Treat every sentence as a contract.

- Note every file path, command, URL, prerequisite, and version mentioned
- Note any setup steps, environment variables, and configuration files referenced
- Read any supplementary docs the README links to (CONTRIBUTING, API docs, etc.)
- Flag anything ambiguous, contradictory, or that assumes context a newcomer wouldn't have

### Phase 2: Verify referenced files exist

Every file the docs mention must exist.

- .env.example, docker-compose.yml, Makefile, config files, scripts
- Source files referenced in examples or architecture descriptions
- A missing file is a broken onboarding experience — log it immediately

### Phase 3: Run the install path

Follow the documented install steps exactly. Do not improvise.

- Clone instructions (if applicable — skip if already in the repo)
- Dependency installation: `npm install`, `uv sync`, `make install`, etc.
- Does it complete without errors?
- Are there undocumented prerequisites (system packages, runtimes, services)?

### Phase 4: Environment setup

- Copy .env.example to .env (or whatever the docs say)
- Are all required variables documented? Do the example values make sense?
- What happens if you skip this step? Is the error message clear?
- Check: is .env in .gitignore?
- Check: do env var names in .env.example match what the docs say?

### Phase 5: Run every documented command

Try each command the docs mention, in isolation:

- Build commands: `make build`, `npm run build`, `uv run build`, etc.
- Test commands: `make test`, `npm test`, `pytest`, etc.
- Lint/format commands: `make lint`, `make check`, etc.
- Dev server: `make dev`, `npm run dev`, etc.
- Any other scripts or make targets documented

Each should exit 0 (or produce expected output). Log any that fail, hang, or produce unexpected
warnings.

### Phase 6: Start the dev server

Test the development server experience:

- Start without config/env — is the error clear about what's missing?
- Start with minimal config — does it boot cleanly?
- Hit the health/root endpoint — does it respond?
- If API endpoints are documented, test them with curl:
  - No auth → should get 401 (if auth is required)
  - Invalid input → should get a clear error response
  - Valid input → should get a structured response

Skip this phase if the project has no server component.

### Phase 7: Run the test suite

- Run the full test suite as documented
- Do all tests pass? If not, are failures environmental or real bugs?
- Is there a way to run a subset (unit only, integration only)?
- Are test dependencies documented (databases, services, API keys)?

### Phase 8: Verify tooling consistency

Cross-reference versions and config across files:

- Language version: does README match the lockfile / config (e.g., .python-version, .nvmrc,
  engines)?
- Dependencies: does the lockfile exist and match the manifest?
- CI config: do CI steps match what the docs say to run locally?
- Docker (if applicable): does the Dockerfile/compose file parse? Do referenced paths exist?

### Phase 9: Check supplementary docs and scripts

- Read any additional markdown files (CONTRIBUTING, ARCHITECTURE, etc.)
- Run scripts with `--help` to verify they're usable
- Check that links in docs aren't broken (relative paths, URLs)

### Phase 10: Compile the report

Produce a structured report with these sections:

```markdown
## Fresh Eyes Report

### Summary

[One paragraph: overall DX quality and biggest issues]

### Blockers

[Things that completely prevent a new developer from getting started]

### Bugs

[Commands that fail, tests that break, configs that don't work]

### Doc Gaps

[Missing info, stale references, wrong file paths, unclear steps]

### Inconsistencies

[Version mismatches, env var name differences, CI vs local divergence]

### Nitpicks

[Minor improvements — unclear wording, missing examples, etc.]

### What Worked Well

[Things that were smooth and well-documented — reinforce good patterns]
```

## Rules

- Follow docs literally. If the README says `npm install` but the project uses pnpm, that's a bug in
  the docs — don't silently substitute.
- Do not fix things silently. The goal is to find and report problems, not to quietly work around
  them. Log every issue, even if you can guess the fix.
- Test the unhappy path. What happens when env vars are missing? When a service isn't running? A new
  developer will hit these cases.
- Scope to what's documented. Don't test undocumented features. If it's not in the docs, it doesn't
  exist to a new developer.
- After the report, ask the user if they want you to fix the issues found.
