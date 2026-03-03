---
name: qmd
description: >
  Search across project memory, skills, and docs using QMD semantic search. Use when the user asks
  to recall past decisions, find relevant context, or search their knowledge base. Requires QMD
  installed; gracefully falls back if unavailable.
---

# QMD

Search your indexed knowledge base using QMD (semantic + keyword search). Surfaces relevant context
from project memory files, skill definitions, and documentation.

## When This Skill Applies

- User explicitly says "/qmd"
- User asks "what do I know about X?" or "have I dealt with X before?"
- User wants to find past decisions, patterns, or context across projects

## Prerequisites

QMD must be installed. Check availability before running any search:

```bash
~/.claude/scripts/qmd.sh status        # Check index health
~/.claude/scripts/qmd.sh mcp --http    # Start daemon if not running
```

If the wrapper exits with code 127 ("No working qmd binary found"), QMD is not installed on this
machine. **Do not attempt to search** — tell the user QMD is not available and fall back to standard
tools (Grep, Glob, Read) instead.

## Search Modes

### 1. Quick Search (keyword, fastest)

For exact terms, function names, error messages, or known phrases:

```bash
~/.claude/scripts/qmd.sh search "pre-commit hook gitleaks" -n 5
```

### 2. Semantic Search (vector similarity)

For conceptual queries where exact words may differ:

```bash
~/.claude/scripts/qmd.sh vsearch "how to handle database migrations safely" -n 5
```

### 3. Deep Search (hybrid + reranking, best quality)

For open-ended questions combining keyword and semantic understanding:

```bash
~/.claude/scripts/qmd.sh query "authentication patterns across projects" -n 5
```

## Execution

### Step 1: Understand the Query

Determine which search mode fits:

| Query type       | Mode      | Example                              |
| ---------------- | --------- | ------------------------------------ |
| Exact term/error | `search`  | "ANTHROPIC_API_KEY", "exit code 126" |
| Conceptual       | `vsearch` | "how do I handle retries"            |
| Open-ended       | `query`   | "what testing patterns do I use"     |

If unsure, default to `query` (deep search).

### Step 2: Search

Run the appropriate command. Use `--json` for structured output when you need to process results
programmatically, or `--md` for readable output:

```bash
~/.claude/scripts/qmd.sh query "the user's question" -n 6 --md
```

To restrict to a specific collection:

```bash
~/.claude/scripts/qmd.sh query "deployment setup" -n 6 --md -c claude-memory
```

Available collections:

| Collection      | Contains                                                      |
| --------------- | ------------------------------------------------------------- |
| `claude-memory` | Project-specific memory files (learnings, bugs, architecture) |
| `claude-skills` | Skill definitions and reference docs                          |
| `claude-config` | CLAUDE.md and README                                          |

### Step 3: Read Relevant Files

If search results point to a file that needs more context, read it:

```bash
~/.claude/scripts/qmd.sh get "claude-memory/path/to/MEMORY.md"
```

Or use the file path directly with the Read tool for full content.

### Step 4: Synthesize

Present findings to the user:

1. **Direct answer** — what the search found
2. **Sources** — which files/collections the information came from
3. **Gaps** — if the search didn't find what was expected, note it

## Rules

- Always cite the source file when presenting information from search results
- If QMD daemon is not running, start it or fall back to `~/.claude/scripts/qmd.sh search` (slower)
- Do not modify any files during this skill — it is read-only
- If no results found, say so clearly rather than guessing
- For broad queries, search multiple collections or omit the `-c` flag
