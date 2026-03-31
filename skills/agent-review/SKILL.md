---
name: agent-review
description: >
  Run a fresh-context secondary review with Codex (default) or Claude, then adjudicate findings in
  the current implementation session and apply fixes you agree with.
argument-hint: "[codex|claude]"
---

# Agent Review

Run a reviewer agent in a separate CLI session, then apply the reviewer feedback in the current
session with implementer context.

## When This Skill Applies

- User asks for implement -> review -> implementer adjudication flow
- User says `/agent-review`
- User wants a second-opinion review before finalizing changes

## Reviewer Selection

- Default reviewer: `codex`
- Optional override: `claude`

Examples:

```text
/agent-review
/agent-review claude
```

## Script

Use the bundled script to run the external reviewer and capture output:

```bash
./scripts/run-review.sh <codex|claude> <project_dir> <output_file>
```

Default artifact location:

```text
<project>/.agent-review/review-YYYYMMDD-HHMMSS-<reviewer>.md
```

## Workflow

### 1. Preconditions

- Confirm current directory is a git repo
- Confirm there are local changes to review (`git status --short`)
- If there are no changes, stop and tell the user there is nothing to review

### 2. Run Reviewer (Fresh Context)

Determine reviewer from the first argument:

- if argument is missing, use `codex`
- if argument is `claude`, use `claude`

Run:

```bash
~/.claude/skills/agent-review/scripts/run-review.sh "${REVIEWER}" "$(pwd)"
```

Capture the returned file path.

### 3. Adjudicate In Current Session

Read the review file and apply this decision prompt in the current session:

```text
I had another agent review these changes and this was its feedback. Determine what you agree or disagree with, and then make any changes as needed.
```

Decision rules:

- Do not accept findings blindly
- Validate each finding against current goals and code intent
- Prefer high-confidence, behavior-affecting fixes first
- If a finding is rejected, briefly record why

### 4. Implement Agreed Fixes

- Apply only agreed fixes
- Keep scope tight to reviewed changes
- Run relevant tests/lint for touched areas when available

### 5. Report Back

Provide a concise summary:

- reviewer used (`codex` or `claude`)
- review artifact path
- accepted findings and implemented fixes
- rejected findings and rationale
- verification commands run

## Notes

- Step 2 intentionally runs in a fresh context to reduce implementer bias.
- This skill complements `pr-review`; it does not replace project-specific QA gates.
- If reviewer output is empty or tool execution fails, stop and report the error before making code
  changes.
