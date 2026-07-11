# Feature Specification: Graph View

**Feature Branch**: `020-graph-view`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an interactive knowledge graph visualization showing entities, events, and their relationships"

## User Scenarios & Testing

### User Story 1 - Interactive Graph Visualization (Priority: P1)

The graph view renders the knowledge graph as an interactive force-directed layout. Nodes represent entities, events, and projects. Edges represent relationships. Users can pan, zoom, click, and drag nodes. Node and edge colors/types are visually distinct.

**Why this priority**: The graph visualization is the most intuitive way to explore the knowledge graph. It reveals connections that lists and tables hide.

**Independent Test**: Load 50 nodes and 120 edges into the graph. Verify all nodes render, edges show connection lines with arrowheads, and force layout stabilizes within 3 seconds without overlapping nodes.

**Acceptance Scenarios**:

1. **Given** a graph with entities (blue circles), events (smaller gray dots), and projects (green squares), **When** the graph loads, **Then** each node type has a distinct shape and color, edges show relationship type as labels, and the layout stabilizes in a readable configuration
2. **Given** the graph is rendered, **When** the user pans and zooms, **Then** the graph responds smoothly at 60fps with no visual artifacts

---

### User Story 2 - Node Exploration and Expansion (Priority: P1)

Clicking a node shows a popover with node details (name, type, mention count, related events). A "Expand" button loads the node's immediate neighbors, adding them to the visible graph. Double-clicking a node centers and zooms on it.

**Why this priority**: Graph exploration is iterative. Users start with an overview, then drill into specific nodes of interest, expanding the graph organically.

**Independent Test**: Click on "Kubernetes" node, verify popover shows type "technology", mention count 15, and related entities. Click "Expand" and verify 8 new neighbor nodes appear with edges.

**Acceptance Scenarios**:

1. **Given** a visible "TypeScript" node, **When** clicked, **Then** a popover shows: type (technology), mention count, top 3 related events, and "Expand neighbors" and "View in Timeline" buttons
2. **Given** a node is expanded, **When** neighbors load, **Then** they render with a subtle entrance animation and the graph re-laysout to accommodate new nodes

---

### User Story 3 - Search and Filter (Priority: P2)

Users search for nodes by name or type. Results highlight matching nodes and dim non-matching ones. Filters by node type, edge type, or project scope constrain the visible subgraph.

**Why this priority**: Large graphs with hundreds of nodes are overwhelming. Search and filters let users focus on relevant subgraphs.

**Independent Test**: Type "React" in the search bar. Verify the "React" node highlights, dims unrelated nodes, and shows a count "1 of 50 nodes match". Apply a filter for "technology" type only and verify only technology-type nodes remain visible.

**Acceptance Scenarios**:

1. **Given** a graph with 100 nodes, **When** typing a search query, **Then** matching nodes are highlighted with a glow effect, non-matching nodes are dimmed (opacity 0.2), and edge opacity is reduced proportionally
2. **Given** filter options for node type (entity/event/project), **When** selecting "entity" only, **Then** event and project nodes are hidden, edges to hidden nodes are also hidden

---

### User Story 4 - Path Finding Between Nodes (Priority: P2)

Users can select two nodes and find the shortest path between them through the graph. The path is highlighted with animated edges. Results show intermediate nodes and relationship types.

**Why this priority**: Path finding reveals how concepts are connected — "How is React related to AWS?" The answer might show React → Next.js → Vercel → AWS, revealing a chain the user didn't consciously notice.

**Independent Test**: Select "Python" and "Docker", run path finding, and verify the result shows a connected path (e.g., Python → Flask → Docker → Container) with edge labels at each step.

**Acceptance Scenarios**:

1. **Given** two nodes "React Native" and "TypeScript" selected, **When** requesting path finding, **Then** the shortest path is highlighted with animated dashed edges and intermediate nodes are emphasized
2. **Given** no path exists between two nodes, **When** requesting path finding, **Then** a message "No direct path found — these nodes are in disconnected subgraphs" is displayed

---

### User Story 5 - Graph Layout Controls (Priority: P3)

Users can switch layout algorithms (force-directed, hierarchical, radial), adjust physics parameters (gravity, repulsion, link distance), toggle labels on/off, and export the current view as PNG or SVG.

**Why this priority**: Different graphs benefit from different layouts. Force-directed works for general exploration. Hierarchical works for dependency graphs. Radial works for ego-centric views.

**Independent Test**: Switch from force-directed to radial layout centered on the "User" node. Verify the graph re-arranges with User at center and all other nodes in concentric circles by edge distance.

**Acceptance Scenarios**:

