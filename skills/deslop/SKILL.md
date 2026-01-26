---
name: deslop
description:
  Remove AI-generated code slop from recent changes. Checks the diff against main and removes
  unnecessary comments, defensive code, type hacks, and other patterns inconsistent with
  human-written code.
---

# Remove AI Code Slop

Check the diff against main and remove all AI-generated slop introduced in this branch using
parallel detection agents.

## When This Skill Applies

- After generating or editing code
- Before committing changes
- User asks to clean up or "deslop" code

## What to Remove

### Unnecessary Comments

- Comments explaining obvious code that a human wouldn't add
- Comments inconsistent with the rest of the file's style
- Inline comments that just restate what the code does
- Section dividers or decorative comments not used elsewhere in the codebase

### Over-Defensive Code

- Extra try/catch blocks that are abnormal for that area of the codebase
- Defensive null/undefined checks on trusted/validated codepaths
- Redundant validation that's already handled upstream
- Error handling that swallows errors silently

### Type Hacks

- Casts to `any` to work around type issues
- Type assertions (`as Type`) that hide real problems
- `@ts-ignore` or `@ts-expect-error` comments
- Overly permissive types (`any`, `unknown`, `object`) where specific types exist

### Style Inconsistencies

- Naming conventions that don't match the file
- Different formatting patterns
- Abstractions or patterns not used elsewhere in the codebase
- Over-engineered solutions for simple problems

## Process

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
LINE [n]: [slop type] - [what to remove/change]

If no slop found: 'Clean'"
```

### Step 3: Collect and Apply Fixes

After all detection agents complete:

1. Collect all findings by file
2. For each file with findings, apply the edits using the Edit tool
3. Keep changes minimal - only remove clear slop

## Slop Patterns Reference

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
if (!userInput) {
  return;
}

// GOOD: Legitimate type assertion with reason
const data = response as ApiResponse; // API guarantees this shape
```

## Output

Provide a 1-3 sentence summary:

- Files cleaned: [count]
- Changes made: [brief list]

No lengthy explanations.
