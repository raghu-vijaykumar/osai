# Feature Specification: SDK Packages

**Feature Branch**: `004-sdk-packages`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Create @osai/protocol and @osai/storage npm packages with typed exports, bundling, and CI publishing"

## User Scenarios & Testing

### User Story 1 - Import and Use @osai/protocol (Priority: P1)

A connector developer installs `@osai/protocol` and gets fully typed APIs for defining schemas, validating events, and publishing context. Everything is tree-shakeable and works in Node.js and browsers.

**Why this priority**: The protocol package is the public API that all connectors and consumers depend on. It must be the most polished package.

**Independent Test**: A test script imports `publish`, `ContextEvent`, and `validateSchema` from `@osai/protocol`, creates an event, validates it, and calls publish — all with full TypeScript type checking.

**Acceptance Scenarios**:

1. **Given** a TypeScript project with `@osai/protocol` installed, **When** importing `{ publish, query }` from `@osai/protocol`, **Then** TypeScript resolves the types without errors
2. **Given** `@osai/protocol` imported in a browser bundle (Vite), **When** calling `validateSchema()`, **Then** it works without Node.js-specific dependencies

---

### User Story 2 - Import and Use @osai/storage (Priority: P1)

A knowledge engine developer installs `@osai/storage` and gets a fully typed storage client with SQLite persistence and vector search. The package handles database initialization automatically.

**Why this priority**: The storage package is the backbone of all data persistence. Every other component depends on it.

**Independent Test**: A test imports `createStorageAdapter` from `@osai/storage`, initializes it with `:memory:`, stores events, queries them, and verifies results — all typed.

**Acceptance Scenarios**:

1. **Given** `@osai/storage` installed, **When** calling `createStorageAdapter({ dbPath: ':memory:' })`, **Then** it returns a `StorageAdapter` instance with all methods typed
2. **Given** a `StorageAdapter` instance, **When** calling `store(event)` followed by `get(event.id)`, **Then** the returned event matches the stored one with correct types

---

### User Story 3 - Dual Export: ESM + CJS (Priority: P2)

Both packages are published with ESM (`import`) and CJS (`require`) entry points so they work in any Node.js project regardless of module system.

**Why this priority**: The ecosystem is split between ESM and CJS. Dual exports maximize compatibility.

**Independent Test**: A CJS script using `require('@osai/protocol')` and an ESM script using `import ... from '@osai/protocol'` both resolve correctly and produce identical behavior.

**Acceptance Scenarios**:

1. **Given** a `package.json` with `"type": "module"`, **When** importing `@osai/protocol` via `import`, **Then** the ESM entry point is used
2. **Given** a `package.json` without `"type": "module"`, **When** importing via `require()`, **Then** the CJS entry point is used

---

### User Story 4 - Type Declarations Published (Priority: P2)

All public APIs have `.d.ts` declaration files included in the published package. Consumers get full IntelliSense and type checking without additional `@types/` packages.

**Why this priority**: Type declarations are the primary DX differentiator for a TypeScript-first SDK.

**Independent Test**: After `npm pack` and install, a consumer project references a function from the package and TypeScript resolves its parameter and return types correctly.

**Acceptance Scenarios**:

1. **Given** a published package, **When** inspecting `publish()` in an editor, **Then** the signature shows `(event: ContextEvent) => string` with full parameter documentation
2. **Given** a type error in consumer code (e.g., passing a string instead of `ContextEvent`), **When** running `tsc`, **Then** the error references the correct type from `@osai/protocol`

---

### User Story 5 - Package Documentation (Priority: P3)

Each package has a README with installation, quick start, API reference, and links to the full protocol spec. Key exports have JSDoc comments that appear in IDE hover tooltips.

**Why this priority**: Documentation reduces support burden and enables self-service adoption.

**Independent Test**: A developer who has never used OSAI can publish their first event in under 5 minutes by following the README.

**Acceptance Scenarios**:

