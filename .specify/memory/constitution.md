# OSAI Constitution

## Core Principles

### I. Protocol-First

Every feature starts with a schema. The Context Protocol is the foundation that all other components build upon. Schemas must be versioned, typed, and documented before any implementation begins.

### II. Local-First Architecture

User data lives on-device by default. Cloud is optional, opt-in, and encrypted. All core functionality must work fully offline with no degradation in capability.

### III. Testable Contracts

Every protocol schema and API boundary must have independently testable contracts. Contract tests are mandatory for cross-package interfaces. CI gates on contract conformance.

### IV. Pluggable Design

All layers expose extension points. Storage backends, capture connectors, AI models, and UI components are swappable via well-defined interfaces. No vendor lock-in at any layer.

### V. Privacy by Default

Events never leave the device without explicit user consent. Connectors require per-source permission grants. Full data export and deletion APIs are required for all storage backends.

## Technical Constraints

- **Runtime**: Node.js 20+ for SDK and core services; browser APIs for extensions
- **Language**: TypeScript for SDK, protocol, knowledge engine, storage, and MCP server
- **Storage**: SQLite for local cache; pgvector for vector store; Postgres for sync
- **Package Manager**: pnpm workspaces with turborepo
- **Testing**: Vitest for unit/integration; Playwright for E2E
- **Linting**: ESLint + Prettier + tsc --strict
- **Packaging**: Individual npm packages per module (`@osai/protocol`, `@osai/storage`, etc.)

## Development Workflow

1. Spec-driven: Constitution → Specify → Plan → Tasks → Implement
2. PRs must include contract tests for new interfaces
3. Breaking changes require a protocol version bump and migration path
4. Documentation is required at every layer (schemas, APIs, architecture)

## Governance

This constitution supersedes all other practices. Amendments require documentation of the change, team approval, and a migration plan. All PRs must verify constitution compliance.

**Version**: 1.0.0 | **Ratified**: 2026-07-11 | **Last Amended**: 2026-07-11
