# Feature Specification: Go SDK

**Feature Branch**: `043-go-sdk`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a Go SDK for integrating OSAI event publishing and context querying into Go applications"

## User Scenarios & Testing

### User Story 1 - Simple Event Publishing (Priority: P1)

Go developers add `go get github.com/osai-dev/osai-sdk-go`. The SDK provides a simple API: `client := osai.NewClient(); client.PublishEvent(ctx, osai.Event{Type: "custom.event", Payload: map[string]any{"key": "value"}})`. Events are validated, serialized, and sent via gRPC or HTTP to the local OSAI service.

**Why this priority**: Go is widely used for backend services, CLIs, and DevOps tools. Easy event publishing is the primary integration point.

**Independent Test**: Write a Go program that imports the SDK, creates a client, publishes 10 events of different types, and exits. Run the program, verify all 10 events appear in the OSAI timeline with correct types and payloads.

**Acceptance Scenarios**:

1. **Given** the Go SDK, **When** a developer calls `client.PublishEvent(ctx, osai.Event{Type: "deploy.started", Payload: payload})`, **Then** the event appears in the timeline with the correct type and payload
2. **Given** the Go SDK with an invalid event (missing required field), **When** the developer attempts to publish, **Then** the SDK returns an `osai.ValidationError`

---

### User Story 2 - Context Queries for DevOps (Priority: P2)

Go-based DevOps tools can query OSAI context: "What deployments happened in the last 24 hours?" or "Show me recent GitHub activity for project X." Query results are typed Go structs with standard interfaces.

**Why this priority**: DevOps integration is a natural fit for Go. CI/CD pipelines, monitoring tools, and deployment scripts can all publish and query context.

**Independent Test**: Create a Go CLI tool that queries `client.SearchEvents(ctx, osai.SearchQuery{Type: "deploy.*", Since: time.Now().Add(-24 * time.Hour)})` and prints a summary. Verify it returns events matching the "deploy." type pattern from the last 24 hours.

**Acceptance Scenarios**:

1. **Given** the Go SDK, **When** a developer calls `client.SearchEvents(ctx, query)`, **Then** matching events are returned as `[]osai.Event` with all fields populated
2. **Given** the Go SDK, **When** a developer calls `client.GetEntity(ctx, "Kubernetes")`, **Then** the entity details are returned as an `osai.Entity` struct

---

### User Story 3 - gRPC and HTTP Transport (Priority: P2)

The Go SDK supports multiple transports: gRPC (efficient, structured) and HTTP/REST (simple, debuggable). Transports are interchangeable via a `Transport` interface. The default transport auto-detects the most efficient available option.

**Why this priority**: gRPC is idiomatic in Go ecosystems. HTTP provides a simpler fallback for restricted environments.

**Independent Test**: Create two Go programs — one using gRPC transport, one using HTTP transport. Both should successfully publish and query events with identical APIs.

**Acceptance Scenarios**:

1. **Given** the Go SDK with a `grpc` build tag, **When** a developer creates a client, **Then** the client uses gRPC transport for all operations
2. **Given** the Go SDK with an `http` build tag, **When** a developer creates a client, **Then** the client uses HTTP/REST transport and all operations work identically

---

### User Story 4 - Go Agent Development (Priority: P3)

The Go SDK includes an Agent framework for building OSAI agents in Go. Agents implement the `Agent` interface, register tools, and run as subprocesses managed by the scheduling system. The framework handles MCP protocol compliance automatically.

**Why this priority**: Go's concurrency model is well-suited for long-running agent processes.

**Independent Test**: Create a Go agent with a tool `hello(name string) string`. Register it as a local agent, call it from the agent panel, and verify it responds correctly.

**Acceptance Scenarios**:

1. **Given** the Go Agent SDK, **When** a developer creates a struct implementing the `Agent` interface with tool handlers, **Then** the agent is registered with the MCP server and tools are callable
2. **Given** a Go agent with concurrent tool handlers, **When** multiple tool calls arrive simultaneously, **Then** they are handled concurrently with correct results

---

### Edge Cases

- What happens when the gRPC connection is lost?
- How are context deadlines and timeouts handled?
- What happens when the Go version is too old?
- How are circular imports avoided in the SDK design?

## Requirements

### Functional Requirements

- **FR-001**: SDK MUST be installable via `go get github.com/osai-dev/osai-sdk-go`
- **FR-002**: SDK MUST support publishing events with validation
- **FR-003**: SDK MUST support querying events, entities, and projects
- **FR-004**: SDK MUST support gRPC and HTTP transports
- **FR-005**: Transports MUST be interchangeable via a `Transport` interface
- **FR-006**: SDK MUST auto-detect the best available transport
- **FR-007**: SDK MUST include an Agent framework for building Go agents
- **FR-008**: Agent framework MUST handle MCP protocol compliance
- **FR-009**: SDK MUST support context deadlines and cancellation (`context.Context`)
- **FR-010**: SDK MUST have comprehensive documentation with examples

## Success Criteria

### Measurable Outcomes

- **SC-001**: Single event publish latency < 5ms (gRPC, local)
- **SC-002**: Throughput > 30,000 events/second (gRPC, local, batch)
- **SC-003**: Query latency < 20ms (local)
- **SC-004**: SDK compiles with Go 1.21+
- **SC-005**: SDK has zero external dependencies beyond stdlib + protobuf/gRPC

## Assumptions

- Published as `github.com/osai-dev/osai-sdk-go`
- Requires Go 1.21+
- Primary transport: gRPC (with Protocol Buffers)
- Fallback transport: HTTP/REST (for environments without gRPC)
- Agent framework uses stdio MCP transport for subprocess communication
- Go agents run as subprocesses managed by the scheduler
- Documentation via pkg.go.dev with examples in doc comments
- Source code lives at `sdks/go/` in the monorepo