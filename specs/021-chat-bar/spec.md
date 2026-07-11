# Feature Specification: Chat Bar

**Feature Branch**: `021-chat-bar`

**Created**: 2026-07-11

**Status**: Draft

**Input**: Conversational interface for querying memory, executing actions, and interacting with background agents. Replaces the command bar (search + actions) with a multi-turn chat that slides up from the bottom of the app. Search and actions become capabilities of the chat, not separate modes.

---

## User Scenarios & Testing

### User Story 1 - Ask Anything (Priority: P1)

The user presses Ctrl+K / Cmd+K anywhere in the app. A chat bar slides up from the bottom with an input field. The user types "What was I reading about CRDTs last week?" and presses Enter. The background agent host (spec 064) searches the knowledge graph, finds the matching events, and streams a response token-by-token: "You read 3 articles about CRDTs last Tuesday: 'CRDTs for Mortals', 'A CRDT Primer', and 'Conflict Resolution in Collaborative Apps'. Want me to summarize one?"

**Why this priority**: A single natural language interface replaces the need to learn which view to open, which filter to apply, or how to search. It's the primary interaction mode.

**Independent Test**: Open chat bar, type "show me what I did yesterday", verify the response includes session groupings, top entities, and a summary with streaming text appearing progressively.

**Acceptance Scenarios**:

1. **Given** the chat bar is open, **When** the user types "find the article about MCP protocol" and presses Enter, **Then** the chat dispatches to the agent host (spec 064), searches the knowledge graph, and returns matching events with titles, links, and a brief description
2. **Given** the chat bar is open, **When** the user types "summarize my week", **Then** the agent host aggregates sessions from the past 7 days and returns a structured summary with bullet points

---

### User Story 2 - Multi-Turn Conversation (Priority: P1)

After asking "What was I doing yesterday?", the user follows up with "Show me the code files I edited" without repeating context. The chat maintains conversation history and the follow-up is understood in context. The response shows the specific files changed.

**Why this priority**: Multi-turn conversations feel natural and productive. The user should never have to repeat context.

**Independent Test**: Ask "What was I working on this morning?", then ask "What files did I change?" and verify the response narrows to files from the morning session without needing to re-specify the time.

**Acceptance Scenarios**:

1. **Given** an active conversation about "yesterday's activity", **When** the user asks "what files did I change?", **Then** the response narrows to file events from yesterday without re-specifying the time
2. **Given** a conversation about "React state management", **When** the user asks "save this page to that topic" while on a relevant browser tab, **Then** the chat bar dispatches a "Save to KB" request with context from the active window

---

### User Story 3 - Actions and Commands (Priority: P2)

The user types "> timeline" or just "go to timeline". The chat bar recognizes this as a navigation intent and navigates to the History view. The chat bar understands: "pause capture", "show my goals", "start a note about home renovation", "save this to the MCP topic". Actions are a subset of what the chat understands, not a separate mode.

**Why this priority**: The `>` prefix is a power-user shortcut for known actions, but the chat should also infer intent from natural language.

**Independent Test**: Type "go to projects" — verify it navigates to Topics view. Type "pause" — verify capture pauses. Type "show my goals" — verify the goal list appears in the response. All without `>` prefix.

**Acceptance Scenarios**:

1. **Given** the chat bar is open, **When** the user types "go to timeline", **Then** the app navigates to the History view
2. **Given** the chat bar is open, **When** the user types "pause capture", **Then** capture pauses and a confirmation message appears in the chat
3. **Given** the chat bar is open, **When** the user types "save this page to the MCP topic", **Then** a "Save to KB" request is dispatched with the active browser URL as context

---

### User Story 4 - Search (Priority: P2)

The user types a plain keyword like "kubernetes". The chat bar returns search results (entities, events, files) inline in the chat, grouped by type with previews. Results are the same as the old command bar search, but rendered as a chat message.

**Why this priority**: Quick lookup without forming a full question is still valuable. Search becomes a chat response type rather than a separate UI.

**Independent Test**: Type "kubernetes". Verify the chat responds with an inline card showing matching entities, recent events, and files, grouped by type.

**Acceptance Scenarios**:

1. **Given** the chat bar is open, **When** the user types a single keyword like "react", **Then** the chat returns search results grouped by type (Entities, Events, Sessions, Files) with previews
2. **Given** the chat bar is open, **When** the user types a keyword that matches nothing, **Then** the chat responds with "No results found" and suggests trying different terms

---

### User Story 5 - Proactive Suggestions (Priority: P2)

When the chat bar is closed, the background agent host (spec 064) may push suggestion chips that appear above the chat bar trigger area. These are subtle, non-intrusive hints: "You were reading about auth patterns — want a refresher?" Clicking a chip opens the chat bar with the query pre-filled.

**Why this priority**: Proactive suggestions are the bridge between background memory processing and the user. They make the system feel intelligent without being intrusive.

**Independent Test**: Work on authentication topics for 30 minutes. After 5 min of idle, verify a suggestion chip appears above the chat bar: "You spent 30 min on auth — want me to find that article about JWT vs sessions?"

