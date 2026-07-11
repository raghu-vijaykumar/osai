# Feature Specification: Project Detection

**Feature Branch**: `015-project-detection`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Auto-detect project boundaries by clustering related events across sources"

## User Scenarios & Testing

### User Story 1 - Auto-Detect Projects from Event Clusters (Priority: P1)

The system analyzes events across all sources and automatically detects project boundaries. A project is a cluster of related events sharing common entities, file paths, time proximity, and domains. Projects are named based on dominant entities or working directories.

**Why this priority**: Projects are the primary organizational unit. Auto-detection means users get organized context without manual effort. The system discovers what the user is working on.

**Independent Test**: Generate 50 events across 3 distinct clusters (browser research on Kubernetes, VSCode work on a React app, PDF reading about ML), then run project detection and verify 3 distinct projects are identified with appropriate names.

**Acceptance Scenarios**:

1. **Given** 30 events sharing file paths under `~/Projects/osai/`, entities "TypeScript" and "Context Protocol", and browser docs about knowledge graphs, **When** project detection runs, **Then** a project named "OSAI" (or "osai") is created containing those events
2. **Given** 15 events about "Kubernetes" across browser docs and downloaded PDFs, with no code file associations, **When** project detection runs, **Then** a project named "Kubernetes" (or "Learning Kubernetes") is created

---

### User Story 2 - Multiple Signals for Project Boundaries (Priority: P1)

Project detection uses multiple signals: file system paths (working directory), domain clusters (related URLs), entity overlap (shared technologies), temporal proximity (events happening close together), and explicit project annotations from connectors.

**Why this priority**: No single signal is reliable enough. File paths may overlap (monorepos). Domains may be unrelated (research spanning many sites). Combining signals produces robust detection.

**Independent Test**: Create events with mixed file paths but strong entity overlap (all mentioning "Rust"), and verify they are clustered into a single project despite different file paths.

**Acceptance Scenarios**:

1. **Given** 10 events in `~/Projects/foo/` and 10 in `~/Projects/bar/`, all mentioning "WebAssembly", **When** clustering runs, **Then** all 20 are clustered into a single "WebAssembly" project (entity overlap outweighs path separation)
2. **Given** 10 events sharing the same working directory but covering completely unrelated topics (Kubernetes docs and cooking recipes), **When** clustering runs, **Then** they are split into separate projects (entity dissimilarity outweighs path overlap)

---

### User Story 3 - Project Lifecycle: Active, Idle, Archived (Priority: P2)

Projects have lifecycle states. A project with recent events (within 7 days) is Active. One with no events for 30+ days becomes Idle. One explicitly archived or with no events for 90+ days is Archived. Users can manually override states.

**Why this priority**: Without lifecycle management, the project list grows forever with stale projects. Lifecycle states help users focus on current work.

**Independent Test**: Create a project, add events daily for 5 days, then stop. After 35 days (simulated), verify the project transitions from Active → Idle.

**Acceptance Scenarios**:

1. **Given** a project with events in the last 3 days, **When** querying project state, **Then** it's `active`
2. **Given** a project with no events for 45 days, **When** the lifecycle check runs, **Then** it's marked `idle` and can be hidden from the default project list

---

### User Story 4 - Project Merging and Splitting (Priority: P2)

Users can manually merge two detected projects or split a project into two. The system learns from manual corrections and adjusts future detection.

**Why this priority**: No auto-detection is perfect. Users need the ability to correct the system. Learning from corrections improves detection over time.

**Independent Test**: Detect two separate projects "React" and "Next.js", manually merge them into "Frontend", then add more events and verify the merged project receives new events correctly.

**Acceptance Scenarios**:

1. **Given** projects "A" and "B" detected, **When** the user merges them into "AB", **Then** all events from both are reassigned to "AB" and a `merge` record is stored
2. **Given** a merged project, **When** new events arrive, **Then** they are assigned to the merged project if they match either original's signals

---

### User Story 5 - Project Signals Dashboard (Priority: P3)

The system shows why events were clustered into a project — which signals contributed to the detection — as an "explainability" panel. Users see that "this event was assigned to Project X because of file path /Users/me/projects/x (weight: 0.6) and entity 'React' (weight: 0.4)."

**Why this priority**: Explainability builds trust and helps users correct false assignments. Without it, project detection is a black box.

**Independent Test**: Query a project's event assignment reasons and verify the output lists the contributing signals with weights.

**Acceptance Scenarios**:

1. **Given** a project with 3 events, **When** querying `getProjectSignals(projectId)`, **Then** each event has a list of signals that contributed to its assignment (path overlap, entity overlap, temporal proximity) with weights
2. **Given** an event was assigned to a project with low overall confidence (< 0.5), **When** viewing the signals, **Then** the system flags the assignment as "uncertain" and suggests manual review

---

### Edge Cases

- What happens when a user works on multiple projects simultaneously (context switching)?
- How are events that belong to no project handled — are they assigned to an "Unorganized" bucket?
- What happens when an event equally matches two projects — which one wins?
- How are project names generated when no clear dominant entity emerges?
- What happens when a user changes project structures (renames a directory)?
- How are system-level events (activity monitor, system events) excluded from project detection?
- What happens when the clustering algorithm produces too many or too few projects?

