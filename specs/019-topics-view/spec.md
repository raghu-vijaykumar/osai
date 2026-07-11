# Feature Specification: Topics

**Feature Branch**: `019-topics-view`

**Created**: 2026-07-11

**Status**: Draft

**Input**: What occupies your attention. Auto-clustered topics from your events — not project management, but themes you work on (e.g., "Learning Rust", "Auth Design", "Home Reno Planning"). Each topic shows related events, entities, notes, and a timeline. Formerly Projects View.

## User Scenarios & Testing

### User Story 1 - Project List with States (Priority: P1)

The topics view displays all detected topics in a list/grid with name, state badge (Active/Idle/Archived), event count, time range, top entities, and last activity timestamp. Users can filter by state and search by name.

**Why this priority**: The project list is the entry point for project-centric browsing. It gives users an immediate overview of all their work areas.

**Independent Test**: With 10 projects detected (5 active, 3 idle, 2 archived), verify the list shows all 10 with correct state badges. Filter to "Active" only and verify 5 remain.

**Acceptance Scenarios**:

1. **Given** 12 topics across all states, **When** loading the topics view, **Then** topics are displayed sorted by last activity (most recent first) with name, state badge, event count, and top 3 entity tags
2. **Given** the filter bar, **When** selecting "Active" state filter, **Then** only active projects are shown with a count badge "5 of 12"

---

### User Story 2 - Project Detail Page (Priority: P1)

Clicking a project opens a detail view showing: project timeline (sessions within this project), associated entities (technologies, topics), event distribution by source and activity type, and related projects.

**Why this priority**: The detail page is the primary destination for exploring what the user has done within a project. It consolidates all context around a project.

**Independent Test**: Open a project "OSAI" detail page. Verify it shows: 10 sessions, entities ["TypeScript", "Context Protocol", "Knowledge Graph"], source breakdown (browser: 60%, vscode: 30%, files: 10%), and activity breakdown.

**Acceptance Scenarios**:

1. **Given** a project with 50 events across 3 sources, **When** viewing project detail, **Then** a source distribution pie chart shows correct proportions (browser 60%, vscode 30%, files 10%)
2. **Given** a project with detected entities, **When** viewing the detail page, **Then** the entity cloud shows "TypeScript" (18 mentions), "React" (12), "GraphQL" (8) sized by mention count

---

### User Story 3 - Project Timeline (Priority: P2)

The project detail page includes a mini-timeline showing only sessions/events belonging to this project. It follows the same patterns as the main timeline (session cards, expand/collapse, filtering within the project scope).

**Why this priority**: Users need to see project-specific activity without leaving the project context. A scoped timeline provides this without cross-project noise.

**Independent Test**: Open project "OSAI" and verify the project timeline shows 3 sessions. Each session card shows only events tagged with the OSAI project. Clicking an event shows entity tags for the project.

**Acceptance Scenarios**:

1. **Given** a project with 5 sessions across 3 days, **When** viewing the project timeline, **Then** sessions are shown with correct project attribution only (no events from other projects)
2. **Given** the project timeline has filters, **When** filtering by source "vscode-extension", **Then** only VSCode events within this project are shown

---

### User Story 4 - Project Management Actions (Priority: P2)

Users can rename, merge, split, reassign events, archive, pin/reorder, and delete projects. Merge combines two projects into one. Split moves a subset of events from one project to a new or existing project. Reassign moves individual events or batches between projects. Pin keeps important projects at the top. All operations produce outbound Context Protocol events in the event log. Manual corrections are fed back to the detection system (spec 015).

**Why this priority**: Auto-detection isn't perfect. Users need full control to organize projects as they see fit.

**Independent Test**: Rename "Untitled Project 3" to "Research: Knowledge Graphs". Archive an old project. Verify the rename updates immediately and the archived project moves to the archived section. Select 3 events from project A and reassign to project B — verify events appear under B and a `project.reassigned` event exists in the log.

**Acceptance Scenarios**:

