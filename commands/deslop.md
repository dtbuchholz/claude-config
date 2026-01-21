---
description: Remove AI-generated code slop from recent changes
model: sonnet
allowed-tools: Bash(git diff:*), Read, Edit, Glob, Grep, Task
---

## Context

- Current branch: !`git branch --show-current`
- Main branch diff: !`git diff main...HEAD --name-only 2>/dev/null || git diff HEAD~5 --name-only`

## Your Task

Remove all AI-generated slop from the changes in this branch using parallel detection agents.

### Step 1: Get Changed Files

```bash
git diff main...HEAD --name-only 2>/dev/null || git diff HEAD~5 --name-only
```

### Step 2: Launch Parallel Detection Agents

**Launch ALL agents in a SINGLE message.** Use `model: haiku` for fast, cheap detection.

For EACH changed file, spawn a detection agent:

```
Task (model: haiku): "SLOP DETECTION for [filename]

Analyze this file for AI-generated slop patterns. Read the file and identify:

1. UNNECESSARY COMMENTS
   - Comments explaining obvious code
   - Inline comments restating what code does
   - Comments inconsistent with file's style

2. OVER-DEFENSIVE CODE
   - Extra try/catch blocks abnormal for codebase
   - Redundant null checks on trusted paths
   - Error handling that swallows errors silently

3. TYPE HACKS
   - Casts to `any`
   - Unnecessary type assertions (`as Type`)
   - `@ts-ignore` or `@ts-expect-error`

4. STYLE INCONSISTENCIES
   - Naming that doesn't match the file
   - Patterns not used elsewhere
   - Over-engineered solutions

File: [filepath]

Output format:
```
LINE [n]: [slop type] - [what to remove/change]
LINE [n]: [slop type] - [what to remove/change]
```

If no slop found: 'Clean'"
```

### Step 3: Collect and Apply Fixes

After all detection agents complete:

1. Collect all findings by file
2. For each file with findings, apply the edits using the Edit tool
3. Keep changes minimal - only remove clear slop

### Slop Patterns Reference

**Remove these:**
```typescript
// BAD: Obvious comment
const count = items.length; // Get the length of items

// BAD: Defensive null check on guaranteed value
if (user && user.id && user.id !== undefined && user.id !== null) {

// BAD: Type hack
const data = response as any;

// BAD: Over-engineered
const isEmpty = (arr: unknown[]): boolean => Array.isArray(arr) && arr.length === 0;
```

**Keep these:**
```typescript
// GOOD: Explains WHY, not what
const count = items.length; // Used for pagination limit

// GOOD: Necessary check at system boundary
if (!userInput) { return; }

// GOOD: Legitimate type assertion with reason
const data = response as ApiResponse; // API guarantees this shape
```

### Output

Provide a 1-3 sentence summary:
- Files cleaned: [count]
- Changes made: [brief list]

No lengthy explanations.
