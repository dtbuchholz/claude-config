---
name: qmd
description: >
  Search across project memory, skills, and docs using QMD semantic search. Use when the user asks
  to recall past decisions, find relevant context, or search their knowledge base. Requires QMD
  installed; gracefully falls back if unavailable.
---

# QMD

Search your indexed knowledge base using QMD (semantic + keyword search). Surfaces relevant context
from project memory files, skill definitions, documentation, and past conversation transcripts.

## When This Skill Applies

- User explicitly says "/qmd"
- User asks "what do I know about X?" or "have I dealt with X before?"
- User wants to find past decisions, patterns, or context across projects

## Prerequisites

QMD must be installed. Check availability before running any search:

```bash
command -v qmd >/dev/null && qmd --version
qmd status             # Check index health
qmd mcp --http         # Start daemon if not running
```

If `qmd` is not available in PATH, QMD is not installed for the active runtime. **Do not attempt to
search** — tell the user QMD is unavailable and fall back to standard tools (Grep, Glob, Read).

## Search Modes

### 1. Quick Search (keyword, fastest)

For exact terms, function names, error messages, or known phrases:

```bash
qmd search "pre-commit hook gitleaks" -n 5
```

### 2. Semantic Search (vector similarity)

For conceptual queries where exact words may differ:

```bash
qmd vsearch "how to handle database migrations safely" -n 5
```

### 3. Deep Search (hybrid + reranking, best quality)

For open-ended questions combining keyword and semantic understanding:

```bash
qmd query "authentication patterns across projects" -n 5
```

### 4. Temporal Recall (date-scoped conversations)

For questions about what happened on a specific day. Resolves natural language dates and searches
conversation transcripts:

```bash
~/.claude/scripts/qmd-temporal-recall.py "last Tuesday" "what did I do?" --source both --top 5
```

Accepts: `YYYY-MM-DD`, `today`, `yesterday`, `last Monday`, etc. Use `--source claude`,
`--source codex`, or `--source both`.

## Execution

### Step 1: Understand the Query

Determine which search mode fits:

| Query type       | Mode              | Example                              |
| ---------------- | ----------------- | ------------------------------------ |
| Exact term/error | `search`          | "ANTHROPIC_API_KEY", "exit code 126" |
| Conceptual       | `vsearch`         | "how do I handle retries"            |
| Open-ended       | `query`           | "what testing patterns do I use"     |
| Date-scoped      | `temporal-recall` | "what did I do last Tuesday"         |

If unsure, default to `query` (deep search). For questions about specific days, use temporal recall.

### Step 2: Search

Run the appropriate command. Use `--json` for structured output when you need to process results
programmatically, or `--md` for readable output:

```bash
qmd query "the user's question" -n 6 --md
```

To restrict to a specific collection:

```bash
qmd query "deployment setup" -n 6 --md -c claude-memory
```

Available collections:

| Collection             | Contains                                                      |
| ---------------------- | ------------------------------------------------------------- |
| `claude-memory`        | Project-specific memory files (learnings, bugs, architecture) |
| `claude-skills`        | Skill definitions and reference docs                          |
| `claude-config`        | CLAUDE.md and README                                          |
| `claude-conversations` | Cleaned conversation transcripts (day-scoped, timestamped)    |
| `codex-conversations`  | Cleaned Codex conversation transcripts                        |

### Step 3: Read Relevant Files

If search results point to a file that needs more context, read it:

```bash
qmd get "claude-memory/path/to/MEMORY.md"
```

Or use the file path directly with the Read tool for full content.

### Step 4: Synthesize

Present findings to the user:

1. **Direct answer** — what the search found
2. **Sources** — which files/collections the information came from
3. **Gaps** — if the search didn't find what was expected, note it

## Rules

- Always cite the source file when presenting information from search results
- If QMD daemon is not running, start it with `qmd mcp --http` or fall back to `qmd search` (slower)
- Do not modify any files during this skill — it is read-only
- If no results found, say so clearly rather than guessing
- For broad queries, search multiple collections or omit the `-c` flag
