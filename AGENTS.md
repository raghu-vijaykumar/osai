# OSAI — AI Agent Instructions

This file tells AI coding agents how to work within this project.

## Validation Loop

Before committing any change, run the full validation:

```bash
# Quick validation (lint + typecheck + unit tests)
pnpm validate

# Full validation (adds integration + coverage)
pnpm validate:full

# E2E (for UI changes, adds Playwright tests)
pnpm validate:e2e
```

## Test First

1. Read the spec for the feature you're implementing
2. Write tests that match the spec's acceptance scenarios
3. Implement until tests pass
4. Run validation
5. Commit

## Conventions

- **TypeScript/React**: Functional components, Tailwind CSS, `vitest` + `@testing-library/react`
- **Rust core**: `rusqlite` for SQLite, `notify` crate for file watching, `cargo test`
- **Node.js sidecars**: Knowledge engine, MCP server, agents — `vitest` for tests
- **Branch naming**: `###-feature-name` matching spec number (e.g., `001-context-protocol`)
- **No comments in code** unless the logic is non-obvious
- **No emojis** in any file
- **Coverage gate**: 90% Rust core, 80% webview/sidecars

## Directory Layout

```
crates/osai-core/      — Rust core (SQLite, IPC, file watcher, tray)
apps/desktop/          — Tauri app (React webview + Tailwind)
packages/              — Shared TypeScript libs (@osai/protocol, @osai/storage)
services/              — Node.js sidecars (knowledge engine, MCP server, agents)
sdks/                  — Language SDKs (python, rust, go)
connectors/            — Capture connectors (browser ext, vscode, media, pdf, api)
protocol/              — Protocol schemas, sync protocol, specification
docs/                  — Architecture, roadmap, development guides
```

## CI

See `.github/workflows/ci.yml`. Every push runs: lint → typecheck → unit → coverage → integration → (PR only) e2e.
