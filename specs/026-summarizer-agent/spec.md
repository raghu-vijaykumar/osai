# Feature Specification: Summarizer Agent

**Feature Branch**: `026-summarizer-agent`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a summarizer agent that generates daily and weekly summaries of user activity with key insights and patterns"

## User Scenarios & Testing

### User Story 1 - Daily Activity Summary (Priority: P1)

The summarizer agent automatically generates a daily summary at the end of each day (configurable time, default 9 PM). The summary includes: total events captured, active time, top apps and topics, key topics and entities, notable sessions, and an AI-written narrative paragraph connecting the day's work. The summary appears on the Home screen and is also available via the MCP API.

**Why this priority**: Daily summaries are the core feature. Users get a birds-eye view of their day without manually reviewing the timeline.

**Independent Test**: After a day of activity, trigger the daily summary generation. Verify the summary includes: total events (e.g., 1,247), active time (4h 32m), top apps (VSCode, Chrome), top projects (osai, docs), top entities (React, TypeScript, MCP), top sessions (3 sessions), and a coherent narrative paragraph.

**Acceptance Scenarios**:

1. **Given** capture has been running all day, **When** the scheduled summary time is reached, **Then** a daily summary is generated and stored within 30 seconds
2. **Given** a daily summary exists, **When** the user opens Home, **Then** the summary is displayed at the top with a calendar icon and "Today's Summary" header
3. **Given** the user wants to see a specific day, **When** navigating to a past date, **Then** that day's summary is displayed (or "No summary available" if capture wasn't running)

---

### User Story 2 - Weekly Review (Priority: P2)

The summarizer generates a weekly summary every Sunday evening (or configurable day). The weekly summary aggregates daily data plus adds: week-over-week comparisons, top trends, project progress, most-visited topics, and a "week in review" narrative. It highlights what changed compared to the previous week.

**Why this priority**: Weekly summaries reveal patterns and trends that aren't visible day-to-day. They help users understand their work habits over time.

**Independent Test**: After a week of capture, trigger the weekly summary. Verify it includes: daily breakdown (5 days with stats), week-over-week comparison ("This week: 25 hours vs. last week: 22 hours"), top trends (up 30% in React work), project progress per project, and a narrative summary.

**Acceptance Scenarios**:

1. **Given** a full week of capture data, **When** the weekly summary is generated, **Then** it includes a per-day breakdown bar with total events and active time for each day
2. **Given** last week's data exists, **When** generating this week's summary, **Then** it includes a "Compared to Last Week" section with deltas for: total events, active time, top project hours
3. **Given** the user has been working on project X all week, **When** reading the weekly summary, **Then** the narrative paragraph mentions project X as the primary focus area

---

### User Story 3 - Project-Specific Summary (Priority: P2)

Users can request a summary scoped to a specific project. The summarizer analyzes all events, sessions, and entities related to the project and produces: total time spent, key contributors, files changed, milestones reached, and a project progress narrative.

**Why this priority**: Project summaries help users track progress on specific work without manually filtering the timeline.

**Independent Test**: After working on project "osai" for a week, request a project summary for "osai". Verify it includes: total time (35 hours), files changed (47), sessions (12), key topics (MCP protocol, React UI, storage layer), and a progress narrative.

**Acceptance Scenarios**:

1. **Given** a project with associated events, **When** the user requests `summarize_project({ projectId: "osai" })`, **Then** the response includes total time, event count, date range, top contributors, top entity tags, and a narrative
2. **Given** a project with no recent activity, **When** requesting a summary, **Then** the response indicates "No recent activity" with the last activity date

---

### User Story 4 - Custom Time Range Summaries (Priority: P3)

Users can request summaries for arbitrary time ranges: "summarize last 3 hours", "summarize yesterday afternoon", "summarize this sprint (2 weeks)". The summarizer handles arbitrary date ranges and adjusts the summary format accordingly (shorter ranges get more detail, longer ranges get more aggregation).

**Why this priority**: Flexible time ranges accommodate users' diverse needs — a standup prep summary (last 24h) is different from a quarterly review.

**Independent Test**: Request a summary for "last 3 hours" while actively coding. Verify the summary is very detailed with specific file names, entities, and a granular timeline. Then request a summary for "last month" and verify it's higher-level with aggregated statistics and trends.

**Acceptance Scenarios**:

1. **Given** an active work session, **When** requesting `summarize_range({ start: "<3 hours ago>", end: "now" })`, **Then** the summary includes individual file changes, specific topics browsed, and exact active time
2. **Given** a 30-day range, **When** requesting `summarize_range({ start: "<30 days ago>", end: "now" })`, **Then** the summary includes weekly breakdowns, top projects, trends, and a high-level narrative

---

### User Story 5 - Summary Notifications and Delivery (Priority: P3)

