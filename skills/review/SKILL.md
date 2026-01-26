---
name: review
description:
  Quick code review of recent changes using parallel specialist agents for security, bugs,
  performance, and code quality.
---

# Code Review

Review recent code changes using parallel specialist agents for thorough coverage.

## When This Skill Applies

- User asks to review code or recent changes
- User says "review my changes" or "/review"
- Before creating a PR

## Workflow

### Step 1: Get the Diff

```bash
# Get changed files
git diff main...HEAD --name-only 2>/dev/null || git diff HEAD~3 --name-only

# Get the full diff
git diff main...HEAD 2>/dev/null || git diff HEAD~3
```

### Step 2: Launch Parallel Review Agents

**CRITICAL: Launch ALL of these agents in a SINGLE message with multiple Task tool calls.**

Use `model: haiku` for each agent to keep costs low:

```
Task (model: haiku): "SECURITY REVIEW

Check this diff for security issues:
- SQL injection
- XSS vulnerabilities
- Hardcoded secrets/credentials
- Missing input validation
- Insecure dependencies

Diff:
[paste diff]

Output format:
[HIGH/MEDIUM/LOW] file:line - description

If no issues: 'No security issues found'"
```

```
Task (model: haiku): "BUG REVIEW

Check this diff for bugs and logic errors:
- Off-by-one errors
- Null/undefined handling
- Missing edge cases
- Race conditions
- Incorrect conditionals

Diff:
[paste diff]

Output format:
[HIGH/MEDIUM/LOW] file:line - description

If no issues: 'No bugs found'"
```

```
Task (model: haiku): "PERFORMANCE REVIEW

Check this diff for performance issues:
- N+1 queries
- Unnecessary loops/iterations
- Missing memoization
- Large bundle imports
- Memory leaks

Diff:
[paste diff]

Output format:
[HIGH/MEDIUM/LOW] file:line - description

If no issues: 'No performance issues found'"
```

```
Task (model: haiku): "CODE QUALITY REVIEW

Check this diff for code quality:
- Unclear naming
- Overly complex logic
- Code duplication
- Missing error handling
- Inconsistent patterns

Diff:
[paste diff]

Output format:
[HIGH/MEDIUM/LOW] file:line - description

If no issues: 'No quality issues found'"
```

### Step 3: Synthesize Results

Collect all agent responses and combine into a single report:

```
## Review Summary

### Security
[agent 1 findings]

### Bugs
[agent 2 findings]

### Performance
[agent 3 findings]

### Code Quality
[agent 4 findings]

---
Files reviewed: [count]
Issues found: [HIGH: n, MEDIUM: n, LOW: n]
```

## Output Format

If issues found:

```
[HIGH] path/to/file.ts:42 - SQL injection vulnerability in user query
[MEDIUM] path/to/other.ts:15 - Missing null check on optional param
[LOW] path/to/util.ts:8 - Variable name 'x' is unclear
```

If no issues: "No issues found" with a brief note on what was reviewed.
