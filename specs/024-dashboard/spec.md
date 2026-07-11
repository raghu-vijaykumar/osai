# Feature Specification: Dashboard

**Feature Branch**: `024-dashboard`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a dashboard that serves as the home screen, showing activity overview, insights, recent work, and quick access to all views"

## User Scenarios & Testing

### User Story 1 - Activity Overview (Priority: P1)

The dashboard opens as the default/home view. It shows a today's activity summary: total events captured, active time, top apps used, top projects worked on, and sessions completed. Data is for "today" by default with the ability to view "this week" and "this month".

**Why this priority**: The overview is the first thing users see. It gives immediate value by showing what they've accomplished.

**Independent Test**: Open the dashboard. Verify it shows: Total Events (e.g., 1,247), Active Time (e.g., 4h 32m), Top Apps (VSCode 2h, Chrome 1.5h), Top Projects (osai 3h, docs 1h), Sessions (5). Verify the "This Week" toggle changes data to a broader range.

**Acceptance Scenarios**:

1. **Given** the dashboard is the home view, **When** the user opens the app, **Then** the dashboard loads with today's activity overview within 500ms
2. **Given** the dashboard is showing today's data, **When** the user clicks "This Week", **Then** the overview updates to show aggregated weekly data with a smooth transition
3. **Given** no activity today, **When** the dashboard loads, **Then** it shows a "No activity recorded today" state with a prompt to start capturing

---

### User Story 2 - Recent Events Timeline (Priority: P1)

Below the overview, the dashboard shows a scrollable timeline of the most recent events (up to 50). Each event shows time, app icon, title, and a brief preview. Users can click any event to see details or navigate to the full Timeline view.

**Why this priority**: Recent events provide the most immediate value — users can quickly scan what they've been doing.

**Independent Test**: Scroll down on the dashboard. Verify the recent events timeline shows the last 50 events in reverse chronological order with time, app icon, and title. Click an event and verify a detail panel opens showing the full event data.

**Acceptance Scenarios**:

1. **Given** the dashboard, **When** the user scrolls to the "Recent Events" section, **Then** the last 50 events are displayed in a timeline format with time, app icon, and truncated title
2. **Given** a specific event in the timeline, **When** the user clicks it, **Then** a detail sheet slides up showing: full timestamp, app, duration (if applicable), content preview, and related entities/projects
3. **Given** the timeline section, **When** the user clicks "View All Events", **Then** the app navigates to the full Timeline view

---

### User Story 3 - Widget Dashboard (Priority: P2)

The dashboard supports customizable widgets that users can add, remove, rearrange, and configure. Built-in widgets: Active Sessions, Top Projects, Weekly Trend (events/day chart), Entity Cloud (frequently mentioned entities), Recent Files, and Capture Status. Widgets can be sized (small, medium, large).

**Why this priority**: Customization makes the dashboard personally relevant. Different users care about different metrics.

**Independent Test**: Open dashboard settings, click "Customize Dashboard", remove "Top Projects" widget, add "Weekly Trend" widget in its place, resize "Capture Status" to large. Verify the dashboard re-renders with the new layout and widgets.

**Acceptance Scenarios**:

1. **Given** the dashboard, **When** the user clicks the "Customize" button, **Then** the dashboard enters edit mode with widgets showing drag handles, remove buttons, and resize controls
2. **Given** edit mode, **When** the user drags "Weekly Trend" from position 2 to position 4, **Then** the layout updates with a smooth animation
3. **Given** edit mode, **When** the user clicks the "X" on "Entity Cloud" widget, **Then** the widget is removed and the layout reflows
4. **Given** a widget is removed, **When** the user opens "Add Widget" panel, **Then** available widgets are shown with name, description, and "Add" button

---

### User Story 4 - AI-Generated Daily Summary (Priority: P2)

The dashboard shows an AI-generated daily summary at the top: a paragraph summarizing the day's work, highlighting key accomplishments, and noting patterns. The summary is generated from the day's events, sessions, and entities.

**Why this priority**: AI summaries transform raw activity data into narrative insights. Users get a birds-eye view of their day.

**Independent Test**: After a day of activity, open the dashboard. Verify the daily summary paragraph appears at the top with content like "Today you spent 4 hours on frontend development, focusing on the command bar component. You had 5 sessions, with the longest being a 45-minute deep work session on TypeScript types."

**Acceptance Scenarios**:

1. **Given** there are events from today, **When** the dashboard loads, **Then** an AI-generated summary appears at the top with a sparkle icon and timestamp ("Generated 2 minutes ago")
2. **Given** the daily summary, **When** the user clicks "Regenerate", **Then** a new summary is generated and replaces the current one
3. **Given** no activity today, **When** the dashboard loads, **Then** no summary section appears