1. **Given** a project named "k8s-research", **When** the user renames it to "Kubernetes Study", **Then** the name updates in all views, a `project.rename` outbound event is recorded, and the new name is learned by the detection system
2. **Given** two projects "React" and "Next.js", **When** the user merges them into "Frontend", **Then** all events from both are reassigned, a `project.merge` event is recorded, and the merged project shows source events from both originals
3. **Given** a project with 10 events, **When** the user selects 3 events and splits them into a new project "Side Research", **Then** a new project appears with those 3 events, the source project retains 7, and a `project.split` event is recorded
4. **Given** 5 events from project A, **When** the user batch-reassigns them to project B using the event selector, **Then** events move to B, a `project.reassign` event is recorded per batch, and the detection system registers the correction

---

---

### User Story 5 - Project Pinning and Reordering (Priority: P2)

Users can pin important projects to the top of the list and reorder pinned projects by drag-and-drop. Pinned projects appear above unpinned ones and maintain their order across restarts. Archived projects are always at the bottom regardless of pin status.

**Why this priority**: As the project list grows, users need to keep frequently accessed projects accessible. Pinning provides manual curation without affecting auto-detection.

**Independent Test**: Pin projects "OSAI" and "Research" in that order. Verify they appear at the top of the list. Drag "Research" above "OSAI" — verify the order persists after navigating away and back.

**Acceptance Scenarios**:

1. **Given** 20 projects, **When** the user pins "OSAI", **Then** it moves to the top of the list above all unpinned projects with a pin icon visible
2. **Given** 3 pinned projects, **When** the user drags "Project C" from position 3 to position 1, **Then** the pinned order is updated and persists across restarts
3. **Given** a pinned project is archived, **When** viewing the project list, **Then** it moves to the archived section regardless of pin status

---

### User Story 6 - Project Discovery and Recommendations (Priority: P3)

The topics view includes a "Discover" section suggesting potential topics from orphan events (events not assigned to any topic). It also shows "Related Topics" based on shared entities or sources.

**Why this priority**: Not all events are immediately clustered. The discover section lets users manually confirm or dismiss potential projects that don't meet the auto-detection confidence threshold.

**Independent Test**: Generate 15 unclustered events about "WebAssembly". Verify the Discover section suggests a new project "WebAssembly" with a "Create Project" button.

**Acceptance Scenarios**:

1. **Given** 20 orphan events about "Machine Learning", **When** viewing Discover, **Then** an "ML Research" suggestion appears with confidence score and "Create Project" / "Dismiss" actions
2. **Given** a project "Kubernetes" with related entity overlap with "Docker", **When** viewing the project detail, **Then** "Docker" appears in the "Related Projects" section

---

### Edge Cases

- What happens when a project has zero events (empty after deletion)?
- How are very large projects (10K+ events) handled — does the project timeline need additional pagination?
- What happens when two projects have the same or similar names?
- How are projects spanning very long time periods (years) displayed?
- What happens to project associations when events are deleted?
- How are project signals displayed for explainability in the UI?
- What happens when the last event is reassigned out of a project — does the project auto-archive?
- How are pinned project orders persisted and optionally synced across devices?
- What happens to reassignment history (log) when the reassigned event is pruned by data retention?
- How does split handle overlapping signals — what if the split events also match the source project's signals?

## Requirements

### Functional Requirements

- **FR-001**: Projects view MUST display a list/grid of all projects with: name, state badge (active/idle/archived), event count, date range, top 3 entity tags, last activity timestamp
- **FR-002**: Project list MUST support filtering by state (all/active/idle/archived) and search by project name
- **FR-003**: Project detail page MUST show: project name (editable), timeline of project sessions, entity cloud (top entities by mention count), source distribution chart, activity distribution chart, related projects
- **FR-004**: Project detail MUST include a scoped timeline showing only sessions/events assigned to this project
- **FR-005**: Project detail MUST show signal explainability — why events were assigned to this project (path overlap, entity overlap, etc.)
- **FR-006**: Users MUST be able to rename, archive, unarchive, merge, and delete projects
- **FR-007**: Merge MUST combine two projects — all events from source project are reassigned to target project; source project is removed
- **FR-008**: Archive MUST hide the project from the default active list but preserve all data
- **FR-009**: Delete MUST remove the project entity but keep events unassociated (events are not deleted)
- **FR-010**: Projects view MUST include a "Discover" section showing suggested projects from orphan events with confidence scores
- **FR-011**: Projects view MUST show "Related Projects" based on shared entities, sources, or temporal proximity
- **FR-012**: Manual project operations (rename, merge) MUST be persisted and learned by the detection system (spec 015)
- **FR-013**: Projects view MUST use components and tokens from the design system (spec 059) — all colors, spacing, typography, and interactive elements
- **FR-014**: Projects view MUST support dark, light, and high-contrast themes via the theme provider (spec 059)

