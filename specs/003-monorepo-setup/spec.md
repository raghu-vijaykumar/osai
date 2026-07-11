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
- How are native modules (like `better-sqlite3` for Node.js sidecars) handled during build and publish?
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
- **FR-007**: System MUST use Vitest as the TypeScript test runner with root `vitest.workspace.ts` config
- **FR-008**: System MUST define root `package.json` scripts: `build`, `test`, `lint`, `format`, `typecheck`, `clean`, `validate`, `validate:full`, `validate:e2e`
- **FR-009**: System MUST configure `.npmrc` with `shamefully-hoist=true` for proper package resolution
- **FR-010**: System MUST configure turborepo pipeline with `build`, `test`, `lint`, `typecheck` tasks respecting dependency order
- **FR-011**: System MUST use lefthook or husky for pre-commit hooks (lint-staged)
- **FR-012**: System MUST use changesets for versioning and changelog generation
- **FR-013**: Each package MUST be scoped under `@osai/` namespace
- **FR-014**: Each package MUST have a `package.json` with `publishConfig` for public access
- **FR-015**: System MUST support both ESM and CJS output formats
- **FR-016**: System MUST configure git hooks via lefthook for formatting staged files

### Testing Infrastructure Requirements

- **FR-017**: System MUST define root `pnpm validate` script that runs: lint → typecheck → unit tests (exit on first failure)
- **FR-018**: System MUST define root `pnpm validate:full` script that runs: lint → typecheck → unit → integration → coverage
- **FR-019**: System MUST define root `pnpm validate:e2e` script for E2E Playwright tests (runs after full build)
- **FR-020**: System MUST configure turborepo pipeline so `test` depends on `build` for each package
- **FR-021**: Rust core (`crates/osai-core/`) MUST use `cargo test` with tests runnable from root via `pnpm test:rust`
- **FR-022**: Root `vitest.workspace.ts` MUST include all TypeScript packages (apps, services, packages, sdks)
- **FR-023**: Each TypeScript package MUST have a `vitest.config.ts` with resolved `project` reference
- **FR-024**: Coverage MUST be collected per-package and aggregated at root via `pnpm test:coverage`
- **FR-025**: Minimum coverage thresholds: 90% for Rust core and SDKs, 80% for webview and sidecars
- **FR-026**: CI MUST define separate jobs for: lint, typecheck, unit, coverage, integration, e2e (PR only), contract
- **FR-027**: Pre-commit hooks MUST run lint-staged on: `*.{ts,tsx}` (eslint + prettier), `*.rs` (cargo fmt)
- **FR-028**: Test framework MUST support `--watch` mode for development (vitest --watch, cargo watch)
- **FR-029**: All tests MUST be runnable in CI with a single root command: `pnpm ci:all` (full pipeline, exit on failure)

### Cross-Cutting Infrastructure

#### Error & Crash Monitoring (Sentry)

- **FR-030**: System MUST integrate Sentry (free tier) for error and crash monitoring in both Rust and TypeScript runtimes
- **FR-031**: Rust core MUST capture `panic!` and `Result::unwrap()` crashes via `sentry-rust` crate — breadcrumbs for file I/O, IPC, and SQLite operations
- **FR-032**: React webview MUST capture `unhandledrejection` and `onerror` via `@sentry/react` — breadcrumbs for component rendering, API calls, user interactions
- **FR-033**: Node.js sidecars MUST capture uncaught exceptions and promise rejections via `@sentry/node`
- **FR-034**: Sentry MUST be opt-in — user consent collected at first launch; can be disabled in Settings at any time
- **FR-035**: Sentry DSN MUST be configurable via environment variable `SENTRY_DSN` with a fallback to the OSAI project DSN
- **FR-036**: Sentry events MUST NOT include event payload content or personal data — only metadata (error type, stack trace, breadcrumbs, performance spans)
- **FR-037**: System MUST add breadcrumbs for: storage operations (store/query count), IPC calls, capture status toggles, feature flag evaluations

#### Structured Logging

- **FR-038**: System MUST output structured logs in JSON format — one line per log entry
- **FR-039**: Log levels MUST be: `trace`, `debug`, `info`, `warn`, `error` — initial default: `info`
- **FR-040**: Rust logging MUST use the `tracing` crate with a JSON formatter subscriber
- **FR-041**: TypeScript logging MUST use a structured logger (e.g., `pino`) — console transport for development, file transport for production
- **FR-042**: Log output MUST include: timestamp (ISO 8601), level, module/component, message, and structured context (event_id, session_id, source where applicable)
- **FR-043**: Log files MUST be written to `~/.osai/logs/` with daily rotation and 30-day retention
- **FR-044**: CLI tool MUST support `osai logs` command to view, filter (`--level`, `--module`), and tail (`--follow`) logs
- **FR-045**: Log level MUST be configurable via environment variable `OSAI_LOG_LEVEL` and Settings UI

