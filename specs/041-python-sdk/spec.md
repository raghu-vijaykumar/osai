# Feature Specification: Python SDK

**Feature Branch**: `041-python-sdk`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a Python SDK for publishing and consuming context events from the OSAI ecosystem"

## User Scenarios & Testing

### User Story 1 - Publish Events from Python (Priority: P1)

Python developers can use `pip install osai-sdk` to install the SDK. With a few lines of code, they can publish events: `from osai import Client; client = Client(); client.publish_event(type="custom.event", payload={"key": "value"})`. Events go through the Context Protocol, are validated, and appear in the user's timeline.

**Why this priority**: Event publishing is the primary use case. Python is widely used in data science, ML, and backend development.

**Independent Test**: Install the SDK, create a simple Python script that publishes 5 events with different types, run it. Verify the events appear in the OSAI timeline with correct types and payloads within 10 seconds.

**Acceptance Scenarios**:

1. **Given** the SDK is installed, **When** a developer calls `client.publish_event(type="code.run", payload={"script": "train.py", "duration": 120})`, **Then** the event appears in the timeline with type "code.run" and the payload fields visible
2. **Given** an invalid event (missing required field), **When** the developer attempts to publish, **Then** the SDK raises a `ValidationError` with a message describing the validation failure

---

### User Story 2 - Query Context from Python (Priority: P2)

Python code can query the user's context: search events, get entities, list projects, and query the knowledge graph. This enables Python-based agents, data analysis scripts, and automation. Queries go through the local storage or MCP server.

**Why this priority**: Querying context enables Python tools to leverage the user's knowledge base for data analysis and automation.

**Independent Test**: Write a Python script that queries "What projects was I working on this week?" using `client.search(query="projects this week")`. Verify the script returns a list of projects with event counts and time ranges.

**Acceptance Scenarios**:

1. **Given** the SDK and a running OSAI instance, **When** a developer calls `client.search_events(type="file.modified", limit=10)`, **Then** the last 10 file-modified events are returned as typed Python objects
2. **Given** the SDK, **When** a developer calls `client.get_entity(name="TypeScript")`, **Then** the entity details are returned including related entities and event count

---

### User Story 3 - Python Agent Development (Priority: P2)

The Python SDK includes an Agent base class for building OSAI agents in Python. Developers extend `BaseAgent`, implement handlers, and register tools. The agent runs as a subprocess managed by the scheduling system.

**Why this priority**: Python is a popular language for AI/ML development. Enabling Python agents expands the ecosystem significantly.

**Independent Test**: Create a Python agent that exposes a tool `hello_world(name: str) -> str`. Install it as a local agent, run it via the scheduling system, and call `hello_world("OSAI")` from the agent panel. Verify it returns "Hello, OSAI!"

**Acceptance Scenarios**:

1. **Given** the Python Agent SDK, **When** a developer creates a class extending `BaseAgent` with a `@tool` decorator, **Then** the tool is automatically registered with the MCP server and available in the agent panel
2. **Given** a Python agent is running, **When** it publishes events, **Then** events are sent through the Context Protocol and appear in the timeline

---

### User Story 4 - Async and Streaming Support (Priority: P3)

The Python SDK supports async/await for high-throughput event publishing and streaming for long-running queries. It can publish thousands of events per second in batch mode. Streaming queries return results as they become available.

**Why this priority**: Async support is essential for high-performance use cases like data pipeline integration.

**Independent Test**: Write an async script that publishes 10,000 events in batch mode. Verify all events are published and appear in the timeline. Write a streaming query that returns events as they match, verify results arrive incrementally.

**Acceptance Scenarios**:

1. **Given** the async SDK, **When** a developer publishes 10,000 events with `client.publish_batch(events)`, **Then** all events are published within 5 seconds (local) and appear in the timeline
2. **Given** a streaming query, **When** the developer calls `client.search_stream(query)`, **Then** results are yielded one by one as they become available

---

### User Story 5 - Documentation and Examples (Priority: P3)

The SDK includes comprehensive documentation: API reference, getting-started guide, migration guide, and example projects. Examples include: data pipeline integration, custom agent, Jupyter notebook integration, and CI/CD event publishing.

**Why this priority**: Good documentation is essential for developer adoption. Examples lower the barrier to entry.

**Acceptance Scenarios**:

1. **Given** the SDK documentation, **When** a developer visits the docs page, **Then** they see: quickstart (5-minute setup), API reference (all classes and methods), examples (5+ complete examples), and migration guide (breaking changes)
2. **Given** the SDK examples, **When** a developer runs `python -m osai.examples.jupyter_notebook`, **Then** a working example is demonstrated with clear comments

---

### Edge Cases

- What happens when the OSAI local service is not running?
- How are network errors handled (timeout, retry)?
- What happens when the Python version is incompatible?
- How are very large payloads handled?
- What happens when the user doesn't have OSAI installed?
- How is authentication handled for remote MCP connections?

## Requirements

### Functional Requirements

- **FR-001**: SDK MUST be installable via `pip install osai-sdk`
- **FR-002**: SDK MUST support publishing events through the Context Protocol
- **FR-003**: SDK MUST validate events against the protocol schemas before publishing
- **FR-004**: SDK MUST support querying events, entities, projects, and sessions
- **FR-005**: SDK MUST support querying via local storage and remote MCP server
- **FR-006**: SDK MUST include a `BaseAgent` class for building Python agents
- **FR-007**: Agents MUST support `@tool` decorator for registering MCP tools
- **FR-008**: SDK MUST support async/await for high-throughput operations
- **FR-009**: SDK MUST support batch event publishing
- **FR-010**: SDK MUST support streaming query results
- **FR-011**: SDK MUST have comprehensive API reference documentation
- **FR-012**: SDK MUST include 5+ example projects

## Success Criteria

### Measurable Outcomes

- **SC-001**: SDK installs in under 10 seconds (clean environment)
- **SC-002**: Single event publishes in under 10ms (local)
- **SC-003**: Batch publish of 10,000 events completes in under 5 seconds (local)
- **SC-004**: Query returns results in under 50ms (local)
- **SC-005**: SDK package size is under 1MB (excluding dependencies)

## Assumptions

- Published to PyPI as `osai-sdk`
- Supports Python 3.10+
- Uses HTTP for local MCP communication (or stdio subprocess)
- Async support via `asyncio` and `httpx`
- Validation uses Pydantic models matching the Context Protocol schemas
- Agent subprocess communicates with the scheduling system via stdio MCP
- Documentation hosted on Read the Docs or similar
- Source code lives at `sdks/python/` in the monorepo