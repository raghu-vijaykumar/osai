# Feature Specification: Now

**Feature Branch**: `023-now-bar`

**Created**: 2026-07-11

**Status**: Draft

**Input**: A thin, persistent awareness bar that shows what the background agents currently know: active app/window, current file, active goals with progress, capture status, and a single suggestion chip from the agent host (spec 064). Informs the user that OSAI is aware without being distracting.

---

## User Scenarios & Testing

### User Story 1 - At-a-Glance Awareness (Priority: P1)

The user sees a thin bar at the bottom or side of the app window. It shows: the active app/window name with icon, the current file (if in VSCode/editor), a capture status dot (green/yellow/red/gray), and a single suggestion chip from the agent host. The bar is always visible but unobtrusive.

**Why this priority**: Users need to know OSAI is working and aware. The Now bar provides this reassurance without requiring them to open any view.

**Independent Test**: Switch between Chrome and VSCode. Verify the Now bar updates within 5 seconds to show the active app and current file name. Pause capture. Verify the status dot turns gray.

**Acceptance Scenarios**:

1. **Given** the user is active in VSCode editing `chat-bar.tsx`, **When** they glance at the Now bar, **Then** it shows VSCode icon + "VSCode — chat-bar.tsx" and a green status dot
2. **Given** capture is paused, **When** the user looks at the Now bar, **Then** the status dot is gray

---

### User Story 2 - Goal Progress (Priority: P2)

If the user has active goals (spec 030), the Now bar shows a compact goal progress indicator: "Learn Rust — 45/60 min" with a thin progress bar. Multiple goals cycle every 10 seconds.

**Why this priority**: Goals need constant gentle visibility to be effective. The Now bar is the perfect subtle reminder.

**Independent Test**: Set a goal "Read 30 min daily". Spend 15 min reading. Verify the Now bar shows "Read — 15/30 min" with a half-filled progress bar.

**Acceptance Scenarios**:

1. **Given** an active goal with progress today, **When** the Now bar is visible, **Then** it shows the goal name and fractional progress (e.g., "Learn Rust — 12/60 min")
2. **Given** multiple active goals, **When** displayed, **Then** they cycle every 10 seconds showing one at a time

---

### User Story 3 - Single Suggestion Chip (Priority: P2)

The Now bar shows the highest-priority active suggestion from the agent host. It's a single compact chip: icon + short text. Clicking it opens the Chat Bar with the suggestion's query pre-filled. The chip auto-updates when the suggestion expires or a higher-priority one appears.

**Why this priority**: The Now bar is a persistent surface for one suggestion — just enough to catch the user's attention without being noisy.

**Independent Test**: Work on auth for 30 min. Within 2 minutes, verify the Now bar shows a chip: "Auth patterns refresher?" Click it — verify the Chat Bar opens with "Show me what I learned about auth" pre-filled.

**Acceptance Scenarios**:

1. **Given** a high-priority suggestion exists, **When** the Now bar is visible, **Then** it shows a compact chip with icon and short text
2. **Given** a suggestion chip, **When** clicked, **Then** the Chat Bar opens with the suggestion's query pre-filled
3. **Given** no active suggestions, **When** the Now bar is visible, **Then** no chip is shown (status dot + active app only)

---

### Edge Cases

- What happens when the user switches apps 20 times in a minute — does the bar flicker?
- How is sensitive content handled in the active file/URL display?
- What happens when the agent host is not running — does the suggestion chip area go blank?
- How does the bar behave in a very small window?

---

## Requirements

### Functional Requirements

- **FR-001**: Now bar MUST be a thin, persistent strip at the bottom of the app window (or collapsible to the side)
- **FR-002**: Now bar MUST display: active app icon + name, active file name (if available), capture status dot, and optionally a suggestion chip and goal progress
- **FR-003**: Active app and file MUST update within 5 seconds of a focus change (pulled from the event log's most recent `app.focused` or `file.opened` event)
- **FR-004**: Capture status dot MUST show: green (all connectors active), yellow (some disconnected), gray (paused), red (error)
- **FR-005**: Now bar MUST display the single highest-priority active suggestion from the agent host as a compact chip — icon + short text, clickable to pre-fill Chat Bar
- **FR-006**: Suggestion chip MUST update automatically when the current suggestion expires or a higher-priority one arrives
- **FR-007**: Now bar MUST display goal progress when goals are active — format: "Goal name — current/target" with a thin progress bar
- **FR-008**: When multiple goals are active, they MUST cycle every 10 seconds
- **FR-009**: Now bar MUST be collapsible via a toggle button — collapsed state shows only the status dot
- **FR-010**: Now bar MUST NOT flicker during rapid app switching — debounce UI updates to at most once per 2 seconds
- **FR-011**: Active file/URL display MUST be truncated to 40 characters
- **FR-012**: Now bar MUST use the design system (spec 059) — theme, typography, spacing, components

### Key Entities

- **NowState**: The current state displayed in the Now bar. Attributes: activeApp (icon + name), activeFile (name, truncated), statusDot (green/yellow/gray/red), suggestionChip (SuggestionCard or null), activeGoals (array of GoalProgress).
- **GoalProgress**: A goal's progress display. Attributes: goalName, current (minutes), target (minutes), unit (min/sessions/events).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Active app/file updates within 5 seconds of focus change
- **SC-002**: Goal progress updates within 30 seconds of matched event
- **SC-003**: Suggestion chip appears within 2 minutes of trigger condition
- **SC-004**: Now bar consumes under 1% CPU and 20MB memory
- **SC-005**: No UI flicker during rapid app switching (20 switches in 10 seconds)

## Assumptions

- The Now bar is a React component rendered in the app shell, not a separate window
- Active app/file is derived from the event log's most recent `app.focused` / `file.opened` events — no separate polling
- Suggestion chips come from the agent host (spec 064) via IPC — the Now bar subscribes to a suggestion stream
- Goal progress is computed by the agent host (spec 064) from event-goal matches
- The status dot color is determined by the Rust core's connector health status (spec 063)
- Source code lives at `ui/now-bar/` in the monorepo (renamed from `023-context-sidebar`)
