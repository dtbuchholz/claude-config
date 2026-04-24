---
name: pr-review
description:
  Comprehensive PR review using 7 specialized agents for code quality, security, error handling,
  tests, types, comments, and simplification.
argument-hint: "[review-aspects]"
---

# Comprehensive PR Review

Run a thorough pull request review using multiple specialized agents, each focusing on a different
aspect of code quality.

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
- `sequential` - Run agents one at a time instead of in parallel

**Examples:**

```
/pr-review                    # Full review, parallel (default)
/pr-review tests errors       # Only test coverage and error handling
/pr-review simplify           # Just code simplification
/pr-review all sequential     # Full review, one agent at a time
```

## Review Scope

The skill supports three review scopes:

| Scope                     | Trigger                                                       | Diff command                                                 |
| ------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------ |
| **Branch diff** (default) | On a feature branch with commits ahead of base                | `git diff <base>...HEAD`                                     |
| **Working tree**          | Uncommitted local changes exist                               | `git diff --cached --no-ext-diff` + `git diff --no-ext-diff` |
| **Explicit range**        | User passes a git range, e.g. `/pr-review range:HEAD~3..HEAD` | `git diff <range>`                                           |

Detection order:

1. If the user supplies `range:<git-range>`, use that range.
2. Else detect the default branch:
   `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`, falling
   back to whichever of `main` or `master` exists locally.
3. If the current branch has commits ahead of the default branch, use the branch diff.
4. If the working tree is dirty (`git status --porcelain`), review uncommitted changes.
5. If none of the above, stop and tell the user there is nothing to review.

## Review Workflow

### 1. Gather Context

```bash
# Detect default branch
default_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')"
if [[ -z "$default_branch" ]]; then
  default_branch="$(git branch --list main master | head -1 | tr -d ' ')"
fi

# Branch diff (default scope)
git diff --name-only "${default_branch}...HEAD"
git diff "${default_branch}...HEAD"

# Working tree scope (when no branch commits)
git diff --cached --no-ext-diff
git diff --no-ext-diff

# Explicit range scope
git diff --name-only "<range>"
git diff "<range>"
```

CRITICAL: Agents must only review lines present in the gathered diff.

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

### 3. Compile Review Packet Before Dispatch

Before dispatching any reviewer, assemble the entire review packet once:

- `review_diff` - the exact diff payload for this run
- `changed_files` - the exact changed-file list for this run
- `guideline_summary` - the relevant CLAUDE.md guidance for this run
- `diff_chunks` - if chunking is needed, the full chunk plan for this run
- `dispatch_plan` - the exact reviewer batching plan for this run
- `prompt_budget` - the prompt-size strategy for this run

Prompt construction rules:

- Do not assemble reviewer prompts lazily inside the dispatch loop.
- If chunking is required, decide all chunks before the first `Task` dispatch.
- Estimate prompt size before dispatch. If the full first wave will exceed tool or context payload
  limits, choose a smaller frozen diff representation before dispatching anyone.
- Prefer this fallback order when prompt size is too large:
  - `git diff --unified=0 --no-ext-diff` for a compact modified-lines-only packet
  - per-file or per-chunk diff slices
  - planned reviewer batching with the same frozen packet
- Build the full prompt string for every first-wave reviewer before dispatching any of them.
- Validate every prompt before dispatch:
  - it contains the agent-specific instructions
  - it contains `Diff to review:`
  - it contains the exact diff payload or exact diff chunk for that reviewer
  - it does not rely on "same diff as above" or similar shorthand
- If reviewer batching is needed for payload reasons, decide all batches up front and keep the same
  frozen review packet across those batches.
- Do not start with a full parallel wave and only later fall back to compact diffs or per-reviewer
  dispatch. Choose the dispatch plan before the first reviewer is launched.
- If any prompt fails validation, stop and rebuild the full prompt set before dispatching anyone.
- Treat the compiled prompt set as frozen for the review wave. Every first-wave reviewer should see
  the same review packet except for its agent-specific instructions and any explicit chunk
  assignment.

Reference preflight pattern:

```text
review_packet = gather_context_once()
review_packet = shrink_or_chunk_if_needed(review_packet)
review_prompts = build_all_first_wave_prompts(review_packet)
dispatch_plan = plan_batches_if_needed(review_prompts)

for prompt in review_prompts:
  assert prompt contains "Diff to review:"
  assert prompt contains exact assigned diff payload
  assert prompt does not contain placeholder text or implicit diff references
  assert prompt fits within payload budget

assert dispatch_plan is final before first dispatch

only after all prompts pass:
  dispatch first-wave reviewers using dispatch_plan
```

If a prompt-integrity failure is discovered after dispatch, close or discard the entire affected
wave and restart from the same frozen review packet rather than mixing old and new reviewer
contexts.

