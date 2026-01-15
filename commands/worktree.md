---
allowed-tools: Bash(~/.claude/skills/git-worktree/scripts/worktree-manager.sh:*)
description: Manage git worktrees for parallel development
argument-hint: "<create|list|switch|cleanup> [branch] [--from base]"
---

# Git Worktree Manager

Manage worktrees for isolated parallel development.

## Execute

```!
~/.claude/skills/git-worktree/scripts/worktree-manager.sh $ARGUMENTS
```

## Quick Reference

- `create <branch>` - Create worktree from main
- `create <branch> --from <base>` - Create from specific branch
- `list` - Show all worktrees
- `switch <branch>` - Get worktree path
- `cleanup <branch>` - Remove worktree
- `cleanup --all` - Remove all worktrees

## Common Use Cases

### Review a PR

```bash
/worktree create pr-feature-xyz
cd .worktrees/pr-feature-xyz
# review code, run tests
/worktree cleanup pr-feature-xyz
```

### Parallel Development

```bash
/worktree create feature-a
/worktree create feature-b --from develop
```
