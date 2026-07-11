# Feature Specification: Onboarding

**Feature Branch**: `061-onboarding`

**Created**: 2026-07-11

**Status**: Draft

## Overview

OSAI uses inline sequential tooltips to introduce new users to key features. No modal wizards, no sign-up walls. Tooltips point at actual UI elements, teach one concept at a time, and can be dismissed individually or restarted from Settings.

## User Scenarios & Testing

### User Story 1 - First-Launch Onboarding Sequence (Priority: P1)

On first launch (no existing data), a subtle tooltip points to Home: "Welcome to OSAI — your memory for everything you do. Your activity will appear here as it's captured." After dismissing, the next tooltip points to the Chat Bar (Ctrl+K): "Press Ctrl+K to ask questions or run commands." Then the History icon: "Browse your past activity in the History view." Each tooltip has a "Next" button, a "Skip all" link, and a progress indicator (1 of 5).

**Independent Test**: Clear app data. Launch the app. Verify the first tooltip appears over the Home area with welcome text. Click "Next" and verify it points to the Chat Bar (Ctrl+K). Click "Skip all" and verify all tooltips are dismissed. Re-launch the app and verify no tooltips appear.

**Acceptance Scenarios**:

1. **Given** a fresh installation, **When** the app launches for the first time, **Then** the first onboarding tooltip appears centered on the home screen within 1 second
2. **Given** a tooltip is showing, **When** the user clicks "Next", **Then** the current tooltip fades out and the next tooltip fades in over the correct element (200ms transition)
3. **Given** a tooltip is showing, **When** the user clicks "Skip all" or presses Escape, **Then** all remaining tooltips are dismissed and onboarding is marked as complete
4. **Given** the full sequence is completed, **When** the user re-launches the app, **Then** no onboarding tooltips appear

### User Story 2 - Tooltip Dismissal and Replay (Priority: P1)

Individual tooltips can be dismissed by clicking the backdrop or pressing Escape. A question mark icon ("?") in the status bar shows remaining onboarding steps when clicked. In Settings > General, "Replay onboarding" restarts the sequence from step 1.

**Independent Test**: Open a tooltip, click outside it (on the backdrop). Verify the tooltip closes and the remaining steps stay available (not marked complete). Open Settings > General, click "Replay onboarding". Verify the first tooltip appears again.

**Acceptance Scenarios**:

1. **Given** an onboarding tooltip, **When** the user clicks the semi-transparent backdrop, **Then** the tooltip closes without marking the step as completed
2. **Given** no current tooltip, **When** the user clicks the "?" icon in the status bar, **Then** if there are unfinished steps, the next incomplete step is shown
3. **Given** onboarding was completed or skipped, **When** the user clicks "Replay onboarding" in Settings, **Then** the sequence restarts from step 1

### User Story 3 - Contextual Tips (Priority: P2)

Beyond the initial sequence, contextual one-time tips appear when the user first performs certain actions: "Sessions group related activity — click to expand" (first history use), "Try asking a question in natural language" (first chat bar use). These tips have a "Got it" button and a "Don't show again" toggle in their footer.

**Independent Test**: Open History for the first time. Verify a contextual tip appears: "Sessions group related activity — click to expand." Click "Got it." Navigate away and back to History. Verify the tip does not reappear.

**Acceptance Scenarios**:

1. **Given** a user opens the Chat Bar for the first time, **When** they type a query, **Then** a one-time tip appears: "Try typing 'What did I work on yesterday?' for AI-powered answers"
2. **Given** a contextual tip is showing, **When** the user clicks "Don't show this again", **Then** all future tips from that category are suppressed

### Edge Cases

- What happens if the user resizes the window while a tooltip is pointing at a specific element?
- How are tooltips handled on very small windows (< 800px)?
- What happens if the target element doesn't exist yet (lazy loaded)?
- How do tooltips interact with modals, dialogs, or the Chat Bar overlay?
- What happens if the user switches themes while a tooltip is showing?
- How are tooltips handled for users who reload the app mid-onboarding?

