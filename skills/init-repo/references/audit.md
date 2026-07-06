# Init Repo Audit

Audit mode is read-only. Do not create, edit, move, delete, install, format, or generate files.

## Goal

Determine the repo's current setup tier and recommend the smallest useful next step:

- `starter`: basic commands exist, no hooks or CI expected.
- `standard`: scripts, basic hooks, basic CI, and agent docs are present.
- `hardened`: init-repo-hardened markers and three-layer gates are present.

## Inspect

Run read-only checks:

```bash
git rev-parse --is-inside-work-tree
pwd
find . -maxdepth 2 -type f \( -name package.json -o -name pyproject.toml -o -name Cargo.toml -o -name Makefile -o -name AGENTS.md -o -name CODEX.md \) -print
find . -maxdepth 3 -type f \( -path './.github/workflows/*' -o -path './.husky/*' -o -name '.pre-commit-config.yaml' -o -path './scripts/pre-*.sh' \) -print
rg -n "# init-repo-hardened|# repo-quality-rails|format:check|type-check|cargo clippy|ruff|mypy|pytest|vitest|eslint|prettier" package.json pyproject.toml Cargo.toml Makefile .github .husky scripts .pre-commit-config.yaml 2>/dev/null || true
```

## Classify

Classify as `hardened` when:

- any hook/config contains `# init-repo-hardened` (or the legacy `# repo-quality-rails`), or
- the repo has pre-commit, pre-push, and CI gates with anti-gaming or advanced checks.

Classify as `standard` when:

- format/lint/typecheck/test commands exist,
- basic hooks exist,
- lightweight CI exists,
- `AGENTS.md` and Codex/Claude context files exist when relevant.

Classify as `starter` when:

- the repo has a valid project manifest,
- basic format/lint/test commands exist,
- hooks and CI are missing or intentionally absent.

Classify as `below starter` when core commands or manifests are missing.

## Report

Return:

```markdown
## Init Repo Audit

- Language: JS/TS | Python | Rust | mixed | unknown
- Current tier: below starter | starter | standard | hardened
- Evidence: [short bullets with file paths]
- Missing for starter: [...]
- Missing for standard: [...]
- Missing for hardened: [...]
- Recommended next step: starter | standard | hardened | no change
```

Do not make changes in audit mode.
