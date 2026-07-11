# Spec 000: Implementation Control Tower

**Feature Branch**: `000-implementation-control`

**Created**: 2026-07-11

**Status**: Draft

## Purpose

This spec is the implementation control tower for the entire OSAI project. It defines:

1. **MVP 1.0 scope** — the minimum spec set for the first usable release
2. **Incremental ordering** — every spec after MVP builds on past specs without breaking them
3. **Per-spec implementation gate** — the checklist that must pass for every spec before marking it complete
4. **Milestones and checkpoints** — key integration points across spec boundaries
5. **Regression strategy** — how we guarantee nothing breaks when adding new specs
6. **References** — pointers to the build guide (`docs/development/building.md`), testing guide (`docs/development/testing.md`), and validation commands

This spec does NOT replace any other spec. It is a coordination layer that references all 59 specs (001–059) and the supporting documentation.

---

## MVP 1.0 Scope

MVP 1.0 is called **"Personal Memory"** — a desktop application that captures your digital activity, stores it locally, extracts basic understanding, and lets you browse and search your history.

### Required Specs (in implementation order)

| Order | Spec | Area | Why Required for MVP |
|-------|------|------|---------------------|
| 1 | **003** Monorepo Setup | Infrastructure | Everything builds from here |
| 2 | **001** Context Protocol | Foundation | Defines the event schema all other specs depend on |
| 3 | **002** Local Storage | Foundation | SQLite persistence layer for all data |
| 4 | **004** SDK Packages | Foundation | Protocol SDK consumed by all TypeScript packages |
| 5 | **059** Design System | UI | Component library, theming, typography — all UI views depend on it |
| 6 | **005** CLI Tool | Foundation | Manual event ingestion for testing and debugging |
| 7 | **006** Browser Extension | Capture | Primary capture source (page visits, tabs) |
| 8 | **007** VSCode Extension | Capture | IDE capture (file opens, git events) |
| 9 | **008** File Watcher | Capture | File system change monitoring |
| 10 | **009** Activity Monitor | Capture | Window focus tracking, idle detection |
| 11 | **010** Status Tray | Capture | System tray icon, capture controls, OS dark mode |
| 12 | **012** Entity Extraction | Knowledge | Extract people, technologies, topics from events |
| 13 | **013** Event Classification | Knowledge | Classify events (learning/building/researching/planning) |
| 14 | **016** Session Detection | Knowledge | Group contiguous related activity into sessions |
| 15 | **015** Project Detection | Knowledge | Auto-detect projects from event clusters |
| 16 | **014** Graph Builder | Knowledge | Store entity relationships in the graph |
| 17 | **018** Timeline View | UI | Chronological activity feed, filtering, search |
| 18 | **024** Dashboard | UI | Home screen with activity overview and widgets |
| 19 | **021** Command Bar | UI | Universal search, Ctrl+K, actions |

**Total: 19 specs for MVP 1.0**

### What MVP 1.0 Delivers

- A desktop app (Tauri) that captures browser, IDE, file system, and window activity
- Events stored locally in SQLite with full-text search
- Entities extracted, events classified, sessions and projects detected
- A knowledge graph of entities and relationships
- A timeline view with filtering, search, and density modes
- A dashboard with activity overview and customizable widgets
- A command bar for universal search and actions
- A system tray for capture control
- Consistent design system (light/dark/high-contrast themes, Inter typography, Lucide icons, responsive layout)

---

## Incremental Implementation Order

Every spec in MVP 1.0 and beyond must be implemented in the order listed below. Each spec assumes all specs listed before it are already complete and passing their gates.

### Phase 0: Foundation (MVP Part 1)

```
003 → 001 → 002 → 004 → 059 → 005
```

After Phase 0: Monorepo builds, protocol schemas exist, storage layer works, design system renders, CLI can ingest and query events.

### Phase 1: Capture (MVP Part 2)

```
006 → 007 → 008 → 009 → 010
```

After Phase 1: Events flowing in from browser, IDE, file system, and window focus. User can pause/resume capture from system tray.

### Phase 2: Basic Knowledge (MVP Part 3)

```
012 → 013 → 016 → 015 → 014
```

After Phase 2: Entities extracted from events, events classified, sessions and projects detected, relationship graph built.

### Phase 3: Core UI (MVP Part 4)

```
018 → 024 → 021
```

