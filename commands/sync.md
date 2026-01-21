---
allowed-tools: Bash(git fetch:*), Bash(git checkout:*), Bash(git pull:*), Bash(git rebase:*), Bash(git status:*), Bash(git branch:*)
description: Sync current branch with main/master (fetch, checkout, pull, rebase)
---

## Context

- Current branch: !`git branch --show-current`
- Default branch: !`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"`
- Status: !`git status --short`

## Your Task

Sync the current branch with the main/master branch:

1. **Fetch latest from origin**
   ```bash
   git fetch origin
   ```

2. **If on a feature branch**: Rebase onto main/master
   ```bash
   git rebase origin/main  # or origin/master
   ```

3. **If on main/master**: Just pull
   ```bash
   git pull --rebase origin main
   ```

### Handle Conflicts

If rebase conflicts occur:
- List the conflicting files
- Do NOT automatically resolve - inform the user and stop
- Provide the command to abort: `git rebase --abort`

### Output

Report:
- What branch you synced
- How many commits were rebased (if any)
- Current status after sync
