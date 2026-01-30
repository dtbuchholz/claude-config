---
name: commit-push-pr
description:
  Stage changes, create a git commit, push to remote, and open a pull request. Follows conventional
  commits format.
---

# Commit, Push, and PR

Complete workflow for staging changes, creating a well-formatted commit, pushing to remote, and
opening a pull request.

## When This Skill Applies

- User asks to commit and push changes
- User wants to create a PR for current work
- User says "commit, push, and PR" or similar

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
- Remote tracking: !`git remote -v`

## Your Task

Based on the above changes:

1. **Create a new branch if on main/master** - Don't commit directly to main
2. **Stage and commit** with conventional commit format
3. **Push the branch** to origin
4. **Create a pull request** using `gh pr create`

### Conventional Commit Format

Use conventional commit prefixes:

- `feat:` new feature
- `fix:` bug fix
- `refactor:` code refactoring
- `docs:` documentation changes
- `test:` test additions/changes
- `chore:` maintenance tasks

### Push Handling

- If branch doesn't exist on remote: `git push -u origin <branch-name>`
- Otherwise: `git push`

### Pull Request

Use GitHub CLI:

```bash
gh pr create --title "the pr title" --body "PR body here"
```

- Generate a descriptive title based on the commit(s)
- Include a body summarizing the changes
- Do NOT include any "Generated with Claude Code" footer or similar attribution
- If a PR already exists for this branch, show its status with `gh pr view`

### Execution

You have the capability to call multiple tools in a single response. You MUST do all of the above in
a single message where possible. Do not use any other tools or do anything else. Do not send any
other text or messages besides these tool calls.

## Output

Provide a summary of:

1. What was committed
2. The commit hash
3. The PR URL (or existing PR status)
