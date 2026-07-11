# Feature Specification: Session Detection

**Feature Branch**: `016-session-detection`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Detect work sessions by grouping contiguous related activity across sources"

## User Scenarios & Testing

### User Story 1 - Detect Sessions from Idle Gaps (Priority: P1)

The system groups events into sessions by detecting idle gaps. Events within a configurable idle threshold (default: 15 minutes) of each other belong to the same session. A gap longer than the threshold starts a new session.

**Why this priority**: Session detection is the primary mechanism for segmenting the timeline into meaningful work periods. Idle gaps are the most reliable signal — a coffee break, meeting, or lunch naturally divides work.

**Independent Test**: Generate 20 events with timestamps: 5 events at 09:00, gap of 20 min, 5 events at 09:25, gap of 2 hours, 10 events at 11:30. Verify 3 sessions are detected.

**Acceptance Scenarios**:

1. **Given** events at 10:00, 10:05, 10:12, 10:18, **When** session detection runs with 15-min idle threshold, **Then** all 4 events belong to the same session
2. **Given** events at 10:00, 10:05, then 10:25, 10:30, **When** session detection runs, **Then** 2 sessions are created (10:00–10:05 and 10:25–10:30)

---

### User Story 2 - Detect Sessions from System State (Priority: P1)

The system uses system state events (lock/unlock, sleep/wake, login/logout) as session boundaries. A lock or sleep event followed by an unlock or wake event starts a new session.

**Why this priority**: System state events are stronger signals than idle gaps. A locked workstation means the user intentionally stopped working. Sleep means no activity is possible.

**Independent Test**: Publish events before a lock, a `system.locked` event, then events after an `system.unlocked` event. Verify the lock/unlock pair creates a session boundary.

**Acceptance Scenarios**:

1. **Given** events before `system.locked` at 12:00 and after `system.unlocked` at 13:00, **When** session detection runs, **Then** two sessions are created with the boundary at 12:00
2. **Given** `system.sleep` at 23:00 and `system.wake` at 07:00, **When** session detection runs, **Then** events before 23:00 are in one session and events after 07:00 are in another

---

### User Story 3 - Session Metadata and Summary (Priority: P2)

Each session has calculated metadata: duration, event count, activity distribution, primary project, top entities, and an auto-generated name (e.g., "Morning research on Knowledge Graphs").

**Why this priority**: Session summaries provide a high-level understanding of work without reading individual events. The timeline UI renders sessions as cards with summary data.

**Independent Test**: Create a session with 15 events across 3 activity types, 2 projects, and 5 entities. Verify the session summary includes correct duration, primary activity, and top entities.

**Acceptance Scenarios**:

1. **Given** a session from 09:00 to 11:30 with 20 events, **When** querying session metadata, **Then** `duration: 9000` (seconds), `eventCount: 20`, `primaryActivity: "building"`, `topEntities: ["React", "TypeScript", "Next.js"]`
2. **Given** a session with events across 2 projects, **When** querying session metadata, **Then** `projects: ["osai", "website"]` with respective event counts

---

### User Story 4 - Session Continuity Across Gaps (Priority: P2)

Short gaps within a session (e.g., a brief distraction, switching to email for 2 minutes) don't break the session. Only gaps exceeding the idle threshold create boundaries. Sessions can also be explicitly continued by the user.

**Why this priority**: Not all gaps are session boundaries. A 2-minute check of Slack notifications is a distraction within a session, not a new session.

**Independent Test**: Generate events: work from 10:00–10:30, email check at 10:31–10:33, work resumes 10:34–11:00. Verify this is one session, not three.

**Acceptance Scenarios**:

1. **Given** events with gaps of 8, 12, 5, and 3 minutes, **When** session detection runs with a 15-min threshold, **Then** all events are in one session (all gaps < 15 min)
2. **Given** a gap of 14 minutes and 59 seconds, **When** session detection runs, **Then** events bridge the gap (under 15-min threshold)

---

### User Story 5 - Session Timeline API (Priority: P3)

The system exposes a timeline query that returns sessions (not individual events) as the primary unit. Queries support date range, project filter, activity filter, and pagination. Each session result includes its summary metadata.

**Why this priority**: The timeline UI is organized by sessions. An API that returns sessions directly enables efficient rendering without client-side aggregation.

**Independent Test**: Query sessions for the last 7 days with a project filter, verify the response contains session objects with all summary metadata and no individual events.

**Acceptance Scenarios**:

