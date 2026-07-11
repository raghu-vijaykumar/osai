# OSAI Build Guide

This document describes how to build, compile, package, and verify OSAI across all platforms. It is referenced by the Implementation Control Tower (spec 000) as the canonical build verification reference.

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Rust | 1.80+ | Tauri backend, core crate, Rust SDK |
| Node.js | 20+ | TypeScript packages, sidecars, webview |
| pnpm | 9+ | Monorepo package manager |
| Tauri CLI | 2.x | Desktop app bundling |
| cargo-tauri | 2.x | Tauri build and dev commands |

### Platform-specific

- **Windows**: WebView2 (included in Windows 11, requires runtime on Windows 10), Visual Studio Build Tools with C++ workload
- **macOS**: Xcode Command Line Tools
- **Linux**: `libwebkit2gtk-4.1-dev`, `libgtk-3-dev`, `libappindicator3-dev`, `librsvg2-dev`

## Quick Start

```bash
# Install dependencies
pnpm install

# Build everything
pnpm build

# Run in development mode
cd apps/desktop && pnpm tauri dev
```

## Build Layers

### 1. TypeScript Packages

```bash
# Build all TypeScript packages (protocol, storage, UI components, sidecars)
pnpm build

# Build a specific package
pnpm --filter @osai/protocol build
pnpm --filter @osai/storage build
pnpm --filter @osai/ui build
```

Output: `packages/*/dist/`

### 2. Rust Core

```bash
# Debug build (fast, for development)
cargo build

# Release build (optimized, for distribution)
cargo build --release

# Build only the core crate
cargo build -p osai-core

# Check compilation without producing binaries (fast)
cargo check --all-targets --all-features
```

Output: `target/debug/` or `target/release/`

### 3. Tauri Desktop App

```bash
# Development mode (hot-reload webview)
cd apps/desktop && pnpm tauri dev

# Production build
cd apps/desktop && pnpm tauri build

# Build from root
pnpm build:desktop
```

Output:
- **Windows**: `apps/desktop/src-tauri/target/release/OSAI Setup.exe` + `.msi`
- **macOS**: `apps/desktop/src-tauri/target/release/OSAI.dmg` + `.app`
- **Linux**: `apps/desktop/src-tauri/target/release/OSAI.deb` + `.AppImage`

### 4. Connectors

```bash
# Browser extension
cd connectors/browser-extension && pnpm build

# VSCode extension
cd connectors/vscode-extension && pnpm build && pnpm vsce package

# Other connectors follow the same pattern
```

### 5. Sidecars

```bash
# Knowledge engine
cd services/knowledge-engine && pnpm build

# MCP server
cd services/mcp-server && pnpm build

# All sidecars
pnpm build --filter=./services/*
```

## Binary Verification Smoke Tests

After building, each binary must pass a smoke test before the build is considered valid.

### Desktop App

```bash
# Verify the binary exists
Test-Path "apps/desktop/src-tauri/target/release/osai.exe"  # Windows
# or
test -f "apps/desktop/src-tauri/target/release/osai"         # macOS/Linux

# Launch and verify it doesn't crash immediately
# (Run with --no-sandbox for CI environments)
./apps/desktop/src-tauri/target/release/osai --help

# Verify the app window appears (CI: use Tauri test harness)
pnpm test:e2e -- --grep "app launches"
```

### CLI Tool

```bash
# Verify CLI binary exists and responds
cargo run --release -- --help

# Verify basic event ingestion
cargo run --release -- ingest --event-type page_visit --title "test"

# Verify query works
cargo run --release -- query --last-24h
```

### Packages

```bash
# Verify packages build and are publishable
pnpm --filter @osai/protocol pack --dry-run
pnpm --filter @osai/storage pack --dry-run
```

## CI Build Reproduction

To reproduce a CI build locally:

```bash
# Same order as CI
pnpm install
pnpm lint
pnpm typecheck
pnpm test:unit
pnpm test:rust
pnpm test:integration
pnpm build
pnpm build:desktop

# Optional: coverage
pnpm test:coverage
```

## Distribution Build

For release distribution:

```bash
# 1. Clean build
pnpm clean
pnpm install

# 2. Full validation
pnpm validate:full

# 3. Release builds
cargo build --release
cd apps/desktop && pnpm tauri build

# 4. Package connector artifacts
cd connectors/browser-extension && pnpm build && pnpm zip

# 5. Verify all artifacts
# (run smoke tests)
```

## Common Build Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `webview2` not found | Missing WebView2 runtime | Install from Microsoft |
| `linker` errors on Windows | Missing MSVC build tools | `rustup toolchain install stable-x86_64-pc-windows-msvc` |
| `glib` version mismatch (Linux) | Old system libraries | Update system or use Docker build |
| `pnpm build` fails with TS errors | TypeScript mismatch | `pnpm install && pnpm typecheck` |
| Tauri build fails with cargo errors | Rust version too old | `rustup update` |
| macOS code signing fails | Missing certificate | `export APPLE_SIGNING_IDENTITY="-"` for dev builds |

## Artifact Output Summary

| Artifact | Location | Format |
|----------|----------|--------|
| Desktop installer | `apps/desktop/src-tauri/target/release/bundle/` | `.exe` / `.dmg` / `.deb` |
| Desktop portable | `apps/desktop/src-tauri/target/release/` | `.exe` / `.AppImage` |
| Browser extension | `connectors/browser-extension/dist/` | `.zip` |
| VSCode extension | `connectors/vscode-extension/` | `.vsix` |
| CLI tool | `target/release/osai-cli` | binary |
| npm packages | `packages/*/dist/` | `.tgz` (via `pnpm pack`) |
| SDK packages | `sdks/*/dist/` | language-specific |
