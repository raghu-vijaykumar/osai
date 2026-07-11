# Tasks: CLI Tool

Input: Design documents from specs/005-cli-tool/

Prerequisites: spec.md
Tests: Tests are OPTIONAL - only include if explicitly requested.
Organization: Tasks are grouped by user story.

## Format: [ID] [P] [Story] Description

- [P]: Can run in parallel
- [Story]: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 [P] Create feature directory structure per OSAI monorepo layout
- [ ] T002 [P] Add package.json / Cargo.toml with dependencies: commander, @osai/protocol
- [ ] T003 Configure build scripts and CI integration in .github/workflows/ci.yml

---

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T004 Define data types and interfaces based on spec Key Entities
- [ ] T005 [P] Set up test framework (vitest)
- [ ] T006 [P] Implement base classes and shared utilities

Checkpoint: Foundation ready - user story implementation can begin

---

## Phase 3: User Story 1 - Publish an Event from CLI (Priority: P1) (Priority: P3)

Goal: Publish an Event from CLI (Priority: P1)

Independent Test: Verify acceptance scenarios from spec.md for this story

###Implementation for User Story 1

- [ ] T007 [US1] Implement core logic for Publish an Event from CLI (Priority: P1)
- [ ] T008 [P] [US1] Write unit tests for Publish an Event from CLI (Priority: P1)
- [ ] T009 [US1] Integrate Publish an Event from CLI (Priority: P1) with existing OSAI infrastructure

Checkpoint: US1 functional

---

## Phase 4: User Story 2 - Query Events from CLI (Priority: P1) (Priority: P3)

Goal: Query Events from CLI (Priority: P1)

Independent Test: Verify acceptance scenarios from spec.md for this story

###Implementation for User Story 2

- [ ] T010 [US2] Implement core logic for Query Events from CLI (Priority: P1)
- [ ] T011 [P] [US2] Write unit tests for Query Events from CLI (Priority: P1)
- [ ] T012 [US2] Integrate Query Events from CLI (Priority: P1) with existing OSAI infrastructure

Checkpoint: US2 functional

---

## Phase 5: User Story 3 - List and Manage Sources (Priority: P2) (Priority: P3)

Goal: List and Manage Sources (Priority: P2)

Independent Test: Verify acceptance scenarios from spec.md for this story

###Implementation for User Story 3

- [ ] T013 [US3] Implement core logic for List and Manage Sources (Priority: P2)
- [ ] T014 [P] [US3] Write unit tests for List and Manage Sources (Priority: P2)
- [ ] T015 [US3] Integrate List and Manage Sources (Priority: P2) with existing OSAI infrastructure

Checkpoint: US3 functional

---

## Phase 6: User Story 4 - Storage Management Commands (Priority: P2) (Priority: P3)

Goal: Storage Management Commands (Priority: P2)

Independent Test: Verify acceptance scenarios from spec.md for this story

###Implementation for User Story 4

- [ ] T016 [US4] Implement core logic for Storage Management Commands (Priority: P2)
- [ ] T017 [P] [US4] Write unit tests for Storage Management Commands (Priority: P2)
- [ ] T018 [US4] Integrate Storage Management Commands (Priority: P2) with existing OSAI infrastructure

Checkpoint: US4 functional

---

## Phase 7: User Story 5 - Semantic Search from CLI (Priority: P3) (Priority: P3)

Goal: Semantic Search from CLI (Priority: P3)

Independent Test: Verify acceptance scenarios from spec.md for this story

###Implementation for User Story 5

- [ ] T019 [US5] Implement core logic for Semantic Search from CLI (Priority: P3)
- [ ] T020 [P] [US5] Write unit tests for Semantic Search from CLI (Priority: P3)
- [ ] T021 [US5] Integrate Semantic Search from CLI (Priority: P3) with existing OSAI infrastructure

Checkpoint: US5 functional

---

## Phase 8: Polish and Cross-Cutting Concerns

- [ ] T022 [P] Document API and usage patterns in docs/
- [ ] T023 Code cleanup and refactoring
- [ ] T024 [P] Additional integration tests
- [ ] T025 Run end-to-end validation per spec Success Criteria

---

## Dependencies and Execution Order

- Setup (Phase 1): No dependencies - can start immediately
- Foundational (Phase 2): Depends on Setup completion - BLOCKS all user stories
- User Stories (Phase 3+): All depend on Foundational phase completion
- Polish (Final Phase): Depends on all desired user stories being complete

###User Story Dependencies
- User Story 1 (P3): Publish an Event from CLI (Priority: P1) - can start after Foundational (Phase 2)
- User Story 2 (P3): Query Events from CLI (Priority: P1) - can start after Foundational (Phase 2)
- User Story 3 (P3): List and Manage Sources (Priority: P2) - can start after Foundational (Phase 2)
- User Story 4 (P3): Storage Management Commands (Priority: P2) - can start after Foundational (Phase 2)
- User Story 5 (P3): Semantic Search from CLI (Priority: P3) - can start after Foundational (Phase 2)

###Implementation Strategy
1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Implement user stories in priority order (P1 first, then P2, then P3)
4. Each story should be independently testable
5. Polish after all stories are complete