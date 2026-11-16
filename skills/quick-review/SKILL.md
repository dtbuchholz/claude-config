---
name: quick-review
description: >
  Comprehensive single-pass code review of a small-to-medium change, with no subagents. Covers bugs,
  security, error handling, tests, types, comments, and simplification in one sweep. Use for
  everyday diffs and quick pre-commit checks; use /pr-review for large or high-risk changes.
argument-hint: "[range:<git-range>] [focus areas...]"
---

# Quick Review

Review the change yourself, in this session, in one pass. Same rigor and lenses as `/pr-review`,
without spawning reviewer agents. Do not use the Agent tool.

## Arguments

- `range:<git-range>` - review an explicit range, e.g. `range:HEAD~3..HEAD`
- Focus areas (optional, any of): `bugs`, `security`, `errors`, `tests`, `types`, `comments`,
  `simplify`. Default is all lenses. Named areas get extra depth; the others still get a quick pass.

## 1. Determine Scope

1. If `range:<git-range>` was given, use `git diff <range>`.
2. Else detect the default branch:
   `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`, falling
   back to whichever of `main` or `master` exists locally.
3. If the current branch has commits ahead of the default branch, use `git diff <base>...HEAD`.
4. Else if the working tree is dirty, review `git diff --cached` plus `git diff`, and list untracked
   files from `git status --porcelain` (read new files in full).
5. Else stop: nothing to review.

Run `git diff --stat` for the chosen scope first. **Escalate** if the change is large (roughly 800+
changed lines or 20+ files) or touches auth, payments, migrations, or concurrency in non-trivial
ways: tell the user `/pr-review` is a better fit and ask whether to continue anyway.

## 2. Gather Context

- Read the full diff.
- Read each changed file in full (or the surrounding functions, for very long files). Diff hunks
  alone hide callers, invariants, and the error paths a change breaks.
- Read the root `CLAUDE.md` / `AGENTS.md` and any in directories containing changed files. Keep only
  guidance relevant to review (conventions, patterns, prohibitions).
- For changed function signatures or exported symbols, grep for call sites.

## 3. Review Through Each Lens

Walk the diff once per lens. Only flag issues on added or modified lines (or behavior they break
elsewhere, such as a call site the change invalidates). Never flag pre-existing problems in
untouched code.

| Lens         | Look for                                                                                          |
| ------------ | ------------------------------------------------------------------------------------------------- |
| **Bugs**     | Logic errors, off-by-one, wrong conditions, null/undefined paths, races, broken call sites        |
| **Security** | Injection, unvalidated input, secrets in code, authz gaps, unsafe deserialization, path traversal |
| **Errors**   | Swallowed exceptions, empty catches, missing error propagation, misleading fallbacks              |
| **Tests**    | New behavior without tests, untested edge cases, tests that can't fail or assert the wrong thing  |
| **Types**    | Overly broad types (`any`, `object`), unenforced invariants, unsafe casts (typed languages only)  |
| **Comments** | Comments or docs that contradict the code, stale docstrings, outdated README/CLAUDE.md claims     |
| **Simplify** | Needless abstraction, dead code, duplication of an existing repo helper (grep before claiming)    |

Also check the change against the CLAUDE.md guidance gathered in step 2.

## 4. Verify and Filter

For every candidate finding, re-read the relevant code and confirm it before reporting. Assign a
confidence score:

- 91-100: confirmed with evidence (you can name the input or state that triggers it)
- 75-90: very likely real and impactful
- below 75: drop it

Drop anything that is:

- Pre-existing or on unmodified lines
- Caught by a linter, formatter, or typechecker (assume CI runs them)
- A style preference not stated in project guidelines
- An intentional behavior change that fits the feature
- Silenced by an explicit lint-ignore with a reason

## 5. Report

Findings first. Keep it compact.

```markdown
# Quick Review

**Scope:** [branch diff vs main | working tree | range] · **Files:** N · **Issues:** N

## Critical (≥ 91)

- `file:line` — Issue. Failure scenario: [concrete input/state → wrong result].

## Important (75-90)

- `file:line` — Issue. Suggested fix: [one line].

## Notes

- [Optional: lenses that were clean, or coverage gaps such as "did not run tests"]
```

- Omit empty sections. If nothing survives filtering, say `No significant issues found.` and list
  which lenses were checked.
- Do not edit files. After reporting, offer to apply the fixes.
