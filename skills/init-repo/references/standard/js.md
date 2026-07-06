# Standard JS/TS Setup

Use this as the default JavaScript or TypeScript setup. Standard mode is a practical production
baseline: scripts, basic hooks, lightweight CI, and agent docs. It is not the full hardened
quality-rails setup.

## Defaults

- Package manager: `pnpm`.
- TypeScript: strict mode when TypeScript is selected or detected.
- Formatter: Prettier.
- Linter: ESLint flat config.
- Tests: Vitest.
- Hooks: Husky + lint-staged.
- CI: one lightweight job from `standard/basic-ci.md`.

## Layout

Single-package default:

```text
src/
tests/
package.json
tsconfig.json        # TypeScript only
eslint.config.mjs
vitest.config.ts
lint-staged.config.mjs
.prettierrc
.prettierignore
.gitignore
```

Monorepo only when requested:

```text
apps/
packages/
pnpm-workspace.yaml
turbo.json
```

## Root Scripts

Use these root scripts and adapt package paths to the repo:

```json
{
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "lint": "eslint .",
    "type-check": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest",
    "prepare": "husky"
  }
}
```

For JavaScript-only projects, omit `build` and `type-check` unless a build tool exists.

## Hooks

Pre-commit should be fast and staged-file focused:

```bash
pnpm lint-staged
```

Pre-push should run the local verification suite:

```bash
pnpm format:check && pnpm lint && pnpm type-check && pnpm test
```

For JavaScript-only projects, remove `pnpm type-check`.

## Verify

Run:

```bash
pnpm install
pnpm format:check
pnpm lint
pnpm test
```

For TypeScript, also run:

```bash
pnpm type-check
```