1. **Given** a graph in force-directed layout, **When** switching to hierarchical layout, **Then** nodes arrange in top-down tree layout based on edge direction with smooth transition animation
2. **Given** a graph with labels visible, **When** toggling labels off, **Then** only nodes (shapes/colors) are visible; labels fade out

---

### Edge Cases

- What happens when the graph has 5,000+ nodes — does it need clustering or level-of-detail rendering?
- How are very long entity names (50+ chars) displayed on nodes?
- What happens when two nodes have the same position after layout (overlap resolution)?
- How is graph performance affected by 1,000+ edges between two densely-connected communities?
- What happens when the user's screen is very small or very high-DPI?
- How are cycles in the graph visualized (A → B → C → A)?
- What happens when the graph data changes (live updates)?

## Requirements

### Functional Requirements

- **FR-001**: Graph MUST render nodes and edges using a force-directed layout (D3-force or similar) with configurable physics
- **FR-002**: Node types MUST have distinct visual representations: entity (circle, colored by subtype), event (small dot, gray), project (square, green), user (large circle, gold highlight)
- **FR-003**: Edge types MUST have distinct visual styles: mention (thin solid), co_occurs_with (dashed), related_to (dotted), strongly_related (thick solid), interested_in (animated dash)
- **FR-004**: Graph MUST support pan (drag background), zoom (scroll/pinch), drag nodes (reposition), and double-click to center on node
- **FR-005**: Clicking a node MUST show a detail popover with: name, type, mention count, top related events, entity metrics, and action buttons (Expand, View in Timeline, View in Projects)
- **FR-006**: Graph MUST support incremental expansion — clicking "Expand" on a node loads and renders its immediate neighbors
- **FR-007**: Graph MUST support search — highlight matching nodes, dim non-matching (opacity 0.2), show match count
- **FR-008**: Graph MUST support filtering by node type, edge type, and project scope
- **FR-009**: Graph MUST support path finding between two selected nodes — highlight shortest path with animated edges
- **FR-010**: Graph MUST support layout switching: force-directed, hierarchical (DAG), radial (ego-centric)
- **FR-011**: Graph MUST support toggling labels on/off
- **FR-012**: Graph MUST support export as PNG and SVG
- **FR-013**: Graph MUST handle > 500 nodes with WebGL rendering (or canvas fallback when SVG performance degrades)
- **FR-014**: Graph MUST support live updates — new nodes/edges appear with entrance animation without full re-render
- **FR-015**: Graph MUST use colors from the design system node color palette (spec 059, --os-color-node-*) — theme-aware and colorblind-friendly
- **FR-016**: Graph MUST use design system (spec 059) components for the search bar, filter panel, layout control, and action buttons

### Key Entities

- **GraphCanvas**: The main visualization component. Handles rendering, layout, zoom/pan, and node/edge interactions.
- **GraphNode**: A rendered node. Attributes: type, color, size (proportional to mention count/page rank), label, isExpanded, isHighlighted, isDimmed.
- **GraphEdge**: A rendered edge. Attributes: type, line style, thickness (proportional to weight), source, target, label (relationship type), isHighlighted.
- **NodePopover**: Detail popup on node click. Shows metadata, related entities, action buttons.
- **SearchBar**: Graph search input with autocomplete and result highlighting.
- **FilterPanel**: Side panel or dropdown for filtering by node type, edge type, project.
- **LayoutControl**: Dropdown/toggle for switching between force-directed, hierarchical, radial layouts.
- **PathFinder**: Tool for selecting two nodes and computing/highlighting shortest path.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Graph with 200 nodes and 500 edges renders in under 2 seconds
- **SC-002**: Force layout stabilizes within 3 seconds (alpha < 0.001)
- **SC-003**: Node click → popover shows in under 50ms
- **SC-004**: Search results highlight in under 100ms
- **SC-005**: Path finding between two nodes completes in under 200ms
- **SC-006**: Graph maintains 60fps during pan/zoom with 500 nodes
- **SC-007**: Layout switch animates smoothly within 2 seconds

## Assumptions

- Uses D3-force for force-directed layout computation and Canvas/WebGL for rendering (via d3-force-canvas or a library like react-force-graph-2d or react-force-graph-3d)
- Node size = proportional to page rank or degree centrality (capped min/max for readability)
- Initial graph loads with top 100 nodes by degree centrality (configurable)
- Large graphs (> 500 nodes) use canvas rendering for performance; SVG is too slow
- Color palette follows the design system (spec 059) — node type colors, dark/light/high-contrast modes, and colorblind-friendly palette are inherited
- Node labels are truncated to 20 chars with ellipsis; full name in popover/tooltip
- Layout physics parameters are exposed as sliders for advanced users
- Graph data format: JSON node-link format (compatible with D3)
- Source code lives at `ui/graph-view/` in the monorepo