---

### User Story 5 - Quick Actions and Shortcuts (Priority: P3)

The dashboard provides quick action buttons: "Start Session", "Add Note", "Capture Screenshot", "Export Report", "Open Settings". These are prominently placed in a toolbar at the top of the dashboard.

**Why this priority**: Quick actions reduce friction for common tasks. Users shouldn't need to navigate menus for frequent operations.

**Acceptance Scenarios**:

1. **Given** the dashboard, **When** the user clicks "Start Session", **Then** a new session begins with a toast confirmation and the session timer appears in the status bar
2. **Given** the dashboard, **When** the user clicks "Add Note", **Then** a quick-note dialog opens (inline, not modal) where the user can type and save

---

### Edge Cases

- What happens when there's no data at all (first time user)?
- How are very long activity periods handled (e.g., 16-hour day)?
- What happens when AI summary generation fails?
- How does the dashboard handle data from multiple timezones?
- What happens when widget data sources are unavailable?
- How are overlapping sessions handled in the activity timeline?

## Requirements

### Functional Requirements

- **FR-001**: Dashboard MUST load as the default home view within 500ms
- **FR-002**: Dashboard MUST show a today's activity overview: total events, active time, top apps, top projects, sessions count
- **FR-003**: Overview data MUST be toggleable between Today, This Week, and This Month
- **FR-004**: Dashboard MUST show a scrollable recent events timeline (up to 50 events) in reverse chronological order
- **FR-005**: Each event in the timeline MUST show: timestamp, app icon, title, and be clickable for detail view
- **FR-006**: Dashboard MUST support customizable widgets: add, remove, rearrange, and resize (small/medium/large)
- **FR-007**: Built-in widgets MUST include: Active Sessions, Top Projects, Weekly Trend (events/day chart), Entity Cloud, Recent Files, Capture Status
- **FR-008**: Edit mode for widgets MUST be accessible with a "Customize" button
- **FR-009**: Dashboard MUST show an AI-generated daily summary paragraph at the top (when data is available)
- **FR-010**: Daily summary MUST include: time spent, key topics, sessions count, and notable patterns
- **FR-011**: Users MUST be able to regenerate the daily summary
- **FR-012**: Dashboard MUST show quick action buttons: Start Session, Add Note, Capture Screenshot, Export Report, Open Settings
- **FR-013**: Dashboard MUST show loading state while data is being fetched
- **FR-014**: Dashboard MUST show empty state for first-time users with a setup prompt
- **FR-015**: Dashboard MUST support dark and light themes
- **FR-016**: Dashboard widgets MUST be responsive — layout adjusts to sidebar open/closed and window resize

### Key Entities

- **DashboardConfig**: User's dashboard layout configuration. Attributes: id, widgets (ordered list of widget configs), activePeriod (today/week/month).
- **WidgetConfig**: Configuration for a single widget. Attributes: id, type, visible, position (row/col), size (small/medium/large), customSettings (type-specific).
- **ActivitySummary**: Aggregated activity data. Attributes: period (today/week/month), totalEvents, activeTimeMs, topApps (array of {appName, timeMs}), topProjects (array of {projectName, timeMs}), sessionCount, dailySummary (AI-generated text).
- **QuickNote**: A note added from the dashboard. Attributes: id, content, timestamp, source ("dashboard-quick-note"), tags (optional).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Dashboard loads in under 500ms with data for up to 10,000 events
- **SC-002**: Widget customization changes apply in under 100ms
- **SC-003**: AI daily summary generates in under 3 seconds
- **SC-004**: Period toggle (Today/Week/Month) switches data in under 300ms
- **SC-005**: Dashboard consumes under 60MB memory with all widgets active
- **SC-006**: Users can access any primary action (start session, add note) within 2 clicks

## Assumptions

- Built as a React page component with a grid/card layout
- Activity overview data aggregated from events stored in local SQLite via the storage layer
- AI daily summary generated by the recommendation engine (spec 017) using LLM
- Widget system uses a simple layout grid (CSS Grid) with drag-and-drop via dnd-kit
- Widget preferences persisted in localStorage and optionally synced
- Quick notes stored as events in the event store (with type "quick-note")
- Chart widget (Weekly Trend) uses a lightweight chart library (e.g., Chart.js or recharts)
- Dashboard is the default route ("/") in the app router
- Empty state shows illustration + "Start capturing your activity" CTA button
- Source code lives at `ui/dashboard/` in the monorepo
