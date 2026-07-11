# Feature Specification: Knowledge Graph Builder

**Feature Branch**: `014-graph-builder`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build the personal knowledge graph from entities, events, and their relationships"

## User Scenarios & Testing

### User Story 1 - Build Graph from Entities and Events (Priority: P1)

The graph builder takes extracted entities, events, and known relationships and builds a directed, typed graph. Nodes represent entities (technologies, people, topics) and events. Edges represent relationships ("mentions", "related_to", "followed_by").

**Why this priority**: The knowledge graph is the central organizing structure of OSAI. Without it, entities and events remain disconnected tables rather than a navigable understanding.

**Independent Test**: Publish 3 events mentioning "Kubernetes" and "Docker", then query the graph for the Kubernetes node and verify it has edges to both events and a `related_to` edge to Docker.

**Acceptance Scenarios**:

1. **Given** 5 events mentioning "React", **When** the graph builder runs, **Then** a node `React` (type: technology) exists with 5 incoming `mentions` edges from events
2. **Given** events mentioning both "React" and "Next.js" in the same context, **When** the builder processes co-occurrences, **Then** a `co_occurs_with` edge exists between React and Next.js with a weight proportional to co-occurrence frequency

---

### User Story 2 - Infer Implicit Relationships (Priority: P1)

The graph builder infers relationships between entities that share events in common, are mentioned together frequently, or follow sequential patterns (e.g., visiting docs.python.org then writing a .py file implies "learning" followed by "building").

**Why this priority**: Explicit relationships (entity A mentioned in event B) are straightforward. Implicit relationships (entity A is related to entity C because they co-occur in events) create the real value — discovering connections the user may not have noticed.

**Independent Test**: Visit 3 pages about "Rust" and 2 pages about "WebAssembly", then visit a page mentioning both. Verify the graph infers a `strongly_related` edge between Rust and WebAssembly.

**Acceptance Scenarios**:

1. **Given** "TypeScript" and "React" co-occur in 10+ events, **When** the graph builder runs, **Then** a `strongly_related` edge exists between them with weight > 0.8
2. **Given** a temporal sequence where a `url.visited` for a documentation page is followed within 2 minutes by a `file.modified` for a code file, **When** the builder detects this pattern, **Then** a `learning_led_to_building` edge connects the two events

---

### User Story 3 - Graph Query API (Priority: P2)

The graph builder exposes a query API for retrieving subgraphs, traversing relationships, and finding paths between entities. Queries support depth limits, type filters, and pagination.

**Why this priority**: The graph is only useful if it's queryable. UI components (graph view, context sidebar, command bar) and agents all need to traverse the graph efficiently.

**Independent Test**: Query "find path from 'Kubernetes' to 'AWS'" and verify the returned path includes intermediate nodes (e.g., "Kubernetes" → "EKS" → "AWS") with correct edge types.

**Acceptance Scenarios**:

1. **Given** a graph with 100 nodes and 300 edges, **When** querying `getSubgraph("Kubernetes", { depth: 2 })`, **Then** all nodes within 2 hops of Kubernetes are returned with their edges
2. **Given** two entities "React Native" and "TypeScript", **When** querying `findPath("React Native", "TypeScript")`, **Then** the shortest path is returned with edge types and node types

---

### User Story 4 - Graph Persistence and Incremental Updates (Priority: P2)

The graph is persisted to storage and updated incrementally as new events arrive. Only the affected subgraph is recomputed — not the entire graph. The full graph can be rebuilt from scratch if needed.

**Why this priority**: Rebuilding the entire graph from scratch on every new event is O(n) and doesn't scale. Incremental updates keep the graph fresh without recomputation.

**Independent Test**: Build a graph from 100 events, add 10 new events, verify the graph is updated within 2 seconds without recomputing the original 100 events' contributions.

**Acceptance Scenarios**:

1. **Given** a graph built from 500 events, **When** a new event mentioning "Astro" (new entity) arrives, **Then** only the new entity, its event, and edges are added — no full rebuild
2. **Given** a graph with corrupted data, **When** a `rebuildGraph()` operation is triggered, **Then** the entire graph is rebuilt from scratch using all stored events and entities

---

### User Story 5 - User-Centric Graph Roots (Priority: P3)

The graph has a root `User` node with edges to frequently used entities representing the user's interests, skills, projects, and preferences. The root node serves as the entry point for the "personal knowledge graph."

**Why this priority**: The user-centric root transforms a generic entity graph into a personal knowledge graph. It answers "what does this user care about?" at a glance.

**Independent Test**: After generating 100 events across 10 technologies, query the User node and verify it has `interested_in` edges to the top 5 technologies by mention count.

**Acceptance Scenarios**:

