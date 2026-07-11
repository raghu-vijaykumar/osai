# Feature Specification: Timeline View

**Feature Branch**: `018-timeline-view`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build the timeline view showing chronological activity feed across all sources with filtering and search"

## User Scenarios & Testing

### User Story 1 - Session-Based Timeline (Priority: P1)

The timeline displays sessions as primary visual units, with each session expandable to show individual events. Sessions are rendered as cards with duration, activity summary, project name, and top entities. Events within a session are shown as a chronological list with type icons.

**Why this priority**: Sessions are the most natural unit for browsing past activity. Individual events within a session provide drill-down detail.

**Independent Test**: Load the timeline for the current day showing 5 sessions. Verify each session card displays duration, project, activity type, and expand/collapse toggles correctly.

**Acceptance Scenarios**:

1. **Given** 8 sessions exist today, **When** the timeline loads, **Then** 8 session cards are displayed ordered by startTime descending, each showing duration, project name (if detected), activity distribution bar, and event count
2. **Given** a session card is clicked/expanded, **When** the user expands it, **Then** the individual events appear in chronological order with source icon, type label, timestamp, and truncated summary

---

### User Story 2 - Filtering and Search (Priority: P1)

Users filter the timeline by date range, source, activity type, project, and free-text search. Filters are composable (AND logic). Active filters are displayed as removable chips above the timeline.

**Why this priority**: The unfiltered timeline shows everything. Filters make it useful for specific questions — "what did I do in VSCode yesterday?" or "show me Kubernetes research from last week."

**Independent Test**: Apply filters: source=browser-extension, activity=learning, date=today. Verify only browser-based learning events from today are shown.

**Acceptance Scenarios**:

1. **Given** mixed events from browser, VSCode, and file watcher, **When** filtering by `source: vscode-extension`, **Then** only VSCode events are visible in the timeline
2. **Given** events across 3 projects, **When** filtering by `project: osai`, **Then** only sessions containing osai project events are shown
3. **Given** filter chips for "source: browser" and "activity: learning" are active, **When** the user clicks the "X" on a chip, **Then** that filter is removed and results update

---

### User Story 3 - Infinite Scroll and Calendar Navigation (Priority: P2)

The timeline supports infinite scroll backward in time (loading older sessions on scroll). A mini-calendar or date picker allows jumping to a specific date. A "Jump to Today" button resets the view.

**Why this priority**: Scrolling is the primary navigation pattern for browsing. Calendar jumps are for targeted lookups. Both patterns are needed.

**Independent Test**: Scroll to the bottom of the timeline, verify the next batch of sessions loads automatically. Use the date picker to jump to a date 2 weeks ago, verify the timeline shows that date's sessions.

**Acceptance Scenarios**:

1. **Given** the timeline shows the most recent 20 sessions, **When** the user scrolls to the bottom, **Then** the next 20 sessions load automatically (no duplicate, no gap)
2. **Given** a date picker is available, **When** the user selects "2026-07-01", **Then** the timeline jumps to sessions from that date with a smooth scroll animation

---

### User Story 4 - Event Detail Panel (Priority: P2)

Clicking on an individual event opens a detail panel (slide-over or modal) showing full event metadata: source, type, timestamp, payload, associated project, session context, entities mentioned, and classification. Links allow navigating to related events.

**Why this priority**: The timeline shows summaries. The detail panel provides full context for any event — what was the full URL, what entities were extracted, what project was it in.

**Acceptance Scenarios**:

1. **Given** a `page.content` event in the timeline, **When** clicked, **Then** a detail panel shows: full URL, page title, extracted text preview (500 chars), entities mentioned, activity classification, project assignment
2. **Given** an event detail panel is open, **When** clicking on an entity tag (e.g., "Kubernetes"), **Then** the timeline filters to show other events mentioning that entity

---

### User Story 5 - Timeline Visual Density Controls (Priority: P3)

Users switch between density modes: Compact (shows 2x more sessions per viewport), Normal (default cards), and Detailed (expanded session cards by default). Preference is persisted.

