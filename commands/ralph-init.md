---
allowed-tools: Bash(~/.claude/skills/ralph-loop/scripts/ralph-init.sh:*)
description: Initialize a Ralph loop with fresh-context-per-iteration design
argument-hint: "TASK_SPEC [--max-iterations N] [--promise TEXT]"
---

# Ralph Loop Initialization

Initialize a Ralph loop - an **external bash loop** that spawns fresh Claude sessions for each
iteration.

Key properties:

- External bash loop (not in-session)
- Fresh context per iteration
- File I/O as state
- Re-anchors from source files each iteration

## Execute

```!
~/.claude/skills/ralph-loop/scripts/ralph-init.sh $ARGUMENTS
```

## After Initialization

The `.ralph/` directory will be created with:

- `spec.md` - Your task specification
- `state.json` - Loop state tracking
- `progress.log` - Append-only progress log
- `evidence/` - Iteration output logs

## Running the Loop

After initialization, run the loop from your terminal:

```bash
~/.claude/skills/ralph-loop/scripts/ralph.sh
```

Options:

- `--max-iterations N` - Override max iterations
- `--timeout SECONDS` - Timeout per iteration (default: 1800)
- `--verbose` - More detailed output

## Monitoring

```bash
# Watch progress
tail -f .ralph/progress.log

# Check state
cat .ralph/state.json | jq .

# View latest output
cat .ralph/evidence/iter-*.log | tail -50
```