Summaries can be delivered via notification (system tray, email, webhook). Users configure when and how they receive summaries. The agent supports: push notification (in-app), system notification (OS), scheduled email, and webhook POST to a custom URL.

**Why this priority**: Automated delivery ensures users actually see their summaries without manually checking Home.

**Independent Test**: Configure daily summary delivery to "system notification at 9 PM". At 9 PM, verify a system notification appears with the summary title and key stats (e.g., "Today's Summary: 4h 32m active, 3 projects, 1,247 events").

**Acceptance Scenarios**:

1. **Given** notification delivery is configured, **When** a summary is generated, **Then** the configured delivery channel receives the summary within 1 minute
2. **Given** webhook delivery is configured with URL `https://example.com/summaries`, **When** a summary is generated, **Then** a POST request is made to the URL with the full summary JSON body

---

### Edge Cases

- What happens on days with no activity — empty summary with note?
- How are partial days handled (capture started mid-day)?
- What happens when the scheduled generation time passes while the app is closed?
- How are timezone changes handled across weeks?
- What happens when very high activity days exceed token limits?
- How are duplicate or redundant events handled in summaries?
- What happens when AI model is unavailable for narrative generation?

## Requirements

### Functional Requirements

- **FR-001**: Summarizer agent MUST generate daily summaries automatically at a configurable time (default 9 PM)
- **FR-002**: Daily summary MUST include: total events, active time, top apps, top projects, top entities, top sessions, and an AI narrative paragraph
- **FR-003**: Summarizer agent MUST generate weekly summaries on a configurable day/time (default Sunday 9 PM)
- **FR-004**: Weekly summary MUST include all daily summary fields plus: per-day breakdown, week-over-week comparison, trends, project progress
- **FR-005**: Week-over-week comparison MUST include deltas for total events, active time, top project hours
- **FR-006**: Summarizer MUST support project-scoped summaries via `summarize_project(projectId)`
- **FR-007**: Project summary MUST include: total time, event count, date range, top entities, narrative
- **FR-008**: Summarizer MUST support custom time range summaries via `summarize_range(start, end)`
- **FR-009**: Custom range summaries MUST adapt format to range length (more detail for short ranges, more aggregation for long ranges)
- **FR-010**: Summarizer MUST support multiple delivery channels: in-app, system notification, and webhook
- **FR-011**: Users MUST be able to configure summary schedule (time, frequency, delivery channel)
- **FR-012**: Summarizer MUST handle missing data gracefully (no activity days, partial days)
- **FR-013**: Summarizer MUST be available as an MCP tool via the MCP server
- **FR-014**: Summary generation MUST be cacheable — re-requesting the same period returns cached result
- **FR-015**: Summaries MUST be persisted in storage for historical access

### Key Entities

- **Summary**: A generated summary. Attributes: id, type (daily/weekly/project/custom), period (date range), createdAt, data (structured summary object), narrative (AI-generated text), status (generated/pending/failed).
- **DailySummaryData**: Structured daily data. Attributes: date, totalEvents, activeTimeMs, topApps (array of {app, timeMs}), topProjects (array of {project, timeMs}), topEntities (array of {entity, count}), topSessions (array of {sessionId, duration, topic}), narrative.
- **WeeklySummaryData**: Structured weekly data. Attributes: weekStart, weekEnd, dailyBreakdown (array of DailySummaryData), weekOverWeek (comparison with previous week), trends (array of {topic, changePercent}), projectProgress (array of {project, hoursThisWeek, hoursLastWeek}).
- **SummaryConfig**: User's summary delivery configuration. Attributes: dailyTime, weeklyDay, weeklyTime, deliveryChannels (array of {type: inApp/system/webhook, config}).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Daily summary generation completes in under 30 seconds (for up to 50,000 events)
- **SC-002**: Weekly summary generation completes in under 2 minutes
- **SC-003**: Summary retrieval (cached) completes in under 100ms
- **SC-004**: Notifications are delivered within 1 minute of summary generation
- **SC-005**: Narrative quality: user finds the summary "useful" in 80% of cases (measured by user feedback)

## Assumptions

- Built as an OSAI agent running in the background process
- Uses the knowledge engine for event aggregation and entity extraction (specs 011-017)
- Uses an LLM for narrative generation via the centralized provider layer (spec 062) — supports local (Ollama, Transformers.js) and remote (OpenAI, Anthropic) backends
- Summaries stored in the local storage layer (SQLite) via the storage package
- Scheduled via the agent scheduling system (spec 031)
- Config stored in user preferences (localStorage or config file)
- Narrative generation can be disabled if users prefer stats-only summaries
- Summary format is a structured JSON object with optional narrative text
- Source code lives at `agents/summarizer/` in the monorepo