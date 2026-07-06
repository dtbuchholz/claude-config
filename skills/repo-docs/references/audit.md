# Audit

Audit mode is strictly read-only. All checks are advisory and performed by inspection — there is no
deterministic linter. Cover schema/frontmatter, taxonomy/path/filename, freshness,
reachability/orphans, and broken markdown links as part of the checks below.

## Advisory Checks

### 1. Staleness By Git Activity

For each curated doc in `docs/` plus `AGENTS.md`:

```bash
git log -1 --format="%ci" -- <file>
```

Severity:

- warning: 90-179 days since last modification
- critical: 180+ days since last modification

Skip files with no git history. Exclude generated or derived docs.

### 2. Code-Path Drift

For curated docs that include both `code_paths` and `reviewed`:

- find the latest commit touching any listed `code_paths`
- compare that date with the doc's `reviewed` date
- flag docs where code changed after the doc was reviewed

### 3. Coverage Gaps

Identify top-level code modules/packages and check whether each has corresponding docs coverage.
Major modules with no docs are coverage gaps.

### 4. AGENTS.md Drift

Compare `AGENTS.md` against reality:

- commands still exist
- directory structure still matches
- env vars are still current
- the file is still compact enough to act as an index

### 5. Missing-Docs Heuristics

| Pattern Found                      | Suggested Doc    |
| ---------------------------------- | ---------------- |
| Dockerfile / docker-compose        | runbook          |
| migrations directory               | database runbook |
| route/api/endpoints dirs           | API reference    |
| `.env.example` with many variables | config reference |

### 6. Symlink Validity

Verify that `CLAUDE.md` and `CODEX.md` point to `AGENTS.md`. Flag broken or divergent links.

## Report Shape

Produce:

- summary
- stale files
- code-path drift
- coverage gaps
- `AGENTS.md` drift
- missing-doc suggestions
- symlink issues
- suggested actions

After the report, stop.
