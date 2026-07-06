# Step 02 — Package Patterns

This step defines the standard package structures for libraries, apps, and shared config packages.

## 2a. Library Package (packages/\*)

Library packages build to `dist/`, source lives in `src/`, and use the nested exports pattern for
development-time TypeScript resolution.

**packages/core-domain/package.json:**

```json
{
  "name": "@myorg/core-domain",
  "version": "0.1.0",
  "private": false,
  "license": "UNLICENSED",
  "type": "module",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "files": ["dist"],
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
    }
  },
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "format": "prettier --write --ignore-path ../../.prettierignore .",
    "format:check": "prettier --check --ignore-path ../../.prettierignore .",
    "lint": "eslint --quiet src/",
    "type-check": "tsc --noEmit",
    "test": "vitest run --silent",
    "test:watch": "vitest",
    "clean": "rm -rf dist .turbo node_modules tsconfig.tsbuildinfo"
  },
  "dependencies": {
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "@myorg/eslint-config": "workspace:*",
    "@myorg/tsconfig": "workspace:*",
    "typescript": "^5",
    "vitest": "^2.1.0"
  }
}
```

**packages/core-domain/tsconfig.json:**

```json
{
  "extends": "@myorg/tsconfig/library.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

## 2b. App Package — Next.js (apps/\*)

**apps/web/package.json:**

```json
{
  "name": "@myorg/web",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "next dev --port 3000",
    "build": "next build",
    "start": "next start --port 3000",
    "format": "prettier --write --ignore-path ../../.prettierignore .",
    "format:check": "prettier --check --ignore-path ../../.prettierignore .",
    "lint": "eslint --quiet",
    "type-check": "tsc --noEmit",
    "test": "vitest run --silent",
    "test:coverage": "vitest run --coverage",
    "clean": "rm -rf .next .turbo node_modules tsconfig.tsbuildinfo"
  },
  "dependencies": {
    "@myorg/core-domain": "workspace:*",
    "@myorg/database": "workspace:*",
    "@myorg/ui": "workspace:*",
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@myorg/eslint-config": "workspace:*",
    "@myorg/tsconfig": "workspace:*",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "typescript": "^5"
  }
}
```

**apps/web/tsconfig.json:**

```json
{
  "extends": "@myorg/tsconfig/nextjs.json",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@myorg/core-domain": ["../../packages/core-domain/src/index.ts"],
      "@myorg/core-domain/*": ["../../packages/core-domain/src/*"],
      "@myorg/*": ["../../packages/*/src/index.ts"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "next-env.d.ts", ".next/types/**/*.ts"],
  "exclude": ["node_modules", ".next"]
}
```

## 2c. App Package — Node.js Service (apps/\*)

**apps/api/package.json:**

```json
{
  "name": "@myorg/api",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=20"
  },
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "format": "prettier --write --ignore-path ../../.prettierignore .",
    "format:check": "prettier --check --ignore-path ../../.prettierignore .",
    "lint": "eslint --quiet .",
    "type-check": "tsc --noEmit",
    "test": "vitest run --silent",
    "test:watch": "vitest",
    "clean": "rm -rf dist node_modules tsconfig.tsbuildinfo"
  },
  "dependencies": {
    "@myorg/core-domain": "workspace:*",
    "@myorg/database": "workspace:*",
    "dotenv": "^16.4.5",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "@myorg/eslint-config": "workspace:*",
    "@myorg/testing": "workspace:*",
    "@myorg/tsconfig": "workspace:*",
    "@types/node": "^20",
    "tsx": "^4.19.0",
    "typescript": "^5",
    "vitest": "^2.1.0"
  }
}
```

**apps/api/tsconfig.json:**

```json
{
  "extends": "@myorg/tsconfig/library.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

## 2d. Config Package — tsconfig

**packages/tsconfig/package.json:**

```json
{
  "name": "@myorg/tsconfig",
  "version": "0.0.0",
  "private": true,
  "license": "MIT",
  "files": ["base.json", "nextjs.json", "library.json"]
}
```

## 2e. Config Package — eslint-config

**packages/eslint-config/package.json:**

```json
{
  "name": "@myorg/eslint-config",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "main": "./index.js",
  "exports": {
    ".": "./index.js",
    "./base": "./base.mjs",
    "./nextjs": "./nextjs.js",
    "./library": "./library.mjs",
    "./testing": "./testing.js"
  },
  "dependencies": {
    "@eslint/js": "^9.0.0",
    "@next/eslint-plugin-next": "^15.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint-config-prettier": "^10.0.0",
    "eslint-plugin-import-x": "^4.0.0",
    "eslint-import-resolver-typescript": "^4.0.0",
    "globals": "^15.0.0",
    "typescript-eslint": "^8.0.0"
  },
  "peerDependencies": {
    "eslint": "^9.0.0",
    "typescript": "^5.0.0"
  }
}
```

**packages/eslint-config/base.mjs:**

```javascript
import { defineConfig, globalIgnores } from "eslint/config";
import tseslint from "@typescript-eslint/eslint-plugin";
import tsparser from "@typescript-eslint/parser";

const baseConfig = defineConfig([
  {
    files: ["**/*.ts", "**/*.tsx", "**/*.mts"],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        ecmaVersion: "latest",
        sourceType: "module",
      },
    },
    plugins: {
      "@typescript-eslint": tseslint,
    },
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/explicit-function-return-type": "error",
      "@typescript-eslint/explicit-module-boundary-types": "error",
      "@typescript-eslint/no-non-null-assertion": "error",
      "no-console": ["error", { allow: ["warn", "error"] }],
      "no-debugger": "error",
      "no-alert": "error",
      "prefer-const": "error",
      "no-var": "error",
      eqeqeq: ["error", "always"],
      curly: ["error", "all"],
    },
  },
  globalIgnores(["dist/**", "node_modules/**", "*.js", "*.mjs", "*.cjs"]),
]);

export default baseConfig;
```

## Stop & Confirm

Confirm package patterns before moving to Step 03.
