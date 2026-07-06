# Step 05 — Root package.json

This step sets up root scripts and devDependencies.

## Root package.json

```json
{
  "name": "my-project",
  "version": "0.1.0",
  "private": true,
  "packageManager": "pnpm@9.15.0",
  "scripts": {
    "build": "turbo run build --output-logs=errors-only",
    "dev": "turbo run dev",
    "lint": "turbo run lint --output-logs=errors-only",
    "format": "prettier --write --ignore-path .prettierignore '*.md' '*.json' '*.yaml' '*.yml' '.vscode/**' && turbo run format",
    "format:check": "prettier --check --ignore-path .prettierignore '*.md' '*.json' '*.yaml' '*.yml' '.vscode/**' && turbo run format:check",
    "test": "turbo run test --output-logs=errors-only",
    "test:unit": "turbo run build --filter=./packages/** && vitest run",
    "test:coverage": "mkdir -p coverage/.tmp && turbo run build --filter=./packages/** && vitest run --coverage",
    "test:integration": "vitest run --config vitest.integration.config.ts --silent",
    "type-check": "turbo run type-check --output-logs=errors-only",
    "clean": "turbo run clean && rm -rf node_modules",
    "prepare": "husky",
    "qa:quick": "pnpm lint && pnpm type-check",
    "qa": "pnpm lint && pnpm type-check && pnpm test && pnpm build",
    "ci": "pnpm qa",
    "cpd": "jscpd apps/ packages/ --config .jscpd.json",
    "cpd:report": "jscpd apps/ packages/ --config .jscpd.json --reporters html",
    "lint:sql": "squawk --config .squawk.toml packages/database/drizzle/*.sql packages/database/migrations/*.sql",
    "changeset": "changeset",
    "changeset:status": "changeset status",
    "changeset:version": "changeset version",
    "changeset:publish": "changeset publish",
    "db:push": "turbo run db:push",
    "db:migrate:sql": "turbo run db:migrate:sql"
  },
  "devDependencies": {
    "@changesets/cli": "^2.29.0",
    "@vitest/coverage-v8": "^2.1.0",
    "husky": "^9.1.0",
    "jscpd": "^4.0.7",
    "lint-staged": "^16.2.0",
    "prettier": "^3.5.0",
    "squawk-cli": "^2.36.0",
    "tsx": "^4.19.0",
    "turbo": "^2.3.0",
    "typescript": "^5",
    "vitest": "^2.1.0"
  }
}
```

## Stop & Confirm

Confirm the root `package.json` structure and scripts before moving to Step 06.
