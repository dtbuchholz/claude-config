---
name: pr-review-quick
description:
  Quick code review of recent changes using parallel specialist agents for security, bugs,
  performance, and code quality.
---

# Quick Code Review

Fast, cheap review using 4 parallel haiku agents. For comprehensive PR review with 6 specialized
agents, use `/pr-review` instead.

## When This Skill Applies

- User asks for a quick review
- User says "/pr-review-quick"
- Fast feedback before committing

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

Use `model: haiku` for each agent to keep costs low.

**Every agent MUST receive this instruction:**

```
IMPORTANT: Only report issues on lines that were ADDED or MODIFIED in this diff (+ lines).
Do NOT report pre-existing issues in unchanged code.
```

```
Task (model: haiku): "SECURITY REVIEW

CRITICAL: Only flag issues on ADDED/MODIFIED lines (+ lines in diff). Ignore pre-existing code.

Check this diff for security issues:
- SQL injection
- XSS vulnerabilities
- Hardcoded secrets/credentials
- Missing input validation

Diff:
[paste diff]

Output format (only for issues with confidence ≥ 75%):
[HIGH/MEDIUM/LOW] file:line - description

If no high-confidence issues: 'No security issues found'"
```

```
Task (model: haiku): "BUG REVIEW

CRITICAL: Only flag issues on ADDED/MODIFIED lines (+ lines in diff). Ignore pre-existing code.

Check this diff for bugs and logic errors:
- Off-by-one errors
- Null/undefined handling
- Missing edge cases
- Race conditions
- Incorrect conditionals

Diff:
[paste diff]

Output format (only for issues with confidence ≥ 75%):
[HIGH/MEDIUM/LOW] file:line - description

If no high-confidence issues: 'No bugs found'"
```

```
Task (model: haiku): "PERFORMANCE REVIEW

CRITICAL: Only flag issues on ADDED/MODIFIED lines (+ lines in diff). Ignore pre-existing code.

Check this diff for performance issues:
- N+1 queries
- Unnecessary loops/iterations
- Missing memoization
- Large bundle imports
- Memory leaks

Diff:
[paste diff]

Output format (only for issues with confidence ≥ 75%):
[HIGH/MEDIUM/LOW] file:line - description

If no high-confidence issues: 'No performance issues found'"
```

```
Task (model: haiku): "CODE QUALITY REVIEW

CRITICAL: Only flag issues on ADDED/MODIFIED lines (+ lines in diff). Ignore pre-existing code.

Check this diff for code quality:
- Unclear naming
- Overly complex logic
- Code duplication
- Missing error handling
- Inconsistent patterns

Diff:
[paste diff]

Output format (only for issues with confidence ≥ 75%):
[HIGH/MEDIUM/LOW] file:line - description

If no high-confidence issues: 'No quality issues found'"
```

### Step 3: Synthesize Results

Collect all agent responses and combine into a single report.

**Filter out:**

- Issues on lines not in the diff
- Low-confidence findings (nitpicks, maybes)
- Things a linter would catch

```
## Review Summary

### Security
[agent 1 findings, or "No issues"]

### Bugs
[agent 2 findings, or "No issues"]

### Performance
[agent 3 findings, or "No issues"]

### Code Quality
[agent 4 findings, or "No issues"]

---
Files reviewed: [count]
Issues found: [HIGH: n, MEDIUM: n, LOW: n]
```

## Output Format

If issues found:

```
[HIGH] path/to/file.ts:42 - SQL injection vulnerability in user query
[MEDIUM] path/to/other.ts:15 - Missing null check on optional param
```

If no issues: "No issues found" with a brief note on what was reviewed.
