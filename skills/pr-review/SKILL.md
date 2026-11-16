---
name: pr-review
description:
  Comprehensive multi-agent PR review with up to 7 specialist reviewers (code, security, error
  handling, tests, types, comments, simplification), selected to fit the diff. Use for large or
  high-risk changes; use /quick-review for small ones.
argument-hint:
  "[aspects...] [range:<r>|base:<ref>|uncommitted] [plan:<path>] [lockfiles] [sequential]"
---

# Comprehensive PR Review

Run a thorough review using specialized reviewer agents over one frozen diff packet, then filter,
merge, and report the findings yourself.

## Arguments

Reviewer aspects (default `all`; applicability rules in step 3 still apply):

- `code` - bugs, logic, project-guideline compliance, and plan conformance
- `security` - vulnerabilities
- `errors` - silent failures and error handling
- `tests` - test coverage and quality
- `types` - type design and invariants
- `comments` - comment and documentation accuracy
- `simplify` - simplification and reuse of existing code
- `all` - every applicable reviewer

Options:

- `range:<git-range>` / `base:<ref>` / `uncommitted` - force a scope (default: auto, see step 1)
- `plan:<path>` - a spec, plan, or acceptance-criteria file the diff should implement
- `lockfiles` - include lockfiles (excluded by default)
- `sequential` - run reviewers one at a time instead of in parallel

```
/pr-review                          # Full review, auto scope
/pr-review tests errors             # Only test coverage and error handling
/pr-review plan:docs/plan.md        # Also check the diff against the plan
/pr-review base:develop lockfiles   # Branch vs develop, lockfiles included
```

## 1. Build the Frozen Packet

Use the shared packet builder. Never assemble the diff by hand: hand-built diffs miss untracked
files.

```bash
S="<your session scratchpad dir, or $(mktemp -d) if none is listed>"
~/.claude/scripts/review-packet.sh build "$(pwd)" --out-dir "$S/review/packet" \
  [--range <r> | --base <ref> | --uncommitted] [--include-lockfiles] [--plan <path>]
```

Pass `--plan <path>` whenever `plan:<path>` was given. The script copies the plan into the packet as
`plan.md`, so reviewers read a frozen copy, and it fails if the file doesn't exist; stop and say so.
A plan file inside the repo is excluded from the diff (reason `plan`).

It prints `key=value` lines. Keep `packet`, `sha256`, `bytes`, `scope_label`, `files`, `excluded`,
`docs_only`, `typed`, and (with a plan) `plan` and `plan_sha256` for later steps.

- **Auto scope:** branch changes vs the default branch (committed, uncommitted, and untracked) when
  HEAD is ahead of it; otherwise uncommitted changes including untracked files; otherwise the script
  exits with "nothing to review", so stop and tell the user.
- **Lockfiles** are excluded by default and listed in `excluded-files.tsv` next to the packet. If
  the script reports that every file was excluded, ask whether to rerun with `lockfiles`.
- The whole packet directory is read-only. Do not write into it (no scratch files, no probes);
  `verify` treats any added, removed, or edited file there as tampering.

## 2. Gather Guidelines and Plan

- Read the root `CLAUDE.md` / `AGENTS.md` and any in directories containing changed files
  (`changed-files.txt`). Summarize only review-relevant guidance (conventions, patterns,
  prohibitions) as `guideline_summary`.
- If a plan was given, read the frozen copy (`plan` from step 1) in full as `plan_text`, not the
  original path.

## 3. Select Reviewers

Start from the requested aspects, then drop reviewers that have nothing to check:

| Diff shape                                                     | Run                                             |
| -------------------------------------------------------------- | ----------------------------------------------- |
| `docs_only=true`                                               | `comment-analyzer`, `code-reviewer`             |
| Code diff only changing comments/docstrings (check the packet) | `comment-analyzer`, `code-reviewer`             |
| `typed=false` and no type hints/annotations in the diff        | skip `type-design-analyzer`                     |
| Config, CI, or build files only                                | skip `pr-test-analyzer`, `type-design-analyzer` |
| Diff with no tests and no testable logic (pure wiring/rename)  | skip `pr-test-analyzer`                         |

`code-simplifier` runs only when a code reviewer is running and the diff contains code. Record every
skipped reviewer and the reason for the report.

## 4. Choose Delivery Mode

- **Inline** (`bytes` ≤ 24000): paste the full packet into every reviewer prompt under
  `Diff to review:`.