1. **Given** a user with 20 events about "React" and 5 about "Vue", **When** querying the User node, **Then** "React" appears as an `interested_in` edge with weight 0.8 and "Vue" with weight 0.2
2. **Given** a user works on "osai" and "website-redesign" projects, **When** querying the User node, **Then** `works_on` edges connect to project nodes with the project names

---

### Edge Cases

- What happens when the graph has disconnected subgraphs (entities with no relationships)?
- How are very high-degree nodes (an entity mentioned in 10K+ events) handled in queries — pagination required?
- What happens when entity mention counts decrease (events deleted) — is the graph adjusted?
- How are conflicting entity types resolved (e.g., "Spring" as a framework vs a season)?
- What happens when the graph query exceeds a 5-second timeout?
- How are bidirectional vs directed edges modeled and queried differently?

## Requirements

### Functional Requirements

- **FR-001**: System MUST build a directed, typed graph from entities, events, and their relationships
- **FR-002**: Graph MUST have node types: `entity` (with subtypes from entity extraction), `event`, `session`, `project`, `user`, `source`
- **FR-003**: Graph MUST have edge types: `mentions`, `co_occurs_with`, `related_to`, `followed_by`, `part_of`, `depends_on`, `interested_in`, `works_on`, `learning_led_to_building`, `strongly_related`
- **FR-004**: System MUST persist the graph to storage (SQLite with adjacency table) with tables: `graph_nodes`, `graph_edges`, `graph_node_properties`
- **FR-005**: System MUST support incremental updates — only recompute affected subgraphs on new events
- **FR-006**: System MUST support full graph rebuild from stored events and entities
- **FR-007**: System MUST expose a graph query API: `getNode(id)`, `getSubgraph(nodeId, { depth, types, direction })`, `findPath(from, to, { maxDepth })`, `searchNodes(query, { types, limit })`, `getNeighbors(nodeId, { edgeTypes, direction })`
- **FR-008**: System MUST compute edge weights based on: co-occurrence frequency (0.0–1.0), temporal proximity, confidence scores from entity extraction
- **FR-009**: System MUST create a root `User` node with inferred edges: `interested_in` (top entities by mention count), `works_on` (project names from events), `uses` (frequent tools)
- **FR-010**: System MUST support user-defined edge annotations — users can add, remove, or modify edges
- **FR-011**: System MUST publish `graph.updated` events when the graph changes (add/remove nodes or edges)
- **FR-012**: System MUST support graph export in standard formats: JSON (node-link), DOT (Graphviz), GraphML

### Key Entities

- **GraphNode**: A node in the knowledge graph. Attributes: `id` (TEXT PK), `type` (TEXT — `entity`/`event`/`session`/`project`/`user`/`source`), `label` (TEXT), `properties` (JSON), `degree` (INT — number of edges), `createdAt`, `updatedAt`.
- **GraphEdge**: A typed, directed edge between two nodes. Attributes: `sourceId`, `targetId`, `type`, `weight` (0.0–1.0), `properties` (JSON — e.g., context snippet, confidence), `createdAt`.
- **GraphQuery**: A query against the graph. Types: `getNode`, `getSubgraph`, `findPath`, `searchNodes`, `getNeighbors`. Each has type-specific parameters.
- **UserNode**: The root node representing the user. Has `interested_in`, `works_on`, `uses`, `learning`, `prefers` edges to other nodes.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Graph builds from 1000 events in under 5 seconds
- **SC-002**: Incremental update for a single new event completes in under 100ms
- **SC-003**: Full graph rebuild from 10,000 events completes in under 60 seconds
- **SC-004**: `getSubgraph(node, { depth: 2 })` on a node with 50 neighbors returns in under 50ms
- **SC-005**: `findPath` between two nodes returns in under 200ms on a graph with 1000 nodes
- **SC-006**: Graph persistence: storage overhead < 1MB per 10,000 edges
- **SC-007**: Incremental updates never produce inconsistent state (atomic node+edge writes)

## Assumptions

- Graph is stored in SQLite using adjacency list model (not a dedicated graph DB like Neo4j)
- Node properties stored as JSON blob for flexibility
- Edge weights are computed using: `co_occurrence_count / max_co_occurrence` normalized to 0.0–1.0
- Temporal proximity bonus: entities mentioned within 5 minutes get 0.1 weight boost
- The full graph is always kept in memory (compressed) for fast queries, with periodic persistence to SQLite
- Graph memory budget: 10MB for 10,000 nodes and 50,000 edges (compressed adjacency + properties)
- Graph export to JSON for UI visualization (D3.js, vis-network, or similar)
- Source code lives at `knowledge-engine/graph-builder/` in the monorepo
