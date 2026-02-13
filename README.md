# Claude Code CLI Configuration

Shared configuration for [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) to ensure
consistent tooling, workflows, and best practices across projects.

## Prerequisites

Before using this configuration, ensure you have the following installed:

### Required

| Tool                                                      | Purpose                    | Install                                |
| --------------------------------------------------------- | -------------------------- | -------------------------------------- |
| [Claude Code CLI](https://docs.anthropic.com/claude-code) | AI coding assistant        | `brew install claude`                  |
| [Node.js](https://nodejs.org/) (v18+)                     | Runtime for tooling        | `brew install node`                    |
| [pnpm](https://pnpm.io/)                                  | Package manager            | `brew install pnpm`                    |
| [Prettier](https://prettier.io/)                          | Code formatter             | Installed via `pnpm install`           |
| [GitHub CLI](https://cli.github.com/)                     | PR creation, git workflows | `brew install gh` then `gh auth login` |

### Optional (for notifications)

| Tool                                                               | Purpose             | Install                          |
| ------------------------------------------------------------------ | ------------------- | -------------------------------- |
| [terminal-notifier](https://github.com/julienXX/terminal-notifier) | macOS notifications | `brew install terminal-notifier` |

## Installation

1. **Clone this repository** to your home directory:

   ```bash
   git clone <repo-url> ~/.claude
   ```

2. **Install dependencies**:

   ```bash
   cd ~/.claude
   pnpm install
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

| Skill                      | Purpose                                                 |
| -------------------------- | ------------------------------------------------------- |
| `agent-browser`            | Browser automation using Vercel's agent-browser CLI     |
| `analyze-data`             | Data analysis with parallel EDA agents                  |
| `api-design`               | REST/GraphQL API design conventions                     |
| `clean-gone`               | Clean up git branches deleted on remote                 |
| `commit`                   | Create git commit with conventional format              |
| `commit-push-pr`           | Stage, commit, push, and create PR in one workflow      |
| `data-science`             | Data science methodology and workflows                  |
| `debugging`                | Systematic debugging and error analysis                 |
| `deepen-plan`              | Enhance plans with parallel research agents             |
| `deslop`                   | Remove AI-generated code slop from changes              |
| `documentation`            | Code comments, docstrings, READMEs                      |
| `explain`                  | Explain code execution and dependencies                 |
| `git-workflow`             | Conventional commits, branching, PR best practices      |
| `git-worktree`             | Manage git worktrees for parallel development           |
| `init-repo`                | Initialize new JS/TS or Python repositories             |
| `napkin`                   | Per-repo mistake/correction tracking across sessions    |
| `performance`              | Performance optimization and profiling                  |
| `pr-review`                | Comprehensive PR review with 6 specialized agents       |
| `recall-commit`            | Commit with learning capture for Recall Labs projects   |
| `repo-quality-rails-setup` | Full quality rails setup for TS monorepos / any project |
| `pr-review-quick`          | Quick PR review with 4 parallel agents                  |
| `quant-strategy-eval`      | Evaluate trading strategies (Sharpe, drawdown, etc.)    |
| `ralph-loop`               | Autonomous development loop with fresh context          |
| `review-and-fix`           | Fresh-context review then apply fixes                   |
| `security`                 | OWASP top 10, input validation, secrets management      |
| `sync`                     | Sync current branch with main/master                    |
| `testing`                  | TDD, testing pyramid, language-specific test patterns   |

### Agents (`agents/`)

Agents are specialized AI personas that Claude can spawn for specific tasks.

| Agent           | Purpose                                                     |
| --------------- | ----------------------------------------------------------- |
| `verify-app.md` | Runs tests, linting, and builds across multiple tech stacks |

### Hooks (`hooks/`)

Shell scripts that run automatically at specific points in Claude's workflow.

| Hook                       | Purpose                                         |
| -------------------------- | ----------------------------------------------- |
| `check-push-main.sh`       | Blocks direct pushes to main/master branches    |
| `check-sensitive-files.sh` | Blocks edits to .env, lockfiles, .git/          |
| `notify.sh`                | Sends macOS notifications via terminal-notifier |

### Plugins (enabled in `settings.json`)

Pre-built plugins from the official marketplace:

| Plugin            | What it provides                                |
| ----------------- | ----------------------------------------------- |
| `feature-dev`     | 7-phase structured feature development workflow |
| `frontend-design` | Distinctive, production-grade UI design         |

### Hook Configuration (in `settings.json`)

| Hook Event     | What it does                                                   |
| -------------- | -------------------------------------------------------------- |
| `PreToolUse`   | Blocks edits to sensitive files via `check-sensitive-files.sh` |
| `PreToolUse`   | Blocks direct pushes to main/master via `check-push-main.sh`   |
| `Notification` | Sends macOS notification when Claude awaits input              |
| `Stop`         | Sends macOS notification when task completes                   |

### Permissions (in `settings.json`)

Pre-approved commands that Claude can run without asking:

- **Package manager**: `pnpm test`, `pnpm lint`, `pnpm build`, `pnpm dev`, etc.
- **File utilities**: `ls`, `find`, `grep`, `sed`, `awk`, `jq`, etc.
- **Git operations**: `git status`, `git add`, `git commit`, `git push`, etc.
- **GitHub CLI**: `gh pr view`, `gh pr create`, `gh api`
- **Shell config reads**: `~/.zshrc`, `~/.bashrc`, `~/.profile`, etc.

**Note:** While `git push` is allowed, pushes to `main` or `master` are blocked by the
`check-push-main.sh` hook.

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

### Format all files

```bash
pnpm format
```

### Check formatting (CI)

```bash
pnpm format:check
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
