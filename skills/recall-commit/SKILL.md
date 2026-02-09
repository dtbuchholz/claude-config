---
name: recall-commit
description:
  Commit with inline learning capture for Recall Labs projects. Requires explicit invocation.
---

# Recall Commit

Conventional commit with built-in learning capture. One commit, one atomic unit of work + knowledge.

## When This Skill Applies

- User explicitly says "/recall-commit"
- Do NOT activate on generic "commit this" or "/commit" — this skill requires explicit invocation

## Guard

Verify this is a Recall Labs project:

```bash
git remote -v 2>/dev/null | grep -q recallnet || test -f AGENT-LEARNINGS.md
```

Check ALL remotes, not just origin. If neither condition is true, warn: "This doesn't appear to be a
Recall Labs project (no recallnet remote, no AGENT-LEARNINGS.md). Use a standard commit instead."
Allow the user to override if they confirm they want to proceed.

## Context

Gather before starting:

- `git status`
- `git diff HEAD`
- `git branch --show-current`
- `git log --oneline -5`

## Procedure

### Phase 1: Stage & Compose

**Stage changes:**

- If nothing staged, confirm with user which files to stage. Prefer specific files over
  `git add -A`.
- Never stage secrets (`.env`, `credentials.json`, `*.pem`). Warn if requested.

**Compose commit message:**

Subject line (50 chars max):

```
type(scope): imperative description
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`, `build`, `style`

Body (wrapped at 72 chars):

```
## Summary
What and why in 1-2 sentences.

## Changes
- Change 1
- Change 2

## Why
Rationale if non-obvious. Omit if summary is sufficient.

## Testing
How verified. Omit for docs-only changes.

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

### Phase 2: Reflect & Capture

Before committing, reflect on the session. Prioritize **high-leverage insights** — knowledge that
steers an agent toward the right direction or solution space. Small tactical failures that an agent
would overcome through normal persistence are low value. The best learnings change how someone
_approaches_ a problem, not just how they recover from a specific error.

Ask yourself:

1. **What knowledge would change how an agent approaches this problem?** What context, mental model,
   or design rationale would send them toward the right solution space from the start?
2. **What non-obvious constraint or relationship shaped your decisions?** What's not in the code or
   docs but was critical to getting this right?

If the user called out specific learnings during the session (e.g., "log this learning: ..."),
include those alongside your own reflections.

**Quality gates:**

- **High-leverage test:** Does this learning change the _approach_ an agent would take, or just help
  them recover from a specific failure? Prioritize the former.
- Would a capable agent figure this out through normal trial and error? If yes, skip it.
- Would they find it in the code or docs? If yes, skip it.
- Nothing worth capturing? **Zero learnings is valid.** Do not fabricate.

**If learnings exist:**

First, check if `AGENT-LEARNINGS.md` already has uncommitted changes (e.g., from a previous failed
commit attempt):

```bash
git diff --name-only AGENT-LEARNINGS.md 2>/dev/null
git diff --cached --name-only AGENT-LEARNINGS.md 2>/dev/null
```

If the file has uncommitted changes, **skip writing** — the learnings from the previous attempt are
already there. Just ensure the file is staged.

Otherwise, insert each new entry immediately after the `<!-- Entries below, newest first -->`
comment line in `AGENT-LEARNINGS.md`, before any existing entries:

```markdown
### YYYY-MM-DD — Summary sentence (confirmed|hypothesis)

Insight: One sentence stating the key implication — why this matters and what it changes about how
you'd approach the problem.

Detail: The specific context, evidence, or mechanism behind the insight. What happened, what you
tried, what the constraints were.

Directive: Do X, not Y. Context: branch, what was being done
```

Lead with the insight — a reader scanning the file should understand the implication from that line
alone, without reading the full detail.

For cross-cutting learnings (not specific to this repo — tool quirks, framework gotchas, workflow
patterns), add `, meta` to the tag:

```markdown
### YYYY-MM-DD — Summary sentence (confirmed, meta)
```

If `AGENT-LEARNINGS.md` does not exist and this is a recallnet repo, prompt the user: "This repo
doesn't have an AGENT-LEARNINGS.md yet. Create one to capture learnings for the team?" If they
confirm, create it with this header:

```markdown
# Agent Learnings

Cross-cutting insights from AI agent sessions. These are learnings that don't belong in a specific
doc but help future agents work smarter.

Atlas indexes this file nightly for semantic search across the team.

Each entry includes a directive: a concrete "Do X, not Y" instruction. Entries marked `hypothesis`
have not been independently verified. Entries tagged `meta` are cross-cutting (not repo-specific)
and surfaced team-wide.

---

<!-- Entries below, newest first -->
```

Then stage the file:

```bash
git add AGENT-LEARNINGS.md
```

**Anti-patterns — do NOT produce:**

- Small tactical failures an agent would overcome through persistence (e.g., "command X fails, use
  command Y instead")
- Restating what the code does (the code is readable)
- Vague advice without specifics ("be careful with X")
- Learnings without the Insight line — detail without implication is noise
- Learnings without directives
- Fabricated learnings to seem productive

### Phase 3: Commit

Execute via HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
type(scope): subject line

## Summary
...

Co-Authored-By: Claude <model> <noreply@anthropic.com>
EOF
)"
```

If pre-commit hooks fail: fix the issue, re-stage, and create a NEW commit. Never amend — amending
after a hook failure modifies the previous commit, not the failed one.

Run `git status` to confirm success.

## Rules

- Requires explicit `/recall-commit` invocation. Never activate implicitly.
- Never fabricate learnings. Zero is valid.
- Never amend after hook failure.
- Never `git add -A` without user confirmation.
- Never commit secrets.
- Always use HEREDOC for commit messages.
- Always include `Co-Authored-By` trailer.
- Learnings are the agent's own reflection. Do not ask the user to reflect.