- **Packet file** (`bytes` > 24000): give each reviewer the packet path and `sha256` instead. Each
  reviewer must run `shasum -a 256 <packet>` before reading it and stop with `PACKET HASH MISMATCH`
  if the hash differs. Reviewers may read `index.tsv` and the per-file diffs in `diffs/` to work
  file by file.

The plan follows the same rule: paste `plan_text` in inline mode when it is 8000 bytes or less;
otherwise (and always in packet-file mode) give its path and `plan_sha256` and have reviewers check
that hash too.

Pick the mode once, before dispatching anyone. Every first-wave reviewer gets the same packet.

## 5. Dispatch Reviewers

Use `Agent (subagent_type: general-purpose)` for every reviewer. (Explore reads only excerpts and is
not suited to reviewing.) Launch the first wave in parallel (or one at a time with `sequential`),
excluding `code-simplifier`. Create a work dir per reviewer: `mkdir -p "$S/review/work/<reviewer>"`.

Prompt template:

```
Agent (subagent_type: general-purpose): "[REVIEWER] REVIEW

Scope: <scope_label> (<files> files). Excluded from review: <excluded list or 'none'>.

CRITICAL: Only report issues on lines ADDED or MODIFIED in this diff (+ lines), or behavior those
lines break elsewhere (for example, a call site the change invalidates). Do NOT report pre-existing
issues in unchanged code. An unchanged line counts only when this diff makes it wrong (a comment
or doc whose behavior the diff changed, or a sentence the diff half-edited); cite the nearest
changed line and say which unchanged line goes stale.

Rules for what you may run:
- Do not modify the repository: no file edits, no installs, no git commands that change state
  (add, commit, checkout, switch, restore, reset, stash, clean, worktree).
- You may run read-only commands (read files, grep, git log/show/diff/blame) and the project's
  existing test, lint, typecheck, and build commands as they are. A build may write only to the
  project's gitignored build output (for example dist/ or build/).
- Run `git status --porcelain` before and after any test, lint, typecheck, or build command. If the
  output changed, stop running commands and report what changed.
- Experiments that need changed code (mutating code to see whether a test catches it) happen only
  on copies inside your work dir W=<S>/review/work/<reviewer>. Copy only the files you need.
  Any deletion must be guarded: rm -rf "${W:?}/<path>". Never delete anything outside W.
- Never write inside the packet directory.

Project guidelines:
<guideline_summary>

[If plan given, pasted] Plan / acceptance criteria:
<plan_text>

[If plan given, by path] Plan / acceptance criteria: read <plan path>. First run
`shasum -a 256 <plan path>` and confirm it equals <plan_sha256>; if not, reply only
`PACKET HASH MISMATCH`.

[Inline mode] Diff to review:
<packet contents>

[File mode] Diff to review: read <packet path>. First run `shasum -a 256 <packet path>` and
confirm it equals <sha256>; if not, reply only `PACKET HASH MISMATCH`.

<reviewer-specific focus from 'Reviewers' below>

For each issue give file:line, description, a concrete failure scenario, and two separate scores.

Confidence (0-100), how sure you are the issue is real:
  91-100 confirmed with evidence (reproduced, mutation-tested, or traced end to end)
  75-90 very likely real · 55-74 plausible, worth a human look · below 55 omit it

Severity, how much it matters if real (independent of confidence):
  high - wrong results, crashes, data loss or corruption, a security exposure, or an explicit plan
         requirement violated
  medium - a realistic bug in an edge case or race, a misleading API contract, or a missing test
         for a stated requirement
  low - maintainability, naming, duplication, docs, or a rare race with a benign outcome

Output format, one per line:
[CONFIDENCE: XX] [SEVERITY: high|medium|low] file:line - description - failure scenario"
```

Then wait until every first-wave reviewer has finished or failed before continuing.

## 6. Drift Check, Simplifier, Drift Check

The packet is frozen, but reviewers also read the live checkout. Check that the checkout still
matches the packet:

```bash
~/.claude/scripts/review-packet.sh verify "$S/review/packet"
```

- `status=ok`: continue.
- `status=drift`: the listed `drifted=` files changed during review. Continue, but mark the report
  **drifted** and list those files; findings on them may be stale. A new untracked file in the
  checkout shows up here too, which is how a reviewer that wrote into the repo gets caught.
  `drifted=plan:<path>` means the plan changed after it was frozen; reviewers used the frozen copy.