After Phase 3: Desktop app with timeline, dashboard, and command bar. The user can see, search, and navigate their captured activity.

### Phase 3.5: Extended UI

```
019 → 020 → 022 → 023
```

After Phase 3.5: Projects view, interactive graph view, agent panel shell, context sidebar.

### Phase 4: Knowledge Engine Advanced

```
011 → 017
```

After Phase 4: Embeddings pipeline powers the recommendation engine. Related content suggestions, semantic search.

### Phase 5: AI Agents

```
025 → 026 → 027 → 028 → 029 → 030 → 031 → 032 → 033
```

After Phase 5: MCP server exposes all capabilities. Summarizer, organizer, researcher, planner, and recommendation agents run on schedule or on demand. Agent marketplace for third-party extensions.

### Phase 6: Sync & Cloud

```
034 → 035 → 036 → 037 → 038 → 039 → 040
```

After Phase 6: Multi-device sync with CRDT conflict resolution. Cloud backup, user accounts, cloud dashboard, billing, E2EE.

### Phase 7: Ecosystem

```
041 → 042 → 043 → 044 → 045 → 046 → 047 → 048 → 049
```

After Phase 7: Python/Rust/Go SDKs published. Media, PDF, and API connectors available. Mobile app for timeline viewing. Protocol published as open standard. Community site with plugin registry.

### Phase 8: Enterprise

```
050 → 051 → 052 → 053 → 054 → 055 → 056 → 057 → 058
```

After Phase 8: Team context sharing, organizational knowledge graph, RBAC, audit logging, admin panel, SSO/SAML, on-premise deployment, analytics, enterprise SLA.

---

## Per-Spec Implementation Gate

Every spec implementation MUST pass this gate before it can be marked complete. The gate ensures incremental safety — no spec breaks what came before.

### Gate Checklist

```
[ ] IMPLEMENTATION
    [ ] All user stories from the spec are implemented
    [ ] All acceptance scenarios pass
    [ ] All edge cases from the spec are handled

[ ] CODE QUALITY
    [ ] All unit tests pass (cargo test + vitest)
    [ ] TypeScript compiles with zero errors (tsc --noEmit)
    [ ] Rust compiles with zero warnings (cargo check --all-targets --all-features)
    [ ] Lint passes (cargo clippy + eslint + prettier)
    [ ] No console.log / dbg! / debugging artifacts in production code

[ ] BUILD
    [ ] Full monorepo build succeeds (pnpm build + cargo build)
    [ ] Tauri app builds without errors (pnpm build:desktop)
    [ ] Binary smoke test: app launches and shows main window
    [ ] All packages publishable (pnpm pack --dry-run on changed packages)

[ ] REGRESSION
    [ ] All prior-spec unit tests still pass
    [ ] All prior-spec integration tests still pass
    [ ] All prior-spec E2E tests still pass
    [ ] Coverage thresholds maintained (90% Rust, 80% TS — no decrease)

[ ] DOCUMENTATION
    [ ] Architecture doc (docs/architecture/overview.md) updated if spec changes data flow or layers
    [ ] Roadmap (docs/roadmap/phases.md) updated if spec scope changed
    [ ] README or relevant guides updated for any new user-facing features
    [ ] CHANGELOG entry added for the spec
```

### Commands

```bash
# Full validation (lint + typecheck + unit)
pnpm validate

# Extended validation (adds integration + coverage)
pnpm validate:full

# E2E validation (for UI specs, requires built app)
pnpm validate:e2e

# Build verification
pnpm build
pnpm build:desktop

# Rust-specific
cargo build --release
cargo test --lib --all-features

# Coverage check
pnpm test:coverage
```

---

## Milestones & Checkpoints

Milestones mark integration points where the product becomes usable at a new level. Each milestone has a verification script or checklist.

