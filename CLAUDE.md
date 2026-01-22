# Global Claude Code Instructions

These instructions apply to all projects.

## GitHub URLs

When the user shares a GitHub URL, **always use the `gh` CLI** instead of WebFetch. This ensures access to private repositories.

### URL Patterns and Commands

| URL Pattern | Command |
|-------------|---------|
| `github.com/{owner}/{repo}/issues/{number}` | `gh issue view {number} --repo {owner}/{repo}` |
| `github.com/{owner}/{repo}/pull/{number}` | `gh pr view {number} --repo {owner}/{repo}` |
| `github.com/{owner}/{repo}/pull/{number}/files` | `gh pr diff {number} --repo {owner}/{repo}` |
| `github.com/{owner}/{repo}/blob/{ref}/{path}` | `gh api repos/{owner}/{repo}/contents/{path}?ref={ref} --jq '.content' \| base64 -d` |
| `github.com/{owner}/{repo}` (repo root) | `gh repo view {owner}/{repo}` |
| `github.com/{owner}/{repo}/commits` | `gh api repos/{owner}/{repo}/commits --jq '.[].commit.message'` |

### Examples

```bash
# Issue
gh issue view 43 --repo recallnet/execution-arb-bot

# PR with comments
gh pr view 123 --repo recallnet/execution-arb-bot --comments

# PR diff
gh pr diff 123 --repo recallnet/execution-arb-bot

# File contents at specific ref
gh api repos/recallnet/execution-arb-bot/contents/src/main.ts?ref=main --jq '.content' | base64 -d

# List PR files changed
gh pr view 123 --repo recallnet/execution-arb-bot --json files --jq '.files[].path'
```

### Why Not WebFetch?

- Private repos require authentication
- `gh` is already authenticated via `gh auth login`
- Provides structured data (JSON) that's easier to parse
- Can access PR diffs, comments, reviews, and checks
