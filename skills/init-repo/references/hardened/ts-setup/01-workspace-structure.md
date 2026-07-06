# Step 01 — Workspace Structure

This step establishes the monorepo layout and pnpm workspace configuration.

## Directory Layout

```
my-project/
  apps/
    web/                    # Next.js app
    api/                    # Node.js service
  packages/
    core-domain/            # Shared types and domain logic
    database/               # Drizzle ORM, schema, migrations
    service-core/           # Shared service utilities
    testing/                # Test utilities and fixtures
    eslint-config/          # Shared ESLint configuration
    tsconfig/               # Shared TypeScript configuration
    ui/                     # Shared UI components (if applicable)
  .changeset/
  .husky/
  turbo.json
  pnpm-workspace.yaml
  package.json
  vitest.config.ts
  lint-staged.config.mjs
  .prettierrc
  .jscpd.json
  .squawk.toml
```

## pnpm-workspace.yaml

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

## .npmrc

```ini
auto-install-peers=true
strict-peer-dependencies=false
```

## Stop & Confirm

Confirm the repo layout and workspace files before moving to Step 02.
