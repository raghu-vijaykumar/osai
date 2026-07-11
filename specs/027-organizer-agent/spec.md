# Feature Specification: Organizer Agent

**Feature Branch**: `027-organizer-agent`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an organizer agent that auto-tags events, suggests project membership, and helps curate the user's knowledge base"

## User Scenarios & Testing

### User Story 1 - Automatic Event Tagging (Priority: P1)

The organizer agent automatically tags events as they are ingested. Tags include: event type (learning, building, researching, planning, reviewing, communicating), topic tags (React, TypeScript, architecture, etc.), priority tags (deep-work, quick-lookup, meeting), and custom user-defined tags. Tags are stored with confidence scores, and users can review/approve/reject suggestions.

**Why this priority**: Auto-tagging organizes the firehose of events into browsable, filterable categories. Without tags, the timeline is just a flat list.

**Independent Test**: Browse a page about "Rust async/await patterns" in the browser. Verify the event is automatically tagged with: type "learning", topics ["Rust", "async", "async/await"], priority "deep-work". Verify tags are visible in the event detail view.

**Acceptance Scenarios**:

1. **Given** a new event is ingested from the browser, **When** the organizer processes it, **Then** within 5 seconds the event is tagged with an event type (learning/building/researching/planning/reviewing/communicating) and relevant topic tags
2. **Given** an event with auto-generated tags, **When** the user views the event detail, **Then** tags are shown with a confidence indicator (e.g., 85% confidence) and Approve/Reject buttons
3. **Given** the user rejects a tag, **When** the organizer processes similar events in the future, **Then** it learns from the rejection and adjusts confidence

---

### User Story 2 - Project Membership Suggestions (Priority: P1)

The organizer analyzes events and suggests which project they belong to. When the user starts researching a new topic (e.g., "WebAssembly"), the organizer may suggest creating a new project or adding events to an existing one. Suggestions appear as notifications with quick actions: "Add to Project X", "Create New Project", "Dismiss".

**Why this priority**: Project organization is one of OSAI's most powerful features but requires user input to be accurate. Smart suggestions reduce the friction of manual categorization.

**Independent Test**: Browse 5 pages about "WebAssembly" over 2 days, then search in Google for "wasm vs docker". Verify the organizer suggests either creating a new "WebAssembly" project or adding events to an existing related project. Verify the suggestion notification includes "Add to Project X", "Create New Project", "Dismiss" buttons.

**Acceptance Scenarios**:

1. **Given** 3+ events about a new topic "WebGPU" within 24 hours, **When** the organizer runs its clustering analysis, **Then** a suggestion notification appears: "3 events about WebGPU detected. Create new project?"
2. **Given** the user clicks "Create New Project", **When** the dialog opens, **Then** it pre-fills the project name as "WebGPU" with a list of suggested events to include
3. **Given** existing events are not clearly associated with any project, **When** the organizer analyzes them, **Then** it shows "Uncategorized Events" with a "Suggest Project" action

---

### User Story 3 - Knowledge Base Cleanup (Priority: P2)

The organizer identifies and helps clean up issues in the knowledge base: duplicate events (merging), broken entity links, orphaned events (not associated with any project or session), and stale/irrelevant content. It surfaces these in a "Cleanup Suggestions" panel with one-click fix actions.

**Why this priority**: Over time, the knowledge base accumulates noise. Regular cleanup keeps the graph accurate and useful.

**Independent Test**: Generate two near-identical events (same URL, same timestamp range). Verify the organizer detects them as duplicates and shows "2 duplicate events detected. Merge?" with a "Merge" button that combines them.

**Acceptance Scenarios**:

1. **Given** two events with >90% content similarity within 5 minutes, **When** the organizer runs deduplication, **Then** it flags them as potential duplicates with a "Merge" and "Dismiss" action
2. **Given** an entity referenced only once with no relationships, **When** the organizer runs orphan detection, **Then** it shows "1 orphaned entity detected" with options to delete or keep
3. **Given** events from 6+ months ago with zero views/references, **When** the organizer runs staleness analysis, **Then** it suggests archiving them with "Archive N stale events" action

---

### User Story 4 - Custom Tag Rules and Automation (Priority: P3)

Users can define custom tagging rules: "if event source is arxiv.org and contains 'machine learning', tag as 'research:ML' and priority 'deep-work'". Rules support conditions (source, URL pattern, content keywords, time, day) and actions (add tags, set priority, assign project). Rules are evaluated in order and can be reordered.

**Why this priority**: Custom rules let users tailor auto-tagging to their specific workflow without waiting for the AI to learn.

**Independent Test**: Create a rule: "If source contains 'github.com/osai' then tag 'work:osai' and project 'osai'". Open a GitHub page in the osai repo. Verify the event is automatically tagged with "work:osai" and associated with the osai project within 5 seconds.

**Acceptance Scenarios**:

1. **Given** the rules editor, **When** the user creates a rule with condition "source contains 'stackoverflow.com'" and action "tag 'research'", **Then** the rule is saved and active immediately
2. **Given** an active rule and a matching event, **When** the event is ingested, **Then** the rule is applied within 5 seconds and the event shows both AI-generated tags and rule-based tags

