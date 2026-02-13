# Agent Configuration

When setting up quality rails for a Recall Labs repo, agent configuration is part of the baseline.
Quality gates enforce code standards mechanically; agent configuration ensures AI agents working in
the repo follow team standards from their first interaction.

## What Gets Set Up

### Files

| File                                  | Purpose                                                                      |
| ------------------------------------- | ---------------------------------------------------------------------------- |
| `AGENTS.md`                           | All agent instructions — cross-tool compatible (Claude, Cursor, Codex, etc.) |
| `CLAUDE.md`                           | Minimal file that imports AGENTS.md via `@AGENTS.md`                         |
| `AGENT-LEARNINGS.md`                  | Knowledge capture — insights from agent sessions, indexed by Atlas nightly   |
| `.claude/skills/recall-commit`        | Symlink to recall-skills — conventional commits with learning capture        |
| `.claude/skills/adversarial-verifier` | Symlink to recall-skills — deep verification for critical changes            |

### AGENTS.md Structure

AGENTS.md is the canonical source of truth for any AI agent. It contains both team-wide standards
(managed by `setup.sh`) and project-specific instructions (written by the team).

The team standards section is injected between markers:

```markdown
<!-- BEGIN RECALL LABS TEAM STANDARDS -->
<!-- This section is managed by recall-skills/setup.sh — do not edit manually. -->

[team standards content]

<!-- END RECALL LABS TEAM STANDARDS -->
```

Running `setup.sh --update` refreshes this section from the latest template without touching
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

- **Commits**: `/recall-commit` for every commit. Conventional format. Co-Authored-By trailers. No
  `--no-verify`. Learning capture in AGENT-LEARNINGS.md.
- **Code quality**: No `any` in TypeScript. No silent fallbacks. No dead code. Hooks are
  non-negotiable.
- **Development**: TDD for all new features and bug fixes. Bug detection before bug fix. Plan before
  implementing. Verify before claiming completion.
- **Knowledge capture**: AGENT-LEARNINGS.md with Insight/Detail/Directive/Context format.
  High-leverage insights only. Zero learnings is valid.
- **Skills**: `/recall-commit` required, `/adversarial-verifier` encouraged.
- **Team context**: Atlas MCP tools for alignment checks, learnings search, context bundles.

### Atlas MCP

Atlas is the team's context curation agent. It runs as a remote MCP server at
`https://mcp.recall.network/mcp`. Clients connect via `mcp-remote` with a shared API key passed as
an `x-api-key` header.

Setup is per-user (not per-repo):

```bash
# During quality rails setup, if the user has the Atlas API key:
/path/to/recall-skills/setup.sh --atlas-key THE_SHARED_KEY
```

This writes `~/.mcp.json` with the Atlas server config and enables it in Claude Code's
`~/.claude/settings.local.json`.

## Integration with Quality Rails

Agent configuration should be set up **after** the quality gate infrastructure (hooks, CI, linting)
is in place. The order matters because:

1. Pre-commit hooks enforce code standards mechanically.
2. Agent instructions reference those hooks ("never `--no-verify`").
3. The `/recall-commit` skill respects pre-commit hooks and creates new commits on failure.

When running the full quality rails setup:

1. Set up the three-layer gate infrastructure (pre-commit, pre-push, CI)
2. Run `recall-skills/setup.sh` to configure agent standards
3. Customize the project-specific sections of AGENTS.md
4. Verify: `cat AGENTS.md` should show team standards between markers + project sections

## Updating Team Standards

When team standards change (new rules, new skills, updated practices):

1. Update `recall-skills/templates/team-standards-section.md`
2. In each repo: `recall-skills/setup.sh --update`
3. Commit the updated AGENTS.md

This is a manual propagation step. It keeps repos in sync without requiring submodules or complex
automation.

## For Existing Repos

Repos that already have AGENTS.md or CLAUDE.md:

- **AGENTS.md exists without markers**: `setup.sh` warns and asks you to add the marker comments
  where you want the team standards section. Then re-run with `--update`.
- **CLAUDE.md exists without `@AGENTS.md`**: `setup.sh` suggests adding the import but does not
  modify the file. Existing Claude-specific instructions are preserved.
- **AGENT-LEARNINGS.md exists**: Left untouched. Existing learnings are preserved.
