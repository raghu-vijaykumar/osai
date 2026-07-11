# Feature Specification: Agent Permission System

**Feature Branch**: `032-agent-permissions`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an agent permission system that controls what agents can read and write, with user approval flows and granular access control"

## User Scenarios & Testing

### User Story 1 - Granular Agent Permissions (Priority: P1)

Each agent has a permission manifest declaring what it needs to access: event types, data sources, storage operations, external APIs, and system capabilities. Users can review permissions on a per-agent basis and grant/deny individual permissions. The system enforces these permissions at runtime.

**Why this priority**: Permissions are fundamental to user trust and security. Users must know and control what agents can access.

**Independent Test**: Open the permission settings for the Researcher agent. Verify the manifest shows: "Read: events (all types), entities, projects, sessions" and "Write: events (research results only), reports" and "External: web search API, GitHub API". Toggle off "External: GitHub API" and verify the Researcher can no longer make GitHub API calls (returns "Permission denied").

**Acceptance Scenarios**:

1. **Given** the Researcher agent's permission manifest, **When** the user views it in the Agent Panel, **Then** permissions are grouped by category (Read, Write, External, System) with toggle switches
2. **Given** a permission is revoked, **When** the agent attempts an operation requiring that permission, **Then** the operation is blocked and a "Permission denied" event is logged

---

### User Story 2 - Permission Request Flow (Priority: P2)

When an agent needs a permission it doesn't have (e.g., first time accessing a new event type), it requests it at runtime. The user sees a notification: "Researcher wants to access your Location events. Allow / Deny / Allow Once". The request includes an explanation of why it's needed.

**Why this priority**: Runtime permission requests enable progressive authorization. Users don't need to pre-approve everything at install time.

**Independent Test**: Temporarily revoke the "read:file-events" permission from the Summarizer. When it next tries to generate a daily summary, verify a permission request appears: "Summarizer needs access to File events to include file activity in your daily summary. Allow / Deny / Allow Once."

**Acceptance Scenarios**:

1. **Given** an agent lacks a permission for an operation, **When** it attempts the operation, **Then** a permission request notification appears with agent name, resource requested, explanation, and Allow/Deny/Allow Once options
2. **Given** the user selects "Allow Once", **When** the agent makes a second request for the same permission, **Then** the request is shown again (not auto-approved)
3. **Given** a permission request is denied, **When** the agent makes the same request within 5 minutes, **Then** it's auto-denied without notifying the user (to avoid notification spam)

---

### User Story 3 - Data Access Audit Log (Priority: P2)

Every agent data access (read or write) is logged: which agent, what resource, when, and whether it was allowed or denied. Users can view the audit log in the Agent Panel, filter by agent, resource type, and date range. The log is append-only and cannot be tampered with by agents.

**Why this priority**: Audit logs provide transparency and accountability. Users can see exactly what agents are doing with their data.

**Independent Test**: Search for an entity via the Researcher agent. Then open the audit log and verify an entry exists: "Researcher | read | entity:TypeScript | 2026-07-11T10:32:00Z | allowed". Filter by agent "Organizer" and verify only Organizer events are shown.

**Acceptance Scenarios**:

1. **Given** agents have been running, **When** the user opens the audit log, **Then** all data access events are shown in reverse chronological order with agent, resource, action, timestamp, and result
2. **Given** the audit log, **When** the user filters by agent "Researcher" and resource type "external-api", **Then** only Researcher's external API calls are shown

---

### User Story 4 - Sensitive Content Controls (Priority: P3)

Users can mark specific events, entities, or projects as "sensitive" or "private". Agents are blocked from reading sensitive content unless explicitly granted permission. The Organizer agent's cleanup suggestions also respect sensitive content — it won't suggest archiving/deleting sensitive items without explicit confirmation.

**Why this priority**: Some content is inherently private (passwords, personal documents, health info). Users need guarantees that agents won't access it.

**Independent Test**: Mark an event as "sensitive" (via the event detail menu). Verify that searching for its content via the Researcher agent returns no results. Verify the daily summary from the Summarizer agent doesn't mention the sensitive event's content.

**Acceptance Scenarios**:

1. **Given** an event is marked as sensitive, **When** any agent attempts to read it, **Then** the read is blocked with a "Sensitive content — permission required" audit log entry
2. **Given** a project is marked as sensitive, **When** the Summarizer generates a project summary, **Then** the response is "Content not available — sensitive project" unless the Summarizer has explicit sensitive-content permission
3. **Given** sensitive content exists, **When** the Organizer suggests cleanup, **Then** it does not include sensitive items in cleanup suggestions

---

### User Story 5 - Permission Profiles and Templates (Priority: P3)