---

### User Story 5 - One-Click Curation Actions (Priority: P3)

The organizer provides quick curation actions directly on events: "Remove from timeline" (soft delete), "Mark as private" (exclude from context sent to agents), "Highlight" (pin for later reference), "Add note" (attach a personal note to an event). These actions appear as an overflow menu on each event.

**Why this priority**: Granular curation puts users in control of their knowledge base. Not all events are equally important.

**Independent Test**: Right-click any event in the timeline, select "Mark as private". Verify the event now shows a lock icon and does not appear in MCP search results. Right-click again and select "Unmark as private" to reverse.

**Acceptance Scenarios**:

1. **Given** an event in the timeline, **When** the user selects "Mark as private", **Then** the event is tagged with `visibility: private` and excluded from all non-UI queries (MCP, agents, exports)
2. **Given** an event, **When** the user selects "Highlight", **Then** the event is pinned with a star icon and appears in a "Highlights" section on Home

---

### Edge Cases

- What happens when the user creates conflicting rules?
- How are tags from rules vs. AI differentiated?
- What happens when an event matches multiple rules?
- How is tag taxonomy managed (user-created vs. AI-discovered tags)?
- What happens when events are bulk-processed — performance considerations?
- How are project suggestions handled when a user ignores/dismisses multiple suggestions?
- What happens to auto-tags when the user deletes a custom tag?

## Requirements

### Functional Requirements

- **FR-001**: Organizer agent MUST automatically tag events with event type, topic tags, and priority tags
- **FR-002**: Event types MUST include: learning, building, researching, planning, reviewing, communicating
- **FR-003**: Topic tags MUST be extracted from event content using the entity extraction pipeline (spec 012)
- **FR-004**: All auto-generated tags MUST include a confidence score
- **FR-005**: Users MUST be able to approve or reject auto-generated tags per-event
- **FR-006**: Organizer MUST learn from tag rejections and adjust future confidence
- **FR-007**: Organizer MUST detect topic clusters and suggest project membership
- **FR-008**: Project suggestions MUST include: notification, event count, suggested name, and quick actions
- **FR-009**: Organizer MUST detect potential duplicate events (content similarity >90%, timestamp proximity <5min)
- **FR-010**: Organizer MUST detect orphaned entities (single reference, no relationships)
- **FR-011**: Organizer MUST detect stale events (no views/references for 6+ months)
- **FR-012**: All cleanup suggestions MUST have one-click fix actions
- **FR-013**: Users MUST be able to define custom tagging rules with conditions and actions
- **FR-014**: Custom rules MUST support conditions: source, URL pattern, content keywords, time of day, day of week
- **FR-015**: Custom rules MUST support actions: add tags, set priority, assign project
- **FR-016**: Users MUST be able to mark events as private, highlighted, or add personal notes
- **FR-017**: Private events MUST be excluded from all MCP and agent queries
- **FR-018**: Organizer MUST be available as an MCP tool via the MCP server

### Key Entities

- **Tag**: A label applied to an event. Attributes: id, name, namespace (system/user/custom), type (eventType/topic/priority/custom), confidence (0-1), source (ai/rule/manual), color.
- **TagRule**: A user-defined tagging rule. Attributes: id, name, conditions (array of {field, operator, value}), actions (array of {type: addTag/setPriority/assignProject, value}), priority, enabled, createdAt.
- **CleanupSuggestion**: A suggestion to clean up the knowledge base. Attributes: id, type (duplicate/orphan/stale), affectedItems (array of IDs), description, action (merge/delete/archive/keep), resolved, createdAt.
- **ProjectSuggestion**: A suggestion for project membership. Attributes: id, projectName, eventIds, source (auto-detected), status (pending/approved/rejected), createdAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Event tagging completes within 5 seconds of event ingestion
- **SC-002**: Tag confidence accuracy: 80%+ of AI-generated tags are approved by users
- **SC-003**: Project suggestion accuracy: 70%+ of suggestions are accepted by users
- **SC-004**: Custom rules are evaluated and applied within 3 seconds of event ingestion
- **SC-005**: Cleanup analysis for 100,000 events completes in under 5 minutes
- **SC-006**: Duplicate detection precision >95% (low false positives)

## Assumptions

- Built as an OSAI agent running in the background process
- Uses the entity extraction pipeline (spec 012) and event classification (spec 013) for tagging
- Uses the project detection system (spec 016) for project suggestions
- Tagging is asynchronous — events are tagged shortly after ingestion
- Tags stored as event metadata in the storage layer
- Tags are indexed for fast filtering in the UI
- Users can create unlimited custom rules
- Custom rules are evaluated client-side for speed, AI tagging is server-side
- Organizer learns from user feedback via a simple Bayesian confidence adjustment
- AI tagging and classification use the LLM provider layer (spec 062) when transformer models are enabled
- Source code lives at `agents/organizer/` in the monorepo