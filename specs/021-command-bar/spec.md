# Feature Specification: Command Bar

**Feature Branch**: `021-command-bar`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a universal command bar for querying personal knowledge, searching, and executing actions"

## User Scenarios & Testing

### User Story 1 - Universal Search (Priority: P1)

The command bar opens with Ctrl+K (or Cmd+K) and provides a search-as-you-type experience across all OSAI data: events, entities, projects, sessions, and files. Results are grouped by type with icons and previews.

**Why this priority**: The command bar is the primary interface for quickly finding anything. It's the Ctrl+K / Cmd+P pattern users already know from VSCode, Slack, and GitHub.

**Independent Test**: Open the command bar, type "Kubernetes", and verify results show: matching entities (Kubernetes node), events (pages about Kubernetes), sessions (learning Kubernetes sessions), and projects (Kubernetes research project).

**Acceptance Scenarios**:

1. **Given** the command bar is open, **When** the user types "React", **Then** results appear within 100ms grouped by type: Entities (React, React Native), Events (3 recent events mentioning React), Projects (Project: Frontend), Sessions (2 sessions)
2. **Given** no results match the query, **When** the user types "zzznotfound", **Then** the command bar shows "No results found" with a suggestion to try different terms

---

### User Story 2 - Quick Actions (Priority: P1)

The command bar supports actions prefixed with `>` or typed directly. Actions include: navigating to views (`> timeline`, `> projects`, `> graph`), running commands (`> pause capture`, `> export data`), and creating items (`> new note`, `> new project`).

**Why this priority**: Actions transform the command bar from a search tool into the primary navigation and command interface for the entire application.

**Independent Test**: Type "> timeline" in the command bar, press Enter, and verify the view navigates to the Timeline page. Type "> pause", press Enter, and verify capture is paused with a confirmation toast.

**Acceptance Scenarios**:

1. **Given** the command bar is open, **When** the user types "> projects" and presses Enter, **Then** the app navigates to the Projects view and the command bar closes
2. **Given** the command bar is open, **When** the user types "> pause capture", **Then** a confirmation is shown, capture is paused, and a toast "Capture paused" appears

---

### User Story 3 - Semantic Query with Natural Language (Priority: P2)

The command bar supports natural language queries. "What was I reading about Kubernetes last week?" returns relevant events, sessions, and entities. Queries are routed to the recommendation engine for semantic understanding.

**Why this priority**: Natural language queries are more powerful than keyword search. They let users ask questions in their own words.

**Independent Test**: Type "show me what I learned about TypeScript" and verify results include TypeScript-related sessions, pages, and code files with a brief AI-generated summary.

**Acceptance Scenarios**:

1. **Given** the command bar is open, **When** the user types "what was I working on yesterday", **Then** the command bar shows yesterday's top sessions with a summary of activity
2. **Given** the command bar is open, **When** the user types "find the PDF about MCP protocol", **Then** results prioritize PDF documents matching the query

---

### User Story 4 - Keyboard Navigation and History (Priority: P2)

Commands support full keyboard navigation: arrow keys to select, Enter to execute, Escape to close. The command bar remembers recent searches and frequently used actions, showing them when opened with an empty query.

**Why this priority**: Power users rely on keyboard-only navigation. History reduces friction for repeated searches.

**Acceptance Scenarios**:

1. **Given** the command bar is open with results, **When** pressing ArrowDown, **Then** the next result is highlighted; pressing Enter executes the highlighted result
2. **Given** the command bar was used 5 times previously, **When** opening with empty query, **Then** the 5 most recent searches are shown as "Recent" with a clock icon

---

### User Story 5 - Extensible Actions (Priority: P3)

The command bar supports user-configurable actions and plugins. Connectors and agents can register their own commands (e.g., "Summarize today's activity", "Generate weekly report"). Actions have descriptions and optional arguments.

**Why this priority**: The command bar should not be hardcoded. As the ecosystem grows, new capabilities should register themselves as commands.