#### Project Reorganization

- **FR-015**: Users MUST be able to reassign individual events or batches between projects — produces outbound `project.reassign` event in the log
- **FR-016**: Users MUST be able to split a project — select a subset of events and move them to a new or existing project — produces outbound `project.split` event
- **FR-017**: Users MUST be able to create a project manually before any events are detected — produces outbound `project.create` event
- **FR-018**: Users MUST be able to pin/unpin projects — pinned projects appear at the top of the list, order persists across restarts
- **FR-019**: Users MUST be able to reorder pinned projects by drag-and-drop
- **FR-020**: All project operations (create, rename, merge, reassign, split, archive, unarchive, delete, pin) MUST produce outbound events following the Context Protocol envelope (spec 001) — `app: "com.osai.projects-view"`, `event: "project"`, `action: {operation}` with relevant payload
- **FR-021**: Manual project corrections MUST be fed back to the detection system (spec 015) as training signals — the system adjusts signal weights for future auto-detection
- **FR-022**: If the last event is reassigned out of a project, the project MUST be automatically archived after user confirmation
- **FR-023**: Event selector for reassign/split MUST support multi-select with shift-click range and Ctrl-click toggle

### Key Entities

- **ProjectCard**: A project list item. Displays: name, state badge, event count, date range, entity tags, last activity, pinned state, pin toggle.
- **ProjectDetail**: Full project view. Sections: project header (name, state, actions), scoped timeline, entity cloud, source chart, activity chart, related projects, signal explanation.
- **ProjectTimeline**: A scoped timeline component showing only sessions/events for a specific project.
- **EntityCloud**: Visual representation of entities sized by mention count within a project.
- **DiscoverSection**: Suggested projects from orphan events. Each suggestion has confidence score and Create/Dismiss actions.
- **ProjectActionBar**: Actions available per project: Rename, Archive/Unarchive, Merge (select target), Split, Reassign Events, Pin/Unpin, Delete.
- **EventSelector**: Batch selection UI for reassign/split operations. Supports shift-click range, Ctrl-click toggle, select all. Shows count of selected events.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Project list with 50 projects loads in under 200ms
- **SC-002**: Project detail page for a project with 500 events loads in under 300ms
- **SC-003**: Scoped project timeline loads in under 200ms
- **SC-004**: Project rename updates in all views in under 100ms
- **SC-005**: Merge operation for 2 projects with 200 events completes in under 500ms
- **SC-006**: Split operation on 50 events completes in under 200ms
- **SC-007**: Reassign batch of 20 events completes in under 100ms
- **SC-008**: Pin reorder persists across app restarts
- **SC-009**: Entity cloud renders with 50+ entities at 60fps

## Assumptions

- Projects view is part of the desktop app, built with React + Tailwind CSS
- Charts use a lightweight library (recharts or visx)
- Entity cloud is a flex-wrap layout with font-size proportional to mention count
- Project data comes from the project detection API (spec 015)
- Orphan events for Discover are events with no project assignment and confidence above 0.3
- Learn more about manual corrections via the project_corrections table
- Empty state: illustration + "No projects yet. Projects are auto-detected as you work." message
- Topic auto-classification from Save-to-KB content is done by the agent host (spec 064) — this spec handles the display/storage side
- Design system (spec 059) provides the theming engine, component library, and typography — dark/light/high-contrast modes, font scaling, and responsive behavior are inherited
- Source code lives at `ui/topics/` in the monorepo (renamed from `019-projects-view`)
