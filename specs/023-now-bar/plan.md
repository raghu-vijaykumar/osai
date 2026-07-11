# Implementation Plan: Now

Branch: 023-now-bar | Date: 2026-07-11 | Spec: spec.md

Input: Feature specification from specs/023-now-bar/spec.md

## Summary

Implement the Now feature as specified. This spec covers 0 functional requirements across 3 user stories with 0 acceptance scenarios.

## Technical Context

**Language/Version**: TypeScript (React)

**Primary Dependencies**: React, Tailwind, @osai/ui

**Storage**: @osai/storage (event log)

**Testing**: vitest + @testing-library/react

**Target Platform**: webview component

**Project Type**: UI component

## Constitution Check

Gate: Must pass before implementation.

- Follow OSAI coding conventions (TypeScript: functional components, Tailwind, vitest; Rust: rusqlite, refinery, cargo test)
- No comments in code unless logic is non-obvious
- No emojis in files
- Coverage gate: 90% Rust core, 80% webview/sidecars
- Branch naming: 023-now-bar

## Project Structure

###Documentation (this feature)

```text
specs/023-now-bar/
 spec.md              # Feature specification
 plan.md              # This file
 tasks.md             # Task breakdown
```

###Source Code (repository root)

```text
ui/... (TBD by implementation)
```

## User Stories

- **US1 (P3)**: At-a-Glance Awareness (Priority: P1)
- **US2 (P3)**: Goal Progress (Priority: P2)
- **US3 (P3)**: Single Suggestion Chip (Priority: P2)
