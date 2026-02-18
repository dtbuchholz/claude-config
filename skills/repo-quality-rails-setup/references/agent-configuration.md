# Agent Configuration

When setting up quality rails for a repo, agent configuration is part of the baseline. Quality gates
enforce code standards mechanically; agent configuration ensures AI agents working in the repo
follow team standards from their first interaction.

## What Gets Set Up

### Files

| File                 | Purpose                                                                      |
| -------------------- | ---------------------------------------------------------------------------- |
| `AGENTS.md`          | All agent instructions — cross-tool compatible (Claude, Cursor, Codex, etc.) |
| `CLAUDE.md`          | Minimal file that imports AGENTS.md via `@AGENTS.md`                         |
| `AGENT-LEARNINGS.md` | Knowledge capture — insights from agent sessions                             |

### AGENTS.md Structure

AGENTS.md is the canonical source of truth for any AI agent. It contains both team-wide standards
(managed centrally) and project-specific instructions (written by the team).

The team standards section is injected between markers:

```markdown
<!-- BEGIN TEAM STANDARDS -->
<!-- This section is managed centrally — do not edit manually. -->

[team standards content]

<!-- END TEAM STANDARDS -->
```

Refreshing this section from the latest template updates team standards without touching
project-specific content. This is how team standards propagate across all repos.

### CLAUDE.md

CLAUDE.md exists only for Claude Code compatibility. Its entire content is:

```markdown
# [Project Name]

@AGENTS.md
```

The `@AGENTS.md` directive tells Claude Code to load AGENTS.md as if its contents were inline. This
means agents using Claude Code get the same instructions as agents using any other tool that reads
AGENTS.md natively.

### Team Standards

The managed section enforces:

- **Commits**: Conventional format. Co-Authored-By trailers. No `--no-verify`. Learning capture in
  AGENT-LEARNINGS.md.
- **Code quality**: No `any` in TypeScript. No silent fallbacks. No dead code. Hooks are
  non-negotiable.
- **Development**: TDD for all new features and bug fixes. Bug detection before bug fix. Plan before
  implementing. Verify before claiming completion.
- **Knowledge capture**: AGENT-LEARNINGS.md with Insight/Detail/Directive/Context format.
  High-leverage insights only. Zero learnings is valid.

## Integration with Quality Rails

Agent configuration should be set up **after** the quality gate infrastructure (hooks, CI, linting)
is in place. The order matters because:

1. Pre-commit hooks enforce code standards mechanically.
2. Agent instructions reference those hooks ("never `--no-verify`").
3. Commit skills respect pre-commit hooks and create new commits on failure.

When running the full quality rails setup:

1. Set up the three-layer gate infrastructure (pre-commit, pre-push, CI)
2. Configure agent standards (AGENTS.md, CLAUDE.md)
3. Customize the project-specific sections of AGENTS.md
4. Verify: `cat AGENTS.md` should show team standards between markers + project sections

## For Existing Repos

Repos that already have AGENTS.md or CLAUDE.md:

- **AGENTS.md exists without markers**: Add the marker comments where you want the team standards
  section, then populate with current standards.
- **CLAUDE.md exists without `@AGENTS.md`**: Add the import. Existing Claude-specific instructions
  are preserved.
- **AGENT-LEARNINGS.md exists**: Left untouched. Existing learnings are preserved.