| Milestone | Specs Complete | Verification |
|-----------|---------------|--------------|
| **M0: Scaffold** | 003 | `pnpm build` succeeds, Tauri window opens, monorepo structure intact |
| **M1: Data In** | 001, 002, 004, 005, 006, 007, 008, 009, 010 | Events from browser/IDE/files/window stored in SQLite, queryable via CLI |
| **M2: Understanding** | 012, 013, 014, 015, 016 | Entities extracted, events classified, sessions and projects detected, graph populated |
| **M3: Desktop MVP** | 018, 024, 021, 059 | Desktop app with timeline, dashboard, command bar, design system. This is MVP 1.0. |
| **M4: Full UI** | 019, 020, 022, 023 | All 7 UI views functional. Projects, graph, agent panel, context sidebar. |
| **M5: Smart** | 011, 017 | Embeddings + recommendation engine. Related content, semantic search. |
| **M6: Agents** | 025, 026, 027, 028, 029, 030, 031, 032, 033 | AI agents running. MCP server active. Agent marketplace. |
| **M7: Cloud** | 034, 035, 036, 037, 038, 039, 040 | Multi-device sync. Cloud backup. User accounts. Billing. E2EE. |
| **M8: Ecosystem** | 041, 042, 043, 044, 045, 046, 047, 048, 049 | SDKs published. Connectors available. Mobile app. Protocol standard. Community site. |
| **M9: Enterprise** | 050, 051, 052, 053, 054, 055, 056, 057, 058 | Team features. RBAC. SSO. On-premise. Enterprise SLA. |

### Checkpoint: After Every Spec

After completing a spec's implementation gate, run:

```bash
# 1. Full validation
pnpm validate:full

# 2. Build all artifacts
pnpm build
pnpm build:desktop

# 3. Binary smoke test
# (verify the app launches without crashing)

# 4. Document the completion
# Update CHANGELOG.md with the spec's user-facing changes

# 5. Mark the spec checklist as complete
# (in the tracking system or this spec's progress table)
```

---

## Regression Strategy

Each spec implementation runs against ALL existing tests. The validation commands (`pnpm validate`, `pnpm validate:full`, `pnpm validate:e2e`) cover:

1. **Lint** — catches style and anti-pattern regressions
2. **Typecheck** — catches type contract regressions across the entire codebase
3. **Unit tests** — catches logic regressions in at least 80-90% of lines
4. **Integration tests** — catches cross-module contract regressions
5. **E2E tests** — catches user-facing behavioral regressions
6. **Coverage** — prevents coverage from decreasing

### When a Regression is Found

1. The implementing spec's work is paused
2. The regression is fixed (may be in the new spec or an older spec)
3. The fix is committed with a comment referencing both the old and new spec
4. Validation is re-run from scratch
5. Only then does the new spec resume

### Cross-Spec Dependencies

If Spec B depends on Spec A:

- Spec A MUST be implemented and gated before Spec B starts
- If Spec B's implementation reveals a bug in Spec A, the bug is fixed as part of Spec B's work (with a note in the commit)
- Spec B cannot change Spec A's public API without creating a new spec and updating all consumers

---

## Implementation Progress

This table tracks progress across all specs. Updated as each spec completes its implementation gate.