1. **Given** 14 days of data with 30 sessions, **When** querying `getTimeline({ days: 7 })`, **Then** sessions from the last 7 days are returned with summaries
2. **Given** a session has 50 events, **When** querying `getSessionEvents(sessionId, { limit: 3 })`, **Then** only 3 events are returned (not all 50)

---

### Edge Cases

- What happens when a session spans midnight — is it split across days or kept intact?
- How are sessions with a single event handled — noise or valid session?
- What happens when there's no data for days (vacation, weekend) — many separate sessions or one campaign?
- How are sessions detected in real-time (incremental) vs. batch (historical)?
- What happens when the user changes the idle threshold — are existing sessions recalculated?
- How are overlapping sessions from multiple devices handled?
- What happens when device timezone changes mid-session (travel)?

## Requirements

### Functional Requirements

- **FR-001**: System MUST detect sessions by splitting events at idle gaps exceeding a configurable threshold (default: 15 minutes)
- **FR-002**: System MUST use system state events (`system.locked`, `system.sleep`, `system.logout`) as mandatory session boundaries
- **FR-003**: System MUST persist sessions in a `sessions` table: `id`, `startTime`, `endTime`, `duration`, `eventCount`, `activityDistribution` (JSON), `projects` (JSON), `topEntities` (JSON), `sourceCount` (number of unique sources), `summary` (auto-generated text)
- **FR-004**: System MUST persist session-event assignments: `eventId`, `sessionId`, `order` (sequence within session)
- **FR-005**: System MUST compute session metadata: duration (seconds), activity distribution (fraction per activity type), primary project, top 5 entities by mention count, unique sources
- **FR-006**: System MUST auto-generate a session name from primary activity, primary project, or top entity (e.g., "Building osai — 45 min")
- **FR-007**: System MUST support real-time (incremental) session detection — new events are added to the current open session, or a new session opens when the idle threshold is exceeded
- **FR-008**: System MUST support batch session detection for historical data
- **FR-009**: System MUST expose a timeline API: `getTimeline({ startTime, endTime, project, activity, limit, offset })` returning sessions ordered by startTime descending
- **FR-010**: System MUST expose `getSession(id)`, `getSessionEvents(id, { limit, offset })`, `getAdjacentSessions(id, { before, after })`
- **FR-011**: System MUST support configurable idle threshold: `sessionDetection.idleThreshold` (seconds, default: 900 = 15 min)
- **FR-012**: System MUST publish `session.started` and `session.ended` events
- **FR-013**: System MUST handle midnight-spanning sessions — keep them intact with date range spanning both days

### Key Entities

- **Session**: A contiguous period of activity. Attributes: `id`, `startTime` (ISO 8601), `endTime`, `duration` (seconds), `eventCount`, `activityDistribution` ({learning: 0.4, building: 0.6}), `projects` ([{id, name, eventCount}]), `topEntities` ([{name, type, count}]), `sourceCount`, `summary` (generated text), `devices` (if multi-device).
- **IdleGap**: A gap between events exceeding the threshold. Attributes: `startTime` (of gap), `endTime`, `duration`, `precedingEvent`, `followingEvent`.
- **SessionBoundary**: A reason for session separation. Types: `idle_gap`, `system_lock`, `system_sleep`, `system_logout`, `manual_break`, `day_change`.
- **TimelineQuery**: A query returning sessions. Parameters: `startTime`, `endTime`, `project`, `activity`, `limit`, `offset`, `order`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Session detection on 10,000 events completes in under 5 seconds
- **SC-002**: Real-time session assignment for a new event completes in under 10ms
- **SC-003**: Session boundary accuracy > 95% (correctly identifies work sessions vs idle periods)
- **SC-004**: Timeline query returning 30 sessions completes in under 50ms
- **SC-005**: Session summary generation is meaningful > 90% of the time (validated by user ratings)

## Assumptions

- Idle gap detection uses the activity monitor's idle events + event timestamp gaps
- If idle events are not available, fall back to timestamp gaps between events alone
- Sessions are device-specific initially; cross-device session merging comes in Phase 5 (sync)
- Minimum session duration: 2 minutes (shorter sessions are noise)
- Maximum session duration: 12 hours (beyond that is likely an error or forgetfulness)
- Session summary format: `"{activity} on {project/topic} — {duration}"` (e.g., "Learning Kubernetes — 1h 15m")
- Users can manually merge sessions, split sessions, and rename sessions
- Session names use emoji-free text (APIs should be parseable)
- Source code lives at `knowledge-engine/session-detection/` in the monorepo
