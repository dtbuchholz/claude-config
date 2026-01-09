# Claude Code CLI Configuration

Shared configuration for [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) to ensure
consistent tooling, workflows, and best practices across the team.

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

### Agents (`agents/`)

Agents are specialized AI personas that Claude can spawn for specific tasks.

| Agent                | Purpose                                                     |
| -------------------- | ----------------------------------------------------------- |
| `code-simplifier.md` | Simplifies and cleans up code after implementation          |
| `verify-app.md`      | Runs tests, linting, and builds across multiple tech stacks |

### Commands (`commands/`)

Slash commands you can invoke in Claude Code with `/command-name`.

| Command             | Purpose                                              |
| ------------------- | ---------------------------------------------------- |
| `commit-push-pr.md` | Stage, commit, push, and create a PR in one workflow |
| `explain.md`        | Explain how a piece of code works                    |

### Skills (`skills/`)

Skills provide contextual knowledge that Claude uses automatically based on your task.

| Skill           | Topics Covered                                            |
| --------------- | --------------------------------------------------------- |
| `testing`       | TDD, testing pyramid, language-specific test patterns     |
| `git-workflow`  | Conventional commits, branching, PR best practices        |
| `documentation` | Comments, docstrings, READMEs, API docs                   |
| `debugging`     | Systematic debugging, error analysis, common bug patterns |
| `security`      | OWASP top 10, input validation, secrets management        |
| `api-design`    | REST conventions, status codes, pagination, versioning    |

### Plugins (enabled in `settings.json`)

Pre-built plugins from the official marketplace:

| Plugin              | What it provides                                     |
| ------------------- | ---------------------------------------------------- |
| `code-review`       | Code review with confidence scoring                  |
| `frontend-design`   | Distinctive, production-grade UI design guidance     |
| `commit-commands`   | `/commit`, `/commit-push-pr`, `/clean_gone` commands |
| `pr-review-toolkit` | 6 specialized PR review agents                       |
| `feature-dev`       | 7-phase structured feature development workflow      |
| `ralph-wiggum`      | Fun personality plugin                               |

### Hooks (in `settings.json`)

Hooks are shell commands that run automatically at specific points in Claude's workflow.

| Hook Event     | What it does                                                 |
| -------------- | ------------------------------------------------------------ |
| `PreToolUse`   | Blocks edits to sensitive files (`.env`, lockfiles, `.git/`) |
| `PostToolUse`  | Auto-formats files with Prettier after edits                 |
| `Notification` | Sends macOS notification when Claude awaits input            |
| `Stop`         | Sends macOS notification when task completes                 |

### Permissions (in `settings.json`)

Pre-approved commands that Claude can run without asking:

- **Package manager**: `pnpm test`, `pnpm lint`, `pnpm build`, `pnpm dev`, etc.
- **File utilities**: `ls`, `find`, `grep`, `sed`, `awk`, `jq`, etc.
- **Git operations**: `git status`, `git add`, `git commit`, `git push`, etc.
- **Shell config reads**: `~/.zshrc`, `~/.bashrc`, `~/.profile`, etc.

## Configuration Files

| File                 | Purpose                                               |
| -------------------- | ----------------------------------------------------- |
| `settings.json`      | Main Claude Code config (permissions, hooks, plugins) |
| `package.json`       | Node.js dependencies (Prettier)                       |
| `.prettierrc`        | Prettier formatting configuration                     |
| `.prettierignore`    | Files excluded from formatting                        |
| `.gitignore`         | Files excluded from version control                   |
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

### Adding new commands

Create a new `.md` file in `commands/`:

```yaml
---
allowed-tools: Bash(command:*), Read, Write
description: What this command does
---
Your command instructions here...
```

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

## Troubleshooting

### Notifications not working

1. Ensure `terminal-notifier` is installed: `brew install terminal-notifier`
2. Check macOS permissions: **System Settings → Notifications → terminal-notifier**
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

## Contributing

1. Make your changes
2. Run `pnpm format` to ensure consistent formatting
3. Test your changes with Claude Code
4. Commit and push

## License

MIT OR Apache-2.0
