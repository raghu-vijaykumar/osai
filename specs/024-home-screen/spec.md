# Feature Specification: Home

**Feature Branch**: `024-home-screen`

**Created**: 2026-07-11

**Status**: Draft

**Input**: The home screen showing today's activity, current session, suggestion feed from background agents, and quick note entry. Focuses on "what's happening now" and "what should I do next" rather than analytical charts.

---

## User Scenarios & Testing

### User Story 1 - Today at a Glance (Priority: P1)

The user opens the app and sees Home, the default route. At the top: a greeting with the date, a single AI sentence summarizing the day so far ("You've been deep on the capture controls spec this morning — 3 sessions, 2 hours active"). Below: the current active session with recent events. Below that: a suggestion feed from background agents.

**Why this priority**: Home replaces the analytics-heavy dashboard with a human-readable summary. The single AI sentence is more valuable than a row of metrics.

**Independent Test**: Work for 2 hours on a topic. Open Home. Verify it shows a greeting, a relevant AI summary sentence, the current session with recent events, and suggestion cards.

**Acceptance Scenarios**:

1. **Given** the user has been active today, **When** Home loads, **Then** it shows a greeting with date, an AI summary sentence about the day's work, and the current session's recent events within 500ms
2. **Given** no activity today, **When** Home loads, **Then** it shows "No activity recorded yet today" with a prompt to start a session or open the chat bar

---

### User Story 2 - Current Session (Priority: P1)

Below the greeting, Home shows the current active session (if any): duration so far, the last 10 events in reverse chronological order, and the topics/entities detected so far. If no session is active, it shows a "Start Session" button.

**Why this priority**: The session is the user's current context. Showing it prominently helps them stay oriented.

**Independent Test**: Start a session. Work for 10 minutes on a topic. Open Home. Verify the session card shows 10 min duration, 5+ recent events, and detected entities.

**Acceptance Scenarios**:

1. **Given** an active session exists, **When** Home loads, **Then** a session card shows: duration (live counter), last 10 events, detected entities as chips
2. **Given** no active session, **When** Home loads, **Then** a "Start Session" button is shown with a brief description

---

### User Story 3 - Suggestion Feed (Priority: P2)

Below the session card, Home shows a feed of suggestion cards pushed by the background agent host (spec 064). Cards are compact, with an icon, title, short body, and 1-2 action buttons. Examples: "You were reading about CRDTs last week — want a refresher?", "Goal: Learn Rust — 0/60 min today. Start?", "Saved 'CSS Grid Guide' to 'Frontend' topic."

**Why this priority**: Suggestions make the system feel intelligent and proactive. They bridge background processing to the user's attention.

**Independent Test**: Generate events simulating auth research for 30 min. Within 2 minutes, verify a suggestion card appears on Home: "You've been working on auth for 30 min — want me to find related articles?"

**Acceptance Scenarios**:

1. **Given** a suggestion is pushed by the agent host, **When** Home is open or next loaded, **Then** the suggestion card appears in the feed with icon, title, body, and action buttons
2. **Given** a suggestion card, **When** the user clicks an action button, **Then** the action is executed (e.g., pre-fills chat bar, navigates to a view) and the card is dismissed
3. **Given** a suggestion card with "Dismiss", **When** clicked, **Then** the card disappears and a dismiss event is sent to the agent host

---

### User Story 4 - Quick Note (Priority: P2)

A compact note input at the bottom of Home. The user types and saves a note without leaving the page. Notes appear as `note.created` events and are linked to the current session/topic.

**Why this priority**: Quick notes are the simplest form of intentional knowledge capture. They should be 1 click + type + enter.

**Independent Test**: Type "Remember to check the MCP PR" in the quick note input and press Enter. Verify the note appears in the recent events timeline as a `note.created` event.

**Acceptance Scenarios**:

1. **Given** Home is open, **When** the user types in the note input and presses Enter, **Then** the note is saved as a `note.created` event and the input clears
2. **Given** a note is saved, **When** it appears in the recent events, **Then** it shows with a note icon, the text preview, and a timestamp

---

### Edge Cases

- What happens when there's no data at all (first time user)?
- How are very long activity periods handled (e.g., 16-hour day with 1000+ events)?
- What happens when no suggestions are available?
- How are suggestions that the user has already seen handled (session-level dedup)?
- What happens when the AI summary generation fails?

---

## Requirements

### Functional Requirements

- **FR-001**: Home MUST be the default route ("/") and load within 500ms
- **FR-002**: Home MUST show a greeting with current date and user's name (from profile, or "there" if not set)
- **FR-003**: Home MUST show a single AI-generated sentence summarizing today's activity so far — generated by the agent host (spec 064) every 15 minutes or on significant activity change
- **FR-004**: Home MUST show the current active session card: live duration counter, last 10 events (icon + title + time), detected entities as clickable chips
- **FR-005**: If no active session, Home MUST show a "Start Session" button that creates a new session
- **FR-006**: Home MUST show a suggestion feed — vertically scrolling list of suggestion cards from the agent host (spec 064)
- **FR-007**: Each suggestion card MUST include: icon (based on type: insight/nudge/reminder/save_confirmation), title, body text, and 1-2 action buttons
- **FR-008**: Suggestion cards MUST have a dismiss button (X) that removes the card and notifies the agent host
- **FR-009**: Action buttons on suggestion cards MUST support: pre-fill chat bar query, navigate to view, execute command
- **FR-010**: Home MUST show a quick note input at the bottom — single line, expandable, saves on Enter
- **FR-011**: Quick notes MUST be published as `note.created` events with source "home-screen"
- **FR-012**: Home MUST show an empty state for first-time users with: illustration, "Start capturing your activity" CTA, and a "What can OSAI do?" link
- **FR-013**: Home MUST use the design system (spec 059) — theme, typography, spacing, components

### Key Entities

- **DaySummary**: AI-generated summary of today. Attributes: text (one sentence), generatedAt, eventCount, activeDuration.
- **SessionCard**: The current session display. Attributes: sessionId, duration (live), recentEvents (array of EventPreview), topEntities (array of EntityChip).
- **SuggestionCard**: A proactive suggestion. Attributes: id, type (insight/nudge/reminder/save_confirmation), icon, title, body, actions (array of {label, action, value}), dismissed.
- **SuggestedAction**: An action on a suggestion card. Types: `chat` (pre-fill chat bar), `navigate` (go to view), `command` (execute system command), `dismiss`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Home loads in under 500ms with data for up to 10,000 events
- **SC-002**: Suggestion cards appear within 2 minutes of the trigger condition being met
- **SC-003**: Quick note save completes in under 100ms
- **SC-004**: Session counter updates every second with no visible lag
- **SC-005**: AI summary sentence updates within 30 seconds of a significant activity change

## Assumptions

- Built as a React page component — the default route ("/") in the app router
- AI summary sentence is generated by the agent host (spec 064) every 15 minutes or on significant event — not on every page load
- Suggestion cards come from the agent host's proactive suggestion engine (spec 064) — Home just renders them and handles interactions
- Suggestion cards are ephemeral — stored in-memory by the agent host, not persisted across app restarts (re-generated based on current context)
- Quick notes stored as events in the event store (type: "note.created", source: "home-screen")
- Empty state shows an illustration + "Start capturing" CTA + link to docs
- Source code lives at `ui/home/` in the monorepo (renamed from `024-dashboard`)
