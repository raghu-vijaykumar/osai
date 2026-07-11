# Feature Specification: Rust SDK

**Feature Branch**: `042-rust-sdk`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a Rust SDK for high-performance event publishing and context querying from Rust applications"

## User Scenarios & Testing

### User Story 1 - High-Performance Event Publishing (Priority: P1)

Rust developers add `osai-sdk` to their `Cargo.toml`. The SDK provides a high-performance event publishing API optimized for low latency and minimal overhead. Events are serialized with Serde and sent via Unix domain sockets (Linux/macOS) or named pipes (Windows) for zero-allocation local communication.

**Why this priority**: Rust is used for performance-critical applications. The SDK must match Rust's performance expectations — minimal overhead and zero-cost abstractions.

**Independent Test**: Create a Rust application that publishes 100,000 events in a tight loop. Measure throughput — verify it exceeds 50,000 events/second locally. Verify all events arrive in the timeline with correct data.

**Acceptance Scenarios**:

1. **Given** the Rust SDK, **When** a developer publishes an event with `client.publish_event(Event::new("custom.event", serde_json::json!({"key": "value"})))?`, **Then** the event appears in the timeline within 5ms
2. **Given** the Rust SDK, **When** a developer publishes 100,000 events, **Then** throughput exceeds 50,000 events/second (local, Unix domain socket)

---

### User Story 2 - Safe and Typed API (Priority: P2)

The SDK provides a fully typed API. Event types are defined as Rust structs with Serde derive macros. Compile-time safety: invalid event structures fail to compile. The SDK uses idiomatic Rust patterns: `Result` for fallible operations, `async`/`await` for async, `Stream` for streaming queries.

**Why this priority**: Type safety is a primary benefit of Rust. The SDK should leverage Rust's type system to catch errors at compile time.

**Independent Test**: Define a custom event struct `#[derive(Serialize, Deserialize, Event)] struct CodeRun { script: String, duration: u64 }` and publish it. Try publishing an event with a missing field — verify it fails to compile with a meaningful error.

**Acceptance Scenarios**:

1. **Given** the Rust SDK, **When** a developer defines a typed event struct and publishes it, **Then** the event is serialized correctly and appears in the timeline with the correct fields
2. **Given** a typed event with a missing required field, **When** the developer tries to compile, **Then** the compiler rejects it with an error related to missing field

---

### User Story 3 - Embedded and CLI Use Cases (Priority: P3)

The Rust SDK can be used in embedded contexts: as a library within larger Rust applications, as a standalone CLI tool for scripting, and as a Wasm target for browser-based event publishing. The SDK has optional features to minimize dependency footprint.

**Why this priority**: Rust's embedded/Wasm ecosystem is growing. Supporting these targets expands OSAI's reach.

**Independent Test**: Compile the SDK for `wasm32-unknown-unknown` target and use it in a browser context to publish events. Build a minimal binary with `default-features = false` that only publishes events, verify the binary is under 2MB.

**Acceptance Scenarios**:

1. **Given** the Rust SDK, **When** compiled with `--target wasm32-unknown-unknown`, **Then** it compiles successfully and can publish events from a browser context
2. **Given** the Rust SDK with minimal features, **When** built as a standalone binary, **Then** the binary size is under 2MB (stripped)

---

### User Story 4 - Async Query and Stream (Priority: P3)

The SDK provides async query APIs: `client.search_events(query).await` returns a `Vec<Event>`, and `client.search_stream(query)` returns a `Stream<Item=Event>` for incremental results. Queries can be filtered, paginated, and sorted.

**Why this priority**: Async queries enable non-blocking integration into event loops (tokio, async-std).

**Acceptance Scenarios**:

1. **Given** the Rust SDK with async runtime, **When** a developer calls `client.search_events(SearchQuery::new().with_type("file.modified").limit(10)).await`, **Then** the last 10 file-modified events are returned as a `Vec<Event>`
2. **Given** a streaming query, **When** the developer calls `client.search_stream(query)`, **Then** results are yielded incrementally as a `Stream<Item=Event>`

---

### Edge Cases

- What happens when the local OSAI socket is not available?
- How are feature flags managed for different use cases?
- What happens on platforms without Unix domain sockets (Windows)?
- How is async runtime agnosticism handled (tokio vs. async-std vs. smol)?

## Requirements

### Functional Requirements

- **FR-001**: SDK MUST be addable via `cargo add osai-sdk`
- **FR-002**: SDK MUST support publishing events via local IPC (Unix domain socket, named pipe)
- **FR-003**: Events MUST use Serde for serialization with derive macros
- **FR-004**: SDK MUST provide compile-time type checking for event structures
- **FR-005**: SDK MUST support async/await for non-blocking operations
- **FR-006**: SDK MUST support streaming query results as a `Stream`
- **FR-007**: SDK MUST support Wasm target compilation
- **FR-008**: SDK MUST have optional features to minimize dependency footprint
- **FR-009**: SDK MUST support querying events, entities, and projects
- **FR-010**: SDK MUST have comprehensive documentation with examples

## Success Criteria

### Measurable Outcomes

- **SC-001**: Single event publish latency < 5ms (local IPC)
- **SC-002**: Throughput > 50,000 events/second (local IPC, batch)
- **SC-003**: Minimal binary size < 2MB (stripped, no default features)
- **SC-004**: Query latency < 20ms (local)
- **SC-005**: SDK compiles on stable Rust (no nightly features)

## Assumptions

- Published to crates.io as `osai-sdk`
- Requires Rust 1.75+
- Local IPC via Unix domain sockets (Linux/macOS) or named pipes (Windows)
- Async via tokio (primary) with feature flag for async-std
- Serialization via serde + serde_json
- Wasm target via wasm-bindgen + web-sys
- Documentation via rustdoc with examples
- Source code lives at `sdks/rust/` in the monorepo