1. **Given** `@osai/protocol` README, **When** following the quick start, **Then** a working publish-query loop is demonstrated in under 20 lines of code
2. **Given** a public API function, **When** hovering in VS Code, **Then** JSDoc shows the function's purpose, parameters, return type, and example

---

### Edge Cases

- What happens when `better-sqlite3` native module fails to install on a platform?
- How are circular dependencies between protocol and storage handled at the package level?
- What happens if a consumer bundles the package twice (ESM + CJS) in the same app?
- How are Node.js built-in modules (like `crypto` for UUIDs) polyfilled for browser bundles?
- What happens when a consumer is on an older TypeScript version that doesn't support some syntax?

## Requirements

### Functional Requirements

- **FR-001**: `@osai/protocol` MUST export: `ContextEvent`, `EventSchema`, `Source`, `Permission`, `publish()`, `query()`, `validateSchema()`, `registerSchema()`, `getSchema()`, `listSources()`, `createSource()`
- **FR-002**: `@osai/storage` MUST export: `StorageAdapter`, `createStorageAdapter()`, `QueryFilter`, `QueryResult`, `SearchResult`, `StorageConfig`
- **FR-003**: Both packages MUST have ESM (`"type": "module"` compatible) and CJS (`require()`) entry points
- **FR-004**: Both packages MUST include TypeScript declaration files (`.d.ts`) in their published output
- **FR-005**: Both packages MUST use `tsup` for bundling with `--format esm,cjs --dts`
- **FR-006**: Both packages MUST target `es2022` in their `tsconfig.json`
- **FR-007**: Both packages MUST have a `"module": "node16"` or `"moduleResolution": "bundler"` in their tsconfig
- **FR-008**: Both packages MUST declare `"sideEffects": false` in `package.json` for tree-shaking
- **FR-009**: `@osai/storage` MUST list `better-sqlite3` as a peer dependency (not bundled)
- **FR-010**: Both packages MUST have a `"publishConfig": { "access": "public" }` in `package.json`
- **FR-011**: Both packages MUST export a clean public API surface — internal types prefixed with `_` or placed in `src/internal/`
- **FR-012**: `@osai/protocol` MUST be a leaf dependency (no internal OSAI deps)
- **FR-013**: `@osai/storage` MUST depend on `@osai/protocol` for `ContextEvent` type
- **FR-014**: Both packages MUST have a README.md in the package root with installation, quick start, and API reference
- **FR-015**: All public exports MUST have JSDoc comments with `@param` and `@returns` tags

### Key Entities

- **@osai/protocol**: Core protocol SDK. Zero runtime dependencies. Works in Node.js and browser. Exports: event types, validation, publish/consume APIs, schema registry, permissions.
- **@osai/storage**: Storage SDK. Depends on `@osai/protocol`. Node.js only (uses `better-sqlite3`). Exports: `StorageAdapter`, initialization, query/search interfaces.
- **tsup**: Build tool that bundles TypeScript to ESM + CJS with type declarations in one step.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `@osai/protocol` published package size < 50KB (gzipped)
- **SC-002**: `@osai/storage` published package size < 100KB (gzipped, excluding native `better-sqlite3`)
- **SC-003**: `import { publish } from '@osai/protocol'` resolves in under 100ms in a Node.js project
- **SC-004**: `pnpm build` for both packages completes in under 10 seconds
- **SC-005**: All public APIs pass TypeScript strict mode with zero `any` types in declarations
- **SC-006**: Both packages have 100% of public API covered by at least one integration test

## Assumptions

- Packages are built with `tsup` — no manual Rollup/Webpack configuration
- `better-sqlite3` is a peer dependency because it's a native module that must match the consumer's Node.js version and platform
- For browser compatibility, `@osai/protocol` uses `crypto.getRandomValues` (available in all modern browsers) for UUID generation, or a pure-JS fallback
- Package versioning is handled by changesets (spec 003)
- The `dist/` directory is the sole publish target — source files are not included
- ESLint and Prettier configs are inherited from the monorepo root (spec 003)
