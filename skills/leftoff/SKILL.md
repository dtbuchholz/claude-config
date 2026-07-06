---
name: leftoff
description: >
  Find where work left off across Claude and Codex sessions for a specific day. Summarizes active
  threads and returns concrete next actions using QMD time-scoped lookup.
argument-hint: "<date> [repo-only]"
---

# Left Off

Find where work left off across Claude + Codex sessions for a specific day.

## When This Skill Applies

- `/leftoff yesterday`
- `/leftoff 2026-03-25`
- `/leftoff last Tuesday`
- `/leftoff last Tuesday repo-only`
- User asks "where did we leave off?", "what were we working on yesterday?", "catch me up on last
  session"

## Input

Format: `/leftoff <date phrase> [scope]`

Accepted date phrases:

- `YYYY-MM-DD`
- `today`, `yesterday`
- `last Monday` (or any weekday)

Scope (optional):

- `repo-only` — filter to threads tied to the current repo

If no date is given, default to `yesterday`.

## Prerequisites

Validate before proceeding:

```bash
command -v qmd >/dev/null && echo "qmd: ok" || echo "qmd: missing"
qmd status >/dev/null 2>&1 && echo "index: ok" || echo "index: missing"
test -f ~/.claude/scripts/qmd-temporal-recall.py && echo "lookup: ok" || echo "lookup: missing"
```

If `qmd` is not available or the index is empty, return a setup gap report:

```markdown
## Setup Gap

QMD is not available or not indexed. To set up:

1. Install qmd (requires Node 24+)
2. Add conversation collections: `qmd collection add claude-conversations <path> "**/*.md"`
3. Run `qmd update && qmd embed`
```

Do not guess or hallucinate summaries if the index is stale or missing.

## Workflow

### Step 1: Refresh Index

Run a quick update to catch any recent transcripts:

```bash
qmd update 2>&1 | tail -3
```

### Step 2: Time-Scoped Lookup

Run the time-scoped helper across both agent sources:

```bash
~/.claude/scripts/qmd-temporal-recall.py "<date>" "where did we leave off" --source both --top 12
```

If the user specified `repo-only`, add the repo filter:

```bash
~/.claude/scripts/qmd-temporal-recall.py "<date>" "where did we leave off" --source both --top 12 --repo auto
```

### Step 3: Expand Top Matches

For the top 3-5 most relevant matches from Step 2, read the full transcript sections:

```bash
qmd get "<qmd://collection/path>" -l 220
```

Look for:

- Session end state (last actions taken)
- Open questions or blockers mentioned
- Next steps the agent or user stated
- Commits made or PRs created

### Step 4: Synthesize

Combine findings into a summary. If `repo-only` was specified, filter out threads not related to the
current working directory's repo.

De-duplicate entries that appear in both parent and subagent threads — prefer the parent thread's
summary.

## Output Format

```markdown
## Left Off Summary (YYYY-MM-DD)

### What Finished

- [completed items with source thread]

### In Progress / Open Loops

- [items started but not finished, blockers encountered]

### Next Actions

1. [concrete next step — what to do first]
2. [second priority]
3. [third priority]

### Sources

- [qmd://collection/path — brief description of thread]
```

## Rules

- Prefer date-scoped evidence over semantic guesses
- De-duplicate repeated subagent/child-thread entries
- If `repo-only`, filter threads by current repo context (look for repo name, path, or branch in
  transcript text)
- Be explicit about missing data — if no transcripts exist for the date, say so clearly
- Never fabricate session content — only report what sources show
- Default to `yesterday` if no date is provided
