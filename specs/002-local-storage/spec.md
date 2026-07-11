# Feature Specification: Local Storage Layer

**Feature Branch**: `002-local-storage`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Implement local storage layer with SQLite for events and vector store for embeddings, with a unified query interface"

## User Scenarios & Testing

### User Story 1 - Store and Retrieve Events via SQLite (Priority: P1)

Events published through the Context Protocol are persisted to a local SQLite database. The storage layer handles schema creation, migration, and CRUD operations without requiring external database setup.

**Why this priority**: Without persistence, events exist only in memory and are lost on process restart. SQLite requires zero configuration.

**Independent Test**: Store 100 events, restart the process, and verify all 100 events are retrievable by querying with various filters.

**Acceptance Scenarios**:

1. **Given** an empty database, **When** an event is stored, **Then** the `events` table contains exactly 1 row with the event's fields mapped to columns
2. **Given** a stored event with `payload: { url: "https://x.com", title: "X" }`, **When** retrieved by ID, **Then** the payload is returned as a parsed JSON object
3. **Given** 50 events with mixed types, **When** querying with `type: "url.visited"`, **Then** only matching events are returned

---

### User Story 2 - Vector Storage and Semantic Search (Priority: P1)

Event content is embedded into vectors and stored in a local vector store. Consumers can search by semantic similarity rather than just exact filters.

**Why this priority**: Semantic search is the key differentiator. It enables "find conversations about Kubernetes" without requiring tag-based queries.

**Independent Test**: Store 3 events about different topics, embed them, then search with a query matching one topic — the relevant event should rank highest by similarity.

**Acceptance Scenarios**:

1. **Given** an event with text content "learning about Kubernetes pods", **When** embedded and stored, **Then** a search for "container orchestration" returns it with similarity > 0.5
2. **Given** events about unrelated topics, **When** searching with a specific query, **Then** results are returned sorted by descending similarity score

---

### User Story 3 - Unified Storage Interface (Priority: P1)

All storage operations go through a single `StorageAdapter` interface that abstracts over SQLite and vector stores. Consumers don't need to know which backend is in use.

**Why this priority**: The storage adapter abstraction enables swapping backends (e.g., PostgreSQL for sync) without changing consumer code.

**Independent Test**: The same query written against `StorageAdapter` returns identical results when backed by SQLite-only vs SQLite+vector stores (with exact-match filters).

**Acceptance Scenarios**:

1. **Given** a `StorageAdapter` instance, **When** calling `store(event)`, **Then** the event is persisted to both SQLite and vector store atomically
2. **Given** a `StorageAdapter` configured with only SQLite, **When** calling `search(query)` with text, **Then** it falls back to FTS5 full-text search instead of vector search

---

### User Story 4 - Schema Migration (Priority: P2)

The storage layer manages its own schema versioning and migration. On first use, tables are created automatically. Schema updates are applied incrementally.

**Why this priority**: As the event schema evolves, storage schemas must evolve with it without manual DB administration.

**Independent Test**: Initialize v1 schema, store events, simulate schema upgrade to v2 with a new column, and verify old events are still readable and new events populate the new column.

**Acceptance Scenarios**:

1. **Given** a fresh installation, **When** the storage layer initializes, **Then** all required tables exist with correct schema version recorded
2. **Given** a database at schema v1, **When** the storage layer initializes with v2 code, **Then** migration runs and the schema version is updated to v2

---

### User Story 5 - Bulk Operations and Pagination (Priority: P3)

The storage layer supports bulk insert for batch event ingestion and paginated queries for large result sets.

**Why this priority**: Connectors may publish events in batches (e.g., importing browser history). Pagination prevents memory exhaustion on large queries.

**Independent Test**: Insert 1000 events in a single bulk call, then paginate through results in pages of 100 — all 1000 are accounted for.

**Acceptance Scenarios**:

1. **Given** an array of 500 events, **When** calling `storeBatch(events)`, **Then** all 500 are inserted and each has a unique ID
2. **Given** 1000 events in storage, **When** querying with `limit: 100, offset: 200`, **Then** exactly 100 events are returned starting from the 201st event

---

### Edge Cases

- What happens when SQLite WAL mode encounters concurrent writes from multiple connectors?
- How does the system recover from a corrupted SQLite database?
- What happens when the vector store embedding model is unavailable?
- How are very large event payloads (>1MB) handled?
- How does migration handle rollback if an upgrade fails mid-flight?
- What happens when storage runs out of disk space?
- How are embedding dimensions handled when the model changes?
- What happens when FTS5 encounters non-ASCII text (Unicode, emoji)?

