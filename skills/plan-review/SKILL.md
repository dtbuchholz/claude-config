---
name: plan-review
description: >
  Review and challenge a plan before implementation. Interactive, opinionated review with scope
  challenge, architecture/code quality/tests/performance passes, and failure mode analysis. Use when
  the user asks to review a plan, challenge a plan, or says "/plan-review".
---

# Plan Review

Review a plan thoroughly before implementation. For every issue, explain concrete tradeoffs, give an
opinionated recommendation, and ask for input before assuming a direction.

## Finding the Plan

If the user doesn't specify a plan file:

1. Check Claude Code's plan mode location:
   ```bash
   ls -lt ~/.claude/plans/*.md 2>/dev/null | head -5
   ```
2. Check local plans:
   ```bash
   ls -la plans/ 2>/dev/null || ls -la *.md 2>/dev/null
   ```
3. If multiple found, ask which one. If none found, ask for the path.

## Priority Hierarchy

If running low on context or the user asks to compress: Step 0 > Test diagram > Opinionated
recommendations > Everything else. Never skip Step 0 or the test diagram.

## Step 0: Scope Challenge

Before reviewing anything, answer:

1. **What existing code already solves each sub-problem?** Can we reuse existing flows instead of
   building parallel ones?
2. **What is the minimum set of changes that achieves the goal?** Flag anything that could be
   deferred. Be ruthless about scope creep.
3. **Complexity check:** If the plan touches more than 8 files or introduces more than 2 new
   classes/services, challenge whether the same goal can be achieved with fewer moving parts.

Then ask the user to pick a review mode:

1. **SCOPE REDUCTION** — The plan is overbuilt. Propose a minimal version, then review that.
2. **FULL REVIEW** — Work through interactively, one section at a time (Architecture → Code Quality
   → Tests → Performance) with at most 4 top issues per section.
3. **QUICK REVIEW** — Compressed single pass. Pick the single most important issue per section.
   Present as one numbered list, mandatory test diagram, completion summary. One confirmation round
   at the end.

**If the user does not pick SCOPE REDUCTION, respect that fully.** Your job becomes making their
chosen plan succeed. Raise scope concerns once in Step 0 — after that, commit to their scope and
optimize within it.

## Review Sections

Work through each section in order. After each section, you MUST present your findings and ask for
user confirmation. Do NOT proceed to the next section until the user responds.

### 1. Architecture Review

Evaluate:

- System design and component boundaries
- Dependency graph and coupling
- Data flow patterns and bottlenecks
- Security architecture (auth, data access, API boundaries)
- For each new codepath or integration point, describe one realistic production failure scenario and
  whether the plan accounts for it

Use ASCII diagrams for any non-trivial data flow, state machine, or processing pipeline.

**STOP.** Present findings and ask for user confirmation before proceeding.

### 2. Code Quality Review

Evaluate:

- Code organization and module structure
- DRY violations — flag repetition aggressively
- Error handling patterns and missing edge cases
- Over-engineering vs under-engineering
- Whether existing ASCII diagrams in touched files are still accurate after this change

**STOP.** Present findings and ask for user confirmation before proceeding.

### 3. Test Review

Build a diagram of all new codepaths, data flows, and branching outcomes. For each item in the
diagram, verify a test exists. Flag gaps.

**STOP.** Present findings and ask for user confirmation before proceeding.

### 4. Performance Review

Evaluate:

- N+1 queries and database access patterns
- Memory usage concerns
- Caching opportunities
- Slow or high-complexity code paths

**STOP.** Present findings and ask for user confirmation before proceeding.

## How to Present Issues

For every issue (bug, smell, design concern, risk):

- Describe the problem concretely, with file and line references
- Present 2–3 options, including "do nothing" where reasonable
- For each option, state in one line: effort, risk, and maintenance burden
- **Lead with your recommendation.** "Do B. Here's why:" — not "Option B might be worth
  considering." Be opinionated.
- Number issues (1, 2, 3...) and letter options (A, B, C...)
- When presenting options, start with "Recommend [LETTER]: [one-line reason]" then list all options
- Keep each option to one sentence max

## Required Outputs

### "What Already Exists" section

List existing code/flows that already partially solve sub-problems, and whether the plan reuses them
or unnecessarily rebuilds them.

### "NOT in Scope" section

List work that was considered and explicitly deferred, with a one-line rationale per item.

### Failure Modes

For each new codepath in the test diagram, list one realistic failure (timeout, nil reference, race
condition, stale data, etc.) and whether:

1. A test covers that failure
2. Error handling exists for it
3. The user would see a clear error or a silent failure

If any failure mode has no test AND no error handling AND would be silent, flag it as a **critical
gap**.

### Deferred Work

Any genuinely valuable deferred work gets captured with:

- **What:** One-line description
- **Why:** The concrete problem it solves
- **Context:** Enough detail to pick this up in 3 months without re-deriving it

Ask the user which deferred items they want captured before writing them.

### Completion Summary

At the end, display:

```
Step 0: Scope Challenge (user chose: ___)
Architecture Review: ___ issues found
Code Quality Review: ___ issues found
Test Review: diagram produced, ___ gaps identified
Performance Review: ___ issues found
NOT in scope: written
What already exists: written
Deferred work: ___ items proposed
Failure modes: ___ critical gaps flagged
Unresolved decisions: ___ (list any skipped confirmation rounds)
```

## Rules

- Never write code during this skill. Only review and challenge the plan.
- If the user skips a confirmation round or interrupts to move on, note which decisions were left
  unresolved. List these at the end as "Unresolved decisions that may bite you later."
- Check git log for this branch. If prior commits suggest a previous review cycle, be more
  aggressive reviewing areas that were previously problematic.
- When the user chose FULL REVIEW or QUICK REVIEW, do not continue lobbying for scope reduction.
  Make their plan succeed.
