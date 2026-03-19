# Context Prune

Proactively manage context window health during long coding sessions.

## When to use

- When you notice the model repeating itself, losing track of the task, or making errors that suggest stale context
- When you've done a lot of exploratory reading and want to slim down before the real work
- Before a complex multi-step operation where you need maximum context headroom
- When the PreCompact hook reports large outputs consuming context

## Context triage rules

### Always preserve (full fidelity)
- The current task description and any user corrections
- Uncommitted code changes (diffs, not full files)
- The most recent test/build output
- Active error messages being debugged
- Decisions: "we chose X because Y"
- File paths and line numbers relevant to current work

### Compress to key facts
- Earlier file reads → "File X contains auth middleware using JWT, key functions: validateToken (L45), refreshToken (L120)"
- Build/test history → "Tests: 42 pass, 3 fail (auth.test.ts L78, L92, L105)"
- Exploration results → "Searched for rate limiting: found in middleware/rateLimit.ts and config/limits.json"

### Drop aggressively
- Full file contents that were read for a few lines
- npm/pip install output
- Verbose build logs (keep only errors)
- `ls`, `find`, `tree` output from exploration
- Failed approaches: "tried X, didn't work" (one line, not the full attempt)
- Duplicate reads of the same file
- Git log/diff output from orientation (keep findings, drop raw output)

## Execution

1. Assess what's in context using the triage rules above
2. Check `~/.claude/context-reports/` for the latest health report
3. Construct specific compaction instructions
4. Run `/compact <instructions>`

## Example compaction instructions

### After exploration phase
```
/compact Keep: the implementation plan for user auth, the schema design in db/schema.ts (tables: users, sessions, tokens), and the failing test at auth.test.ts:78 (expects 401, gets 500). Drop: all full file reads, package.json contents, directory listings, and npm install output. Compress exploration to one-line summaries per file examined.
```

### Mid-implementation
```
/compact Keep: all code changes made this session (auth middleware, token validation, session cleanup), the 3 failing tests and their error messages, and the decision to use sliding-window refresh tokens. Drop: everything before the implementation started — all codebase exploration, earlier test runs, and the initial planning discussion.
```

### After debugging
```
/compact Keep: the root cause (race condition in token refresh when concurrent requests hit the middleware), the fix applied (mutex lock in validateToken), and verification that all 45 tests pass. Drop: all intermediate debugging — the 8 hypothesis tests, console.log additions/removals, and strace output.
```
