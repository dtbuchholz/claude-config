# Global Claude Code Instructions

These instructions apply to all projects.

## Code Snippets

When providing code snippets, commands, or any text the user will copy-paste (curl commands, shell
scripts, code examples, etc.), **always use fenced code blocks** with the appropriate language tag.
This ensures the text can be copied without terminal formatting artifacts.

## GitHub URLs

When the user shares a GitHub URL, **always use the `gh` CLI** instead of WebFetch. This ensures access to private repositories.

### Key Insight: `gh` Accepts URLs Directly

Most `gh` commands accept the full URL as an argument - no need to parse it:

```bash
# These are equivalent:
gh issue view 43 --repo owner/repo
gh issue view https://github.com/owner/repo/issues/43

# Same for PRs:
gh pr view 123 --repo owner/repo
gh pr view https://github.com/owner/repo/pull/123
```

### URL Patterns and Commands

| URL Pattern | Command |
|-------------|---------|
| `.../issues/{number}` | `gh issue view <url>` |
| `.../issues` | `gh issue list --repo owner/repo` |
| `.../pull/{number}` | `gh pr view <url>` |
| `.../pull/{number}/files` | `gh pr diff <url>` |
| `.../pulls` | `gh pr list --repo owner/repo` |
| `github.com/owner/repo` | `gh repo view owner/repo` |
| `.../blob/{ref}/{path}` | `gh api repos/owner/repo/contents/path?ref=ref --jq '.content' \| base64 -d` |

### Useful Flags

**For issues:**
```bash
gh issue view <url>                    # Basic view
gh issue view <url> --comments         # Include comments
gh issue view <url> --json title,body,comments  # Structured JSON
```

**For PRs:**
```bash
gh pr view <url>                       # Basic view
gh pr view <url> --comments            # Include comments
gh pr diff <url>                       # View the diff
gh pr diff <url> --name-only           # Just list changed files
gh pr checks <url>                     # CI status
gh pr view <url> --json files --jq '.files[].path'  # List changed files
```

**For repos:**
```bash
gh repo view owner/repo                # Repo info + README
gh repo view owner/repo --json description,defaultBranchRef
```

### Searching

```bash
# Search issues
gh issue list --repo owner/repo --search "bug in:title"

# Search PRs
gh pr list --repo owner/repo --state all --search "feat"
```

### Why Not WebFetch?

- Private repos require authentication
- `gh` is already authenticated via `gh auth login`
- Provides structured data (JSON) that's easier to parse
- Can access PR diffs, comments, reviews, checks, and more
