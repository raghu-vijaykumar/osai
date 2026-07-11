# OSAI — AI Agent Instructions

This file tells AI coding agents how to work within this project.

## Implementation Loop

Every spec follows this loop, enforced by the Implementation Control Tower (spec 000):

```
Read spec 000 → Read target spec → Write tests → Implement → Run gate → Commit
                                              ↑                   |
                                              └─── Fix ───────────┘
```

The gate checklist is defined in `specs/000-implementation-control/spec.md` under "Per-Spec Implementation Gate". Every spec MUST pass the full gate before being marked complete.

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

1. Read spec 000 to determine the current implementation target
2. Read the spec for the feature you're implementing
3. Write tests that match the spec's acceptance scenarios
4. Implement until tests pass
5. Run the full implementation gate (spec 000 checklist)
6. Commit with a reference to the spec number

## Conventions

- **TypeScript/React**: Functional components, Tailwind CSS, design system tokens (spec 059), `vitest` + `@testing-library/react`
- **Rust core**: `rusqlite` for SQLite, `refinery` for schema migrations, `notify` crate for file watching, `cargo test`
- **Node.js sidecars**: Knowledge engine, MCP server, agents — `vitest` for tests, `umzug` for schema migrations
- **Branch naming**: `###-feature-name` matching spec number (e.g., `001-context-protocol`)
- **No comments in code** unless the logic is non-obvious
- **No emojis** in any file
- **Coverage gate**: 90% Rust core, 80% webview/sidecars

## Directory Layout

```
crates/osai-core/      — Rust core (SQLite, IPC, file watcher, tray)
apps/desktop/          — Tauri app (React webview + Tailwind)
packages/              — Shared TypeScript libs (@osai/protocol, @osai/storage, @osai/ui)
services/              — Node.js sidecars (knowledge engine, MCP server, agents)
sdks/                  — Language SDKs (python, rust, go)
connectors/            — Capture connectors (browser ext, vscode, media, pdf, api)
protocol/              — Protocol schemas, sync protocol, specification
specs/                 — All feature specifications (000–064)
docs/                  — Architecture, roadmap, development guides
```

## References

- **Spec 000**: Implementation Control Tower — order, gates, milestones, tracking
- `docs/development/building.md`: Build, compile, package, binary verification
- `docs/development/testing.md`: Test pyramid, coverage, CI pipeline
- `specs/059-design-system/spec.md`: Design tokens, components, theming
- `specs/060-auto-update/spec.md`: Auto-update mechanism, channels, rollout
- `specs/061-onboarding/spec.md`: First-run onboarding and contextual tips
- `specs/062-llm-integration/spec.md`: Provider abstraction, BYOK, model routing, cost tracking
- `specs/063-capture-controls/spec.md`: Per-connector enable/disable, pause/resume, schedules, central Settings UI
- `specs/064-agent-host/spec.md`: Background agent host — event intake, proactive suggestions, Save-to-KB, chat dispatch

## Community

- `CONTRIBUTING.md`: How to contribute, dev setup, PR workflow
- `SECURITY.md`: Vulnerability reporting process
- `CODE_OF_CONDUCT.md`: Community guidelines

## CI

See `.github/workflows/ci.yml`. Every push runs: lint → typecheck → unit → coverage → integration → (PR only) e2e.
