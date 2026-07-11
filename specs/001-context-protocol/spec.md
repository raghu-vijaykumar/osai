# Feature Specification: Context Protocol

**Feature Branch**: `001-context-protocol`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Define the Context Protocol schema, event envelope, publish/consume APIs, and initial SDK package"

The Context Protocol is application-agnostic — the same generic event categories (`url`, `file`, `app`, `capture`) work across all applications. The `app` field identifies the source, so `file.opened` does not need an app-specific prefix.

The formal protocol specification lives at `protocol/context-protocol.md` and is the authoritative reference for the event envelope, all event categories, schemas, validation rules, and transport details.

## User Scenarios & Testing

### User Story 1 - Publish a Context Event (Priority: P1)

A connector (e.g., browser extension, file watcher, IDE plugin) registers with the platform, then publishes events. The event is appended to the event log immediately, validated and indexed asynchronously, and queryable within milliseconds.

**Why this priority**: Publishing is the fundamental operation. Without it, there is no context to consume.

**Independent Test**: A CLI tool registers as a source, submits a `url.visited` event, and verifies it appears in the event log.

**Acceptance Scenarios**:

1. **Given** a registered source publishing an event matching a registered `event.action` schema (e.g., `{ app: "test-cli", event: "url", action: "visited" }`), **When** calling `publish()`, **Then** the event is appended to the log and returns a unique event ID
2. **Given** an event payload missing required fields for its schema, **When** published, **Then** the SDK returns a validation error with details of missing fields
3. **Given** an event from an unregistered source, **When** published, **Then** the SDK rejects with `SOURCE_NOT_REGISTERED`

---

### User Story 2 - Consume Context via Queries (Priority: P1)

An agent or UI component queries recent context events from the derived store, filtered by app, event, action, time range, or project. Results are returned in a consistent format.

**Why this priority**: Querying is the complementary fundamental operation. Publishing without consumption provides no value.

**Independent Test**: After publishing 3 events with different event categories, query by `event: "url"` returns only URL events.

**Acceptance Scenarios**:

1. **Given** 10 stored events across 3 apps, **When** querying with `app: "com.google.Chrome"` filter, **Then** only Chrome events are returned
2. **Given** events from the last 24 hours, **When** querying with `startTime` and `endTime` filters, **Then** only events within the range are returned
3. **Given** events with different event/action pairs, **When** querying with `event: "file"` and `action: "modified"`, **Then** only file modification events are returned

---

### User Story 3 - Event Schema Validation (Priority: P1)

Each `event.action` pair has a registered JSON Schema that validates payload shape, required fields, and field types at publish time.

**Why this priority**: Schema validation ensures data integrity across all connectors and consumers.

**Independent Test**: A schema for `url.visited` is loaded, validated against the metaschema, and used to validate conforming and non-conforming payloads.

**Acceptance Scenarios**:

1. **Given** a schema for `event: "url"` `action: "visited"` requiring `url` (string) and `title` (string), **When** validating `{ url: "https://example.com", title: "Example" }`, **Then** validation passes
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

- What happens when an event source publishes events faster than the ingestion rate? — Events are appended to the log immediately; processing is async. The log absorbs bursts. No backpressure needed.
- How does the system handle invalid JSON payloads that don't match any registered schema? — Schema versioning handles this. Events with unknown schemas are logged with an error marker and can be re-processed if the schema is updated later.
- What happens to events published without a timestamp? — `timestamp` is required in the envelope schema. If omitted, the SDK assigns current UTC time before validation.
- How are events from unknown/unregistered sources handled? — Rejected with `SOURCE_NOT_REGISTERED`. Sources must register before their first publish via a registration handshake.
- What happens when the local storage is full or corrupted? — The log is append-only and bounded by disk space. If the log is corrupted, data loss is confined to that device. Cloud sync (Phase 5) will provide off-device redundancy.
- How are concurrent writes from multiple connectors handled? — The log is append-only. Multiple writers append without coordination — the log is inherently concurrent-safe.

## Requirements

### Functional Requirements

#### Event Envelope

- **FR-001**: System MUST define a typed `ContextEvent` envelope with fields: `protocol_version` (semver), `id` (UUID v7), `app` (string, reverse-domain), `event` (string, category), `action` (string, verb), `timestamp` (ISO 8601), `payload` (object), and optional `project` and `session`
- **FR-002**: `event` field MUST use single-word lowercase categories (`url`, `file`, `app`, `capture`, `note`, `session`, `project`, `action`)
- **FR-003**: `action` field MUST use past tense for inbound events (`visited`, `modified`, `focused`) and base form for outbound events (`create`, `start`, `schedule`)
- **FR-004**: System MUST support registering event type schemas as JSON Schema (Draft 2020-12), keyed by `event.action` pair

#### Source Registration

