---
allowed-tools:
  Bash(rm:*), Bash(cat:*)
description: Cancel and clean up the current Ralph loop
---

# Cancel Ralph Loop

This will remove the `.ralph/` directory and stop any running loop.

## Current State (before cancellation)

```!
if [[ -f .ralph/state.json ]]; then
  echo "Current state:"
  cat .ralph/state.json | jq '{iteration, attempts, status}'
else
  echo "No Ralph loop found."
  exit 0
fi
```

## Cancellation

To cancel, the user should:

1. **Stop the running loop** (if active): Press Ctrl+C in the terminal running `ralph.sh`

2. **Remove the state directory**:
```bash
rm -rf .ralph/
```

Note: This will delete all evidence logs. If you want to preserve them:
```bash
cp -r .ralph/evidence ~/ralph-backup-$(date +%Y%m%d)/
rm -rf .ralph/
```

## Alternative: Pause Without Deleting

To pause the loop without losing state:
1. Press Ctrl+C to stop `ralph.sh`
2. The loop will resume from where it left off when you run `ralph.sh` again