| Spec | Area | Phase | Status | Target Milestone |
|------|------|-------|--------|-----------------|
| 000 | Control Tower — this spec | — | Draft | — |
| 001 | Context Protocol | Foundation | Not started | M1 |
| 002 | Local Storage (+ data retention) | Foundation | Not started | M1 |
| 003 | Monorepo Setup (+ Sentry, logging, features, secrets) | Infrastructure | Not started | M0 |
| 004 | SDK Packages | Foundation | Not started | M1 |
| 005 | CLI Tool | Foundation | Not started | M1 |
| 006 | Browser Extension | Capture | Not started | M1 |
| 007 | VSCode Extension | Capture | Not started | M1 |
| 008 | File Watcher | Capture | Not started | M1 |
| 009 | Activity Monitor | Capture | Not started | M1 |
| 010 | Status Tray (+ privacy mode) | Capture | Not started | M1 |
| 011 | Embeddings Pipeline | Knowledge | Not started | M5 |
| 012 | Entity Extraction | Knowledge | Not started | M2 |
| 013 | Event Classification | Knowledge | Not started | M2 |
| 014 | Graph Builder | Knowledge | Not started | M2 |
| 015 | Project Detection | Knowledge | Not started | M2 |
| 016 | Session Detection | Knowledge | Not started | M2 |
| 017 | Recommendation Engine | Knowledge | Not started | M5 |
| 018 | Timeline View | UI | Not started | M3 |
| 019 | Projects View | UI | Not started | M4 |
| 020 | Graph View | UI | Not started | M4 |
| 021 | Command Bar | UI | Not started | M3 |
| 022 | Agent Panel | UI | Not started | M4 |
| 023 | Context Sidebar | UI | Not started | M4 |
| 024 | Dashboard | UI | Not started | M3 |
| 025 | MCP Server | Agents | Not started | M6 |
| 026 | Summarizer Agent | Agents | Not started | M6 |
| 027 | Organizer Agent | Agents | Not started | M6 |
| 028 | Researcher Agent | Agents | Not started | M6 |
| 029 | Recommendation Agent | Agents | Not started | M6 |
| 030 | Planner Agent | Agents | Not started | M6 |
| 031 | Agent Scheduling | Agents | Not started | M6 |
| 032 | Agent Permissions | Agents | Not started | M6 |
| 033 | Agent Marketplace | Agents | Not started | M6 |
| 034 | Sync Protocol | Sync | Not started | M7 |
| 035 | Cloud Sync Service | Sync | Not started | M7 |
| 036 | Backup Service | Sync | Not started | M7 |
| 037 | User Accounts | Cloud | Not started | M7 |
| 038 | Cloud Dashboard | Cloud | Not started | M7 |
| 039 | Usage & Billing | Cloud | Not started | M7 |
| 040 | E2E Encryption | Cloud | Not started | M7 |
| 041 | Python SDK | Ecosystem | Not started | M8 |
| 042 | Rust SDK | Ecosystem | Not started | M8 |
| 043 | Go SDK | Ecosystem | Not started | M8 |
| 044 | Media Connectors | Ecosystem | Not started | M8 |
| 045 | PDF Connector | Ecosystem | Not started | M8 |
| 046 | API Connectors | Ecosystem | Not started | M8 |
| 047 | Mobile App | Ecosystem | Not started | M8 |
| 048 | Protocol Specification | Ecosystem | Not started | M8 |
| 049 | Community Site | Ecosystem | Not started | M8 |
| 050 | Team Context Sharing | Enterprise | Not started | M9 |
| 051 | Org Knowledge Graph | Enterprise | Not started | M9 |
| 052 | RBAC | Enterprise | Not started | M9 |
| 053 | Audit Logging | Enterprise | Not started | M9 |
| 054 | Team Dashboard | Enterprise | Not started | M9 |
| 055 | SSO/SAML | Enterprise | Not started | M9 |
| 056 | On-Premise Deployment | Enterprise | Not started | M9 |
| 057 | Analytics & Reporting | Enterprise | Not started | M9 |
| 058 | Enterprise SLA | Enterprise | Not started | M9 |
| 059 | Design System | UI | Not started | M3 |
| 060 | Auto-Update | Infrastructure | Not started | M3 |
| 061 | Onboarding | UI | Not started | M3 |

---

## References

### Build Guide

See `docs/development/building.md` for:

- Full build instructions (all platforms)
- Binary verification smoke tests
- Package and distribution build
- CI build reproduction steps
- Common build troubleshooting

### Testing Guide

See `docs/development/testing.md` for:

- Test pyramid (unit / integration / E2E / contract)
- Per-project test setup (Rust, React, sidecars)
- Coverage requirements and enforcement
- CI pipeline definition
- Pre-commit hooks

### Community Guides

- `CONTRIBUTING.md`: How to contribute, dev setup, PR workflow
- `SECURITY.md`: Vulnerability reporting process, supported versions, disclosure policy
- `CODE_OF_CONDUCT.md`: Community guidelines and enforcement process

### Design System

See `specs/059-design-system/spec.md` for:
- Design tokens (colors, spacing, shadows, border radius)
- Theming engine (light/dark/high-contrast)
- Typography (Inter + JetBrains Mono, type scale, text size control)
- Shared component library (22 components)
- Responsive system, icons, motion, accessibility

### Auto-Update & Onboarding

- `specs/060-auto-update/spec.md`: Update mechanism, channels, rollout, crash rollback
- `specs/061-onboarding/spec.md`: First-run inline tooltips, contextual tips, replay

### Agent Instructions

See `AGENTS.md` for:

- AI agent development loop
- Validation commands
- Coding conventions
- Branch naming

### Validation Commands

| Command | Scope |
|---------|-------|
| `pnpm validate` | Lint + typecheck + unit tests |
| `pnpm validate:full` | Above + integration + coverage |
| `pnpm validate:e2e` | Build desktop + Playwright E2E |
| `pnpm build` | Full monorepo build |
| `pnpm build:desktop` | Tauri desktop app build |
| `cargo build --release` | Rust release build |
| `pnpm test:rust` | Rust unit tests |
| `pnpm test:coverage` | Coverage report generation |
