# Step 09 — Dependencies + Quick Setup Checklist

This step captures the complete dependency list and the recommended setup order.

## Complete Dependency List

### Root devDependencies

| Package               | Version   | Purpose                                             |
| --------------------- | --------- | --------------------------------------------------- |
| `turbo`               | `^2.3.0`  | Monorepo build orchestration                        |
| `typescript`          | `^5`      | TypeScript compiler (root-level for editor support) |
| `prettier`            | `^3.5.0`  | Code formatting                                     |
| `eslint`              | `^9.0.0`  | Linting (peer dependency, installed per-app)        |
| `vitest`              | `^2.1.0`  | Test runner                                         |
| `@vitest/coverage-v8` | `^2.1.0`  | Coverage provider                                   |
| `husky`               | `^9.1.0`  | Git hooks                                           |
| `lint-staged`         | `^16.2.0` | Run formatters on staged files                      |
| `tsx`                 | `^4.19.0` | TypeScript execution for scripts                    |
| `@changesets/cli`     | `^2.29.0` | Version management and changelogs                   |
| `jscpd`               | `^4.0.7`  | Copy-paste detection                                |
| `squawk-cli`          | `^2.36.0` | SQL migration linting                               |

### Per-Package devDependencies (Library)

```json
{
  "@myorg/eslint-config": "workspace:*",
  "@myorg/tsconfig": "workspace:*",
  "typescript": "^5",
  "vitest": "^2.1.0"
}
```

### Per-Package devDependencies (Node.js App)

```json
{
  "@myorg/eslint-config": "workspace:*",
  "@myorg/testing": "workspace:*",
  "@myorg/tsconfig": "workspace:*",
  "@types/node": "^20",
  "tsx": "^4.19.0",
  "typescript": "^5",
  "vitest": "^2.1.0"
}
```

### Per-Package devDependencies (Next.js App)

```json
{
  "@myorg/eslint-config": "workspace:*",
  "@myorg/tsconfig": "workspace:*",
  "@types/node": "^20",
  "@types/react": "^19",
  "@types/react-dom": "^19",
  "eslint": "^9",
  "typescript": "^5"
}
```

## Quick Setup Checklist

1. **Initialize the repo:**

   ```bash
   mkdir my-project && cd my-project
   git init
   pnpm init
   ```

2. **Create pnpm-workspace.yaml** (see Step 01).

3. **Install root devDependencies:**

   ```bash
   pnpm add -D turbo typescript prettier vitest @vitest/coverage-v8 \
     husky lint-staged tsx @changesets/cli jscpd squawk-cli
   ```

4. **Create config packages first:**
   - `packages/tsconfig/` with `base.json`, `library.json`, `nextjs.json`
   - `packages/eslint-config/` with `base.mjs`, `library.mjs`, `nextjs.js`

5. **Create library packages** following the exports pattern in Step 04.

6. **Create app packages** referencing workspace dependencies with `workspace:*`.

7. **Add config files** at root: `turbo.json`, `.prettierrc`, `lint-staged.config.mjs`,
   `vitest.config.ts`, `.jscpd.json`.

8. **Set up git hooks:**

   ```bash
   pnpm exec husky init
   ```

   Write `.husky/pre-commit` and `.husky/pre-push` (see Step 07).

9. **Initialize changesets:**

   ```bash
   pnpm changeset init
   ```

10. **Verify everything works:**
    ```bash
    pnpm install
    pnpm qa
    ```

## Stop & Confirm

Confirm the full checklist and install order. If accepted, the staged setup is complete.
