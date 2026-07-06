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

## Validator Cleanup

If a repo already has markdown validators, they may conflict with the canonical docs shape:

- `.markdownlint.json`
- `.markdownlint-cli2.jsonc`
- `.remarkrc`
- `eslint-plugin-markdown`
- similar markdown lint rails

Preferred outcome:

- keep any validator that is genuinely useful to the repo
- retire or scope away rules that fight the canonical taxonomy, frontmatter, or filename conventions
  on curated `docs/` paths

After migration, validate the curated docs by inspection (structure, naming, frontmatter,
reachability, and links) as described in the skill's Validate step.
