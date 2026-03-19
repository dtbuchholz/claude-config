---
description: Selective context compaction — preserve what matters, drop what doesn't
argument-hint: [focus area or "auto"]
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# Context Prune Command

You are performing selective context management — a targeted `/compact` that preserves important context and aggressively drops the rest.

## Arguments

Arguments: $ARGUMENTS

## Process

### 1. Assess current context

Look at what's in your conversation history. Mentally categorize:

**Keep at full fidelity:**
- Current task goal and constraints
- File changes you've made (diffs, not full file reads)
- Test results from the most recent run
- Error messages you're actively debugging
- Architecture decisions made this session
- User preferences and corrections

**Summarize (compress to key facts):**
- Earlier exploration of the codebase (keep file paths and key findings, drop raw content)
- Intermediate test runs (keep pass/fail, drop full output)
- Tool outputs from solved problems

**Drop entirely:**
- Full file reads where you only needed a few lines
- Duplicate reads of the same file
- Failed approaches that were abandoned
- Verbose command output (build logs, install output, ls listings)
- Exploratory greps that didn't find what you needed

### 2. Check for context health report

```bash
ls -t ~/.claude/context-reports/ 2>/dev/null | head -1
```

If a report exists from a recent PreCompact hook run, read it to identify the largest context consumers.

### 3. Build compaction instructions

Based on your assessment, construct a focused compaction prompt. If the user provided a focus area, prioritize that.

### 4. Execute compaction

Run `/compact` with your constructed instructions. Be specific:

**Good:** `/compact Keep: the auth middleware refactor plan, failing test output from auth.test.ts, and the decision to use JWT over sessions. Drop: all package.json reads, npm install output, and the initial codebase exploration.`

**Bad:** `/compact Summarize everything important.`

### If arguments = "auto"

Automatically analyze and compact without asking. Use the PreCompact report if available, otherwise assess from conversation context.

### If arguments = specific focus

Treat the argument as the thing to preserve. Everything else gets aggressively compressed.

Example: `/context-prune auth middleware changes` → preserve auth-related context, compress everything else.
