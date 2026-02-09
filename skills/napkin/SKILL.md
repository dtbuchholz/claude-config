---
name: napkin
description: Per-repo mistake and correction tracking, always active.
---

# Napkin

You maintain a per-repo markdown file that tracks mistakes, corrections, and patterns that work or
don't. You read it before doing anything and update it continuously as you work — whenever you learn
something worth recording.

**This skill is always active. Every session. No trigger required.**

## Session Start: Read Your Notes

First thing, every session — read `.claude/napkin.md` before doing anything else. Internalize what's
there and apply it silently. Don't announce that you read it. Just apply what you know.

If no napkin exists yet, create one at `.claude/napkin.md`:

```markdown
# Napkin

## Corrections

- (log mistakes and what to do instead)

## User Preferences

- (accumulate here as you learn them)

## Patterns That Work

- (approaches that succeeded)

## Patterns That Don't Work

- (approaches that failed and why)

## Domain Notes

- (project/domain context that matters)
```

## What to Log and When

Update the napkin as you work — not just at session start and end. Log anything that would change
your behavior if you read it next session:

- **You hit an error and figure out why.** Log it immediately. Don't wait.
- **The user corrects you.** Log what you did and what they wanted instead.
- **You catch your own mistake.** Log it. Your mistakes count the same as user corrections — maybe
  more, because you're the one who knows what went wrong internally.
- **You try something and it fails.** Log the approach and why it didn't work so you don't repeat
  it.
- **You try something and it works well.** Log the pattern.
- **Tool/environment surprises.** Things about this repo, its tooling, or its patterns that you
  didn't expect.
- **Preferences.** How the user likes things done — style, structure, process.
- **You re-read the napkin mid-task** because you're about to do something you've gotten wrong
  before. Good. Do this.

Be specific. "Made an error" is useless. "Assumed the API returns a list but it returns a paginated
object with `.items`" is actionable.

The napkin is a living document. Treat it like working memory that persists across sessions, not a
journal you write in once.

## Format

Use bullet lists, not tables. Tables break with long text. Each entry should include the date,
source (self or user), and enough context to be actionable:

```markdown
## Corrections

- **2026-02-06 (self)**: Passed (name, id) to createUser but signature is (id, name). Do instead:
  Check function signatures before calling — this codebase doesn't follow conventional arg ordering.
- **2026-02-06 (user)**: Used relative imports. Do instead: This repo uses absolute imports from
  `src/` — always.
```

## Napkin Maintenance

Every 5-10 sessions, or when the file exceeds ~150 lines, consolidate:

- Merge redundant entries into a single rule.
- Promote repeated corrections to User Preferences.
- Remove entries that are now captured in the project's CLAUDE.md or other permanent instructions.
- Archive resolved or outdated notes.
- Keep total length under 200 lines of high-signal content.

A 50-line napkin of hard-won rules beats a 500-line log of raw entries.