#### Feature Flags

- **FR-046**: System MUST implement a feature flag system with a configuration file at `~/.osai/features.json`
- **FR-047**: Feature flags MUST support three states: `enabled`, `disabled`, `default` (uses the hardcoded default)
- **FR-048**: Feature flags MUST be overridable via environment variable: `OSAI_FEATURE_{FLAG_NAME}=true|false`
- **FR-049**: System MUST expose an API for runtime feature flag checks: `isFeatureEnabled('flag-name'): boolean`
- **FR-050**: Feature flags MUST be used for gradual rollout of experimental features (e.g., nightly-only features)
- **FR-051**: Feature flag configuration MUST be readable at Settings > Advanced > Feature Flags for debugging
- **FR-052**: A list of all feature flags with descriptions and defaults MUST be documented in `docs/development/feature-flags.md`

#### Secret Management

- **FR-053**: System MUST use the OS-native keychain for storing secrets: Windows Credential Manager (`wincred`), macOS Keychain (`securityd`), Linux Secret Service (`libsecret`)
- **FR-054**: Secrets stored in keychain include: LLM provider API keys (OpenAI, Anthropic, etc.), cloud sync credentials, E2EE keys
- **FR-055**: System MUST provide a fallback encrypted file store at `~/.osai/secrets.enc` when keychain is unavailable (e.g., headless CI, some Linux DEs)
- **FR-056**: Encryption for the fallback store MUST use AES-256-GCM with a key derived from a user-provided master password via Argon2id
- **FR-057**: System MUST expose a `SecretStore` interface with methods: `set(key, value)`, `get(key)`, `delete(key)`, `list()` — abstracting keychain vs encrypted file
- **FR-058**: Secrets MUST never be logged, printed to stdout, or included in Sentry breadcrumbs
- **FR-059**: Secret access from Node.js sidecars MUST go through the Rust core via IPC — sidecars never access the keychain directly

### Key Entities

- **Package**: An npm package under `packages/` or any top-level directory with a `package.json`. Named `@osai/<name>`.
- **Turbo Pipeline**: Task definitions in `turbo.json` specifying dependency order, caching behavior, and outputs.
- **Workspace**: A pnpm workspace member directory. All packages are workspace members.
- **Changeset**: A markdown file describing a version change, used by `@changesets/cli` for automated versioning.
- **tsconfig.base.json**: Root TypeScript configuration extended by all packages via `extends`.
- **LogEntry**: A structured log line. Attributes: timestamp, level, module, message, context (key-value pairs).
- **FeatureFlag**: A configuration flag. Attributes: name, description, defaultValue, currentValue, overrides (env/file).
- **SecretEntry**: A stored secret. Attributes: key (string), value (encrypted), createdAt, accessedAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `pnpm install` (no lockfile) completes in under 30 seconds
- **SC-002**: `pnpm build` (initial, no cache) completes in under 30 seconds
- **SC-003**: `pnpm build` (with full cache) completes in under 5 seconds
- **SC-004**: `pnpm lint` completes on the full codebase in under 10 seconds
- **SC-005**: `pnpm test` with no tests yet fails gracefully (exit 0 with "no test files found" message)
- **SC-006**: All TypeScript strict mode checks pass with zero errors on initial setup
- **SC-007**: `pnpm validate` completes the full validation pipeline in under 3 minutes
- **SC-008**: CI pipeline completes (excluding E2E) in under 10 minutes
- **SC-009**: Code coverage is reported per-package with thresholds enforced in CI
- **SC-010**: Pre-commit hooks complete on 10 staged files in under 5 seconds

## Assumptions

- pnpm 9+ is used as the package manager
- Node.js 20+ LTS is the minimum target
- All packages are TypeScript-first with source in `src/` and output in `dist/`
- Packages use `tsup` for bundling (ESM + CJS output from TypeScript)
- The monorepo root is at the repository root (`C:\workspace\code\osai\`)
- All existing directories (`protocol/`, `storage/`, `ingestion/`, etc.) become workspace packages
- No legacy build tools (no Webpack, no Babel) — modern toolchain only
