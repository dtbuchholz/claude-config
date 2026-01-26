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

## Workflow

### 1. Gather Context

First, understand the current state:

```bash
# Current git status
git status

# Current branch
git branch --show-current

# Staged and unstaged changes
git diff HEAD

# Recent commits for style reference
git log --oneline -10

# Remote tracking
git remote -v
```

### 2. Stage and Commit

Stage all relevant changes (or follow user instructions for specific files) and create a single,
well-formatted commit message following conventional commits:

- `feat:` for new features
- `fix:` for bug fixes
- `refactor:` for code refactoring
- `docs:` for documentation changes
- `test:` for test additions/changes
- `chore:` for maintenance tasks

### 3. Push to Remote

Push the current branch to origin:

- If the branch doesn't exist on remote, use `git push -u origin <branch-name>`
- Otherwise, use `git push`

### 4. Create Pull Request

Use GitHub CLI to create a PR:

```bash
gh pr create --title "the pr title" --body "PR body here"
```

- Generate a descriptive title based on the commit(s)
- Include a body summarizing the changes
- Do NOT include any "Generated with Claude Code" footer or similar attribution
- If a PR already exists for this branch, show its status with `gh pr view`

## Output

Provide a summary of:

1. What was committed
2. The commit hash
3. The PR URL (or existing PR status)

## Efficiency

Execute the workflow efficiently by calling multiple tools in parallel where possible. If any step
fails, report the error and stop.
