# Feature Specification: Researcher Agent

**Feature Branch**: `028-researcher-agent`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a researcher agent that performs context-aware web research, finding and summarizing information related to the user's current work"

## User Scenarios & Testing

### User Story 1 - Context-Aware Research Query (Priority: P1)

The researcher agent accepts a research query and automatically augments it with the user's current context (active project, recent events, open files, top entities). For example, asking "Find best practices" while working on a React project returns React-specific results rather than generic best practices. The context used in augmentation is shown to the user.

**Why this priority**: Context-aware research gives dramatically better results than raw web search. It understands what the user cares about without needing explicit qualification.

**Independent Test**: While working on "osai" project with recent events about MCP protocol and storage layer, ask the researcher "Find relevant design patterns." Verify the search query was augmented to include "osai MCP protocol storage" context, and results are specifically about design patterns for MCP and storage systems.

**Acceptance Scenarios**:

1. **Given** the user is working on a React component library, **When** they ask "research find best testing practices", **Then** the researcher augments the query with context (React, component testing, recent testing events) and returns results specific to React component testing
2. **Given** the researcher is executing, **When** the user clicks "Show Context Used", **Then** a panel shows: augmented query, context sources (current project, last 5 events, open files, top 3 entities), and enables editing the query

---

### User Story 2 - Multi-Source Research (Priority: P2)

The researcher searches across multiple sources: web search (via a search API), documentation sites (docs pages matching the query), GitHub (repos, issues, PRs), Stack Overflow (Q&A), and the user's own knowledge base (past events, saved pages). Results are deduplicated and ranked by relevance, with source labels.

**Why this priority**: Multi-source research gives a comprehensive view — not just web results but also relevant GitHub issues and the user's own past work.

**Independent Test**: Ask "research MCP protocol implementations." Verify results include: web search results (top 3), GitHub repos implementing MCP (top 3), Stack Overflow Q&A about MCP (top 2), and any past pages the user visited about MCP (from local knowledge base).

**Acceptance Scenarios**:

1. **Given** a research query, **When** the researcher completes, **Then** results are grouped by source (Web, GitHub, Stack Overflow, My Knowledge Base) with each group showing up to 3 results
2. **Given** the same result appears from multiple sources, **When** results are compiled, **Then** duplicates are deduplicated and the result shows "Also found on: [other sources]"

---

### User Story 3 - Research Session with Follow-up (Priority: P2)

Research queries create a "research session" that maintains context across follow-up questions. Users can ask "find me Rust async runtime comparisons", then follow up with "what about Tokio vs async-std?" and the researcher understands the connection to the original query.

**Why this priority**: Research is iterative. Without session context, each follow-up requires re-stating the topic.

**Independent Test**: Start a research session: "Compare React state management libraries." Then follow up with "what about Zustand?" Verify the follow-up understands "what about" refers to "React state management libraries compared to Zustand."

**Acceptance Scenarios**:

1. **Given** an active research session, **When** the user asks "find more about that", **Then** the researcher interprets "that" as the previously discussed topic and returns additional results
2. **Given** a research session with history, **When** the user asks "summarize what we found", **Then** the researcher generates a summary of all findings from the current session

---

### User Story 4 - Research Report Generation (Priority: P3)

The researcher can compile findings into a structured report. The report includes: an executive summary, key findings with sources, related entities from the user's knowledge base, and suggestions for further reading. Reports can be saved, exported (markdown, PDF), and shared.

**Why this priority**: Research reports transform scattered findings into actionable documents. Users don't need to manually copy-paste from multiple tabs.

**Independent Test**: After a research session on "TypeScript performance tips", request a report. Verify the report includes: "Executive Summary" (2-3 paragraph AI-written summary), "Key Findings" (5 findings with sources), "Related from Your Knowledge Base" (3 past events mentioning TypeScript), "Further Reading" (3 suggested topics).

**Acceptance Scenarios**:

1. **Given** a research session with 10+ interactions, **When** the user clicks "Generate Report", **Then** a structured report is generated within 30 seconds with all required sections
2. **Given** a generated report, **When** the user clicks "Export as Markdown", **Then** the report is saved as a markdown file with proper formatting and frontmatter

---

### User Story 5 - Scheduled Research (Priority: P3)

Users can schedule research queries to run periodically: "Research AI news every Monday morning." The researcher runs the query, compares results to the previous run, highlights what's new, and delivers a briefing. Scheduled research appears as a recurring task in the agent panel.

