---
name: memory-rollup
description: >
  Review and maintain Claude Code memory files. Prunes stale entries, extracts patterns, promotes
  cross-project learnings to global memory, and updates MEMORY.md files. Run manually or via cron.
---

# Memory Rollup

Review, prune, and consolidate Claude Code memory files across projects and global memory.

## When This Skill Applies

- User explicitly says "/memory-rollup"
- Do NOT activate automatically — this skill requires explicit invocation

## Memory Layout

Claude Code stores memory in two scopes:

- **Global**: `~/.claude/memory/MEMORY.md` (+ topic files) — loaded into every session
- **Project**: `~/.claude/projects/<project-hash>/memory/MEMORY.md` (+ topic files) — loaded only in
  that project's sessions

MEMORY.md files are auto-loaded into the system prompt. Lines after 200 are truncated, so they must
stay concise. Topic files (e.g., `debugging.md`, `patterns.md`) are not auto-loaded but can be read
on demand.

## Execution

### Step 1: Discover

Scan for all memory files:

```bash
# Global memory
ls -la ~/.claude/memory/ 2>/dev/null

# All project memory directories with content
for d in ~/.claude/projects/*/memory/; do
  if [ -d "$d" ] && [ "$(ls -A "$d" 2>/dev/null)" ]; then
    echo "=== $d ==="
    ls -la "$d"
  fi
done
```

Read every MEMORY.md and topic file found. Build an inventory:

| Project | MEMORY.md | Topic Files | Line Count | Last Modified |
| ------- | --------- | ----------- | ---------- | ------------- |

### Step 2: Audit Each Project's Memory

For each project that has memory files, evaluate:

1. **Staleness** — Does the entry reference files, APIs, versions, or patterns that may no longer
   exist? Check against the project's current state if the project directory is accessible:
   ```bash
   # Derive project path from the hash (e.g., -Users-jane-myapp → /Users/jane/myapp)
   # Check if the project directory still exists
   ls -la <derived-path> 2>/dev/null
   ```
2. **Accuracy** — Do version numbers, file paths, or command references still match reality? Spot
   check 2–3 concrete claims per file (e.g., does that file still exist at that line number?).
3. **Density** — Is the MEMORY.md under 200 lines? Is information well-organized or rambling?
4. **Duplication** — Are entries repeated across MEMORY.md and topic files, or across projects?

### Step 3: Prune and Consolidate

For each project memory file:

- **Remove** entries that reference deleted projects, outdated versions, or resolved bugs
- **Merge** duplicate entries
- **Move** detailed notes from MEMORY.md into topic files if MEMORY.md exceeds 150 lines
- **Keep** MEMORY.md as a concise index pointing to topic files for details

Log proposed changes, then apply them directly. Format the log as:

```
## [Project Name]

### Remove (stale/resolved)
- "Known bug in X" — X was fixed in commit abc123

### Move to topic file
- Move "Docker Sandbox CLI" section → docker.md (saves 15 lines in MEMORY.md)

### Update
- Version 1.2 → 1.4 (confirmed in package.json)
```

Apply all changes immediately after logging them.

### Step 4: Cross-Project Pattern Extraction

After auditing all projects, look for patterns that appear across 2+ projects:

- Same debugging technique used in multiple repos
- Common architectural decisions or conventions
- Repeated tool configurations or workflow preferences
- Recurring pitfalls or gotchas

These are candidates for **global memory** (`~/.claude/memory/`).

Present candidates:

```
## Global Memory Candidates

### Pattern: [name]
- Seen in: [project A], [project B]
- Summary: [one line]
- Proposed file: ~/.claude/memory/[topic].md
```

Apply global memory changes directly after logging them.

### Step 5: Summary

Display a final report:

```
Memory Rollup Complete
─────────────────────
Projects scanned:     ___
Projects with memory: ___
Entries pruned:       ___
Entries updated:      ___
Topic files created:  ___
Global patterns added: ___
MEMORY.md total lines: ___ (global), ___ avg (project)
```

## Rules

- Never delete a memory file entirely — prune entries, don't remove files
- Keep MEMORY.md files under 150 lines (hard cap at 200 due to system prompt truncation)
- Prefer topic files for detailed notes; MEMORY.md should be an index
- When unsure if something is stale, ask rather than delete
- If a project directory no longer exists on disk, flag it but don't auto-delete its memory — the
  user may have moved or archived the project
- Do not add new learnings during this skill — only reorganize existing ones