### 4. Launch Review Agents

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

**Parallel** (default): Launch all agents at once for speed.

**Sequential** (with `sequential` arg): Run one at a time for easier reading/action.

Use `Task (subagent_type: Explore)` for all review agents — they are read-only.

If the diff is too large to pass in one prompt, split by changed file and send per-file diff chunks
to separate agents, then merge results.

Prompt integrity rules:

- Every agent prompt must include an explicit diff payload.
- Never say "same diff as above" or rely on implicit/shared context across agents.
- If chunking is required, include the exact chunk in that agent's prompt and clearly label it.

For each agent, use this template:

```
Task (subagent_type: Explore): "[AGENT_NAME] REVIEW

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

Execution discipline:

- Launch all review agents except `code-simplifier` in parallel unless `sequential` was requested.
- If payload limits require batching, execute the preplanned first-wave batches in order. This is
  still one logical first wave, not an ad hoc restart.
- Treat completion as a hard barrier: do not synthesize until every first-wave reviewer has finished
  or been explicitly discarded.
- Before dispatching `code-simplifier`, make sure completed first-wave reviewer threads are closed
  or otherwise no longer consuming dispatch capacity.
- Do not launch `code-simplifier` while first-wave reviewer threads are still open if the
  client/runtime keeps them active after completion.
- If dispatch capacity is still exhausted after the first wave resolves, close completed reviewers,
  confirm their results are captured locally, and only then dispatch the simplifier pass.
- After the first review phase completes, launch `code-simplifier` last with:
  - the changed file list
  - the diff payload
  - a brief summary of accepted findings from the other agents
- Do not delegate synthesis; parent agent owns final filtering and summary.

### 5. Filter Results

After collecting all agent responses:

- First state completion status: `N of N agents completed` and list any failed/discarded reviewers.
- If not all agents completed successfully, mark the output as partial and include unresolved or
  discarded reviewer slots.

**Only report issues with confidence ≥ 75%.**

Filter out:

- Pre-existing issues (not in the diff)
- Issues a linter/typechecker would catch (assume CI runs these)
- Pedantic nitpicks a senior engineer wouldn't flag
- Style issues not explicitly in CLAUDE.md
- Issues on lines the user didn't modify
- Intentional changes related to the broader feature

### 6. Aggregate Results

Create a concise findings-first summary with only high-confidence issues:

Required synthesis rules:

- Start with agent completion status: `N of N agents completed` and list any
  failed/discarded/unresolved reviewers.
- If not all agents completed successfully, mark the review as **partial** at the top.
- Present findings before any overview, passed checks, or strengths.
- Preserve the confidence distinction in the final report:
  - `Critical Issues` for confidence `>= 91`
  - `Important Issues` for confidence `75-90`
- Omit empty issue sections.
- If no issues pass the confidence threshold, say `No significant issues found.`
- `Passed Checks` is optional but recommended when it adds clarity about what was reviewed cleanly.
- `Strengths` is optional and should stay brief; never bury findings under praise or summary.

```markdown
# PR Review Summary

**Agent completion:** N of N completed **Files reviewed:** [count] **Issues found:** [count]
(filtered from [total] raw findings)

## Critical Issues (confidence ≥ 91)

- [file:line] Issue description

## Important Issues (confidence 75-90)

- [file:line] Issue description

## Passed Checks

- [list of agents that found no issues]

## Strengths

- [what's done well in this change]
```

Preferred behavior:

- Keep the final synthesis compact.
- Findings should read as direct reviewer output, not a long narrative.
- If `Passed Checks` or `Strengths` would be empty or low-signal, omit them rather than padding the
  report.

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

**Skip** when the diff only touches untyped languages (plain JS, Python without type hints, shell
scripts, etc.). Check changed file extensions to decide.

### comment-analyzer

**Focus**: Documentation accuracy

- Comments that don't match code
- Outdated documentation
- Misleading comments

### code-simplifier

**Focus**: Code simplification and deduplication

- Overly complex code
- Unnecessary abstractions
- Opportunities to simplify
- **Reinvented wheels**: new code that duplicates existing utilities, helpers, or patterns already
  in the repo. Search the broader codebase (not just the diff) for similar functions, constants, or
  abstractions before reporting.

**Always run last.** This agent benefits from the other agents' findings — launch it after all other
agents complete, and include a summary of accepted findings so it doesn't suggest simplifications
that conflict with fixes. Include the list of changed files in the prompt so the agent can search
the rest of the repo for existing equivalents.

## False Positive Examples

Train agents to ignore these:

- Something that looks like a bug but isn't
- Issues a linter would catch (imports, formatting)
- General quality issues not in CLAUDE.md
- Issues silenced by lint-ignore comments
- Intentional functionality changes
- Real issues on lines NOT modified in the diff