Users can create permission profiles — reusable sets of permissions — and apply them to agents. Built-in profiles include: "Read Only" (read events only), "Standard" (read/write events, read entities), "Full Access" (all read/write, external APIs, system). Custom profiles can be created and shared across agents.

**Why this priority**: Permission profiles reduce repetitive configuration. Most agents fall into a few common patterns.

**Independent Test**: Apply "Read Only" profile to the Summarizer agent. Verify it can read events but cannot write summaries or access external APIs. Create a custom profile "Research Only" with "Read: events, entities, projects" + "External: web search" and apply it to the Researcher.

**Acceptance Scenarios**:

1. **Given** the permission profiles panel, **When** the user selects "Standard" profile for a new agent, **Then** permissions are auto-configured to read/write events and read entities
2. **Given** a custom profile named "Minimal Research" is created, **When** the user applies it to the Researcher agent, **Then** only the permissions in the profile are granted

---

### Edge Cases

- What happens when an agent needs a permission that the user hasn't decided on yet (pending)?
- How are permission changes applied to currently running agents?
- What happens when an agent requests a permission that doesn't exist in the system?
- How are first-party (OSAI built-in) vs. third-party agent permissions differentiated?
- What happens when permission conflicts arise (allow on type, deny on specific instance)?
- How are permissions handled during agent updates (version changes with new permissions)?
- What happens when the user revokes a permission while an agent is using it?

## Requirements

### Functional Requirements

- **FR-001**: Every agent MUST have a permission manifest declaring required permissions
- **FR-002**: Permission manifest MUST be in a standard format (machine-readable)
- **FR-003**: Permissions MUST be categorized: Read, Write, External, System
- **FR-004**: Read/Write permissions MUST be granular: by event type, entity type, data source
- **FR-005**: External permissions MUST specify: API endpoint pattern, rate limit impact
- **FR-006**: System permissions MUST cover: file system, network, process management
- **FR-007**: Users MUST be able to view and toggle individual permissions per agent
- **FR-008**: Agents MUST request permissions at runtime when needed (not just at install)
- **FR-009**: Permission requests MUST include: agent name, resource, explanation, allow/deny/allow-once options
- **FR-010**: Repeated denied requests MUST be auto-denied (5-minute cooldown)
- **FR-011**: All agent data access MUST be logged in an append-only audit log
- **FR-012**: Audit log MUST include: agent, action (read/write), resource, timestamp, result (allowed/denied)
- **FR-013**: Audit log MUST be filterable by agent, resource type, date range, and result
- **FR-014**: Users MUST be able to mark events, entities, and projects as sensitive/private
- **FR-015**: Sensitive content MUST be blocked from agent access by default
- **FR-016**: Agents MUST have an explicit sensitive-content permission to access it
- **FR-017**: Users MUST be able to create, save, and apply permission profiles
- **FR-018**: Built-in permission profiles MUST include: Read Only, Standard, Full Access
- **FR-019**: Permission changes MUST take effect immediately (within 2 seconds)

### Key Entities

- **PermissionManifest**: An agent's declared permissions. Attributes: agentId, version, permissions (array of Permission objects), description (why each permission is needed), updatedAt.
- **Permission**: A single permission. Attributes: id, type (read/write/external/system), resource (event type / entity type / API pattern / capability), constraints (optional: time limit, count limit), description.
- **PermissionGrant**: A granted or denied permission. Attributes: id, agentId, permissionId, status (granted/denied/once), grantedAt, expiresAt (for "once" grants).
- **AuditLogEntry**: An audit log entry. Attributes: id, agentId, action (read/write/access), resource (type + identifier), timestamp, result (allowed/denied/blocked-sensitive), details.
- **SensitiveContent**: A content sensitivity marker. Attributes: id, resourceType (event/entity/project), resourceId, sensitivityLevel (sensitive/private/confidential), markedAt, reason.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Permission check overhead: <5ms per access check
- **SC-002**: Permission request notification appears within 1 second of request
- **SC-003**: Audit log queries complete in under 200ms (for up to 100,000 entries)
- **SC-004**: Permission changes take effect within 2 seconds
- **SC-005**: Permission enforcement blocks 100% of unauthorized access attempts
- **SC-006**: Audit log is tamper-proof (append-only, cryptographic verification optional)

## Assumptions

- Built as a core system service that intercepts all agent data operations
- Permission manifest is part of the agent's package/configuration
- Permissions stored in local SQLite (via storage layer)
- Audit log stored in a separate append-only table (no updates, no deletes)
- Runtime permission requests shown via in-app notification system
- Sensitive content is a metadata flag on events/entities/projects
- Permission profiles are stored as reusable JSON templates
- First-party (OSAI built-in) agents have default permissions that users can restrict
- Third-party agents start with zero permissions and must request everything
- Source code lives at `services/permissions/` in the monorepo