- **FR-005**: Every source MUST register before publishing its first event — registration includes `app` (reverse-domain ID), `name`, `version`, and list of `{event, actions[]}` it plans to publish
- **FR-006**: Registration MUST use the event envelope itself: `event: "event"`, `action: "register"` with the capabilities in payload
- **FR-007**: System MUST reject any event from a source that has not completed registration, returning error code `SOURCE_NOT_REGISTERED`
- **FR-008**: Sources MUST be able to update their registration at any time by sending a new registration message — the full list replaces the previous one
- **FR-009**: System MUST expose a `registerSource(app_id, registration)` SDK method
- **FR-010**: System MUST expose a `listSources()` method returning all registered source identifiers

#### Publish & Ingest

- **FR-011**: System MUST provide a `publish(event)` SDK method that accepts a `ContextEvent` and returns the generated `id`
- **FR-012**: System MUST provide a `publishBatch(events[])` SDK method that appends multiple events and returns an array of IDs
- **FR-013**: System MUST generate a unique UUID v7 ID for each event if not provided
- **FR-014**: System MUST append events to an ordered, append-only event log on publish — this is the fast path
- **FR-015**: System MUST run a background consumer that reads the log sequentially and performs: validation → entity extraction → embedding → indexing into SQLite + vector store
- **FR-016**: System MUST checkpoint the consumer's position in the log so it can resume after a crash
- **FR-017**: System MUST support log events that fail validation — they are marked with an error and the consumer continues; they can be re-processed if the schema is updated

#### Query

- **FR-018**: System MUST provide a `query(filters)` SDK method reading from the derived store, supporting filters by `app`, `event`, `action`, `project`, `session`, `startTime`, `endTime`, and free-text search
- **FR-019**: System MUST support query events sorted by timestamp (ascending/descending)
- **FR-020**: System MUST support pagination for query results (limit/offset)
- **FR-021**: System MUST provide a `queryLog(from_position, limit)` method for raw log access (used for rebuild and sync)

#### Protocol Versioning

- **FR-022**: The SDK MUST set `protocol_version` on every event at publish time — defaults to the current protocol version (`1.0.0`)
- **FR-023**: Consumers MUST check `protocol_version` on received events and reject events with a MAJOR version higher than they support, returning error code `UNSUPPORTED_PROTOCOL_VERSION`
- **FR-024**: The SDK MUST expose a `getProtocolVersion()` method returning the supported protocol version string

#### Schema System

- **FR-025**: System MUST support registering JSON Schemas for `event.action` pairs via `registerSchema(event, action, schema)`
- **FR-026**: System MUST expose a `getSchema(event, action)` method to retrieve a registered schema
- **FR-027**: System MUST validate each event's payload against its registered schema during background processing
- **FR-028**: Event type schemas MUST be independently versioned (semver) separate from the protocol version

### Key Entities

- **ContextEvent**: The core event envelope. Attributes: `protocol_version` (semver), `id` (UUID v7), `app` (reverse-domain string), `event` (category), `action` (verb), `timestamp` (ISO 8601), `payload` (Record), `project` (optional string), `session` (optional string).
- **EventSchema**: A JSON Schema (Draft 2020-12) registered for a specific `event.action` pair. Attributes: `event` (string), `action` (string), `schema` (JSON Schema object), `version` (semver).
- **SourceRegistration**: A registered event source. Attributes: `app` (string), `name` (string), `version` (string), `events` (array of `{event, actions[]}`), `registeredAt` (timestamp).
- **EventLog**: The append-only ordered log. Each entry: `position` (monotonic integer), `event` (ContextEvent), `state` (pending/valid/error), `error` (optional).
- **LogConsumer**: Background processor that reads the log sequentially. Attributes: `checkpoint` (last processed position), `batchSize`, `state` (running/paused/crashed).
- **SourcePermission**: Grants a source the ability to publish specific `event.action` pairs. Attributes: `app`, `event`, `action`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Event publish (log append) completes in under 5ms
- **SC-002**: Event query filters return results in under 50ms for 10,000 events
- **SC-003**: Source registration completes in under 10ms
- **SC-004**: Background log consumer processes 1,000 events per second
- **SC-005**: Log consumer checkpoint resumes at the correct position after a crash
- **SC-006**: The SDK API is fully typed (TypeScript strict mode compiles without errors)
- **SC-007**: All contract tests pass in CI (register, publish, query, log rebuild)

## Assumptions

- The formal protocol specification is at `protocol/context-protocol.md` — this feature spec implements that specification
- The initial implementation targets Node.js 20+ and browser environments (via bundling)
- Log is implemented as a JSONL file with append semantics (or SQLite as the log store with monotonic rowid)
- Derived store is SQLite via `rusqlite` in the Tauri Rust core
- Event categories use single-word lowercase (`url`, `file`, `app`, `capture`, `note`, `session`, `project`, `action`)
- All timestamps are UTC ISO 8601 strings
- Protocol version follows semver. Current version is `1.0.0`. Breaking changes increment the MAJOR version.
- The protocol supports optional fields for forward compatibility — consumers MUST ignore unknown fields
- Permissions derived from source registration — stored in the log itself
- No network transport is needed in Phase 0 — publish/consume is local-only
- Schema registry is in-memory on first pass, persisted to storage later
