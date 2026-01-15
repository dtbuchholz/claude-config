---
allowed-tools: Bash(cat:*), Bash(jq:*), Bash(tail:*), Bash(ls:*)
description: Check the status of the current Ralph loop
---

# Ralph Loop Status

Check the current state of the Ralph loop in this directory.

## Current State

```!
if [[ -f .ralph/state.json ]]; then
  echo "=== Ralph State ==="
  cat .ralph/state.json | jq .
  echo ""
  echo "=== Recent Progress ==="
  tail -10 .ralph/progress.log
  echo ""
  echo "=== Evidence Files ==="
  ls -la .ralph/evidence/ 2>/dev/null | tail -5
else
  echo "No Ralph loop found in this directory."
  echo "Run /ralph-init to create one."
fi
```

## Interpreting Status

- **status: pending** - Loop hasn't started or is paused
- **status: completed** - Task finished successfully
- **status: max_iterations** - Stopped after hitting iteration limit
- **status: blocked** - Task blocked after too many failed attempts

## Next Steps

If running:

```bash
# Monitor progress
tail -f .ralph/progress.log

# View latest iteration output
cat .ralph/evidence/iter-*.log | tail -100
```

If blocked:

```bash
# View block reason
cat .ralph/blocked.md

# Reset attempts and retry
jq '.attempts = 0' .ralph/state.json | sponge .ralph/state.json
rm .ralph/blocked.md
```
