# OSAI Testing Strategy

## Philosophy

Tests are a first-class deliverable, not an afterthought. OSAI uses a **test-first development loop** designed for AI agents and humans alike:

```
Write spec → Plan → Write test → Implement → Verify → Commit
                              ↑                     |
                              └── Fix ──────────────┘
```

Every change must be **testable in isolation** and **verifiable by automation**. The goal is a single command that confirms everything works.

---

## Test Pyramid

```
         ╱╲
        ╱ E2E ╲           Few — critical user journeys
       ╱────────╲
      ╱ Integration ╲     Some — Rust core IPC, sidecar communication
     ╱────────────────╲
    ╱   Unit / Component  ╲  Many — every module, every component
   ╱────────────────────────╲
  ╱       Static Analysis       ╲  All — type checks, lint, formatting
 ╱────────────────────────────────╲
```

### Layer 1: Static Analysis (gate, <5s)

| Tool | Scope | Command |
|------|-------|---------|
| `cargo clippy` | Rust core | `cargo clippy -- -D warnings` |
| `cargo fmt --check` | Rust formatting | `cargo fmt --check` |
| `tsc --noEmit` | TypeScript (webview + sidecars) | `pnpm typecheck` |
| `eslint` | TypeScript lint | `pnpm lint` |
| `prettier --check` | Formatting | `pnpm format:check` |

### Layer 2: Unit & Component Tests (fast, <30s)

| Scope | Framework | Command | Coverage Target |
|-------|-----------|---------|-----------------|
| Rust core (storage, protocol, watcher) | `cargo test` (built-in) | `cargo test` | 90%+ lines |
| React components (webview) | `vitest` + `@testing-library/react` | `pnpm test` (in `apps/desktop/`) | 80%+ lines |
| Node.js sidecars (knowledge engine, MCP) | `vitest` | `pnpm test` (per service) | 80%+ lines |
| SDK packages | `vitest` | `pnpm test` (in `sdks/`) | 90%+ lines |

### Layer 3: Integration Tests (moderate, <2min)

| Scope | Tool | Command |
|-------|------|---------|
| Rust core → SQLite | `cargo test --test integration` | `cargo test --test '*'` |
| Tauri IPC commands | Tauri test harness (`tauri::test`) | `cargo test --features test-utils` |
| Sidecar process spawn + IPC | shell tests + vitest | `pnpm test:integration` |
| Protocol encode/decode round-trip | `cargo test` + `vitest` | Cross-language validation |

### Layer 4: E2E Tests (few, <5min)

| Scope | Tool | Command |
|-------|------|---------|
| Tauri app (full React + Rust) | Playwright + Tauri test utils | `pnpm test:e2e` |
| CLI tool end-to-end | shell script | `cargo run -- help` → assert output |

---

## Coverage Requirements

| Module | Minimum Line Coverage | Enforcement |
|--------|----------------------|-------------|
| `crates/osai-core/` (Rust) | 90% | CI fails below threshold |
| `apps/desktop/src/` (React) | 80% | CI fails below threshold |
| `packages/*/` (shared libs) | 90% | CI fails below threshold |
| `services/*/` (sidecars) | 80% | CI fails below threshold |
| `sdks/*/` (language SDKs) | 90% | CI fails below threshold |

Coverage is measured per-crate/package. **New code must maintain or improve coverage** — PRs that decrease coverage are rejected.

---

## Test Quality Rules

1. **No `console.log` in tests** — use the test framework's logging
2. **No network calls in unit tests** — mock all HTTP/gRPC
3. **Deterministic** — same seed = same result; use `#[cfg(test)]` helpers for randomness
4. **Fast** — unit tests must complete in <100ms per test
5. **Isolated** — no shared state between tests (fresh SQLite `:memory:` per test)
6. **Readable** — prefer `assert_eq!(actual, expected)` over complex assertions
7. **One assertion per test** where practical — use `expect` / `should` style

---

## CI Pipeline (GitHub Actions)

See `.github/workflows/ci.yml`. Every push runs:

```
❚ lint        (clippy + tsc + eslint + prettier)    ~15s
❚ typecheck   (cargo check + tsc --noEmit)         ~30s
❚ unit        (cargo test + vitest)                 ~60s
❚ coverage    (tarpaulin + c8 → upload)             ~90s
❚ integration (cargo test --test + pnpm test:int)   ~2min
❚ e2e         (Playwright against built Tauri app)  ~5min  [PR only]
```

PRs require all checks to pass. Coverage reports are posted as PR comments.

---

## AI Agent Validation Loop

A single command runs the full validation pipeline:

```bash
# Full validation (fast path — skip E2E)
pnpm validate

# Full validation including E2E (for PRs)
pnpm validate:full
```

These commands are defined at the monorepo root in `package.json` and delegate to each layer.

---

## Per-Project Test Setup

### Rust Core (`crates/osai-core/`)

```rust
// Cargo.toml
[dev-dependencies]
tempfile = "3"        // temporary directories for SQLite files
pretty_assertions = "1"  // readable diffs

// Tests use in-memory SQLite by default
fn test_storage() -> Storage {
    Storage::memory().unwrap()
}
```

### React Webview (`apps/desktop/`)

```typescript
// vitest.config.ts — already configured in spec 003
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    coverage: { provider: 'v8', thresholds: { lines: 80 } },
  },
});
```

### Node.js Sidecars (`services/*/`)

```typescript
// Each service has its own vitest config with service-specific coverage targets
// Integration tests use a shared test SQLite database
```

---

## Pre-Commit Hooks

Via `husky` + `lint-staged`:

```json
{
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.rs": ["cargo fmt --"],
  "*.{json,md,yaml}": ["prettier --write"]
}
```

Hooks run only the changed files for speed. Full validation runs in CI.

---

## Contract Testing (Cross-Language)

The protocol spec includes **contract tests** that run across languages:

| Test | Rust | TypeScript | Python | Go |
|------|------|------------|--------|-----|
| Encode event → decode | ✓ | ✓ | ✓ | ✓ |
| Validate schema | ✓ | ✓ | ✓ | ✓ |
| Round-trip serialization | ✓ | ✓ | ✓ | ✓ |

A CI matrix job runs contract tests across all language SDKs to ensure interop.

---

## Test Environment

- **CI**: GitHub Actions (ubuntu-latest, windows-latest, macos-latest)
- **Local**: `pnpm validate` with optional `--skip-e2e` flag
- **SQLite**: In-memory (`:memory:`) for unit tests, temp file for integration
- **Tauri**: Headless test mode via `TAURI_TEST=true` env var
- **Time**: Mocked via `std::time::ManualTime` (Rust) or `vi.useFakeTimers()` (Vitest)
