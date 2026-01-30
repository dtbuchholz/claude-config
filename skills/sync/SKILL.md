---
name: sync
description: Sync current branch with main/master (fetch, checkout, pull, rebase).
---

# Sync Branch

Sync the current branch with the main/master branch.

## When This Skill Applies

- User asks to sync their branch
- User wants to update from main/master
- User says "sync" or "rebase on main"

## Context to Gather

```bash
# Current branch
git branch --show-current

# Default branch
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"

# Current status
git status --short
```

## Workflow

### 1. Fetch latest from origin

```bash
git fetch origin
```

### 2. Sync based on branch

**If on a feature branch**: Rebase onto main/master

```bash
git rebase origin/main  # or origin/master
```

**If on main/master**: Just pull

```bash
git pull --rebase origin main
```

### 3. Handle Conflicts

If rebase conflicts occur:

- List the conflicting files
- Do NOT automatically resolve - inform the user and stop
- Provide the command to abort: `git rebase --abort`

## Output

Report:

- What branch you synced
- How many commits were rebased (if any)
- Current status after sync