**Independent Test**: Install a "summarizer" agent that registers a "> summarize today" command. Verify the command appears in the command bar with description and executes correctly.

**Acceptance Scenarios**:

1. **Given** a registered action from an agent, **When** the user types "> summarize", **Then** the action appears in results with the agent's description and icon
2. **Given** an action with arguments ("> search web for [query]"), **When** the user selects it, **Then** the command bar shows an argument input field with placeholder text

---

### Edge Cases

- What happens when the command bar is opened while a modal is already open?
- How are very long result lists handled — pagination or "show all" link?
- What happens when the user types extremely fast (debounced input)?
- How are keyboard shortcuts that conflict with the browser/OS handled?
- What happens when offline — are actions that require network disabled?
- How is sensitive content handled in command bar previews?

## Requirements

### Functional Requirements

- **FR-001**: Command bar MUST open with Ctrl+K / Cmd+K global keyboard shortcut
- **FR-002**: Command bar MUST support search-as-you-type with results appearing within 100ms of the last keystroke
- **FR-003**: Search results MUST be grouped by type: Entities, Events, Sessions, Projects, Files, Actions
- **FR-004**: Each result group MUST show up to 3 items with a "Show all N results" link
- **FR-005**: Command bar MUST support actions with `>` prefix — type `>action` to see available commands
- **FR-006**: Built-in actions MUST include: navigate to views, pause/resume capture, export data, open settings, show shortcuts
- **FR-007**: Command bar MUST support natural language queries — route to the recommendation engine for semantic understanding
- **FR-008**: Natural language results MUST show a brief AI-generated summary where applicable
- **FR-009**: Command bar MUST support full keyboard navigation: ArrowUp/Down (select), Enter (execute), Escape (close), Tab (cycle result groups)
- **FR-010**: Command bar MUST show recent searches when opened with an empty query (up to 10)
- **FR-011**: Command bar MUST support extensible actions — agents and connectors can register commands via a plugin API
- **FR-012**: Command bar MUST have an input debounce of 150ms to avoid excessive queries
- **FR-013**: Command bar MUST show loading state while results are being fetched
- **FR-014**: Command bar MUST use the design system theme (spec 059) — dark, light, and high-contrast modes are inherited from the theme provider

### Key Entities

- **CommandBarInput**: The search input field. Attributes: value, placeholder (context-dependent), debounce timer, recent searches list.
- **ResultGroup**: A group of search results by type (Entities, Events, Sessions, etc.). Attributes: type, icon, items, totalCount, showAllLink.
- **ActionResult**: A registered action. Attributes: id, name, description, icon, handler (function), source (core/agent/connector), arguments (optional schema).
- **RecentSearch**: A persisted search entry. Attributes: query, type (search/action), timestamp, resultCount.
- **SearchProvider**: A backend that provides results. Types: entity search, event search, session search, project search, action registry, recommendation engine.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Command bar opens in under 50ms after keyboard shortcut
- **SC-002**: Search results render within 100ms of last keystroke (for < 10,000 events)
- **SC-003**: Keyboard navigation responds instantly (< 16ms per keypress)
- **SC-004**: Action execution completes in under 200ms
- **SC-005**: Natural language query returns results in under 500ms
- **SC-006**: Command bar consumes under 50MB memory

## Assumptions

- Built as a React portal/overlay component (renders above all other content)
- Uses `fuse.js` for client-side fuzzy search on cached indices
- Natural language queries go to the recommendation engine (spec 017)
- Recent searches stored in localStorage (up to 50 entries)
- Dark/light/high-contrast themes are inherited from the design system (spec 059) — color tokens, typography, spacing, and component styles are provided by the system
- Command bar shortcut: Ctrl+K on Windows/Linux, Cmd+K on macOS
- Plugin actions registered via a `commands.registerAction()` API at runtime
- Source code lives at `ui/command-bar/` in the monorepo
