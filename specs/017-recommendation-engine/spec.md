# Feature Specification: Recommendation Engine

**Feature Branch**: `017-recommendation-engine`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a recommendation engine that suggests related content, next actions, and relevant context based on user activity"

## User Scenarios & Testing

### User Story 1 - Recommend Related Content (Priority: P1)

When the user is reading about a topic (e.g., "Knowledge Graphs"), the recommendation engine suggests related content the user has visited before — past pages, PDFs, conversations, or code files that share entities or semantic similarity with the current topic.

**Why this priority**: Content recommendation turns the knowledge graph into a discovery tool. It surfaces "you read about this before" connections that users would otherwise forget.

**Independent Test**: Publish events about "Rust" and "WebAssembly" across different sessions. Then, while the user is researching "WebAssembly", verify the recommendation engine returns past "Rust" content as related.

**Acceptance Scenarios**:

1. **Given** the user visited 5 pages about "GraphQL" last week, **When** the user opens a new page about "Apollo Client", **Then** recommendations include the 3 most relevant past GraphQL pages ranked by similarity
2. **Given** a user has both PDFs and web pages about "MCP protocol", **When** querying recommendations for current context, **Then** both PDF and web content appear with source labels

---

### User Story 2 - Recommend Next Actions (Priority: P2)

Based on the user's current activity and historical patterns, the engine suggests next actions. Common patterns: "After reading docs, users typically open their IDE" → suggests `file: open project`. "After a git commit, users typically run tests" → suggests `action: run tests`.

**Why this priority**: Next action recommendations reduce context-switching friction. The system anticipates what the user will do next and offers a shortcut.

**Independent Test**: Build a pattern where reading docs is followed by opening a code file within 5 minutes (3 times). Then, after a new doc-reading event, verify the recommendation suggests "Open recent code file."

**Acceptance Scenarios**:

1. **Given** a pattern where `url.visited` (docs) → `file.opened` (code) occurs 5+ times, **When** a new `url.visited` for a docs page occurs, **Then** the engine recommends "Continue coding in [project name]" with confidence > 0.6
2. **Given** a pattern where `git.commit` → `terminal.command: npm test` occurs 3+ times, **When** a commit event is published, **Then** "Run tests" is a recommended next action

---

### User Story 3 - Context-Aware Recommendations (Priority: P2)

The recommendation engine considers the user's current session context — active project, recent entities, current activity type — to rank recommendations. Contextual recommendations are different from global recommendations.

**Why this priority**: A recommendation while building a React app should be different from one while researching ML papers. Context narrows the recommendation space to what's immediately useful.

**Independent Test**: Start a session with project "osai" (TypeScript focus) and a separate session with project "ml-papers" (Python focus). Query recommendations in each and verify the first surfaces TypeScript content and the second surfaces ML content.

**Acceptance Scenarios**:

1. **Given** the user is in a "building" session for project "osai", **When** requesting contextual recommendations, **Then** the top 3 results are relevant to TypeScript, knowledge graphs, and protocol design
2. **Given** the user is in a "learning" session about "Rust", **When** requesting contextual recommendations, **Then** results include "Rust Book" (if visited before), Rust-related code files, and "WebAssembly" (related entity)

---

### User Story 4 - Time-Aware Decay (Priority: P3)

Recommendations are time-weighted. Recent content is weighted higher than old content. A page visited yesterday about "Kubernetes" ranks higher than the same page visited 6 months ago.

**Why this priority**: User interests change over time. Last week's deep dive into "Rust" should not drown out today's interest in "Go." Time decay ensures recommendations reflect current focus.

**Independent Test**: Visit pages about "Vue" 30 days ago and "React" yesterday. Query recommendations for "frontend frameworks" and verify React content ranks higher than Vue content.

**Acceptance Scenarios**:

1. **Given** "Kubernetes" content visited today and "Docker" content visited 3 months ago, **When** recommendations are generated for container topics, **Then** Kubernetes content ranks higher with a decay-adjusted score
2. **Given** an entity with 50 mentions from 6 months ago and 5 mentions from today, **When** computing relevance, **Then** recent mentions are weighted 3x higher than old mentions

---

### User Story 5 - Diverse Recommendations (Priority: P3)

Recommendations balance relevance (similar to current context) with diversity (not all from the same source, type, or project). The engine avoids showing 10 browser pages and 0 code files.

**Why this priority**: Homogeneous recommendations are less useful. Diversity ensures the user discovers different types of relevant content — a code file, a PDF, a conversation, and a web page.

**Independent Test**: Query recommendations for a topic with 20 matching browser events and 3 matching code files. Verify the top 5 includes at least 1 code file (diversity boost).

**Acceptance Scenarios**:

1. **Given** 10 matching browser events and 2 matching PDFs, **When** `getRecommendations({ count: 5 })` is called, **Then** at least 1 PDF is in the results (diversity across sources)
2. **Given** recommendations across 20 events but only 3 unique entities, **When** diversity scoring runs, **Then** results that introduce new entities are boosted by 0.1

