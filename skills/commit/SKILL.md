---
name: commit
description: Create a git commit with conventional commit format.
---

# Git Commit

Create a single, well-formatted git commit following conventional commits.

## When This Skill Applies

- User asks to commit changes
- User says "/commit" or "commit this"

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your Task

Based on the above changes, create a single git commit.

### Conventional Commit Format

Use conventional commit prefixes:

- `feat:` new feature
- `fix:` bug fix
- `refactor:` code refactoring
- `docs:` documentation changes
- `test:` test additions/changes
- `chore:` maintenance tasks
- `perf:` performance improvements
- `style:` formatting, whitespace

### Commit Message Guidelines

- First line: `<type>: <short description>` (50 chars max)
- Commit body is REQUIRED for all non-trivial commits
- Body must follow this structure:
  - `What:` concrete summary of changes
  - `Why:` motivation / problem solved
- Trivial exception: allow subject-only commit only when change is extremely small (e.g., typo,
  comments-only, or formatting-only) and no behavior change
- Reference issues with `Fixes #123` or `Closes #123`

Preferred format:

```text
<type>: <short description>

What:
- ...

Why:
- ...
```

When creating the commit, provide subject and body explicitly (for example with a HEREDOC or
multiple `-m` flags) so body is not omitted.

### Execution

You have the capability to call multiple tools in a single response. Stage and create the commit
using a single message. Do not use any other tools or do anything else. Do not send any other text
or messages besides these tool calls.
