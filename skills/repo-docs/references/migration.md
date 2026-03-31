# Migration

Use this file when a repo already has docs, legacy validators, or an older governance setup.

## Existing Docs Migration

Common migration tasks:

- add missing canonical frontmatter fields (`doc_type`, `owner`, `review_policy`, `reviewed`,
  `status`, `summary`, `tags`, `written`)
- move docs into the correct taxonomy directory for their `doc_type`
- rename files to match canonical filename conventions
- drop clearly obsolete non-canonical frontmatter fields that have no equivalent
- link migrated docs from `docs/INDEX.md`

For repos with more than 10 docs to migrate, prefer scripting frontmatter additions and renames
instead of editing each file by hand.

## Common Mappings

| Legacy pattern                    | Canonical target                                         |
| --------------------------------- | -------------------------------------------------------- |
| `docs/README.md` as index         | `docs/INDEX.md`                                          |
| `docs/adr/` or `docs/adrs/`       | `docs/decisions/NNN-title-kebab-case.md`                 |
| `docs/_templates/`                | `docs/templates/`                                        |
| Undated investigation docs        | `docs/observations/YYYY-MM-DD-title-kebab-case.md`       |
| Flat `docs/` with mixed doc types | Split into taxonomy directories by `doc_type`            |
| Domain-grouped subdirectories     | Preserve groupings within canonical taxonomy directories |
| `docType`                         | `doc_type`                                               |
| `lastReviewed`                    | `reviewed`                                               |
| `created`                         | `written`                                                |
| `codePaths`                       | `code_paths`                                             |
| `relatedDocs`                     | `related_docs`                                           |

## Upgrade Rule For Already-Governed Repos

Upgrading `@recallnet/docs-governance-preset` alone does **not** rewrite the repo's committed:

- `docs/docs-policy.json`
- `docs/docs-frontmatter.schema.json`
- `.remarkrc.mjs`

If the preset gains new canonical policy sections or rules:

- rerun `recall-docs-governance init --profile repo-docs`
- or explicitly migrate the committed governance files

Do not assume a dependency bump alone refreshes taxonomy or any other checked-in policy content.

## Validator Cleanup

If a repo already has markdown validators, they may conflict with governed docs:

- `.markdownlint.json`
- `.markdownlint-cli2.jsonc`
- pre-existing `.remarkrc`
- `eslint-plugin-markdown`
- similar markdown lint rails

Preferred outcome:

- make `docs:lint` the authoritative validator for curated `docs/`
- retire overlapping markdown validators, or scope them away from governed `docs/` paths

After migration, run `docs:lint` and treat remaining failures as the source of truth for schema,
taxonomy, freshness, reachability, and link issues.
