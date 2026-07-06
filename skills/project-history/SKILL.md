---
name: project-history
description: >
  Reconstruct a project's evolution timeline from git history, learnings, decisions, and
  conversations (build mode), or evaluate how well the development process was documented (eval
  mode). Writes into docs/history/ alongside repo-docs structure.
argument-hint: "[build|eval]"
---

# Project History

Mine git logs, learnings, decisions, and conversations to reconstruct a project's historical
narrative or evaluate process documentation quality. Complements repo-docs by writing into its
`docs/` hierarchy.

## When This Skill Applies

- `/project-history` or `/project-history build` — reconstruct project timeline (default)
- `/project-history eval` — evaluate process documentation quality
- User asks to "trace the project history", "build a timeline", "how was this project built",
  "evaluate our process", "audit our documentation practices"

## Guard

Must be inside a git repository with at least one commit:

```bash
git rev-parse --is-inside-work-tree && test "$(git rev-list --count HEAD 2>/dev/null)" -gt 0
```

If not in a git repo or no commits exist, tell the user and stop.

## Mode Detection

- If the argument is `eval`, run **Eval Mode**
- Otherwise (no argument, `build`, or anything else), run **Build Mode**

## Output Location

Writes into `docs/history/` — works alongside repo-docs at any tier:

```
docs/
├── history/           ← this skill
│   ├── TIMELINE.md    ← build mode
│   └── EVAL-REPORT-YYYY-MM-DD.md ← eval mode
├── decisions/         ← read by both modes (existing ADRs)
└── ...                ← untouched
```

---

## Build Mode

### Step 1: Discover Sources

Check what source material is available. Run these checks:

```bash
# Commit count
git rev-list --count HEAD

# Tags
git tag --list

# Check for key files
test -f .claude/project-diary.md && echo "project-diary: yes" || echo "project-diary: no"
test -d docs/decisions && echo "ADRs: yes" || echo "ADRs: no"
test -f CHANGELOG.md && echo "CHANGELOG: yes" || echo "CHANGELOG: no"

# QMD availability
qmd search "test" -n 1 2>/dev/null && echo "QMD: yes" || echo "QMD: no"
```

Present a source inventory table to the user:

```markdown
| Source                 | Status                  | Details           |
| ---------------------- | ----------------------- | ----------------- |
| Git log                | Available               | N commits, M tags |
| Project diary          | Available / Missing     | N entries         |
| ADRs (docs/decisions/) | Available / Missing     | N records         |
| CHANGELOG              | Available / Missing     | —                 |
| QMD (conversations)    | Available / Unavailable | —                 |
```

### Step 2: Bootstrap Missing Files

**Create `docs/history/`** if it does not exist:

```bash
mkdir -p docs/history
```

If `docs/` does not exist at all, suggest the user run `/repo-docs init` to set up the full docs
structure — but continue regardless.

### Step 3: Parallel Mining

Launch 2-3 agents in a single message using `Task (subagent_type: Explore)`. The third agent
(Conversations) is only dispatched if QMD is available.

For repos with 1000+ commits, instruct agents to focus on the last 500 commits unless the user
explicitly requests full history.

**Agent 1 — Git Timeline:**

Prompt the agent to extract:

- Commit history with dates, authors, and messages (use `git log --format="%H|%ai|%an|%s"`)
- All tags with dates (`git tag --list --format="%(refname:short)|%(creatordate:short)"`)
- README and CHANGELOG change history (`git log --oneline -- README.md CHANGELOG.md`)
- Key file first-adds: identify when major files/directories first appeared
  (`git log --diff-filter=A --format="%ai|%s" -- <path>`)
- Monthly commit velocity (`git log --date=format:"%Y-%m" --format="%ad" | sort | uniq -c`)
- Contributor summary (`git shortlog -sn --no-merges`)

Tell the agent to return structured results: a chronological event list, tag list, milestone list,
and velocity table.

**Agent 2 — Learnings & Decisions:**

Prompt the agent to extract:

- All entries from .claude/project-diary.md with dates, topics, insights, and directives (if it
  exists)
- All ADRs from docs/decisions/ with status, date, and decision summary
- Correlate learnings to time periods where possible

Tell the agent to return: a dated list of learnings (with insight + directive), a dated list of
decisions (with rationale), and any cross-references between them.

**Agent 3 — Conversations** _(only if QMD is available):_

Prompt the agent to search for key project milestones using QMD:

```bash
qmd query "project decisions and milestones" -n 20 --md
qmd query "architecture changes" -n 10 --md
qmd query "major features implemented" -n 10 --md
```

Tell the agent to return: session dates, topics discussed, key decisions made in conversations that
may not appear in formal docs.

### Step 4: Correlate & Detect Phases

After all agents return, synthesize their results. Detect project phases heuristically using these
signals:

| Phase                  | Signals                                                                                                          |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Initialization**     | First commits, package manifest creation (package.json, pyproject.toml, Cargo.toml), initial directory structure |
| **Scaffolding**        | Config files (ESLint, Prettier, tsconfig), CI setup, linter/formatter configs, test framework setup              |
| **Core Feature Build** | Sustained velocity, new modules/directories appearing, `feat:` conventional commits                              |
| **Stabilization**      | `fix:` commits increasing, test file growth, `refactor:` commits, coverage improvements                          |
| **Release**            | Version tags, CHANGELOG entries, version bumps in manifests                                                      |
| **Maintenance**        | Low velocity, mostly `fix:` and `chore:` commits, dependency updates                                             |

For each detected phase, identify:

- Start/end commit SHAs and dates
- Dominant commit types
- Key events (file additions, decisions, learnings)
- Confidence level (high/medium/low)

**Present detected phases to the user for confirmation before writing.** Phases are heuristic — the
user knows ground truth. Show a table:

```markdown
| Phase              | Date Range              | Commits | Confidence | Key Event                    |
| ------------------ | ----------------------- | ------- | ---------- | ---------------------------- |
| Initialization     | YYYY-MM-DD – YYYY-MM-DD | N       | high       | Initial commit, package.json |
| Core Feature Build | YYYY-MM-DD – YYYY-MM-DD | N       | medium     | Added auth module            |
| ...                | ...                     | ...     | ...        | ...                          |
```

Ask the user to confirm, merge, split, rename, or reorder phases before proceeding.

### Step 5: Generate Timeline

After user confirms phases, write `docs/history/TIMELINE.md` with a dual-audience format.

**Human-readable top section:**

```markdown
# Project Timeline

> [One-paragraph summary: what this project is, how it evolved, key milestones]

## Timeline at a Glance

| Phase   | Date Range | Commits | Key Event |
| ------- | ---------- | ------- | --------- |
| [phase] | [range]    | [count] | [event]   |

## Phase Details

### [Phase Name] (YYYY-MM-DD – YYYY-MM-DD)

**What Happened:** [Narrative paragraph describing this phase]

**Key Commits:** | Date | SHA | Message | |------|-----|---------| | [date] | [short SHA] |
[message] |

**Decisions:**

- [Decision summary with link to ADR if applicable]

**Learnings:**

- [Learning summary with insight]

**Architecture Changes:**

- [Structural changes: new directories, major refactors]

---

[Repeat for each phase]

## Architecture Evolution

**Initial structure:** [Tree snapshot from earliest commits]

**Current structure:** [Current tree, annotated with when major directories appeared]

**Structural changes:**

- [YYYY-MM-DD] Added [directory/module] — [reason]

## Metrics

| Metric                | Value                 |
| --------------------- | --------------------- |
| Total commits         | [N]                   |
| Date range            | [first] – [last]      |
| Contributors          | [N]                   |
| Tags/releases         | [N]                   |
| ADRs                  | [N]                   |
| Learnings captured    | [N]                   |
| Peak monthly velocity | [N] commits ([month]) |
```

**AI context section at the bottom:**

```markdown
---

<!-- AI CONTEXT — structured data for programmatic consumption -->

## Source Correlation Map

| Learning/Decision | Date   | Related Commits | Phase   |
| ----------------- | ------ | --------------- | ------- |
| [entry]           | [date] | [SHAs]          | [phase] |

## Documentation Gaps

| Period  | Commits | Learnings | Decisions | Gap Type                 |
| ------- | ------- | --------- | --------- | ------------------------ |
| [range] | [N]     | [N]       | [N]       | [high activity, no docs] |

## Phase Boundaries

| Phase   | Start SHA | End SHA | Start Date | End Date |
| ------- | --------- | ------- | ---------- | -------- |
| [phase] | [sha]     | [sha]   | [date]     | [date]   |
```

### Step 6: Cross-Link

After writing the timeline:

1. If `docs/README.md` exists, add a link to the timeline under the appropriate section:

   ```markdown
   - [Project Timeline](history/TIMELINE.md) — Historical evolution of this project
   ```

   Use the Edit tool to insert the link — do not rewrite the entire file.

2. Present a build summary to the user:
   - Phases detected and confirmed
   - Total commits covered
   - Documentation gaps identified (high-activity periods with no learnings or decisions)
   - Sources used

---

## Eval Mode

Eval mode is **read-only**. It analyzes process documentation quality but does not modify any files
(except writing EVAL-REPORT-YYYY-MM-DD.md).

### Step 1: Parallel Evaluation

Launch 3 agents in a single message using `Task (subagent_type: Explore)`.

For repos with 1000+ commits, instruct agents to focus on the last 500 commits unless the user
explicitly requests full history.

**Agent 1 — Commit & Coverage:**

Prompt the agent to analyze:

- Weekly commit counts over the project lifetime
  (`git log --date=format:"%Y-W%V" --format="%ad" | sort | uniq -c`)
- Cross-reference commit weeks with dates in .claude/project-diary.md and docs/decisions/
- Calculate coverage: % of active weeks (1+ commits) that have at least one learning or decision
- Conventional commit format compliance: % of commits matching `type(scope): message` or
  `type: message` pattern