**Acceptance Scenarios**:

1. **Given** the user has been working on a topic for 30+ minutes, **When** they become idle, **Then** a suggestion chip appears near the chat bar with relevant context
2. **Given** a goal nudge is due, **When** the user is idle, **Then** a suggestion chip shows: "Goal: Read 30 min — 0/30 today. Start?"

---

### Edge Cases

- What happens when the agent host is not running (starting up or crashed)?
- How are very long conversations handled — context window limits?
- What happens when the user sends a message while a response is still streaming?
- How is sensitive content handled in chat responses?
- What happens when the LLM provider returns an error?
- How are multiple rapid requests handled (rate limiting)?
- What happens when the user closes the chat bar mid-stream?

---

## Requirements

### Functional Requirements

- **FR-001**: Chat bar MUST open with Ctrl+K / Cmd+K global keyboard shortcut from anywhere in the app
- **FR-002**: Chat bar MUST slide up from the bottom of the app window as an overlay panel (not a modal) — 60px input bar when closed, expands to 400px max height when open
- **FR-003**: Chat bar input MUST start empty on each open. User can continue the previous conversation or start a new one
- **FR-004**: On sending a message, the chat bar MUST dispatch it to the agent host (spec 064) via IPC and stream the response token-by-token
- **FR-005**: Streaming responses MUST render progressively — each token appears as it arrives, with markdown formatting (headings, lists, code blocks, links, images) rendered live
- **FR-006**: Chat bar MUST maintain conversation history for multi-turn context — the agent host sends the full conversation history with each request
- **FR-007**: Each conversation session MUST be auto-saved with a timestamp and first-message preview. Saved to SQLite `chat_history` table.
- **FR-008**: Chat bar MUST support intent inference — plain text ("go to projects", "pause capture") is recognized without `>` prefix
- **FR-009**: `>` prefix MUST still work as a power-user shortcut for explicit actions, bypassing natural language parsing
- **FR-010**: Chat bar MUST support plain keyword search — if the input looks like a keyword query (single word or short phrase), return search results grouped by type: Entities, Events, Sessions, Files
- **FR-011**: Search results MUST render as an inline card in the chat with up to 3 items per group and a "Show all N results" link
- **FR-012**: Chat bar MUST show suggestion chips above the input area when the agent host pushes them — chips are tappable and pre-fill the chat input
- **FR-013**: Suggestion chips MUST have a title, one-tap action, and a dismiss button. They auto-expire after their TTL (30-60 min) or when dismissed
- **FR-014**: Chat bar MUST support aborting an in-progress response (stop button or Escape during streaming)
- **FR-015**: Chat bar MUST show a typing indicator while waiting for the first token from the agent host
- **FR-016**: Chat bar MUST render inline rich content: code blocks with syntax highlighting, images, links, file previews, event cards
- **FR-017**: Chat bar MUST support copy individual messages (both sent and received)
- **FR-018**: Chat bar MUST handle errors gracefully — if the agent host is down, show "Memory assistant is starting up — try again in a moment"
- **FR-019**: Chat bar MUST use the design system (spec 059) — color tokens, typography, spacing, animations

### Key Entities

- **ChatMessage**: A single message in a conversation. Attributes: id, role (user/assistant/system), content (markdown), timestamp, tokens (estimated), sourceEvents (array of event IDs referenced).
- **ChatConversation**: A multi-turn conversation session. Attributes: id, title (auto-generated from first exchange), messages, createdAt, updatedAt, agentContext (snapshot of active context at conversation start).
- **SuggestionChip**: A proactive suggestion shown above the chat input. Attributes: id, title, body, action (label + command to pre-fill), priority, expiresAt, dismissed.
- **SearchResult**: A group of search results for a keyword query. Attributes: query, groups (Entities/Events/Sessions/Files), each with items (preview, id, link) and totalCount.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Chat bar opens in under 50ms after keyboard shortcut
- **SC-002**: First token of streaming response appears within 2 seconds of sending
- **SC-003**: Full response for a typical query (summarize my day) completes within 10 seconds
- **SC-004**: Search results render within 200ms for keyword queries
- **SC-005**: Conversation history loads in under 100ms
- **SC-006**: Chat bar memory usage under 80MB

## Assumptions

- Built as a React overlay component using a portal — renders above all app content
- Chat bar communicates with the agent host (spec 064) via the Rust core IPC bridge — requests go through the named pipe / Unix socket, responses stream back over the same connection
- The agent host manages LLM calls, context building, and knowledge graph searches — the chat bar only renders
- Agents (specs 026-030) are not invoked directly by the chat bar — all dispatching goes through the agent host
- Conversations are automatically saved; the "Ask" screen (spec 022) is where users browse past conversations
- Suggestion chips come from the agent host's proactive suggestion engine (spec 064) — the chat bar just displays them and handles dismiss
- Source code lives at `ui/chat-bar/` in the monorepo