## Requirements

### Functional Requirements

- **FR-001**: System MUST detect projects by clustering events using signals: file path similarity, entity overlap, domain similarity, temporal proximity, and explicit project annotations
- **FR-002**: System MUST use a configurable clustering algorithm (e.g., DBSCAN or HDBSCAN) with parameters for min cluster size (default: 10 events) and similarity threshold (default: 0.3)
- **FR-003**: System MUST persist projects in a `projects` table: `id`, `name`, `description` (auto-generated), `state` (active/idle/archived), `confidence` (0.0–1.0), `signalSummary` (JSON), `firstEvent`, `lastEvent`, `eventCount`, `createdAt`, `updatedAt`
- **FR-004**: System MUST persist event-project assignments in an `event_projects` join table: `eventId`, `projectId`, `assignmentConfidence`, `assignMethod` (auto/manual), `signals` (JSON)
- **FR-005**: System MUST support project lifecycle states with automatic transitions: `active` (events in 7 days), `idle` (no events 30 days), `archived` (no events 90 days or manual)
- **FR-006**: System MUST support manual project operations: create, rename, merge, split, delete, archive, unarchive, reassign events
- **FR-007**: System MUST learn from manual corrections — store `project_corrections` table and adjust future detection weights
- **FR-008**: System MUST auto-generate project names from dominant entity, file path basename, or domain (in priority order)
- **FR-009**: System MUST expose a project query API: `listProjects({ state, search, sort })`, `getProject(id)`, `getProjectEvents(id, { filters })`, `getProjectSignals(id)`, `getProjectTimeline(id)`
- **FR-010**: System MUST exclude system events (activity monitor heartbeats, system lifecycle) from project detection
- **FR-011**: System MUST support re-clustering on demand — re-run detection with updated signals or parameters
- **FR-012**: System MUST publish `project.detected`, `project.updated`, `project.merged`, `project.state_changed` events
- **FR-013**: System MUST consume Context Protocol outbound events (`project.reassigned`, `project.split`, `project.merged`, `project.renamed`, `project.created`, `project.archived`) from the event log as training signals
- **FR-014**: System MUST store all manual corrections in the `project_corrections` table and use them to adjust signal weights for future clustering runs — an event reassigned to a different project reduces the weight of signals that pointed to the original project
- **FR-015**: After processing a manual correction batch, the system MUST re-evaluate unassigned events that share signals with the corrected events to improve their assignment

### Key Entities

- **Project**: A detected cluster of related activity. Attributes: `id`, `name`, `description`, `state`, `confidence`, `signalSummary` (breakdown of which signals contributed), `eventCount`, `activeDays` (distinct days with events).
- **EventProjectAssignment**: Links an event to a project. Attributes: `eventId`, `projectId`, `assignmentConfidence` (0.0–1.0), `assignMethod` (`auto`|`manual`), `signals` (JSON array of {signal, weight}).
- **ProjectCorrection**: A record of manual user correction. Attributes: `userId`, `projectId`, `correctionType` (merge/split/rename/reassign), `before`/`after` state, `timestamp`.
- **ClusterSignal**: A signal used for clustering. Types: `path_overlap` (shared directory prefix), `entity_overlap` (shared entities), `domain_overlap` (shared URL domain), `temporal_proximity` (events within 2 hours), `explicit_project` (connector-provided project tag).
- **ClusteringConfig**: Parameters for the clustering algorithm. Attributes: `algorithm` (dbscan/hdbscan), `minClusterSize`, `epsilon` (DBSCAN distance threshold), `minScore` (entity similarity threshold), `signalWeights` (per-signal weight map).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Project detection on 1000 events completes in under 10 seconds
- **SC-002**: Incremental assignment of a new event to an existing project completes in under 50ms
- **SC-003**: Project detection precision > 0.85 (events assigned to correct projects vs gold standard)
- **SC-004**: Project detection recall > 0.80 (all meaningful projects detected)
- **SC-005**: Manual correction learning: after 10 corrections, detection accuracy improves by at least 10%
- **SC-006**: Project name auto-generation produces readable names > 90% of the time

## Assumptions

- Clustering uses DBSCAN (density-based, handles noise, doesn't require specifying number of clusters)
- Similarity metrics: file paths use longest common prefix ratio, entities use Jaccard similarity on entity sets, domains use TLD+1 overlap, temporal uses exponential decay over a 2-hour window
- Event-to-project assignment is a soft clustering — events can belong to multiple projects with different confidence scores
- The first time project detection runs, it processes all existing events. Subsequent runs only process new events incrementally
- Default min cluster size of 10 events prevents single-session projects from being created
- Users can define "sacred projects" — manually created projects with pinned signals that override auto-detection
- Manual corrections are consumed from the event log as Context Protocol events (spec 001) — the detection system reads `project.reassigned`, `project.split`, etc. from the log and does not require a direct API call from the UI
- The `project_corrections` table stores each correction with the previous and new project assignment, timestamp, and signal context at the time of correction
- Source code lives at `knowledge-engine/project-detection/` in the monorepo
