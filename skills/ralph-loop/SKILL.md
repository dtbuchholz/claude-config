---
name: ralph-loop
description:
  Autonomous development loop with fresh context per iteration. Uses an external bash loop that
  spawns fresh Claude sessions, storing state in files to prevent context drift. Based on the
  original Ralph Wiggum technique by Geoffrey Huntley.
---

# Ralph Loop

An autonomous development loop for Claude Code. The key insight: **fresh context per iteration**
with **file I/O as state**.

## Core Principles

### 1. Fresh Context Per Iteration

Each iteration spawns a **new Claude session**. No transcript accumulation.

```
Iteration 1: claude -p "task.md" → works → exits
Iteration 2: claude -p "task.md" → sees files from iter 1 → works → exits
Iteration 3: claude -p "task.md" → sees files from iter 1+2 → works → exits
```

### 2. File I/O as State

All state lives in `.ralph/`:

- `spec.md` - The task specification (re-read each iteration)
- `state.json` - Iteration count, attempts, status
- `progress.log` - Append-only progress tracking
- `evidence/` - Proof of work (iteration outputs, test results)

### 3. Re-Anchoring Every Iteration

Before each iteration, Claude re-reads:

- The original task specification
- Current git state
- Test results from previous iteration
- Evidence of completed work

This prevents drift and ensures the model stays grounded in reality.

### 4. Failure Handling

- Track attempts per task
- Auto-block after N failures with a reason file
- Failed iterations don't pollute future context

## Directory Structure

```
.ralph/
├── spec.md              # Task specification (user-provided)
├── state.json           # Loop state (iteration, attempts, status)
├── progress.log         # Append-only execution log
├── evidence/            # Proof of work
│   ├── iter-001.log     # Raw output from iteration 1
│   ├── iter-002.log     # Raw output from iteration 2
│   └── ...
└── blocked.md           # If task gets stuck (reason + suggestions)
```

## Commands

### /ralph-init - Initialize a Loop

```bash
# Create spec file and initialize state
/ralph-init "Build a REST API with CRUD operations. Tests must pass."

# With options
/ralph-init "TASK_SPEC" --max-iterations 50 --promise "COMPLETE"
```

Runs: `~/.claude/skills/ralph-loop/scripts/ralph-init.sh`

Creates `.ralph/` directory with:

- `spec.md` - Your task specification
- `state.json` - Loop state tracking
- `progress.log` - Append-only progress log
- `evidence/` - Iteration output logs

### /ralph-status - Check Loop Status

Check the current state of the Ralph loop:

```bash
/ralph-status
```

Shows:

- Current state from `state.json`
- Recent progress log entries
- Evidence files

**Interpreting status:**

- `status: pending` - Loop hasn't started or is paused
- `status: completed` - Task finished successfully
- `status: max_iterations` - Stopped after hitting iteration limit
- `status: blocked` - Task blocked after too many failed attempts

### /ralph-cancel - Cancel Loop

Cancel and clean up the current Ralph loop:

```bash
/ralph-cancel
```

To cancel:

1. **Stop the running loop** (if active): Press Ctrl+C in the terminal running `ralph.sh`
2. **Remove the state directory**: `rm -rf .ralph/`

To pause without deleting: just press Ctrl+C. The loop will resume from where it left off when you
run `ralph.sh` again.

## Running the Loop

After initialization, run the loop from your terminal:

```bash
~/.claude/skills/ralph-loop/scripts/ralph.sh
```

Options:

- `--max-iterations N` - Override max iterations
- `--timeout SECONDS` - Timeout per iteration (default: 1800)
- `--verbose` - More detailed output

### Monitor Progress

```bash
# Watch progress
tail -f .ralph/progress.log

# Check state
cat .ralph/state.json | jq .

# View latest output
cat .ralph/evidence/iter-*.log | tail -50
```

### Stop the Loop

The loop stops when:

1. Claude outputs `<promise>DONE</promise>` (completion)
2. Max iterations reached (default: 25)
3. Max attempts per task exceeded (default: 5)
4. You press Ctrl+C

## Configuration

Environment variables:

- `RALPH_MAX_ITERATIONS` - Max loop iterations (default: 25)
- `RALPH_MAX_ATTEMPTS` - Attempts before blocking (default: 5)
- `RALPH_TIMEOUT` - Seconds per iteration (default: 1800)
- `RALPH_PROMISE` - Completion promise text (default: DONE)
- `RALPH_MODEL` - Claude model to use

## When to Use

**Good for:**

- Well-defined tasks with testable success criteria
- Tasks requiring iteration (get tests to pass)
- Overnight/unattended runs
- Tasks with automatic verification

**Not good for:**

- Tasks requiring human judgment
- Unclear success criteria
- Interactive exploration

## Credits

Based on the Ralph Wiggum technique by Geoffrey Huntley (ghuntley.com/ralph).
