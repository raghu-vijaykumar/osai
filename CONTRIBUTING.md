# Contributing to OSAI

## Getting Started

1. Clone the repo: `git clone https://github.com/raghu-vijaykumar/osai.git`
2. Install dependencies: `pnpm install`
3. Build everything: `pnpm build`
4. Run validation: `pnpm validate`

## Development Workflow

OSAI uses a spec-driven development process coordinated by the Implementation Control Tower (spec 000).

1. Read `specs/000-implementation-control/spec.md` to find the next spec to work on
2. Read the target spec for the feature you're implementing
3. Create a branch: `###-feature-name` (e.g., `001-context-protocol`)
4. Write tests that match the spec's acceptance scenarios
5. Implement until tests pass
6. Run the full implementation gate (see spec 000 — Per-Spec Implementation Gate)
7. Commit and push

## Validation

Before every commit:

```bash
pnpm validate        # lint + typecheck + unit
pnpm validate:full   # + integration + coverage
```

## Code Standards

- **TypeScript/React**: Functional components, Tailwind CSS, design system tokens (spec 059)
- **Rust**: clippy-clean, `cargo fmt`, `rusqlite` for SQLite
- **No comments in code** unless the logic is non-obvious
- **No emojis** in any file

## Pull Request Process

1. Every PR must reference the spec it implements
2. All CI checks must pass (lint, typecheck, unit, coverage, integration)
3. Coverage must not decrease (90% Rust, 80% TS)
4. UI changes must include E2E tests
5. Docs must be updated if the spec changes architecture or user-facing behavior

## Questions

Open a discussion or ask in the project's issues.
