---
name: review-and-fix
description:
  Run a fresh-context code review on current changes, then apply fixes based on findings. Useful
  after implementing a feature to catch issues with an unbiased review.
---

# Review and Fix

Run a code review with fresh context (no knowledge of implementation decisions), then apply your
judgment to fix legitimate issues. This mimics having a separate reviewer look at your code.

## When This Skill Applies

- After implementing a feature, before committing
- User says "/review-and-fix" or "review and fix"
- User wants an unbiased review of their changes

## Why Fresh Context Matters

When you implement a feature, you have context about _why_ decisions were made. A fresh reviewer
only sees _what_ was done, which helps catch:

- Assumptions that aren't obvious from the code
- Missing error handling you "knew" wouldn't happen
- Unclear naming that made sense during implementation
- Edge cases you implicitly handled in your head

## Workflow

### Step 1: Capture Current Changes

```bash
# Get the diff that will be reviewed
git diff main...HEAD 2>/dev/null || git diff HEAD~5

# Get list of changed files
git diff --name-only main...HEAD 2>/dev/null || git diff --name-only HEAD~5
```

### Step 2: Read Project Guidelines

```bash
# Get CLAUDE.md for context the reviewer should have
cat CLAUDE.md 2>/dev/null || true
```

### Step 3: Launch Fresh-Context Review Agent

**CRITICAL: Use the Task tool to spawn a sub-agent. This agent has NO context from the current
session - it only sees what you pass it.**

```
Task (subagent_type: general-purpose, model: sonnet): "
You are reviewing code changes with NO prior context. You don't know why decisions were made -
you only see the diff. This is intentional.

## Project Guidelines (from CLAUDE.md)
[paste relevant CLAUDE.md content]

## Diff to Review
[paste full diff]

## Your Task

Review this diff for issues. Be critical but fair. For each issue:

1. Describe the problem
2. Explain why it's a problem (not just 'looks wrong')
3. Rate confidence (0-100):
   - 90+: Definitely a bug or will cause problems
   - 75-89: Very likely an issue, should fix
   - 50-74: Possible issue, worth considering
   - <50: Nitpick or uncertain

IMPORTANT:
- Only flag issues in the ADDED lines (+ lines in diff)
- Don't flag pre-existing issues
- Don't flag things a linter would catch
- If something looks intentional, note it but lower confidence

## Output Format

For each issue:
[CONFIDENCE: XX] file:line - Issue description
WHY: Explanation of the impact

If no significant issues: 'No issues found - code looks good.'

End with a 1-2 sentence summary.
"
```

### Step 4: Evaluate Review Findings

When the review agent returns, YOU (the parent agent with full context) must evaluate each finding:

For each issue, consider:

1. **Is this actually a problem?** You have context the reviewer didn't.
2. **Was this intentional?** If so, is the code clear enough that a reviewer shouldn't be confused?
3. **Is the confidence justified?** High-confidence issues deserve more attention.

Categorize findings into:

- **Will fix**: Legitimate issues
- **Won't fix**: False positives or intentional decisions
- **Will clarify**: Code is correct but unclear (add comment or rename)

### Step 5: Implement Fixes

For issues you're fixing:

1. Make the code change
2. If the reviewer was confused by intentional code, consider adding a clarifying comment

Do NOT fix:

- Low-confidence nitpicks unless you agree
- Style preferences not in CLAUDE.md
- "Improvements" that change intended behavior

### Step 6: Commit Changes

After implementing fixes, create a commit:

```bash
git add -A
git commit -m "fix: address review findings

- [list what was fixed]
- [note any clarifying comments added]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

## Output

Provide a summary:

```
## Review Summary

**Findings from fresh-context review:** X issues

### Fixed (Y issues)
- [file:line] What was fixed

### Not fixing (Z issues)
- [file:line] Why (intentional/false positive/etc.)

### Clarified (N issues)
- [file:line] Added comment or renamed for clarity

**Commit:** [hash] [message]
```

## Tips

- If the reviewer flags something as confusing, even if correct, consider if the code could be
  clearer
- High-confidence issues (90+) should almost always be addressed
- If you disagree with many findings, the code might need better documentation
- You can run this multiple times - each review is fresh
