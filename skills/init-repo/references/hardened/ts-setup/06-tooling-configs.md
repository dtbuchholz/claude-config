# Step 06 — Tooling Configs

This step sets up Prettier, lint-staged, Vitest, copy-paste detection, and SQL linting configs.

## Formatter Configuration

### .prettierrc

```json
{
  "semi": true,
  "singleQuote": false,
  "trailingComma": "es5",
  "tabWidth": 2,
  "printWidth": 100
}
```

### .prettierignore

```
node_modules
dist
.next
coverage
pnpm-lock.yaml
*.min.js
*.min.css
drizzle/**
```

## lint-staged Configuration

### lint-staged.config.mjs

```javascript
export default {
  "**/*.{ts,tsx,js,jsx,mjs,cjs}": ["prettier --write --ignore-path .prettierignore"],
  "**/*.{json,md,yml,yaml}": ["prettier --write --ignore-path .prettierignore"],
};
```

## Vitest Configuration

### vitest.config.ts (root)

```typescript
import { defineConfig } from "vitest/config";

const isCi = process.env.CI === "true";

export default defineConfig({
  resolve: {
    conditions: ["development", "require", "default"],
  },
  ssr: {
    resolve: {
      conditions: ["development", "require", "default"],
    },
  },
  test: {
    globals: true,
    environment: "node",
    pool: "threads",
    poolOptions: {
      threads: {
        singleThread: isCi,
        isolate: true,
        minThreads: 1,
        maxThreads: isCi ? 1 : 4,
      },
    },
    fileParallelism: !isCi,
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      clean: false,
      cleanOnRerun: false,
      thresholds: {
        lines: 90,
        functions: 90,
        branches: 90,
        statements: 90,
      },
      exclude: [
        "node_modules/**",
        "**/node_modules/**",
        "**/generated/**",
        "**/*.d.ts",
        "**/index.ts",
        "**/*.config.ts",
        "**/*.config.js",
        "**/*.config.mjs",
        ".next/**",
        "**/dist/**",
        "public/**",
        "docs/**",
        "**/coverage/**",
        "**/scripts/**",
        "packages/eslint-config/**",
        "packages/tsconfig/**",
        "packages/testing/**",
      ],
      include: [
        "packages/*/src/**/*.ts",
        "!packages/*/src/**/*.test.ts",
        "!packages/*/src/**/__tests__/**",
      ],
    },
    include: [
      "packages/**/src/**/*.test.ts",
      "packages/**/src/**/*.test.tsx",
      "apps/*/src/**/*.test.ts",
      "apps/*/src/**/*.test.tsx",
    ],
    exclude: ["node_modules", ".next", "**/node_modules/**", "**/*.integration.test.ts"],
  },
});
```

### vitest.integration.config.ts (root)

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  resolve: {
    conditions: ["development", "require", "default"],
  },
  test: {
    globals: true,
    environment: "node",
    include: ["**/*.integration.test.ts"],
    testTimeout: 30_000,
  },
});
```

## Copy-Paste Detection

### .jscpd.json

```json
{
  "threshold": 5,
  "reporters": ["console", "json", "html"],
  "output": "./reports/duplication",
  "ignore": [
    "**/node_modules/**",
    "**/dist/**",
    "**/.next/**",
    "**/coverage/**",
    "**/__tests__/**",
    "**/*.test.ts",
    "**/*.test.tsx",
    "**/*.spec.ts",
    "**/generated/**",
    "**/drizzle/**",
    "**/.turbo/**"
  ],
  "format": ["typescript", "typescriptreact"],
  "minTokens": 50,
  "minLines": 5,
  "absolute": true,
  "gitignore": true
}
```

## SQL Migration Linting

### .squawk.toml

```toml
# Only applicable if your project uses PostgreSQL migrations.
# Squawk catches dangerous migration patterns before they hit production.

assume_in_transaction = false
pg_version = "15.0"

excluded_rules = [
  "prefer-bigint-over-int",
  "prefer-bigint-over-smallint",
  "require-timeout-settings",
  "prefer-robust-stmts",
]
```

## Stop & Confirm

Confirm tooling configs before moving to Step 07.
