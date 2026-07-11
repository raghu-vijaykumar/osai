# Feature Specification: Team Context Sharing

**Feature Branch**: `050-team-context-sharing`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build team context sharing with opt-in, per-project granularity for organizational collaboration"

## User Scenarios & Testing

### User Story 1 - Share Project Context with Team (Priority: P1)

Team members can share specific projects or activity streams with their team. Sharing is opt-in at the project level: the user selects "Share with Team" on a project, chooses which team members or teams to share with, and sets the level of detail (events only, events + entities, full context). Shared projects appear in teammates' timelines.

**Why this priority**: Opt-in per-project sharing is the core feature. It enables collaboration while respecting privacy — users control exactly what's visible.

**Independent Test**: Create a project "Frontend Sprint" in OSAI. Click "Share" and select team "Engineering" with detail level "Events + Entities". Verify teammates in Engineering can see the project in their timeline with events and entities. Verify teammates outside Engineering cannot see it. Verify the user can unshare and the project disappears from teammates' views.

**Acceptance Scenarios**:

1. **Given** a project owned by user A, **When** user A shares it with team "Engineering", **Then** all Engineering team members see the project's events in their timeline with a "shared" badge
2. **Given** a shared project, **When** the owner changes share settings from "Events + Entities" to "Events Only", **Then** teammates see only events (entities are hidden)
3. **Given** a shared project, **When** the owner unshares it, **Then** within 60 seconds the project and its events are removed from all teammates' views

---

### User Story 2 - View Team Member Activity (Priority: P2)

With appropriate permissions, users can view their teammates' shared activity. A "Team" view shows a feed of shared events from all team members, grouped by person and time. Users can filter by team member, project, and time range. This enables awareness of what the team is working on.

**Why this priority**: Team activity awareness reduces the need for status update meetings. It's the primary value of sharing — knowing what others are working on.

**Independent Test**: As a team lead, open the "Team Activity" view. Verify it shows a feed of shared events from all team members. Filter by a specific team member and verify only their events are shown. Click an event and verify it shows detail, including which project it belongs to and who captured it.

**Acceptance Scenarios**:

1. **Given** team members have shared projects, **When** a user opens the Team view, **Then** a chronological feed of all shared events is shown, grouped by person with avatar and name headers
2. **Given** the Team view, **When** the user filters by project "Frontend Sprint", **Then** only events from that shared project are shown across all team members

---

### User Story 3 - Share Requests and Approvals (Priority: P2)

Users can request access to a teammate's context. A request notification is sent: "Alice wants to see your Frontend Sprint project. Allow / Deny / Allow with limited detail." The recipient can set detail level on approval. Pending and past share relationships are visible in settings.

**Why this priority**: Share requests enable bottom-up collaboration. Instead of waiting for someone to share, users can proactively request access.

**Independent Test**: User B clicks "Request Access" on user A's project. User A receives a notification: "User B wants to see your Frontend Sprint project." User A selects "Allow with limited detail (Events only)". User B gets a notification: "Access granted to Frontend Sprint (Events only)."

**Acceptance Scenarios**:

1. **Given** user A has a project, **When** user B requests access, **Then** user A receives a notification with Allow/Deny/Allow with Limited options within 5 seconds
2. **Given** user A approves with limited detail, **When** user B views the project, **Then** only events are visible (no entities, no full content)

---

### User Story 4 - Team-Wide Context Search (Priority: P3)

Users with appropriate permissions can search across their team's shared context. Search results show which team member the result is from, which project, and the relevance score. Results are limited to what each user has shared.

**Why this priority**: Team-wide search turns individual knowledge into collective knowledge. Users can find "who on the team worked on Kubernetes" without guessing.

**Independent Test**: Search for "authentication" in the team-wide search. Verify results show: "Alice worked on auth in Frontend Sprint project (3 events)" and "Bob researched OAuth in Security Audit project (2 events)". Each result shows the team member's name, project, and event count.

**Acceptance Scenarios**:

1. **Given** shared context from multiple team members, **When** a user searches team-wide, **Then** results are grouped by team member and project with relevance indicators
2. **Given** a search result, **When** the user clicks it, **Then** they see the shared event details (limited to the sharing level granted)

---

### Edge Cases

- What happens when a team member leaves the organization?
- How are shared projects handled when the owner deletes their account?
- What happens when sharing settings change while teammates are viewing?
- How is shared data cached across team members?
- What happens when a user shares a project that contains sensitive content?
- How are very large shared projects handled (thousands of events)?

## Requirements

### Functional Requirements

- **FR-001**: Users MUST be able to share projects with specific team members or teams
- **FR-002**: Sharing MUST be opt-in at the project level (nothing shared by default)
- **FR-003**: Detail levels MUST include: Events Only, Events + Entities, Full Context
- **FR-004**: Shared events MUST appear in teammates' timelines with a "shared" badge
- **FR-005**: Users MUST be able to unshare projects at any time
- **FR-006**: Unshared projects MUST be removed from teammates' views within 60 seconds
- **FR-007**: Users MUST be able to view a Team Activity feed of shared events
- **FR-008**: Team Activity MUST be filterable by team member, project, and time range
- **FR-009**: Users MUST be able to request access to a teammate's project
- **FR-010**: Share requests MUST have Allow, Deny, and Allow with Limited options
- **FR-011**: Team-wide context search MUST be supported across shared data
- **FR-012**: Search results MUST show the team member and project for each result
- **FR-013**: Share relationships MUST be visible in user settings (who I share with, who shares with me)
- **FR-014**: When a team member is removed, all their shared data MUST be immediately inaccessible

### Key Entities

- **ShareGrant**: A sharing grant. Attributes: id, projectId, ownerUserId, targetType (user/team), targetId, detailLevel (events/entities/full), status (active/pending/revoked), createdAt, updatedAt.
- **ShareRequest**: A sharing request. Attributes: id, requesterUserId, projectId, status (pending/approved/denied), approvedLevel, respondedAt.
- **TeamActivity**: Aggregated team activity. Attributes: teamId, members (array of user IDs and their shared projects), eventCount, lastActivityAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Share grant takes effect within 10 seconds
- **SC-002**: Share revocation takes effect within 60 seconds
- **SC-003**: Team Activity view loads in under 2 seconds (for 50 team members)
- **SC-004**: Share request notification delivered within 5 seconds
- **SC-005**: Team-wide search returns results in under 2 seconds
- **SC-006**: Zero data leaks: shared data is never visible to unauthorized users

## Assumptions

- Built as a cloud service (part of the sync/cloud infrastructure)
- Sharing metadata stored in the cloud database
- Shared data read from the knowledge engine with permission filters
- Default: nothing shared; every project starts as private
- Team membership managed via the Team plan (spec 039)
- Detail levels enforced server-side (not just UI hiding)
- Event-level sharing granularity (not per-event, per-project)
- Source code lives at `services/team-sharing/` in the monorepo