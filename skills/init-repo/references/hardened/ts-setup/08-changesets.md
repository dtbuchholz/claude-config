# Step 08 — Changesets

This step sets up the changeset workflow for publishable packages.

## .changeset/config.json

```json
{
  "$schema": "https://unpkg.com/@changesets/config@3.0.0/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [],
  "access": "restricted",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": []
}
```

## Creating a Changeset (CLI, preferred)

Use the Changesets CLI to generate the markdown deterministically:

```bash
pnpm changeset
```

Follow the prompts to select packages and bump types. This is the default path; **do not hand-edit
changesets unless you explicitly need a non-interactive flow**.

## Creating a Changeset (Non-Interactive / Automation fallback)

If the CLI is unavailable or you need deterministic automation, write a markdown file to
`.changeset/` with a unique name:

```markdown
---
"@myorg/core-domain": patch
---

Fixed type resolution for nested exports.
```

**Bump types:**

- `patch` — Bug fixes, minor changes (0.0.X)
- `minor` — New features, non-breaking changes (0.X.0)
- `major` — Breaking changes (X.0.0)

**Empty changeset (no version bump needed):**

```markdown
---
---
```

## Stop & Confirm

Confirm the changeset workflow before moving to Step 09.