- `status=tampered`: something in the packet directory was added, removed, or changed (listed as
  `tampered=` lines). Stop and report; do not synthesize.

Run the check **before** dispatching `code-simplifier` and again **before** the final summary.

Launch `code-simplifier` last with the same packet (same delivery mode), the changed-file list, and
a short summary of first-wave findings you expect to keep, so it doesn't suggest simplifications
that conflict with fixes.

## 7. Merge, Score, and Filter

You own synthesis. Do not delegate it.

1. Drop any reviewer output that says `PACKET HASH MISMATCH`, and count that reviewer as failed.
2. **Merge duplicates.** Findings match when they point at the same file and overlapping or nearby
   lines (±5, or the same function) with the same root cause.
3. **Corroboration boost.** A finding reported independently by n ≥ 2 reviewers gets confidence
   `min(95, max_reported + 10 × (n − 1))`. Note `(n reviewers)` on it. The boost raises confidence
   only; take the highest reported severity and re-judge it in step 4.
4. **Verify** every finding at confidence 75 or above by re-reading the code it cites. Lower or drop
   findings that don't hold up, and re-judge severity against the definitions in the prompt
   template: reviewers tend to over-rate severity for issues in their own specialty.
5. **Bucket** by both scores. Confidence says whether it is real; severity says whether it matters:

   | Bucket                        | Confidence | Severity       |
   | ----------------------------- | ---------- | -------------- |
   | Critical                      | ≥ 91       | high           |
   | Important                     | ≥ 75       | high or medium |
   | Below threshold, worth a look | ≥ 55       | any            |
   | drop                          | < 55       | any            |

   Take the first row that matches. A confirmed low-severity issue lands in "worth a look", not
   Important, and a confirmed missing test lands in Important, not Critical, unless it violates an
   explicit plan requirement (high). Keep "worth a look" to at most 5 entries, highest confidence ×
   severity first, one line each.

6. Drop regardless of score: pre-existing issues, issues on lines the diff neither changed nor made
   wrong (see the unchanged-line rule in the prompt template), issues a linter or typechecker would
   catch, style points not in project guidelines, and intentional behavior changes that fit the
   feature.

## 8. Report

Findings first. Omit empty sections.

```markdown
# PR Review Summary

**Scope:** <scope_label> · **Files:** N · **Reviewers:** N of M completed (skipped: x — reason) ·
**Drift:** none | drifted: <files> · **Issues:** N (from R raw findings)

**Excluded from review:** <files and reasons, or omit when none>

## Critical (confidence ≥ 91, high severity)

- `file:line` — Issue. Failure: <scenario>. (n reviewers)

## Important (confidence ≥ 75, high or medium severity)

- `file:line` — Issue. Suggested fix: <one line>.

## Below threshold, worth a look

- `file:line` — One line.

## Plan conformance

- <Only with plan:...> Missing, extra, or divergent behavior vs the plan.
```

- If any reviewer failed, put **Partial review** at the top and name the failed reviewers.
- If nothing reaches Important or Critical, say `No significant issues found.` and still show the
  below-threshold section if it has entries.
- Do not edit files. Offer to apply fixes after the report.

## Reviewers

### code-reviewer

- CLAUDE.md / AGENTS.md compliance
- Bugs, logic errors, behavior regressions, broken call sites
- With `plan:` — checks the diff matches the plan: missing requirements, extra unrequested behavior,
  and behavior that diverges from the spec

### security-reviewer

- Injection (SQL, shell, path traversal), XSS, unsafe deserialization
- Hardcoded secrets, authz gaps, missing input validation

### silent-failure-hunter

- Swallowed exceptions, empty catches, misleading fallbacks
- Missing error propagation or logging

### pr-test-analyzer

- New behavior without tests, missing edge cases
- Tests that can't fail or assert the wrong thing (mutation experiments go in W only)

### type-design-analyzer

- Overly broad types, unsafe casts, unenforced invariants (typed code only)

### comment-analyzer

- Comments and docs that contradict the code; stale docstrings, READMEs, CLAUDE.md claims

### code-simplifier

- Needless complexity or abstraction, dead code
- **Reinvented wheels:** search the wider repo (not just the diff) for existing helpers, constants,
  or patterns the new code duplicates before reporting
- Always runs last (see step 6)
