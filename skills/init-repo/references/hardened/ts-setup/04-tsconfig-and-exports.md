# Step 04 — TypeScript Config + Exports Pattern

This step defines the shared TS configs and the critical exports pattern for workspace packages.

## packages/tsconfig/base.json

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "display": "Base - Strict TypeScript Configuration",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "customConditions": ["development"],
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "incremental": true,

    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "forceConsistentCasingInFileNames": true,
    "verbatimModuleSyntax": false
  }
}
```

## packages/tsconfig/library.json

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "display": "Library Package Configuration",
  "extends": "./base.json",
  "compilerOptions": {
    "customConditions": ["development"],
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true,

    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## packages/tsconfig/nextjs.json

```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "display": "Next.js Application Configuration",
  "extends": "./base.json",
  "compilerOptions": {
    "lib": ["DOM", "DOM.Iterable", "ES2022"],
    "jsx": "preserve",
    "noEmit": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowJs": true,
    "verbatimModuleSyntax": false,

    "plugins": [
      {
        "name": "next"
      }
    ],

    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@myorg/*": ["../../packages/*/src/index.ts"]
    }
  }
}
```

## Package Exports Pattern (CRITICAL)

### The Problem

TypeScript ALWAYS resolves the `"types"` condition first in package exports, regardless of
`customConditions`. If `dist/` does not exist, type-checking fails.

### The Fix

Nest `"types"` INSIDE the `"development"` condition:

```json
{
  "exports": {
    ".": {
      "development": {
        "types": "./src/index.ts",
        "default": "./src/index.ts"
      },
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    }
  }
}
```

### Multiple Sub-path Exports

Apply the same pattern to every export:

```json
{
  "exports": {
    ".": {
      "development": {
        "types": "./src/index.ts",
        "default": "./src/index.ts"
      },
      "types": "./dist/index.d.ts",
      "default": "./dist/index.js"
    },
    "./types": {
      "development": {
        "types": "./src/types/index.ts",
        "default": "./src/types/index.ts"
      },
      "types": "./dist/types/index.d.ts",
      "default": "./dist/types/index.js"
    },
    "./utils": {
      "development": {
        "types": "./src/utils/index.ts",
        "default": "./src/utils/index.ts"
      },
      "types": "./dist/utils/index.d.ts",
      "default": "./dist/utils/index.js"
    }
  }
}
```

### Validation Test

```typescript
// packages/testing/src/__tests__/workspace-exports.test.ts
import { describe, it, expect } from "vitest";
import fs from "node:fs";
import path from "node:path";

function getPackageDirs(): string[] {
  const packagesDir = path.resolve(__dirname, "../../../../packages");
  return fs
    .readdirSync(packagesDir)
    .map((name) => path.join(packagesDir, name))
    .filter((dir) => fs.statSync(dir).isDirectory())
    .filter((dir) => fs.existsSync(path.join(dir, "package.json")));
}

describe("workspace exports", () => {
  it("publishable packages nest types inside development condition", () => {
    for (const dir of getPackageDirs()) {
      const pkg = JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf-8"));
      if (pkg.private) continue;
      if (!pkg.exports) continue;

      for (const [subpath, config] of Object.entries(pkg.exports)) {
        if (typeof config === "string") continue;
        const entry = config as Record<string, unknown>;

        if (entry.development) {
          const dev = entry.development as Record<string, string>;
          expect(dev.types, `${pkg.name} ${subpath} development.types`).toBeDefined();
          expect(dev.types).toMatch(/\.\/src\//);
        }

        if (entry.types) {
          expect(entry.types).toMatch(/\.\/dist\//);
        }
      }
    }
  });
});
```

## Stop & Confirm

Confirm tsconfig + exports pattern before moving to Step 05.
