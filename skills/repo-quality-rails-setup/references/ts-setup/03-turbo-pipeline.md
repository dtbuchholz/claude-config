# Step 03 — Turbo Pipeline

This step defines the Turbo task graph used for build orchestration.

## turbo.json

```json
{
  "$schema": "https://turbo.build/schema.json",
  "ui": "tui",
  "globalEnv": ["DATABASE_URL", "NODE_ENV"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["$TURBO_DEFAULT$", ".env*"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**"]
    },
    "lint": {
      "inputs": ["$TURBO_DEFAULT$", "^$TURBO_DEFAULT$", ".env*"],
      "outputs": []
    },
    "format": {
      "outputs": [],
      "cache": true
    },
    "format:check": {
      "outputs": [],
      "cache": true
    },
    "type-check": {
      "inputs": ["$TURBO_DEFAULT$", "^$TURBO_DEFAULT$"],
      "outputs": ["*.tsbuildinfo"]
    },
    "test": {
      "inputs": ["$TURBO_DEFAULT$", ".env*"],
      "outputs": ["coverage/**"]
    },
    "test:coverage": {
      "inputs": ["$TURBO_DEFAULT$", ".env*"],
      "outputs": ["coverage/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "clean": {
      "cache": false
    },
    "db:push": {
      "dependsOn": ["^build"],
      "cache": false
    },
    "db:migrate:sql": {
      "dependsOn": ["^build"],
      "cache": false
    }
  }
}
```

## Key Design Decisions

- `build` depends on `^build` (upstream packages build first).
- `lint` and `type-check` use `^$TURBO_DEFAULT$` to re-run when upstream source changes.
- `format` and `format:check` are cached but produce no output files.
- `dev` is never cached and marked `persistent` for long-running dev servers.
- `db:push` and `db:migrate:sql` are never cached (always run fresh against the database).
- `clean` is never cached (destructive operation).

## Stop & Confirm

Confirm the Turbo pipeline before moving to Step 04.