**Why this priority**: Keeping up with fast-moving topics (AI, frameworks, security) is labor-intensive. Scheduled research automates this.

**Independent Test**: Schedule a research task: "Research 'React 19 updates' every Friday at 9 AM." After the first run, verify the results appear as a briefing in the dashboard. After the second run, verify it highlights "new since last check."

**Acceptance Scenarios**:

1. **Given** a scheduled research task, **When** the scheduled time arrives, **Then** the researcher runs the query and stores the results with a timestamp
2. **Given** a scheduled task that has run before, **When** it runs again, **Then** results include a "What's New" section comparing with the previous run's results

---

### Edge Cases

- What happens when web search API is unavailable or rate-limited?
- How are very broad queries handled (e.g., "research everything")?
- What happens when no context is available to augment the query?
- How are paywalled or inaccessible sources handled?
- What happens when the research session exceeds token limits?
- How is source credibility assessed and indicated?
- What happens when the user's knowledge base has no relevant events?

## Requirements

### Functional Requirements

- **FR-001**: Researcher agent MUST accept a natural-language research query
- **FR-002**: Researcher MUST automatically augment queries with user context: current project, recent events, open files, top entities
- **FR-003**: Users MUST be able to view and edit the augmented query before execution
- **FR-004**: Researcher MUST search across multiple sources: web, documentation, GitHub, Stack Overflow, local knowledge base
- **FR-005**: Results MUST be grouped by source with up to 3 results per group by default
- **FR-006**: Duplicate results across sources MUST be deduplicated
- **FR-007**: Researcher MUST maintain session context across follow-up questions
- **FR-008**: Follow-up questions MUST be interpreted in the context of the research session (anaphora resolution, topic continuity)
- **FR-009**: Researcher MUST generate structured reports: executive summary, key findings, related knowledge base entities, further reading
- **FR-010**: Reports MUST be exportable as Markdown and PDF
- **FR-011**: Reports MUST be savable to the knowledge base
- **FR-012**: Researcher MUST support scheduled recurring research queries
- **FR-013**: Scheduled research MUST detect and highlight new results since the previous run
- **FR-014**: Scheduled research tasks MUST appear in the agent panel
- **FR-015**: Researcher MUST be available as an MCP tool via the MCP server
- **FR-016**: Researcher MUST show progress/status during long-running queries
- **FR-017**: Researcher MUST respect rate limits for external APIs

### Key Entities

- **ResearchSession**: A research conversation. Attributes: id, query (original), augmentedQuery, context (snapshot of user context at start), messages (array of {role, content, results}), createdAt, updatedAt, status.
- **ResearchResult**: A single research finding. Attributes: id, sessionId, source (web/github/stackoverflow/knowledge-base), url, title, snippet, content (full text), relevanceScore, retrievedAt.
- **ResearchReport**: A compiled report. Attributes: id, sessionId, executiveSummary, keyFindings (array of {finding, source, evidence}), relatedKnowledge (array of {eventId, title, relevance}), furtherReading (array of {topic, reason}), createdAt, format.
- **ScheduledResearch**: A recurring research task. Attributes: id, query, schedule (cron expression), lastRun, nextRun, lastResults, newSinceLastCheck, status (active/paused/completed).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Research query completes in under 15 seconds (for web + knowledge base sources)
- **SC-002**: Context augmentation adds relevant terms in under 2 seconds
- **SC-003**: Follow-up queries are resolved in under 10 seconds
- **SC-004**: Report generation completes in under 30 seconds
- **SC-005**: Scheduled research runs within 1 minute of scheduled time
- **SC-006**: User finds research results "relevant" in 80%+ of queries (measured by feedback)

## Assumptions

- Built as an OSAI agent running in the background process
- Uses a web search API (configurable: Google, Bing, Brave, or self-hosted SearXNG)
- Uses GitHub API for repository/code search
- Uses Stack Exchange API for Stack Overflow search
- Knowledge base search uses the existing storage/search layer
- Context augmentation uses the current session/project/entity data from the knowledge engine
- Research sessions are persisted for up to 30 days, then auto-archived
- Reports use an LLM for narrative generation (local or cloud)
- Scheduled research uses the agent scheduling system (spec 031)
- Rate limiting uses a token bucket algorithm per source
- Source code lives at `agents/researcher/` in the monorepo