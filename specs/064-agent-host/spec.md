# Feature Specification: Background Agent Host

**Feature Branch**: `064-agent-host`

**Created**: 2026-07-11

**Status**: Draft

**Input**: Background Node.js sidecar that runs all agents, consumes the live event stream, builds personal memory, detects patterns, generates proactive suggestions, processes "Save to KB" requests, and pushes results to the UI. This is the intelligence layer behind the proactive UX.

---

## User Scenarios & Testing

### User Story 1 - Background Memory Building (Priority: P1)

After OSAI has been running for a day, events from all connectors flow into the agent host. It processes them continuously: extracts entities, classifies activity, embeds content, builds the knowledge graph, detects sessions and projects. The user doesn't need to do anything — memory builds silently in the background.

**Why this priority**: The entire value proposition depends on automatic memory building. Without it, OSAI is just a log file viewer.

**Independent Test**: Publish 50 varied events (URLs, file edits, app focuses) over 10 minutes. After 10 minutes, verify the knowledge graph contains 5+ entities, sessions are detected, and a topic has formed around repeated activity.

**Acceptance Scenarios**:

1. **Given** events are flowing in from connectors, **When** the agent host processes them, **Then** entities are extracted, events are classified, and the knowledge graph is updated within 30 seconds of each event
2. **Given** 30 minutes of consecutive activity in the same domain (e.g., coding in VSCode), **When** processed, **Then** a session is created and a topic is suggested if 3+ related projects/entities appear

---

### User Story 2 - Proactive Suggestions (Priority: P1)

The user is working on authentication for their app. The agent host, having tracked this across browser tabs (MDN docs), VSCode (auth code), and file watcher (config files), detects the pattern and pushes a suggestion card to Home: "You've been working on auth for 2 hours. Want me to find the article about JWT vs sessions you saved last week?"

**Why this priority**: Proactive suggestions differentiate OSAI from a passive log. They make the system feel intelligent and helpful.

**Independent Test**: Publish events simulating auth research (browse JWT articles, edit auth code files, open auth config). Within 2 minutes, verify a suggestion card appears on Home with relevant context.

**Acceptance Scenarios**:

1. **Given** the user has been editing files and browsing pages all about authentication for 30+ minutes, **When** the agent host detects the pattern, **Then** it generates a suggestion card with related past events or entities
2. **Given** no new events for 5+ minutes (user idle), **When** a goal nudge is due, **Then** the suggestion card shows: "Goal: Read 30 min — 0/30 today. Start?"

---

### User Story 3 - "Save to KB" (Priority: P2)

The user is reading a useful Stack Overflow answer. They click the browser extension's "Save to Knowledge Base" button. The agent host receives the full page content, classifies it (topic: "react state management"), suggests a destination topic, and files it. A toast confirms: "Saved to 'React State Management' topic."

**Why this priority**: Manual save is the bridge between passive capture and intentional knowledge building. It ensures important content is preserved even if the user doesn't browse to it.

**Independent Test**: Click "Save to KB" on a browser page. Within 10 seconds, verify the page appears as a linked event in the most relevant topic, with extracted entities and a content preview.

**Acceptance Scenarios**:

1. **Given** a browser page with content about "CSS Grid", **When** the user clicks "Save to KB", **Then** the agent host classifies it under the topic most related to CSS/layout (or creates a new one), extracts entities, and stores the full content as a note linked to that topic
2. **Given** a "Save to KB" request for content that matches no existing topic, **When** processed, **Then** the agent host creates a new topic based on the dominant entities and suggests a name

---

### User Story 4 - Agentic Action Execution (Priority: P2)

The user types in the chat bar: "What was that article about distributed systems?" The chat bar dispatches this to the agent host, which searches the memory, finds the article, and returns a summary. Behind the scenes, the agent host orchestrates the research agent to query the knowledge graph, the summarizer agent to condense the content, and returns a streaming response.

**Why this priority**: Chat queries are the primary interaction mode. The agent host is the dispatcher that routes queries to the right agent.

