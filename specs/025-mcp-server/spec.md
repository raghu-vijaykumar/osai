# Feature Specification: MCP Server

**Feature Branch**: `025-mcp-server`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an MCP server that exposes OSAI's knowledge engine, storage, and agent capabilities as standard MCP tools, resources, and prompts"

## User Scenarios & Testing

### User Story 1 - Search Context via MCP Tool (Priority: P1)

An MCP-compatible AI assistant (e.g., Claude Desktop, Cursor, or any MCP client) connects to the OSAI MCP server. The assistant can call `search_context` to semantically search across all user events, entities, sessions, and projects. Results include relevant excerpts, timestamps, and source information.

**Why this priority**: Semantic search is the most fundamental capability. Every agent interaction starts with finding relevant context.

**Independent Test**: Connect any MCP client to the server, call `search_context` with query "React component architecture", and verify results include matching events (pages about React), entities (React), sessions, and projects with relevance scores.

**Acceptance Scenarios**:

1. **Given** an MCP client is connected, **When** the client calls `search_context({ query: "typescript generics", limit: 10 }), **Then** the response returns up to 10 results ranked by relevance, each with id, type, title, excerpt, timestamp, and score
2. **Given** a search with no matching results, **When** calling `search_context({ query: "zzznotfound" }), **Then** the response returns an empty results array with a `totalResults: 0` field

---

### User Story 2 - Query Knowledge Graph (Priority: P1)

The MCP server exposes the knowledge graph as MCP resources. Clients can query entities, their relationships, and traverse the graph. Resources follow the `graph://` URI scheme and return structured data.

**Why this priority**: The knowledge graph is OSAI's core data structure. Exposing it via MCP enables rich, contextual AI interactions.

**Independent Test**: Connect an MCP client, read resource `graph://entity/React`, and verify the response includes entity name, type (technology), related entities (React Native, TypeScript, JavaScript), and associated events/sessions.

**Acceptance Scenarios**:

1. **Given** an MCP client, **When** the client reads `graph://entity/typescript`, **Then** the response includes entity metadata: name, type, firstSeen, lastSeen, eventCount, and a list of related entities with relationship types
2. **Given** an MCP client, **When** the client reads `graph://related/typescript?depth=2`, **Then** the response returns a depth-2 traversal showing entities connected to TypeScript and their connections

---

### User Story 3 - Timeline and Session Resources (Priority: P2)

The MCP server exposes timeline events and sessions as resources. Clients can query events by time range, source, and type. Session resources include all events within a session, duration, and project association.

**Why this priority**: Timeline and session data enable temporal context — AI assistants can understand the sequence and flow of user activity.

**Independent Test**: Connect an MCP client, query `timeline://events?start=2026-07-10T00:00:00Z&end=2026-07-11T00:00:00Z`, and verify events from July 10 are returned with timestamps, sources, and content previews.

**Acceptance Scenarios**:

1. **Given** an MCP client, **When** reading `timeline://events?source=vscode&limit=20`, **Then** the last 20 VSCode events are returned with full event data including file paths and content excerpts
2. **Given** an MCP client, **When** reading `session://current`, **Then** the current active session is returned with start time, duration, associated project, and recent events

---

### User Story 4 - Agent Capability Exposure (Priority: P2)

The MCP server exposes each OSAI agent (Summarizer, Organizer, Researcher, etc.) as a set of MCP tools. For example, the Summarizer agent's tools include `summarize_day`, `summarize_week`, and `summarize_project`. Tools have typed parameters and return structured results.

**Why this priority**: Exposing agents as MCP tools makes them available to any MCP client, not just the OSAI UI. This enables composability with external AI tools.

**Independent Test**: Connect an MCP client, call `summarize_day({ date: "2026-07-10" })`, and verify the response includes a structured daily summary with total events, active time, top projects, top topics, and a narrative paragraph.

**Acceptance Scenarios**:

1. **Given** an MCP client connected to the server, **When** calling `organizer_suggest_tags({ eventIds: ["evt_1", "evt_2", "evt_3"] })`, **Then** the response returns suggested tags with confidence scores for each event
2. **Given** an MCP client, **When** listing available tools, **Then** the response includes all registered agent tools with name, description, and input/output schemas

---

### User Story 5 - Streaming and Long-Running Operations (Priority: P3)

Some agent operations (e.g., research, planning) may take significant time. The MCP server supports streaming responses and async job patterns. Long-running operations return a job ID that the client can poll or subscribe to for completion status.

**Why this priority**: Research and planning agents can take 10+ seconds. Non-blocking patterns keep the UI responsive and enable progress tracking.

**Independent Test**: Call `research_topic({ query: "MCP protocol specification" })` and verify a job ID is returned immediately, then polling the job status eventually returns "completed" with research results.

