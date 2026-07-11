# Feature Specification: Context Sidebar

**Feature Branch**: `023-context-sidebar`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a context sidebar that shows the user's current activity, recent events, and relevant context for AI agents"

## User Scenarios & Testing

### User Story 1 - Live Activity Feed (Priority: P1)

The context sidebar displays a real-time feed of the user's current activity. It shows the active window/app, current file/open tabs, recently captured events (last 5 minutes), and the current project or session. The feed updates automatically as the user works.

**Why this priority**: The live feed is the primary purpose of the sidebar — it shows what's happening right now and provides immediate value for self-awareness.

**Independent Test**: Open the context sidebar while editing a file. Verify the sidebar shows the active file name, the app being used (VSCode), and a chronological list of events from the last 5 minutes that updates as new events are captured.

**Acceptance Scenarios**:

1. **Given** the context sidebar is open, **When** the user switches from VSCode to a browser, **Then** within 2 seconds the sidebar updates to show the browser as the active app with the current tab title
2. **Given** the user is typing in a document, **When** events are captured, **Then** the sidebar shows new events appearing at the top of the feed with a subtle animation
3. **Given** the live feed is showing events, **When** the user clicks an event, **Then** the corresponding view opens (or the event detail is shown inline)

---

### User Story 2 - Context Summary for AI (Priority: P1)

The sidebar shows a structured "Context Summary" section that packages the user's current state for AI consumption: active window, open files, current project, recent sessions, and top entities. This is the same context that gets sent to agents when they respond.

**Why this priority**: The context summary gives users visibility into what the AI sees about them, building trust and enabling debugging of agent responses.

**Independent Test**: Open the sidebar, click "Context Summary" to expand it. Verify it shows: Active App (VSCode), Open Files (3 files listed), Current Project (osai), Recent Sessions (2 sessions), Top Entities (React, TypeScript, MCP). Verify this matches what would be sent to an agent.

**Acceptance Scenarios**:

1. **Given** the context sidebar, **When** the user clicks "Context Summary", **Then** a structured view shows Active App, Open Files, Current Project, Recent Sessions, and Top Entities sections
2. **Given** the context summary is visible, **When** the user copies any section (e.g., "Open Files"), **Then** the content is copied as structured text ready to paste into any AI chat

---

### User Story 3 - Relevant Context (Priority: P2)

Beyond current activity, the sidebar shows "relevant context" — people, projects, and topics related to current activity. For example, if the user is looking at a React file, the sidebar might show the React project, recent React events, and related people or PRs.

**Why this priority**: Relevant context helps users discover connections they might not have noticed, making the sidebar a tool for insight, not just monitoring.

**Independent Test**: While working on a file in the "osai" project, verify the sidebar shows "Related: 3 recent events about OSAI, 2 related projects (osai, osai-docs), entity: OSAI type: project".

**Acceptance Scenarios**:

1. **Given** the user is viewing a file named "timeline.tsx", **When** the sidebar loads, **Then** "Related" section shows "Timeline View (project entity)", "3 events about timeline features", "Entity: Timeline (component)"
2. **Given** no related context is found, **When** the sidebar loads, **Then** the "Related" section shows "No related context found" with a subtle indicator

---

### User Story 4 - Context Filters and Customization (Priority: P2)

Users can customize what appears in the sidebar: which sections to show, time windows for recent events, and which data sources to include. Sections can be collapsed/expanded, rearranged by drag-and-drop, and hidden entirely.

**Why this priority**: Different users have different needs. A developer might want files and project context; a researcher might want entities and related topics.

**Acceptance Scenarios**:

1. **Given** the context sidebar, **When** the user clicks the gear icon, **Then** a customization panel opens with toggle switches for each section (Live Feed, Context Summary, Related, Recent Events, Projects, Sessions)
2. **Given** the customization panel, **When** the user drags "Recent Events" above "Live Feed", **Then** the sidebar re-renders with sections in the new order
3. **Given** a section is hidden via customization, **When** the sidebar is reopened, **Then** the section remains hidden until toggled back on

---

### User Story 5 - Context Sharing and Export (Priority: P3)

Users can share their current context as a snapshot — a portable, timestamped document that captures what they were working on. This can be shared with collaborators or attached to issues and PRs. Snapshots are generated as structured markdown.