**Independent Test**: Ask "Show me what I did yesterday" in the chat bar. Verify the response includes session groupings, top entities, and an AI-generated summary within 5 seconds.

**Acceptance Scenarios**:

1. **Given** the user asks "Find the article about CRDTs", **When** the chat bar dispatches to the agent host, **Then** the agent host queries the knowledge graph, finds the matching event, and returns a summary with a link to the original
2. **Given** the user asks "Summarize my week", **When** dispatched, **Then** the agent host aggregates sessions, entities, and topics from the past 7 days and returns a structured summary

---

### Edge Cases

- What happens when the agent host is overloaded (100+ events/sec flooding)?
- How are suggestion deduplicated — same pattern detected twice in 5 minutes?
- What happens when the LLM provider is unavailable for suggestion generation?
- How are "Save to KB" requests handled when the agent host is starting up?
- What happens when a suggestion is shown but the user ignores it (no feedback)?
- How is topic classification handled for ambiguous content (matches 3 topics equally)?
- What happens when the user manually corrects a topic assignment — does the agent host learn?

---

## Requirements

### Functional Requirements

#### Event Intake Pipeline

- **FR-001**: Agent host MUST subscribe to the event log (via `queryLog` polling or a push subscription) and process events continuously — target latency: < 30s from event append to processing completion
- **FR-002**: Agent host MUST run as a long-lived Node.js sidecar process, started and managed by the Rust core
- **FR-003**: Agent host MUST maintain a checkpoint of its position in the event log so it can resume after crash without reprocessing
- **FR-004**: Agent host MUST process events in order — no out-of-order processing
- **FR-005**: Agent host MUST fan out each event to all relevant subsystems in parallel: entity extraction, classification, embedding, session detection, topic detection, goal matching, suggestion evaluation

#### Proactive Suggestion Engine

- **FR-006**: Agent host MUST evaluate events for suggestion triggers after each processing cycle — not on every single event (to avoid thrashing)
- **FR-007**: Suggestion triggers MUST include:
  - **Topic focus detected** — 30+ min on related events, suggests related past content
  - **Goal nudge due** — a goal has unmet daily target and user is idle
  - **Resumption context** — user returns to a topic they haven't touched in 3+ days, suggests summary of where they left off
  - **Save-to-KB confirmation** — after a save, suggests filing to topic
  - **Weekly/daily digest ready** — periodic summary is available
- **FR-008**: Agent host MUST deduplicate suggestions — same trigger MUST NOT fire more than once per 15 minutes
- **FR-009**: Agent host MUST assign each suggestion a priority (low/medium/high) and a category (insight/nudge/reminder/save_confirmation)
- **FR-010**: Agent host MUST push suggestions to the Rust core IPC endpoint, which forwards them to the UI for rendering on Home and "Now" bar
- **FR-011**: Suggestion card payload:

```json
{
  "id": "sug_001",
  "type": "insight" | "nudge" | "reminder" | "save_confirmation",
  "priority": "low" | "medium" | "high",
  "title": "You were reading about CRDTs last week",
  "body": "Want a quick refresher on conflict-free replicated data types?",
  "actions": [
    { "label": "Show me", "action": "chat", "value": "summarize what I learned about CRDTs" },
    { "label": "Dismiss", "action": "dismiss" }
  ],
  "source_events": ["evt_001", "evt_002"],
  "created_at": "2026-07-11T14:30:00Z",
  "expires_at": "2026-07-11T15:00:00Z"
}
```

- **FR-012**: Suggestions MUST expire after a configurable TTL (default: 30 min for insights, 60 min for nudges)

#### "Save to KB" Processing

- **FR-013**: Agent host MUST expose an IPC endpoint `save-to-kb` that accepts:

```json
{
  "source": "browser-extension" | "vscode" | "chat-bar" | "screenshot" | "file-drop",
  "content": { "url"?, "title"?, "text"?, "file_path"?, "image_data"? },
  "context": { "active_app"?, "active_file"?, "active_url"? }
}
```