**Acceptance Scenarios**:

1. **Given** a long-running operation, **When** the client calls the tool, **Then** the server immediately returns `{ jobId: "job_123", status: "processing" }` with a `status_url` for polling
2. **Given** a job is in progress, **When** the client polls `job://job_123/status`, **Then** the response includes status (processing/completed/failed), progress percentage, and (when complete) the result

---

### Edge Cases

- What happens when the MCP client disconnects mid-operation?
- How are rate limits handled for multiple clients?
- What happens when the knowledge engine is still indexing?
- How are MCP protocol version mismatches handled?
- What happens when storage layer is unavailable?
- How are large result sets paginated?
- How is authentication handled for local vs. remote MCP connections?

## Requirements

### Functional Requirements

- **FR-001**: MCP server MUST implement the full MCP protocol specification (transport, tools, resources, prompts)
- **FR-002**: Server MUST support stdio transport (for local desktop clients) and SSE transport (for remote clients)
- **FR-003**: Server MUST expose `search_context` tool — semantic search across all user data
- **FR-004**: `search_context` MUST support parameters: query (string), limit (number), source (optional filter), type (optional filter), startTime/endTime (optional range)
- **FR-005**: `search_context` results MUST include: id, type, title, excerpt, timestamp, source, relevance score
- **FR-006**: Server MUST expose knowledge graph as resources with `graph://` URI scheme
- **FR-007**: Graph resources MUST support: `graph://entity/{name}`, `graph://related/{name}`, `graph://entity/{name}?depth=N`
- **FR-008**: Server MUST expose timeline events as `timeline://` resources with filter parameters
- **FR-009**: Server MUST expose sessions as `session://` resources (current, by ID, by date range)
- **FR-010**: Server MUST expose projects as `project://` resources (by ID, list all)
- **FR-011**: Each OSAI agent MUST register its capabilities as MCP tools
- **FR-012**: Agent tools MUST have typed input/output JSON schemas (MCP tools format)
- **FR-013**: Server MUST expose a list of all available tools via `tools/list`
- **FR-014**: Server MUST support long-running operations with job IDs and status polling
- **FR-015**: Server MUST support streaming responses for appropriate tools
- **FR-016**: Server MUST implement request logging for debugging and auditing
- **FR-017**: Server MUST handle concurrent client connections gracefully
- **FR-020**: Tools that trigger system changes MUST produce outbound Context Protocol events (spec 001) — every MCP action that creates, modifies, or deletes data emits a corresponding `event.action` to the event log
- **FR-021**: MCP tools calling outbound actions MUST await the corresponding inbound confirmation event before returning to the client (e.g., `session.start` waits for `session.started`)
- **FR-022**: All outbound events from MCP tools MUST include `app: "com.osai.mcp-server"` for traceability
- **FR-018**: Server MUST validate all inputs against tool schemas and return clear error messages
- **FR-019**: Server MUST start and be ready within 1 second of launch

### Key Entities

- **MCPServer**: The MCP-compatible server instance. Attributes: transport, tools (registered), resources (registered), prompts (registered), clients (connected), capabilities.
- **MCPTool**: A tool exposed to MCP clients. Attributes: name, description, inputSchema (JSON Schema), outputSchema, handler (function), source (core/agent), executionType (sync/streaming/async).
- **MCPResource**: A resource accessible via URI. Attributes: uri (scheme + path), name, description, mimeType, handler (function producing the resource).
- **MCPJob**: A long-running operation. Attributes: id, tool, status (pending/processing/completed/failed), progress (0-100), result, createdAt, completedAt, error.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Server starts and accepts connections in under 1 second
- **SC-002**: `search_context` returns results in under 200ms (cold start), under 50ms (warm)
- **SC-003**: Graph resource reads complete in under 100ms
- **SC-004**: Timeline/session resource reads complete in under 150ms
- **SC-005**: Server handles 10 concurrent clients without degradation
- **SC-006**: Long-running job polling returns status in under 10ms
- **SC-007**: Server consumes under 100MB base memory, under 200MB with active clients

## Assumptions

- Built as a standalone Node.js process using the `@modelcontextprotocol/sdk` package
- Supports both stdio (default) and SSE transports
- Runs alongside the OSAI desktop app or as a standalone daemon
- MCP server port is configurable (default: 3100 for SSE)
- Authentication via local socket permissions (stdio) or API token (SSE)
- Client connections are ephemeral; no persistent state per client
- Long-running jobs use an in-memory job queue with persistence to SQLite
- Streaming responses use MCP's native streaming capability
- Server auto-discovers agents at startup via the agent registry
- MCP tools that involve LLM calls (e.g., summarization, research) use the provider abstraction layer (spec 062) for routing
- Source code lives at `mcp/server/` in the monorepo