**Why this priority**: Context snapshots enable asynchronous collaboration. A developer can share "here's what I was looking at when I found this bug."

**Independent Test**: Click "Share Context" in the sidebar, verify a snapshot is generated as markdown containing: active app, open files, current project, recent 10 events, and related entities. Verify it can be copied to clipboard.

**Acceptance Scenarios**:

1. **Given** the context sidebar, **When** the user clicks "Share Context", **Then** a modal shows a preview of the context snapshot as formatted markdown with a "Copy" and "Export" button
2. **Given** the context snapshot preview, **When** the user clicks "Copy", **Then** the markdown is copied to clipboard with a toast confirmation

---

### Edge Cases

- What happens when the activity feed is empty (no events captured yet)?
- How are long lists of open files handled — truncation with "show all"?
- What happens when the sidebar is very narrow (resize behavior)?
- How does the sidebar handle very rapid event streams (throttling)?
- What happens when the sidebar is open but the app is in the background?
- How are sensitive events handled in the live feed?

## Requirements

### Functional Requirements

- **FR-001**: Context sidebar MUST show a live activity feed of current events (last 5 minutes by default)
- **FR-002**: Live feed MUST update in real-time as new events are captured (within 2 seconds)
- **FR-003**: Each feed event MUST show: timestamp, app/source icon, event title, and a clickable detail view
- **FR-004**: Sidebar MUST show the active window/app and current open files/tabs
- **FR-005**: Sidebar MUST show the current project and active session if detected
- **FR-006**: Sidebar MUST have a "Context Summary" section that packages current state for AI consumption
- **FR-007**: Context summary MUST include: Active App, Open Files, Current Project, Recent Sessions, and Top Entities
- **FR-008**: Users MUST be able to copy individual context summary sections as structured text
- **FR-009**: Sidebar MUST show "Related Context" — entities, projects, and events related to current activity
- **FR-010**: Users MUST be able to customize which sections appear and in what order
- **FR-011**: Sections MUST be collapsible/expandable
- **FR-012**: Users MUST be able to set time windows for recent events (5min, 15min, 1hr, 4hr)
- **FR-013**: Users MUST be able to generate and copy/export a context snapshot as structured markdown
- **FR-014**: Context snapshot MUST include: timestamp, active app, open files, current project, last 10 events, and related entities
- **FR-015**: Sidebar MUST support resize (collapsible to just icons, expandable to full width)
- **FR-016**: Sidebar MUST support dark and light themes
- **FR-017**: Sidebar MUST show loading state while context is being fetched

### Key Entities

- **ContextSnapshot**: A point-in-time capture of user activity context. Attributes: id, timestamp, activeApp, openFiles, currentProject, recentEvents (array of event summaries), relatedEntities, customNotes.
- **ActivityEvent**: A single event in the live feed. Attributes: id, timestamp, source (app name), type (file/open/navigate/type), title, description, relatedEntityIds.
- **ContextSection**: A configurable section of the sidebar. Attributes: id, type (liveFeed/contextSummary/related/recentEvents/projects/sessions), visible, order, collapsible, expanded.
- **RelatedItem**: An item related to current activity. Attributes: id, type (entity/project/event/session), title, relevanceScore, relationship (how it's related).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Sidebar opens in under 100ms
- **SC-002**: Live feed updates appear within 2 seconds of event capture
- **SC-003**: Context summary builds in under 200ms
- **SC-004**: Related context computation completes in under 500ms
- **SC-005**: Sidebar consumes under 30MB memory when active
- **SC-006**: Section customization changes are applied in under 50ms
- **SC-007**: Context snapshot generation completes in under 300ms

## Assumptions

- Built as a React sidebar component with collapsible/resizable behavior
- Uses WebSocket or polling for real-time event feed updates (depends on ingestion pipeline)
- Context summary built from the knowledge graph and current session state
- Related context computed by the recommendation engine (spec 017)
- Customization settings persisted in localStorage
- Dark/light theme follows the app's theme
- Sidebar width: collapsible to 48px (icons only), default 320px, max 480px
- Context snapshots are ephemeral (generated on demand, not persisted)
- Source code lives at `ui/context-sidebar/` in the monorepo