- Commit body presence: % of commits with multi-line messages (`git log --format="%B" | ...`)
- Issue/PR reference presence: % of commits referencing `#NNN`, `fixes #NNN`, etc.

Return: weekly activity table, coverage percentage, commit quality metrics.

**Agent 2 — Documentation Health:**

Prompt the agent to check:

- Last modified date for every file in `docs/` and root doc files (AGENTS.md, README.md) using
  `git log -1 --format="%ci" -- <file>`
- Staleness classification:
  - **OK:** < 90 days
  - **Warning:** 90–179 days
  - **Critical:** 180+ days
- Missing expected files: check for AGENTS.md, docs/decisions/, CHANGELOG.md
- If docs/history/TIMELINE.md exists, check if it's current (last entry vs. latest commits)

Return: staleness table with severity, missing files list, overall health assessment.

**Agent 3 — Process Gaps:**

Prompt the agent to identify:

- Weeks with 10+ commits but zero documentation artifacts (no learnings, decisions, or doc changes)
- Features (detected from `feat:` commits or new directory creation) without corresponding ADRs
- Estimate a health score (0–100) across 4 dimensions:
  - **Doc Coverage** (25 pts): % of active weeks with documentation activity
  - **Decision Recording** (25 pts): ratio of architectural changes to ADRs
  - **Learning Capture** (25 pts): ratio of learnings to total commit volume
  - **Commit Quality** (25 pts): conventional format + body + references

Return: gap table, unrecorded decisions list, dimension scores with reasoning.

### Step 2: Synthesize Report

Combine all agent outputs. Create `docs/history/` if it does not exist:

```bash
mkdir -p docs/history
```

Write `docs/history/EVAL-REPORT-YYYY-MM-DD.md`:

```markdown
# Process Evaluation Report

**Generated:** [date] **Repository:** [repo name] **Commits analyzed:** [N] ([date range])

## Health Score: [N]/100

| Dimension          | Score  | Grade | Notes        |
| ------------------ | ------ | ----- | ------------ |
| Doc Coverage       | [N]/25 | [A-F] | [brief note] |
| Decision Recording | [N]/25 | [A-F] | [brief note] |
| Learning Capture   | [N]/25 | [A-F] | [brief note] |
| Commit Quality     | [N]/25 | [A-F] | [brief note] |

**Grading scale:** A (90%+), B (75-89%), C (60-74%), D (40-59%), F (<40%)

## Documentation Gaps

Weeks with significant activity but no documentation:

| Week   | Commits | Learnings | Decisions | Doc Changes |
| ------ | ------- | --------- | --------- | ----------- |
| [week] | [N]     | [N]       | [N]       | [N]         |

## Unrecorded Decisions

Evidence from commits suggesting architectural decisions without formal ADRs:

| Date   | Commit          | Evidence                         | Suggested ADR Topic |
| ------ | --------------- | -------------------------------- | ------------------- |
| [date] | [SHA + message] | [why this looks like a decision] | [topic]             |

## Stale Documentation

| File   | Last Modified | Days Stale | Severity                |
| ------ | ------------- | ---------- | ----------------------- |
| [file] | [date]        | [N]        | OK / Warning / Critical |

## Commit Quality

| Metric              | Value | Target | Status      |
| ------------------- | ----- | ------ | ----------- |
| Conventional format | [N]%  | 80%    | [pass/fail] |
| Has body            | [N]%  | 50%    | [pass/fail] |
| References issues   | [N]%  | 30%    | [pass/fail] |

## Improvement Roadmap

### Quick Wins (< 1 hour)

- [Specific action items that can be done immediately]

### Medium-Term (1–3 sessions)

- [Actions requiring more effort]

### Ongoing Habits

- [Process improvements to adopt, e.g., "capture a project-diary entry after each session"]
- [Periodic reviews, e.g., "run /project-history eval monthly"]
```

### Step 3: Present Results

Show the user a summary:

- **Health Score: N/100** with letter grade
- Dimension breakdown (one line each)
- Top 3 actionable recommendations
- If `docs/history/TIMELINE.md` does not exist, suggest: "Run `/project-history build` to
  reconstruct your project timeline."

---

## Rules

- Build mode generates documents; eval mode only writes EVAL-REPORT-YYYY-MM-DD.md
- Never fabricate timeline events — only report what sources show
- Present detected phases for user confirmation before writing the timeline
- QMD/conversation mining is optional — gracefully skip if unavailable
- Phase detection is heuristic — present with low confidence, ask for correction
- Eval grades are directional, not authoritative — present as guidance, not judgment
- Large repos (1000+ commits): sample last 500 unless user requests full history
- Git operations are read-only (build mode creates docs/history/ only)
- Respect existing docs/ structure — never move or reorganize files
- Use relative paths when cross-linking to existing docs
- Do not ask the user to reflect — the skill does its own analysis
