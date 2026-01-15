---
allowed-tools: Bash(git diff:*), Read, Edit, Glob, Grep
description: Remove AI-generated code slop from recent changes
---

## Context

- Current branch: !`git branch --show-current`
- Main branch diff: !`git diff main...HEAD --name-only 2>/dev/null || git diff HEAD~5 --name-only`

## Your Task

Remove all AI-generated slop from the changes in this branch. Check the diff against main (or recent
commits if not on a feature branch).

### What to Remove

1. **Unnecessary comments**
   - Comments explaining obvious code
   - Comments inconsistent with the file's existing style
   - Inline comments that restate what the code does

2. **Over-defensive code**
   - Extra try/catch blocks abnormal for that codebase
   - Redundant null checks on trusted/validated paths
   - Error handling that swallows errors silently

3. **Type hacks**
   - Casts to `any`
   - Unnecessary type assertions (`as Type`)
   - `@ts-ignore` or `@ts-expect-error`

4. **Style inconsistencies**
   - Naming that doesn't match the file
   - Patterns not used elsewhere in the codebase
   - Over-engineered solutions

### Process

1. Get the full diff: `git diff main...HEAD` (or `git diff HEAD~5` if on main)
2. For each changed file, compare new code against existing style
3. Remove patterns that don't match
4. Keep changes minimal - only remove clear slop

### Output

Provide a 1-3 sentence summary of what you changed. No lengthy explanations.
