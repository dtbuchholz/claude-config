---
name: clean-gone
description:
  Clean up git branches marked as [gone] (deleted on remote but still exist locally), including
  removing associated worktrees.
---

# Clean Gone Branches

Remove local branches that have been deleted from the remote repository, including any associated
worktrees.

## When This Skill Applies

- User asks to clean up old/stale branches
- User says "/clean-gone" or "clean gone branches"
- After merging PRs and wanting to clean up

## Your Task

Execute the following steps to clean up stale local branches.

### Step 1: Fetch and Prune

Update remote tracking info:

```bash
git fetch --prune
```

### Step 2: List Branches

Identify branches with [gone] status:

```bash
git branch -v
```

Note: Branches with a '+' prefix have associated worktrees and must have their worktrees removed
before deletion.

### Step 3: Check Worktrees

Identify worktrees that need removal:

```bash
git worktree list
```

### Step 4: Remove Gone Branches

Execute this command to remove worktrees and delete [gone] branches:

```bash
git branch -v | grep '\[gone\]' | sed 's/^[+* ]//' | awk '{print $1}' | while read branch; do
  echo "Processing branch: $branch"
  # Find and remove worktree if it exists
  worktree=$(git worktree list | grep "\\[$branch\\]" | awk '{print $1}')
  if [ ! -z "$worktree" ] && [ "$worktree" != "$(git rev-parse --show-toplevel)" ]; then
    echo "  Removing worktree: $worktree"
    git worktree remove --force "$worktree"
  fi
  # Delete the branch
  echo "  Deleting branch: $branch"
  git branch -D "$branch"
done
```

## Expected Output

Report:

- Which worktrees were removed (if any)
- Which branches were deleted
- If no branches are marked as [gone], report that no cleanup was needed