**Why this priority**: Different users prefer different densities. Power users scanning through many sessions prefer compact. New users exploring prefer detailed.

**Independent Test**: Switch from Normal to Compact, verify the viewport now shows approximately 2x the number of session cards. Switch to Detailed, verify all sessions are pre-expanded with events visible.

**Acceptance Scenarios**:

1. **Given** the timeline is in Normal mode showing 5 session cards, **When** switching to Compact, **Then** 10+ session cards are visible with condensed information (no event previews, shorter summaries)
2. **Given** the timeline is in Detailed mode, **When** a session is collapsed by the user, **Then** it stays collapsed even in Detailed mode (respects manual overrides)

---

### Edge Cases

- What happens when there are zero events for a selected date range?
- How are currently-active sessions (in progress) shown in the timeline?
- What happens when the user scrolls back 6+ months with thousands of sessions (performance)?
- How are events with missing timestamps placed in the timeline?
- What happens when events arrive in real-time while the user is browsing the timeline?
- How does the timeline handle timezone changes?
- What happens when the user has events from multiple timezones?

## Requirements

### Functional Requirements

- **FR-001**: Timeline MUST display sessions as the primary visual unit, with expand/collapse for individual events
- **FR-002**: Each session card MUST show: duration (formatted), date/time range, project name (or "No project"), activity distribution (colored bar), event count, source icons, top 3 entities
- **FR-003**: Timeline MUST support real-time updates — new events/sessions appear as they are ingested
- **FR-004**: Timeline MUST support filtering by: source, activity type, project, entity, date range, and free-text search
- **FR-005**: Active filters MUST be displayed as removable chips above the timeline
- **FR-006**: Timeline MUST support infinite scroll — paginate sessions with page size of 20
- **FR-007**: Timeline MUST include a date picker for jumping to specific dates and a "Jump to Today" button
- **FR-008**: Timeline MUST support density modes: `compact`, `normal`, `detailed`
- **FR-009**: Event detail panel MUST show: event ID, source, type, timestamp, full payload JSON, project, session, entities, classification, and links to related events
- **FR-010**: Clicking an entity tag in any event MUST filter the timeline to that entity
- **FR-011**: Timeline MUST display a live indicator for currently-active sessions with pulsing dot
- **FR-012**: Timeline MUST render with optimized virtualization — only render visible rows (react-window or similar)

### Key Entities

- **SessionCard**: A timeline session unit. Displays: duration, time range, project, activity bar, event count, entity tags. Expandable to show events.
- **EventRow**: An individual event within an expanded session. Displays: source icon, time, type badge, summary text (truncated to 100 chars), clickable for detail panel.
- **FilterChip**: A removable filter indicator. Attributes: `field` (source/activity/project/etc), `value`, `onRemove` callback.
- **DatePicker**: Calendar or date input for jumping to specific dates. Supports single day, week, and custom range.
- **EventDetailPanel**: Slide-over or modal showing full event metadata and navigation to related content.
- **DensityControl**: A toggle group (Compact / Normal / Detailed) that adjusts the timeline rendering density.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Timeline initial load (20 sessions) renders in under 200ms
- **SC-002**: Infinite scroll loads next page in under 100ms
- **SC-003**: Filter application updates results in under 150ms
- **SC-004**: Event detail panel opens in under 100ms
- **SC-005**: Timeline remains responsive at 60fps with 500+ session cards rendered via virtualization
- **SC-006**: Real-time event updates appear in the timeline within 1 second of ingestion

## Assumptions

- Timeline is part of the Tauri desktop app (Rust backend + React webview)
- Virtualization library: `@tanstack/react-virtual` or `react-window`
- UI framework: React with Tailwind CSS (consistent with other UI components)
- Session data comes from the session detection API (spec 016)
- Real-time updates use the OSAI event bus (WebSocket or Server-Sent Events)
- Date formatting uses `date-fns` or `Intl.DateTimeFormat` with the user's locale
- Timezone: display in user's local timezone; store in UTC
- Empty state: illustration + "No activity in this date range. Try adjusting your filters." message
- Source code lives at `ui/timeline/` in the monorepo