## Requirements

### Functional Requirements

- **FR-001**: System MUST use SQLite (via `rusqlite` in the Tauri Rust core) as the primary relational store
- **FR-002**: System MUST automatically create the `events` table with columns: `id` (TEXT PK), `source` (TEXT), `type` (TEXT), `payload` (TEXT/JSON), `project` (TEXT), `session` (TEXT), `timestamp` (TEXT ISO 8601), `created_at` (TEXT)
- **FR-003**: System MUST create indexes on `source`, `type`, `project`, `session`, and `timestamp` for query performance
- **FR-004**: System MUST support JSON extraction queries on the `payload` column using SQLite's `json_extract()`
- **FR-005**: System MUST create an FTS5 virtual table on event payload text content for full-text search
- **FR-006**: System MUST implement a schema version table and migration runner
- **FR-007**: System MUST store vector embeddings in a dedicated table with columns: `event_id` (TEXT FK), `embedding` (BLOB), `model` (TEXT), `dimensions` (INT)
- **FR-008**: System MUST support cosine similarity search against stored embeddings
- **FR-009**: System MUST expose a `StorageAdapter` interface with methods: `store()`, `storeBatch()`, `get()`, `query()`, `search()`, `delete()`, `deleteBefore()`
- **FR-010**: System MUST support the `query()` method with filters: `source`, `type`, `project`, `session`, `startTime`, `endTime`, `text` (FTS5), `limit`, `offset`, `orderBy`, `orderDir`
- **FR-011**: System MUST support the `search()` method for semantic search: `text` (query string), `limit`, `minScore`
- **FR-012**: System MUST return query results as an object with `events` array and `total` count
- **FR-013**: System MUST use SQLite WAL mode for concurrent read/write performance
- **FR-014**: System MUST store the database file at a configurable path defaulting to `~/.osai/data/osai.db`
- **FR-015**: System MUST provide a `close()` method for graceful shutdown
- **FR-016**: System MUST support in-memory SQLite for testing via `:memory:`

### Key Entities

- **StoredEvent**: A database row representing a `ContextEvent`. Columns: `id`, `source`, `type`, `payload` (JSON string), `project`, `session`, `timestamp`, `created_at`.
- **EventEmbedding**: A vector embedding associated with a stored event. Attributes: `event_id`, `embedding` (float32 array as BLOB), `model` (embedding model identifier), `dimensions` (number).
- **SchemaMigration**: A versioned migration step. Attributes: `version` (integer), `name` (string), `applied_at` (timestamp), `checksum` (hash of SQL).
- **StorageAdapter**: The unified interface. Exposes typed methods for all storage operations with pluggable backends.
- **QueryResult**: Return type for query operations. Shape: `{ events: StoredEvent[], total: number }`.
- **SearchResult**: Return type for semantic search. Shape: `{ event: StoredEvent, score: number }[]`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Single event store/retrieve completes in under 5ms
- **SC-002**: Batch insert of 500 events completes in under 500ms
- **SC-003**: Query with filter on indexed column returns in under 10ms for 10,000 events
- **SC-004**: Semantic search with 1,000 embeddings returns in under 100ms
- **SC-005**: Full-text search via FTS5 on 10,000 events returns in under 50ms
- **SC-006**: Migration from v1 to v2 with 10,000 events completes in under 1s
- **SC-007**: Storage adapter passes the same test suite with both SQLite and in-memory backends

## Assumptions

- SQLite version 3.40+ (WAL mode, JSON functions, FTS5) — via `rusqlite` crate in the Tauri Rust backend
- In addition to the Rust core, a `@osai/storage` TypeScript package wraps SQLite via `better-sqlite3` for use in Node.js sidecars (knowledge engine, MCP server, agents)
- Embedding model initially uses local `@xenova/transformers` (all-MiniLM-L6-v2, 384 dimensions)
- Vector search is done in-process (brute-force cosine similarity) — no external vector DB for Phase 0
- The `payload` column stores JSON text; SQLite JSON functions handle extraction
- Database file location is configurable via environment variable `OSAI_DB_PATH`
- Schema migrations use integer version numbers and forward-only (no rollback in Phase 0)
- The storage layer is not responsible for backup — that comes in Phase 5
