---
allowed-tools:
  Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*),
  Bash(gh pr create:*), Bash(gh pr view:*)
description: Stage changes, create a git commit, push to remote, and open a pull request
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
- Remote tracking: !`git remote -v`

## Your Task

Based on the above changes, perform the complete commit-push-PR workflow:

### 1. Stage and Commit

- Stage all relevant changes (or follow user instructions for specific files)
- Create a single, well-formatted commit message following conventional commits:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `refactor:` for code refactoring
  - `docs:` for documentation changes
  - `test:` for test additions/changes
  - `chore:` for maintenance tasks

### 2. Push to Remote

- Push the current branch to origin
- If the branch doesn't exist on remote, use `git push -u origin <branch-name>`

### 3. Create Pull Request

- Use GitHub CLI to create a PR: `gh pr create`
- Generate a descriptive title based on the commit(s)
- Include a body summarizing the changes
- If a PR already exists for this branch, show its status with `gh pr view`

## Output

Provide a summary of:

1. What was committed
2. The commit hash
3. The PR URL (or existing PR status)

You have the capability to call multiple tools in a single response. Execute the workflow
efficiently. If any step fails, report the error and stop.