---

### Edge Cases

- What happens when the user has no history for a topic (cold start)?
- How are recommendations updated when events are deleted or projects are removed?
- What happens when the recommendation engine has insufficient data (< 100 events)?
- How are very popular entities (common words, stop words) prevented from dominating?
- What happens when the user's context changes rapidly (switching projects every 5 minutes)?
- How are privacy-sensitive recommendations handled — should the system suggest content from hidden sources?
- What happens when two users share a device — are recommendations personalized?

## Requirements

### Functional Requirements

- **FR-001**: Engine MUST generate content recommendations based on current context: active entities, active project, session activity type, and recent events
- **FR-002**: Engine MUST support recommendation types: `content` (related past events), `action` (predicted next steps), `entity` (related topics to explore), `project` (related projects)
- **FR-003**: Engine MUST score recommendations using: semantic similarity (cosine distance on embeddings), entity overlap (Jaccard similarity), temporal recency (exponential decay with 30-day half-life), source diversity bonus
- **FR-004**: Engine MUST apply time decay: score multiplier = `exp(-daysSince / halflife)` with configurable half-life (default: 30 days)
- **FR-005**: Engine MUST detect action patterns from event sequences — common transitions between event types (e.g., `url.visited` → `file.opened`) using Markov chain or sequential pattern mining
- **FR-006**: Engine MUST support query parameters: `context` (current event/project/entity), `types` (recommendation types to include), `sources` (event sources to include/exclude), `count`, `diversityWeight` (0.0–1.0, default: 0.3)
- **FR-007**: Engine MUST expose API: `getRecommendations(query)` returning `{ recommendations: [{ type, id, score, title, summary, source, timestamp }], context: { query, processingTime } }`
- **FR-008**: Engine MUST apply diversity re-ranking — MMR (Maximum Marginal Relevance) algorithm balancing relevance and diversity
- **FR-009**: Engine MUST handle cold start — when user has < 100 events, return "getting started" suggestions (enable more connectors, explore the UI)
- **FR-010**: Engine MUST exclude the current event from recommendations (don't recommend the same event)
- **FR-011**: Engine MUST avoid recommending content from hidden/blocked sources
- **FR-012**: Engine MUST be configurable: `recommendations.enabled`, `recommendations.minEvents`, `recommendations.decayHalfLife`, `recommendations.diversityWeight`, `recommendations.maxResults`

### Key Entities

- **Recommendation**: A suggested item. Attributes: `type` (content/action/entity/project), `id`, `score` (0.0–1.0), `title`, `summary`, `source` (event source type), `timestamp` (of original event), `reason` (explanation text like "Similar to what you're reading").
- **RecommendationQuery**: A request for recommendations. Attributes: `context` (optional event/project/entity for contextualization), `types` (filter), `sources` (filter), `count` (default: 10), `diversityWeight` (default: 0.3), `minScore` (default: 0.1).
- **ActionPattern**: A detected sequential transition. Attributes: `fromEventType`, `toEventType`, `frequency`, `avgTimeDelta` (average time between), `projects` (where this pattern is observed).
- **Scorer**: A scoring component. Types: `similarity_scorer` (embedding cosine), `entity_scorer` (entity overlap), `recency_scorer` (time decay), `diversity_scorer` (MMR).
- **ContextSignal**: Input to the recommendation engine. Attributes: `currentEntities` (active entities from recent events), `currentProject`, `currentActivity`, `currentSession`, `recentEvents` (last 20).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Recommendation generation completes in under 100ms for a user with 10,000 events
- **SC-002**: Content recommendation relevance: top-5 precision > 0.7 (user rates recommendations as relevant)
- **SC-003**: Action recommendation accuracy > 0.6 (predicted next action matches actual next action)
- **SC-004**: Diversity: at least 2 different source types in top-5 recommendations (when available)
- **SC-005**: Cold start: recommendations return "getting started" suggestions within 50ms for < 100 events
- **SC-006**: Re-ranking (with diversity) adds less than 20ms to total generation time

## Assumptions

- Primary scoring uses cosine similarity on event embeddings (from the embeddings pipeline)
- Entity overlap uses Jaccard similarity on entity sets from entity extraction
- Action patterns use a 2nd-order Markov model tracking `(previousEventType, currentEventType) → nextEventType`
- Diversity uses MMR (Maximal Marginal Relevance): `MMR = λ * Relevance - (1-λ) * max(SimilarityToSelected)`
- Time decay half-life of 30 days is the default; configurable per user
- The engine runs in-memory (no external recommendation service) for latency
- Cold start content includes: "Install the browser extension", "Open a project in VSCode", "Explore the timeline"
- Recommendations are stored ephemerally (not persisted) — generated on-demand from current state
- The recommendation engine is part of the `@osai/knowledge-engine` package
- Source code lives at `knowledge-engine/recommendations/` in the monorepo
