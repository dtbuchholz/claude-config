# Claude Code CLI Configuration

Shared configuration for [Claude Code CLI](https://code.claude.com/docs) to ensure consistent
tooling, workflows, and best practices across projects.

## Prerequisites

Before using this configuration, ensure you have the following installed:

### Required

| Tool                                             | Purpose                    | Install                                |
| ------------------------------------------------ | -------------------------- | -------------------------------------- |
| [Claude Code CLI](https://code.claude.com/docs)  | AI coding assistant        | `brew install --cask claude-code`      |
| [Node.js](https://nodejs.org/) (v18+)            | Runtime for tooling        | `brew install node`                    |
| [pnpm](https://pnpm.io/)                         | Package manager            | `brew install pnpm`                    |
| [Prettier](https://prettier.io/)                 | Code formatter             | Installed via `pnpm install`           |
| [GitHub CLI](https://cli.github.com/)            | PR creation, git workflows | `brew install gh` then `gh auth login` |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanning            | `brew install gitleaks`                |
| [QMD](https://github.com/tobilu/qmd)             | Semantic search over docs  | `npm install -g @tobilu/qmd`           |

### Optional (for notifications)

| Tool                                                               | Purpose             | Install                          |
| ------------------------------------------------------------------ | ------------------- | -------------------------------- |
| [terminal-notifier](https://github.com/julienXX/terminal-notifier) | macOS notifications | `brew install terminal-notifier` |

## Installation

1. **Clone this repository** to your home directory:

   ```bash
   git clone <repo-url> ~/.claude
   ```

2. **Run the install target** (installs Node deps, CLI tools, and sets hook permissions):

   ```bash
   cd ~/.claude
   make install
   ```

3. **Authenticate GitHub CLI** (if not already done):

   ```bash
   gh auth login
   ```

4. **Restart Claude Code** to pick up the new configuration.

## What's Included

### Skills (`skills/`)

Skills provide contextual knowledge that Claude uses automatically based on your task, or can be
invoked directly with `/skill-name`.

| Skill                 | Purpose                                                                          |
| --------------------- | -------------------------------------------------------------------------------- |
| `adjudicate`          | Adjudicate external review feedback and apply accepted fixes                     |
| `agent-browser`       | Browser automation using Vercel's agent-browser CLI                              |
| `agent-review`        | Fresh-context secondary review (Codex/Claude), then adjudicate                   |
| `analyze-data`        | Data analysis with parallel EDA agents                                           |
| `api-design`          | REST/GraphQL API design conventions                                              |
| `autoresearch`        | Autonomous experiment loop for an optimization target                            |
| `clean-gone`          | Clean up git branches deleted on remote                                          |
| `commit`              | Create git commit with conventional format                                       |
| `commit-push-pr`      | Stage, commit, push, and create PR in one workflow                               |
| `data-science`        | Data science methodology and workflows                                           |
| `debugging`           | Systematic debugging and error analysis                                          |
| `deepen-plan`         | Enhance plans with parallel research agents                                      |
| `deslop`              | Remove AI-generated code slop from changes                                       |
| `documentation`       | Code comments, docstrings, READMEs                                               |
| `explain`             | Explain code execution and dependencies                                          |
| `fresh-eyes`          | Walk a repo as a new dev: verify docs, setup, commands                           |
| `git-workflow`        | Conventional commits, branching, PR best practices                               |
| `git-worktree`        | Manage git worktrees for parallel development                                    |
| `init-repo`           | Initialize or audit repos (starter/standard/hardened/audit; JS/TS, Python, Rust) |
| `leftoff`             | Find where work left off across Claude/Codex sessions                            |
| `memory-rollup`       | Review, prune, and consolidate memory files                                      |
| `performance`         | Performance optimization and profiling                                           |
| `plan-review`         | Challenge and review a plan before implementation                                |
| `pr-review`           | Multi-agent PR review (up to 7 reviewers, chosen to fit the diff)                |
| `project-history`     | Reconstruct project timeline or evaluate process docs                            |
| `quick-review`        | Single-pass comprehensive review for small changes (no subagents)                |
| `qmd`                 | Semantic search across memory, skills, conversations via QMD                     |
| `quant-strategy-eval` | Evaluate trading strategies (Sharpe, drawdown, etc.)                             |
| `ralph-loop`          | Autonomous development loop with fresh context                                   |
| `repo-docs`           | Bootstrap or audit agent-focused repo docs (tooling-agnostic)                    |
| `review-and-fix`      | Fresh-context review then apply fixes                                            |
| `security`            | OWASP top 10, input validation, secrets management                               |
| `sync`                | Sync current branch with main/master                                             |
| `testing`             | TDD, testing pyramid, language-specific test patterns                            |
| `watch-video`         | Extract frames from a video file to view and analyze                             |

### Review packet builder (`scripts/review-packet.sh`)

Shared by `pr-review`, `review-and-fix`, `agent-review`, and the Codex `pr-review --deep` pipeline.
It picks the review scope, includes untracked files, excludes lockfiles (opt-in with
`--include-lockfiles`), writes a read-only packet with its SHA-256, and `verify` detects checkout
drift during a review. Tests: `bash scripts/tests/review-packet.test.sh`.

### Agents (`agents/`)

Agents are specialized AI personas that Claude can spawn for specific tasks.

| Agent           | Purpose                                                     |
| --------------- | ----------------------------------------------------------- |
| `verify-app.md` | Runs tests, linting, and builds across multiple tech stacks |

### Hooks (`hooks/`)

Shell scripts that run automatically at specific points in Claude's workflow.

| Hook                       | Purpose                                      |
| -------------------------- | -------------------------------------------- |
| `check-push-main.sh`       | Blocks direct pushes to main/master branches |
| `check-sensitive-files.sh` | Blocks edits to lockfiles and .git/          |

### Git Hooks (`.husky/`)

Native git hooks managed by [Husky](https://typicode.github.io/husky/), installed via
`make install`.

| Hook         | What it runs                                            |
| ------------ | ------------------------------------------------------- |
| `pre-commit` | `lint-staged` (Prettier) + `gitleaks` on staged changes |
| `pre-push`   | `gitleaks` on outgoing commits                          |

### Plugins (enabled in `settings.json`)

Pre-built plugins from the official marketplace:

| Plugin            | What it provides                                |
| ----------------- | ----------------------------------------------- |
| `feature-dev`     | 7-phase structured feature development workflow |
| `frontend-design` | Distinctive, production-grade UI design         |

### Hook Configuration (in `settings.json`)

| Hook Event   | What it does                                                   |
| ------------ | -------------------------------------------------------------- |
| `PreToolUse` | Blocks edits to sensitive files via `check-sensitive-files.sh` |
| `PreToolUse` | Blocks direct pushes to main/master via `check-push-main.sh`   |

### Permissions (in `settings.json`)

`Read`, `Edit`, `Write`, and `Bash(*)` are allowed globally, so Claude rarely prompts. The
`PreToolUse` hooks above are the guardrails: pushes to `main`/`master` and edits to lockfiles or
`.git/` are blocked regardless of permissions.

### Skill overrides (in `settings.json`)

`skillOverrides` hides the claude.ai-synced copy of `quant-strategy-eval`, which duplicates the
version-controlled one in `skills/`. Skills synced from claude.ai land in `skills/synced/`, which
the CLI manages and `.gitignore` excludes.

## Configuration Files

| File                 | Purpose                                               |
| -------------------- | ----------------------------------------------------- |
| `settings.json`      | Main Claude Code config (permissions, hooks, plugins) |
| `package.json`       | Node.js dependencies (Prettier)                       |
| `.prettierrc`        | Prettier formatting configuration                     |
| `.prettierignore`    | Files excluded from formatting                        |
| `.gitignore`         | Files excluded from version control                   |
| `CLAUDE.md`          | Global instructions for Claude Code                   |
| `CLAUDE.md.template` | Template for project-specific CLAUDE.md files         |

## Usage

### Available make targets

```bash
make help           # Show all targets
make install        # Full setup (deps + hooks)
make deps           # Install Node dependencies and CLI tools
make hooks          # Make all hook scripts executable
make format         # Format all files with Prettier
make format-check   # Check formatting (CI)
```

### Using CLAUDE.md in your projects

Copy `CLAUDE.md.template` to your project root and customize it:

```bash
cp ~/.claude/CLAUDE.md.template /path/to/your/project/CLAUDE.md
```

This file tells Claude about your project's structure, conventions, and commands.

## Customization

### Adding new skills

Create a new directory in `skills/` with a `SKILL.md` file:

```
skills/
└── my-skill/
    └── SKILL.md
```

The frontmatter should include:

```yaml
---
name: my-skill
description: When to use this skill and what triggers it
---
```

Skills can also include helper scripts in a `scripts/` subdirectory.

### Adding new agents

Create a new `.md` file in `agents/`:

```yaml
---
name: agent-name
description: When and how to use this agent
model: inherit
---
Agent instructions here...
```

### Adding new hooks

1. Create a script in `hooks/` (make it executable with `chmod +x`)
2. Reference it in `settings.json` under the appropriate hook event
3. Hook scripts receive JSON on stdin and use exit codes: 0 = allow, 2 = block

## Troubleshooting

### Notifications not working

1. Ensure `terminal-notifier` is installed: `brew install terminal-notifier`
2. Check macOS permissions: **System Settings > Notifications > terminal-notifier**
3. Test manually: `terminal-notifier -title "Test" -message "Hello"`
4. Restart Claude Code after changing hooks

### Hooks not running

1. Run Claude with debug mode: `claude --debug hooks`
2. Ensure hooks are in `settings.json` (not a separate `hooks.json`)
3. Check for JSON syntax errors in `settings.json`

### Formatting not working

1. Run `pnpm install` to ensure Prettier is installed
2. Check `.prettierignore` isn't excluding your files
3. Test manually: `pnpm format path/to/file.md`

### Push to main blocked unexpectedly

The `check-push-main.sh` hook blocks direct pushes to `main` and `master`. To push:

1. Create a feature branch: `git checkout -b my-feature`
2. Push the feature branch: `git push -u origin my-feature`
3. Create a PR via GitHub

## Contributing

1. Make your changes
2. Run `pnpm format` to ensure consistent formatting
3. Test your changes with Claude Code
4. Commit and push

## License

MIT OR Apache-2.0
