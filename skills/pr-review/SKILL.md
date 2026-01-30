---
name: pr-review
description:
  Comprehensive PR review using 6 specialized agents for comments, tests, error handling, types,
  code quality, and simplification.
argument-hint: "[review-aspects]"
---

# Comprehensive PR Review

Run a thorough pull request review using multiple specialized agents, each focusing on a different
aspect of code quality. For a faster, cheaper review, use `/pr-review-quick` instead.

## When This Skill Applies

- User asks for comprehensive PR review
- User says "/pr-review"
- Before creating or merging a PR

## Arguments

Optional arguments to filter which reviews to run:

- `comments` - Analyze code comment accuracy and maintainability
- `tests` - Review test coverage quality and completeness
- `errors` - Check error handling for silent failures
- `types` - Analyze type design and invariants
- `code` - General code review for bugs and quality
- `simplify` - Simplify code for clarity and maintainability
- `security` - Check for security vulnerabilities
- `all` - Run all applicable reviews (default)
- `parallel` - Launch all agents in parallel (faster)

**Examples:**

```
/pr-review                    # Full review, sequential
/pr-review tests errors       # Only test coverage and error handling
/pr-review all parallel       # Full review, parallel execution
/pr-review simplify           # Just code simplification
```

## Review Workflow

### 1. Gather Context

```bash
# Get changed files
git diff --name-only main...HEAD 2>/dev/null || git diff --name-only HEAD~5

# Get the actual diff (CRITICAL: agents must only review lines in this diff)
git diff main...HEAD 2>/dev/null || git diff HEAD~5
```

### 2. Read Project Guidelines

Find and read relevant CLAUDE.md files:

```bash
# Root CLAUDE.md
cat CLAUDE.md 2>/dev/null || true

# CLAUDE.md in directories with changed files
# For each changed directory, check for CLAUDE.md
```

Extract relevant guidelines that apply to code review (not all instructions apply - focus on code
style, patterns, and conventions).

### 3. Launch Review Agents

**CRITICAL INSTRUCTION FOR ALL AGENTS:**

Every agent MUST receive these instructions:

```
IMPORTANT: Only report issues on lines that were ADDED or MODIFIED in this diff.
Do NOT report:
- Pre-existing issues in unchanged code
- Issues on lines that were not modified
- Problems that existed before this change

The diff shows + for added lines and - for removed lines. Only flag issues on + lines.
```

**Sequential** (default): Run one at a time for easier action

**Parallel** (with `parallel` arg): Launch all at once for speed

For each agent, use the Task tool with this template:

```
Task (subagent_type: general-purpose): "[AGENT_NAME] REVIEW

CRITICAL: Only report issues on lines ADDED or MODIFIED in this diff (+ lines).
Do NOT report pre-existing issues or problems in unchanged code.

Project guidelines from CLAUDE.md:
[relevant guidelines]

Diff to review:
[paste diff]

[Agent-specific instructions]

For each issue found, provide:
1. File and line number
2. Issue description
3. Confidence score (0-100):
   - 0-25: Likely false positive, doesn't hold up to scrutiny
   - 26-50: Might be real, but could be intentional or a nitpick
   - 51-75: Likely real issue, but may not happen often in practice
   - 76-90: Verified real issue that will impact functionality
   - 91-100: Definitely a bug/problem, confirmed with evidence

Output format:
[CONFIDENCE: XX] file:line - description"
```

### 4. Filter Results

After collecting all agent responses:

**Only report issues with confidence ≥ 75%.**

Filter out:

- Pre-existing issues (not in the diff)
- Issues a linter/typechecker would catch (assume CI runs these)
- Pedantic nitpicks a senior engineer wouldn't flag
- Style issues not explicitly in CLAUDE.md
- Issues on lines the user didn't modify
- Intentional changes related to the broader feature

### 5. Aggregate Results

Create summary with only high-confidence issues:

```markdown
# PR Review Summary

**Files reviewed:** [count] **Issues found:** [count] (filtered from [total] raw findings)

## Critical Issues (confidence ≥ 91)

- [file:line] Issue description

## Important Issues (confidence 75-90)

- [file:line] Issue description

## Passed Checks

- [list of agents that found no issues]

## Strengths

- [what's done well in this change]
```

If no issues pass the confidence threshold: "No significant issues found."

## Available Review Agents

### code-reviewer

**Focus**: General code review for project guidelines

- Checks CLAUDE.md compliance
- Detects bugs and logic errors
- Reviews code quality issues

### security-reviewer

**Focus**: Security vulnerabilities

- SQL injection, XSS
- Hardcoded secrets/credentials
- Missing input validation

### silent-failure-hunter

**Focus**: Error handling

- Silent failures in catch blocks
- Inadequate error handling
- Missing error logging

### pr-test-analyzer

**Focus**: Test coverage

- Missing tests for new functionality
- Edge cases not covered
- Test quality issues

### type-design-analyzer

**Focus**: Type design (TypeScript/typed languages)

- Type safety issues
- Missing or overly broad types
- Invariant violations

### comment-analyzer

**Focus**: Documentation accuracy

- Comments that don't match code
- Outdated documentation
- Misleading comments

### code-simplifier

**Focus**: Code simplification (run last)

- Overly complex code
- Unnecessary abstractions
- Opportunities to simplify

## False Positive Examples

Train agents to ignore these:

- Something that looks like a bug but isn't
- Issues a linter would catch (imports, formatting)
- General quality issues not in CLAUDE.md
- Issues silenced by lint-ignore comments
- Intentional functionality changes
- Real issues on lines NOT modified in the diff
