# Feature Specification: Organizational Knowledge Graph

**Feature Branch**: `051-org-knowledge-graph`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an organizational knowledge graph that merges team members' personal knowledge graphs into a shared org-wide view"

## User Scenarios & Testing

### User Story 1 - Merged Org Knowledge Graph (Priority: P1)

When team members share projects, their personal knowledge graph entities and relationships are merged into an organizational knowledge graph. The org graph shows: entities (people, technologies, projects, topics), relationships (who worked on what, which projects use which technologies), and event counts. The org graph is visible in a dedicated "Org Graph" view.

**Why this priority**: The org knowledge graph transforms individual context into collective intelligence. It reveals team-wide expertise, project dependencies, and knowledge distribution.

**Independent Test**: Three team members share projects involving "Kubernetes", "Docker", and "React". Open the Org Graph view. Verify "Kubernetes" node shows 3 connections (one per team member), "Docker" shows 2 connections, "React" shows 1 connection. Verify clicking a team member node shows their shared projects and top entities.

**Acceptance Scenarios**:

1. **Given** shared projects from multiple team members, **When** the Org Graph is loaded, **Then** entities from all shared projects are merged into a single graph with team member counts per entity
2. **Given** an entity in the Org Graph, **When** the user clicks it, **Then** they see which team members have this entity in their shared context, with event counts per person

---

### User Story 2 - Expertise Discovery (Priority: P2)

The Org Graph enables expertise discovery. Users can search for a topic and find "who in the organization has the most context about this." The expertise score is based on: event count, recency, project diversity, and sharing level. Results show expertise level (Expert / Proficient / Familiar / Aware).

**Why this priority**: Expertise discovery replaces the need to ask "who knows about X" in Slack. It's immediately actionable for finding the right person to ask.

**Independent Test**: Search for "TypeScript" in expertise discovery. Verify results show: "Alice — Expert (47 events, 3 projects, last active today)", "Bob — Proficient (12 events, 2 projects, last active last week)", "Carol — Familiar (3 events, 1 project, last active 2 months ago)". Verify clicking Alice shows her shared TypeScript events and projects.

**Acceptance Scenarios**:

1. **Given** the Org Graph, **When** a user searches for an entity, **Then** results are ranked by expertise score with level labels and detailed breakdowns
2. **Given** an expertise result, **When** the user clicks "View Context", **Then** they see the team member's shared events related to that entity

---

### User Story 3 - Org-Wide Entity and Project Discovery (Priority: P2)

The Org Graph provides an org-wide view of all entities and projects across the organization. Users can browse: all entities (sorted by team coverage, event count, or recency), all projects (sorted by team members, activity, or recency), and cross-project entity usage (which technologies span multiple projects).

**Why this priority**: Discovery helps users understand the organization's technical landscape — what projects exist, what technologies are used, and where there's overlap.

**Independent Test**: Open the Org Graph "Projects" view. Verify it shows all shared projects across the team: "Frontend Sprint" (3 members, React, TypeScript), "Backend API" (2 members, Go, PostgreSQL), "DevOps" (1 member, Kubernetes, Docker). Click "Technologies" view and verify an entity "React" shows it's used in 2 projects by 3 team members.

**Acceptance Scenarios**:

1. **Given** shared projects across the org, **When** the user browses entities, **Then** entities are listed with team member count, project count, and total event count
2. **Given** shared projects, **When** the user browses projects, **Then** projects are listed with team member count, latest activity, and top entities

---

### User Story 4 - Entity Relationship Analysis (Priority: P3)

The Org Graph shows relationships between entities at the org level: "Which technologies are commonly used together?" and "Which team members share the same expertise areas?" Relationship strength is indicated by co-occurrence frequency across projects and team members.

**Why this priority**: Relationship analysis reveals hidden patterns — technologies that go together, skill overlaps between teams, and potential collaboration areas.

**Independent Test**: In the Org Graph, view "TypeScript" node. Verify it shows strong relationships with "React" (co-occurs in 3 projects, 5 team members) and "Node.js" (co-occurs in 2 projects, 3 team members). View "Alice" node, verify it shows strong entity overlap with "Bob" (share 3 entities, 1 project).

**Acceptance Scenarios**:

1. **Given** the Org Graph, **When** viewing an entity, **Then** related entities are shown with relationship strength (strong/medium/weak) based on co-occurrence in projects
2. **Given** the Org Graph, **When** viewing a team member, **Then** related team members are shown based on shared entity overlap

---

### Edge Cases

- What happens when an entity appears in conflicting contexts across team members?
- How are very common entities (e.g., "the", "code") filtered from the graph?
- What happens when a team member unshares all projects?
- How is entity disambiguation handled (e.g., "React" the library vs. "react" the verb)?
- How is the graph updated when new events are captured?

## Requirements

### Functional Requirements

- **FR-001**: Org Knowledge Graph MUST merge entities from all team members' shared projects
- **FR-002**: Org Graph MUST show: entities, team member relationships, project associations
- **FR-003**: Org Graph MUST support expertise discovery — find who knows most about a topic
- **FR-004**: Expertise score MUST consider: event count, recency, project diversity, sharing level
- **FR-005**: Expertise levels MUST include: Expert, Proficient, Familiar, Aware
- **FR-006**: Org Graph MUST provide an org-wide project browser
- **FR-007**: Org Graph MUST show entity relationships with strength indicators
- **FR-008**: Team member relationships MUST be shown based on shared entity overlap
- **FR-009**: Org Graph MUST support full-text search across entities and projects
- **FR-010**: Common/stopword entities MUST be filtered out
- **FR-011**: Org Graph MUST update in near-real-time as new shared events arrive
- **FR-012**: Org Graph MUST respect sharing permissions (only shared data is visible)

### Key Entities

- **OrgEntity**: An entity in the organizational graph. Attributes: id, name, type, teamMemberCount, projectCount, eventCount, expertiseScores (map of userId to expertise level).
- **OrgRelationship**: A relationship between entities at the org level. Attributes: sourceEntityId, targetEntityId, strength (strong/medium/weak), coOccurrenceCount, sharedProjectCount, sharedTeamMemberCount.
- **TeamMemberExpertise**: Expertise data for a team member. Attributes: userId, entityId, expertiseLevel, eventCount, projectCount, lastActiveAt, sharingLevel.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Org Graph loads in under 3 seconds (for 10 team members, 500 entities)
- **SC-002**: Expertise search returns results in under 1 second
- **SC-003**: Entity relationship calculation updates within 5 minutes of new shared events
- **SC-004**: Expertise accuracy: 80%+ of expertise suggestions are validated by team members
- **SC-005**: Graph respects permissions: zero shared data is visible to unauthorized users

## Assumptions

- Built as a cloud service that aggregates personal knowledge graphs
- Only data from shared projects is included in the org graph
- Entity extraction uses the same pipeline as personal graphs (spec 012)
- Expertise scoring is a weighted combination of: event count (30%), recency (25%), project diversity (25%), sharing level (20%)
- Common entity filtering uses a configurable stopword list
- Entity disambiguation uses context-based disambiguation (project context, co-occurrence)
- Graph updates are near-real-time (within 5 minutes of new shared events)
- The org graph is read-only for non-admin users (curation by admins only)
- Source code lives at `services/org-graph/` in the monorepo