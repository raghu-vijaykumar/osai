# Feature Specification: Ask

**Feature Branch**: `022-ask-screen`

**Created**: 2026-07-11

**Status**: Draft

**Input**: Conversation history archive for the Chat Bar (spec 021). Users browse, search, rename, and resume past chat sessions with the background agent host (spec 064). The actual chat interaction happens in the Chat Bar — this is the history viewer and session manager.

---

## User Scenarios & Testing

### User Story 1 - Browse Past Conversations (Priority: P1)

The user opens the Ask screen (nav sidebar > Ask). They see a list of past chat sessions, each showing: first message preview, timestamp, and a badge indicating whether it was a search, summary, or action. Clicking a conversation opens it in the Chat Bar, restoring the full message history for continued conversation.

**Why this priority**: Conversations are the primary way users interact with their memory. Being able to revisit and continue them is essential.

**Independent Test**: Have 5 chat sessions over a day. Open Ask. Verify all 5 appear in the list with correct first-message previews, timestamps, and type badges. Click one and verify the Chat Bar opens with the full conversation restored.

**Acceptance Scenarios**:

1. **Given** 5 past chat sessions, **When** the user opens Ask, **Then** all 5 are listed sorted by most recent, each showing first-message preview (truncated to 80 chars), relative timestamp, and a type badge (search/summary/action/chat)
2. **Given** a conversation in the list, **When** the user clicks it, **Then** the Chat Bar opens with the full conversation history restored for continued chatting

---

### User Story 2 - Search Conversations (Priority: P2)

The user types in the search bar at the top of the Ask screen. Results filter as they type, matching against message content and conversation titles.

**Why this priority**: With many conversations, finding a specific one requires search. This mirrors the pattern from messaging apps.

**Independent Test**: Have conversations about "CRDTs", "React", and "capture controls". Type "capture" in the search bar. Verify only the capture-controls conversation appears.

**Acceptance Scenarios**:

1. **Given** multiple conversations, **When** the user types in the search bar, **Then** the list filters in real-time to show only matching conversations
2. **Given** no conversations match the search, **When** the user types, **Then** "No conversations found" is shown with a suggestion to start a new one in the Chat Bar

---

### User Story 3 - Manage Conversations (Priority: P3)

The user renames, deletes, or exports a conversation. Right-click (or "..." menu) on a conversation shows: Rename, Delete, Export as Markdown.

**Why this priority**: Basic conversation management gives users control over their history. Export as markdown enables sharing and external use.

**Acceptance Scenarios**:

1. **Given** a conversation, **When** the user clicks "Rename", **Then** the title becomes editable inline; pressing Enter saves the new name
2. **Given** a conversation, **When** the user clicks "Delete", **Then** a confirmation dialog appears; confirming removes it from history permanently
3. **Given** a conversation, **When** the user clicks "Export as Markdown", **Then** a markdown file with the full conversation is downloaded

---

### Edge Cases

- What happens when a conversation is deleted but the Chat Bar is currently viewing it?
- How many conversations are stored — is there a limit?
- What happens when the agent host is down — can the user still browse past conversations?
- How is sensitive content handled in conversation previews on the list?

---

## Requirements

### Functional Requirements

- **FR-001**: Ask screen MUST display a list of all past chat conversations, sorted by most recent first
- **FR-002**: Each conversation in the list MUST show: first message preview (truncated to 80 chars), relative timestamp ("2h ago", "Yesterday", "Jan 5"), type badge (search/summary/action/chat), and message count
- **FR-003**: Clicking a conversation MUST open the Chat Bar with the full message history restored — the user can continue chatting from where they left off
- **FR-004**: Ask screen MUST have a search bar that filters conversations in real-time by matching against message content and conversation title
- **FR-005**: Each conversation MUST support: rename (inline edit), delete (with confirmation), export as markdown
- **FR-006**: Conversation titles MUST be auto-generated from the first user message — truncated to 60 chars
- **FR-007**: Conversations MUST be stored in SQLite `chat_history` table and persist across app restarts
- **FR-008**: There MUST be no hard limit on stored conversations — UI paginates at 50 per page with "Load more"
- **FR-009**: Ask screen MUST show a loading skeleton while conversation history is being fetched
- **FR-010**: Ask screen MUST show an empty state for first-time users: "No conversations yet — start by pressing Ctrl+K and asking something!"
- **FR-011**: Ask screen MUST use the design system (spec 059) — theme, typography, spacing, components

### Key Entities

- **Conversation**: A chat session. Attributes: id, title (auto-generated or user-renamed), messageCount, createdAt, updatedAt, type (search/summary/action/chat — auto-detected).
- **ConversationListItem**: Display entry in the list. Attributes: title, firstMessagePreview, timestamp, type, messageCount.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Conversation list loads in under 200ms for up to 100 conversations
- **SC-002**: Search filters render results in under 100ms of last keystroke
- **SC-003**: Clicking a conversation opens the Chat Bar with full history in under 300ms
- **SC-004**: Rename saves in under 100ms
- **SC-005**: Delete removes the conversation and updates the list in under 200ms

## Assumptions

- Built as a full page component (not a sidebar) accessible from the main navigation sidebar
- Conversations are stored in SQLite via the storage layer — the `chat_history` table
- The Chat Bar (spec 021) and Ask screen share the same conversation data source
- Type badge is auto-detected: "search" if all messages are keyword queries with results, "summary" if the first response contains a summary, "action" if the first user message matches an action intent, "chat" otherwise
- Source code lives at `ui/ask/` in the monorepo (renamed from `022-agent-panel`)
