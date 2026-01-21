---
description: Quick code review of recent changes
model: sonnet
allowed-tools: Bash(git diff:*), Read, Glob, Grep
---

## Context

- Current branch: !`git branch --show-current`
- Changed files: !`git diff main...HEAD --name-only 2>/dev/null || git diff HEAD~3 --name-only`

## Your Task

Review the recent code changes for issues. Check the diff against main (or last 3 commits if on
main).

### Review Checklist

1. **Bugs & Logic Errors**
   - Off-by-one errors
   - Null/undefined handling
   - Edge cases not covered
   - Race conditions

2. **Security Issues**
   - SQL injection
   - XSS vulnerabilities
   - Hardcoded secrets
   - Missing input validation

3. **Code Quality**
   - Unclear naming
   - Overly complex logic
   - Code duplication
   - Missing error handling

4. **Performance Concerns**
   - N+1 queries
   - Unnecessary loops
   - Missing indexes (for DB changes)
   - Memory leaks

### Output Format

List issues found with severity and file location:

```
[HIGH] path/to/file.ts:42 - SQL injection vulnerability in user query
[MEDIUM] path/to/other.ts:15 - Missing null check on optional param
[LOW] path/to/util.ts:8 - Variable name 'x' is unclear
```

If no issues found, say "No issues found" with a brief note on what was reviewed.
