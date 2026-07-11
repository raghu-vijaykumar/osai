# Feature Specification: Monorepo Build System

**Feature Branch**: `003-monorepo-setup`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Set up pnpm workspaces, turborepo, shared TypeScript config, build scripts, and linting"

## User Scenarios & Testing

### User Story 1 - Build All Packages with One Command (Priority: P1)

A developer clones the repo, runs a single command, and all packages (protocol, storage, CLI, etc.) are built in dependency order with caching.

**Why this priority**: Developer experience is paramount. Time-to-first-build under 30 seconds sets the bar for iteration speed.

**Independent Test**: Run `pnpm build` from repo root and verify all packages produce `dist/` with valid JavaScript and type declarations.

**Acceptance Scenarios**:

1. **Given** a clean checkout with only `pnpm install` run, **When** executing `pnpm build`, **Then** all packages build successfully without errors
2. **Given** a package with changed source, **When** re-running `pnpm build`, **Then** turborepo cache misses for changed packages and hits for unchanged ones

---

### User Story 2 - Shared TypeScript Configuration (Priority: P1)

All packages use a shared `tsconfig.base.json` that enforces strict mode, consistent module resolution, and output paths. Individual packages extend the base with package-specific overrides.

**Why this priority**: Consistent TypeScript settings prevent subtle cross-package type mismatches and reduce boilerplate.

**Independent Test**: A type error in one package that violates strict null checks is caught at build time across all dependent packages.

**Acceptance Scenarios**:

1. **Given** a package with `extends: "../../tsconfig.base.json"`, **When** running `tsc --noEmit`, **Then** strict mode, exactOptionalPropertyTypes, and noUncheckedIndexedAccess are enforced
2. **Given** a cross-package import (e.g., `@osai/protocol` → `@osai/storage`), **When** building, **Then** types are resolved correctly via project references

---

### User Story 3 - Lint and Format Enforced (Priority: P2)

ESLint and Prettier are configured at the root with consistent rules across all packages. Pre-commit hooks prevent non-compliant code from being committed.

**Why this priority**: Consistent code style reduces review friction and prevents formatting debates.

**Independent Test**: A file with a lint error fails `pnpm lint` and a file with formatting issues is fixed by `pnpm format`.

**Acceptance Scenarios**:

1. **Given** a TypeScript file with an unused variable, **When** running `pnpm lint`, **Then** ESLint reports the error and exits non-zero
2. **Given** a TypeScript file with inconsistent indentation, **When** running `pnpm format`, **Then** Prettier rewrites the file in place

---

### User Story 4 - Test Runner Configured (Priority: P2)

Vitest is configured at the root with shared settings. Tests run across all packages with a single command and support watch mode for development.

**Why this priority**: Fast, consistent test execution is essential for TDD workflows.

**Independent Test**: A test file in any package is discovered and run by `pnpm test`.

**Acceptance Scenarios**:

1. **Given** test files in both `protocol/` and `storage/` packages, **When** running `pnpm test`, **Then** all tests from both packages execute and report results
2. **Given** `pnpm test -- --watch`, **When** a test file is modified, **Then** only the affected tests re-run

---

### User Story 5 - Package Publishing (Priority: P3)

A CI pipeline builds, versions, and publishes packages to npm when a release tag is pushed. Turborepo handles dependency-ordered publishing.

**Why this priority**: Automated publishing reduces human error and friction in the release process.

**Independent Test**: Running `pnpm publish -r --dry-run` from CI produces the correct list of packages to publish in dependency order.

**Acceptance Scenarios**:

1. **Given** a release commit with changesets, **When** publishing, **Then** packages with changes get a version bump and all dependents are updated
2. **Given** a package that hasn't changed, **When** publishing, **Then** it is skipped

---

### Edge Cases

- What happens when a package's dependency is not yet built (circular dependency)?
- How are native modules (like `better-sqlite3`) handled during build and publish?
- What happens if `pnpm-lock.yaml` is out of date with `package.json`?
- How does turborepo handle cache invalidation when config files change?
- What happens when a package has both ESM and CJS builds?

## Requirements

### Functional Requirements

- **FR-001**: System MUST use pnpm workspaces with all packages listed in `pnpm-workspace.yaml`
- **FR-002**: System MUST use turborepo for task orchestration with caching configured in `turbo.json`
- **FR-003**: System MUST define a root `tsconfig.base.json` with strict mode settings that packages extend
- **FR-004**: System MUST configure project references in TypeScript for cross-package type resolution
- **FR-005**: System MUST use ESLint with `typescript-eslint` at the root, extended by packages
- **FR-006**: System MUST use Prettier as the sole formatter with a root `.prettierrc`
- **FR-007**: System MUST use Vitest as the test runner with root `vitest.workspace.ts` config
- **FR-008**: System MUST define root `package.json` scripts: `build`, `test`, `lint`, `format`, `typecheck`, `clean`
- **FR-009**: System MUST configure `.npmrc` with `shamefully-hoist=true` for proper package resolution
- **FR-010**: System MUST configure turborepo pipeline with `build`, `test`, `lint`, `typecheck` tasks respecting dependency order
- **FR-011**: System MUST use lefthook or husky for pre-commit hooks (lint-staged)
- **FR-012**: System MUST use changesets for versioning and changelog generation
- **FR-013**: Each package MUST be scoped under `@osai/` namespace
- **FR-014**: Each package MUST have a `package.json` with `publishConfig` for public access
- **FR-015**: System MUST support both ESM and CJS output formats
- **FR-016**: System MUST configure git hooks via lefthook (or simple pre-commit script) for formatting staged files

### Key Entities

- **Package**: An npm package under `packages/` or any top-level directory with a `package.json`. Named `@osai/<name>`.
- **Turbo Pipeline**: Task definitions in `turbo.json` specifying dependency order, caching behavior, and outputs.
- **Workspace**: A pnpm workspace member directory. All packages are workspace members.
- **Changeset**: A markdown file describing a version change, used by `@changesets/cli` for automated versioning.
- **tsconfig.base.json**: Root TypeScript configuration extended by all packages via `extends`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `pnpm install` (no lockfile) completes in under 30 seconds
- **SC-002**: `pnpm build` (initial, no cache) completes in under 30 seconds
- **SC-003**: `pnpm build` (with full cache) completes in under 5 seconds
- **SC-004**: `pnpm lint` completes on the full codebase in under 10 seconds
- **SC-005**: `pnpm test` with no tests yet fails gracefully (exit 0 with "no test files found" message)
- **SC-006**: All TypeScript strict mode checks pass with zero errors on initial setup

## Assumptions

- pnpm 9+ is used as the package manager
- Node.js 20+ LTS is the minimum target
- All packages are TypeScript-first with source in `src/` and output in `dist/`
- Packages use `tsup` for bundling (ESM + CJS output from TypeScript)
- The monorepo root is at the repository root (`C:\workspace\code\osai\`)
- All existing directories (`protocol/`, `storage/`, `ingestion/`, etc.) become workspace packages
- No legacy build tools (no Webpack, no Babel) — modern toolchain only
