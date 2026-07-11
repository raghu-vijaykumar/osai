# Feature Specification: Context Protocol

**Feature Branch**: `001-context-protocol`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Define the Context Protocol schema, event envelope, publish/consume APIs, and initial SDK package"

## User Scenarios & Testing

### User Story 1 - Publish a Context Event (Priority: P1)

A connector (e.g., browser extension) captures a user action and publishes it as a typed event to the local context store. The event is validated against its schema, persisted, and immediately queryable.

**Why this priority**: Publishing is the fundamental operation. Without it, there is no context to consume.

**Independent Test**: A CLI tool can submit a `url.visited` event and verify it appears in the local event log.

**Acceptance Scenarios**:

1. **Given** a valid event payload matching the `url.visited` schema, **When** published via the SDK's `publish()` method, **Then** the event is stored and returns a unique event ID
2. **Given** an event payload missing required fields, **When** published, **Then** the SDK returns a validation error with details of missing fields
3. **Given** an event from an unauthorized source, **When** published, **Then** the SDK rejects with a permission error

---

### User Story 2 - Consume Context via Queries (Priority: P1)

An agent or UI component queries recent context events, filtered by source, type, time range, or project. Results are returned in a consistent format.

**Why this priority**: Querying is the complementary fundamental operation. Publishing without consumption provides no value.

**Independent Test**: After publishing 3 events with different types and timestamps, query by type returns only matching events.

**Acceptance Scenarios**:

1. **Given** 10 stored events across 3 sources, **When** querying with `source: "browser-extension"` filter, **Then** only browser events are returned
2. **Given** events from the last 24 hours, **When** querying with `startTime` and `endTime` filters, **Then** only events within the range are returned
3. **Given** events with different event types, **When** querying with `type: "file.modified"` filter, **Then** only file modification events are returned

---

### User Story 3 - Event Schema Validation (Priority: P1)

Each event type has a defined JSON Schema that validates payload shape, required fields, and field types at publish time.

**Why this priority**: Schema validation ensures data integrity across all connectors and consumers.

**Independent Test**: A schema definition is loaded, validated against the metaschema, and used to validate a conforming and a non-conforming payload.

**Acceptance Scenarios**:

1. **Given** a `url.visited` schema requiring `url` (string) and `title` (string), **When** validating `{ url: "https://example.com", title: "Example" }`, **Then** validation passes
2. **Given** the same schema, **When** validating `{ url: 123 }`, **Then** validation fails with a type mismatch error

---

### User Story 4 - Project Association (Priority: P2)

Events can be associated with a project either explicitly (supplied by the connector) or inferred by the system based on context (active window, working directory, etc.).

**Why this priority**: Projects are the primary organizational unit. Associating events to projects enables the project-centric UX vision.

**Independent Test**: Publish two events with different project IDs and verify they appear under separate project queries.

**Acceptance Scenarios**:

1. **Given** an event with `project: "osai"` field, **When** stored, **Then** it is queryable by `project: "osai"`
2. **Given** an event without a project field, **When** stored with session context that includes a project, **Then** the project is inferred and attached

---

### User Story 5 - Session Grouping (Priority: P3)

Events can be grouped into sessions — contiguous periods of related activity (e.g., a coding session, a research session). Sessions provide continuity context.

**Why this priority**: Sessions bridge individual events into coherent work episodes, enabling timeline grouping and context preservation.

**Independent Test**: Publish events with the same session ID and verify they are grouped together in session queries.

**Acceptance Scenarios**:

1. **Given** 5 events sharing `session: "sess_abc123"`, **When** querying by session ID, **Then** all 5 events are returned ordered by timestamp
2. **Given** a session with a `start` and `end` event, **When** querying session metadata, **Then** duration is calculated

---

### Edge Cases

- What happens when an event source publishes events faster than the ingestion rate (backpressure/throttling)?
- How does the system handle invalid JSON payloads that don't match any registered schema?
- What happens to events published without a timestamp (should the server assign one)?
- How are events from unknown/unregistered sources handled?
- What happens when the local storage is full or corrupted?
- How are concurrent writes from multiple connectors handled?

## Requirements

### Functional Requirements

- **FR-001**: System MUST define a typed `ContextEvent` envelope with fields: `id`, `source`, `type`, `timestamp`, `payload`, and optional `project` and `session`
- **FR-002**: System MUST support registering event type schemas as JSON Schema (Draft 2020-12)
- **FR-003**: System MUST validate every published event against its registered schema before storage
- **FR-004**: System MUST provide a `publish(event)` SDK method that accepts a `ContextEvent` and returns the generated `id`
- **FR-005**: System MUST provide a `query(filters)` SDK method supporting filters by `source`, `type`, `project`, `session`, `startTime`, `endTime`, and free-text search
- **FR-006**: System MUST persist events to local SQLite storage on publish
- **FR-007**: System MUST support query events sorted by timestamp (ascending/descending)
- **FR-008**: System MUST support pagination for query results (limit/offset)
- **FR-009**: System MUST reject events from sources not registered in the permissions store
- **FR-010**: System MUST support per-source permission grants (which event types a source can publish)
- **FR-011**: System MUST generate a unique UUID v7 ID for each event
- **FR-012**: System MUST assign the current timestamp if none is provided
- **FR-013**: System MUST expose a `listSources()` method returning all registered source identifiers
- **FR-014**: System MUST expose a `registerSchema(type, schema)` method to add event type schemas
- **FR-015**: System MUST expose a `getSchema(type)` method to retrieve a registered schema

### Key Entities

- **ContextEvent**: The core event envelope. Attributes: `id` (UUID v7), `source` (string identifier), `type` (string, dot-notation), `timestamp` (ISO 8601), `payload` (Record), `project` (optional string), `session` (optional string)
- **EventSchema**: A JSON Schema (Draft 2020-12) registered for a specific event type. Attributes: `type` (string), `schema` (JSON Schema object), `version` (semver)
- **Source**: An application/connector that publishes events. Attributes: `id` (string), `name` (string), `permissions` (array of allowed event types)
- **Permission**: Grants a source the ability to publish specific event types. Attributes: `sourceId`, `eventType` (glob pattern), `grantedAt`

## Success Criteria

### Measurable Outcomes

- **SC-001**: Event publishing completes in under 10ms (local storage, no IO wait)
- **SC-002**: Event query filters return results in under 50ms for 10,000 events
- **SC-003**: Schema validation passes or fails in under 5ms per event
- **SC-004**: The SDK API is fully typed (TypeScript strict mode compiles without errors)
- **SC-005**: All contract tests pass in CI (publish, query, schema validation, permissions)

## Assumptions

- The initial implementation targets Node.js 20+ and browser environments (via bundling)
- Storage is local SQLite via `better-sqlite3` for Node.js, with an in-memory fallback for browsers
- Event types use reverse-domain dot notation (e.g., `osai.url.visited`)
- All timestamps are UTC ISO 8601 strings
- The protocol will support optional fields for forward compatibility
- Permissions stored in a local JSON file initially; database-backed later
- No network transport is needed in Phase 0 — publish/consume is local-only
- Schema registry is in-memory on first pass, persisted to storage later