## Requirements

### Functional Requirements

- **FR-001**: Onboarding MUST consist of inline tooltips anchored to specific UI elements — no modals, no full-screen wizards
- **FR-002**: First-launch sequence MUST include at least 4 steps: Welcome (Home), Chat Bar (Ctrl+K), History, Settings
- **FR-003**: Each tooltip MUST show: title, description (1–2 sentences), step counter ("3 of 5"), "Next" button, "Skip all" link
- **FR-004**: Tooltip transitions MUST use fade (200ms) with no repositioning lag
- **FR-005**: Tooltip positioning MUST auto-adjust if the target element moves (e.g., sidebar resize) using a resize observer
- **FR-006**: Tooltips MUST NOT appear over transparent/empty areas — if the target element is hidden (lazy loaded), the tooltip waits up to 3 seconds, then skips to the next step
- **FR-007**: Tooltips MUST be dismissible by: clicking "Next", clicking "Skip all", pressing Escape, or clicking the backdrop
- **FR-008**: Onboarding state MUST be persisted in localStorage: `completedSteps: number[]`, `dismissedTips: string[]`, `completed: boolean`
- **FR-009**: Contextual one-time tips MUST trigger on first use of specific features (history expand session, chat bar search)
- **FR-010**: Contextual tips MUST include: title, description, "Got it" button, optional "Don't show this again" toggle, and an "x" close button
- **FR-011**: Settings MUST include "Replay onboarding" button under General section
- **FR-012**: A "?" icon in the status bar MUST show remaining unfinished steps when clicked (or "Onboarding complete" checkmark if done)
- **FR-013**: Tooltips MUST use design system components (spec 059) — tooltip styling, color tokens, border radius, shadow elevation
- **FR-014**: Tooltip backdrop MUST be semi-transparent (`--os-opacity-scrim`) and clickable to dismiss
- **FR-015**: If the app restarts mid-onboarding, progress MUST be preserved — resume from the last step shown

### Key Entities

- **OnboardingState**: Current onboarding progress. Attributes: completedSteps (number[]), dismissedTips (string[]), completed (boolean), startedAt (timestamp), lastStepShown (number).
- **OnboardingStep**: A single step in the onboarding sequence. Attributes: id (number), target (CSS selector), title, description, position (top/bottom/left/right/auto), category (initial/contextual), featureKey (for contextual tips).
- **ContextualTip**: A one-time tip for a specific feature. Attributes: id (string), featureKey (string), targetSelector, title, description, position, suppressible (boolean).

## Success Criteria

- **SC-001**: First-launch onboarding renders within 1 second of app load
- **SC-002**: Tooltip transitions complete in under 250ms
- **SC-003**: Tooltip repositions within 100ms of target element resize/move
- **SC-004**: 90%+ of new users see at least 3 onboarding steps before dismissing
- **SC-005**: Onboarding state consumes under 5KB in localStorage
- **SC-006**: Zero layout shift when tooltip backdrop is active

## Assumptions

- Built as a React component (`OnboardingProvider`) wrapping the app root — renders tooltips via absolute positioning + portal
- Target elements are identified by `data-onboarding="step-{id}"` attributes added to existing components
- No interaction tracking or analytics — onboarding state is purely local
- Contextual tips registry is defined in a single configuration object — easy to add/remove
- The "?" status bar icon is part of the shell layout (not view-specific)
- First-launch detection: check `localStorage` for existing `onboarding-completed` flag — if absent, it's a first launch

## Dependencies

- Depends on spec 059 (design system) for tooltip component, color tokens, shadow, typography
- Depends on spec 003 (monorepo) for `packages/ui/` component library
- Optional: if the user has existing data (reinstall), skip first-launch sequence and show only contextual tips