- **FR-014**: On receiving a save request, the agent host MUST:
  1. Extract text content (for images: OCR via Tesseract.js if enabled)
  2. Run entity extraction and classification
  3. Match against existing topics — if confidence > 0.6 for any topic, use it; otherwise suggest a new topic name
  4. Store as a `note.created` event linked to the selected topic
  5. Push a `save_confirmation` suggestion card to the UI with the topic name and an "undo" action (30 second undo window)
- **FR-015**: If content matches multiple topics with similar confidence, the agent host MUST defer to the user — push a suggestion card listing the top 3 topic candidates and let the user pick
- **FR-016**: Agent host MUST support save from: browser extension popup, VSCode context menu, OS share target (file/image drag-drop into the tray or OSAI window), and chat bar command (`save this to [topic]`)

#### Chat Query Dispatch

- **FR-017**: Agent host MUST expose an IPC endpoint `chat` that accepts:

```json
{
  "conversation_id": "conv_001",
  "message": "What was that article about distributed systems?",
  "context": { "active_app"?, "active_file"?, "active_session"? }
}
```

- **FR-018**: On receiving a chat query, the agent host MUST:
  1. Parse the intent (search / summarize / act / save / create)
  2. Search the knowledge graph for relevant events and entities
  3. Build a context prompt from the query + search results + active context
  4. Route to the appropriate agent (research/summarizer/planner) via the LLM provider (spec 062)
  5. Stream the response back to the UI
- **FR-019**: Chat responses MUST be streamed token-by-token via the IPC connection (using SSE-style framing in NDJSON)
- **FR-020**: Each chat session (conversation_id) MUST maintain a message history for multi-turn context — stored in SQLite `chat_history` table

### Key Entities

- **Suggestion**: A proactive card shown to the user. Attributes: id, type, priority, title, body, actions (array), sourceEvents (array of event IDs), createdAt, expiresAt, dismissedAt (nullable).
- **SaveRequest**: A "Save to KB" request. Attributes: id, source, content (JSON), context (JSON), status (pending/processing/completed/failed), topicAssigned, confidence, createdAt.
- **ChatSession**: A multi-turn conversation. Attributes: id, title, messages (array of Message), createdAt, updatedAt, context (the last-known active context).
- **GoalMatch**: A detected match between a goal and an event. Attributes: goalId, eventId, contribution (e.g., 30 min toward reading goal), matchedAt.
- **SuggestionTrigger**: A detected pattern that generates a suggestion. Types: `topic_focus`, `goal_nudge`, `resumption_context`, `save_confirmation`, `digest_ready`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Event intake latency: < 30 seconds from append to processing complete (for 95th percentile)
- **SC-002**: Suggestion generation: within 60 seconds of trigger conditions being met
- **SC-003**: Save-to-KB processing: < 10 seconds from request to confirmation (text), < 30 seconds (image with OCR)
- **SC-004**: Chat query response: first token within 2 seconds, full response within 15 seconds (for 95th percentile)
- **SC-005**: Suggestion deduplication: zero duplicate suggestions shown to the user in any 15-minute window
- **SC-006**: Agent host uptime: 99.5% (crash restarts in < 5 seconds)

## Assumptions

- Agent host is a Node.js sidecar process managed by the Rust core — if it crashes, the core restarts it automatically
- All agents (summarizer, researcher, planner, organizer) run as modules within the agent host, not as separate processes
- The agent host connects to the Rust core via `@osai/protocol` SDK over named pipe / Unix socket
- Suggestion cards are ephemeral — stored in memory + the current Home session. They are NOT persisted in SQLite (but their creation is logged as events)
- The suggestion engine is rules-based for v1 (no ML classification of when to suggest) — triggers are time + activity pattern heuristics
- LLM calls for suggestion generation and chat responses go through the centralized provider layer (spec 062)
- "Save to KB" from screenshots/images uses OCR (Tesseract.js) as an optional step — if disabled, only filenames and metadata are saved
- Source code lives at `services/agent-host/` in the monorepo
