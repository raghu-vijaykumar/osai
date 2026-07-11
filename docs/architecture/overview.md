# KB OS — System Architecture

## Overview

KB OS is a **context operating system** that sits between applications, users, and AI agents. It continuously captures digital activity, organizes it into a persistent knowledge graph, and exposes it through both human interfaces and agent APIs.

---

## Architectural Layers

```text
┌──────────────────────────────────────────────────────────┐
│                     Applications                          │
│  Browser  │  IDE  │  Media  │  Docs  │  Chat  │  ...     │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                     Capture Layer                         │
│  Browser Ext  │  VSCode Ext  │  File Watchers  │  APIs   │
│  Activity Monitor  │  Media Connectors  │  PDF Import    │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                    Context Protocol                       │
│  Event Schemas  │  Publish API  │  Consume API           │
│  Permissions  │  Auth  │  Rate Limits                   │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                    Knowledge Engine                       │
│  Embeddings  │  Entity Extraction  │  Classification     │
│  Graph Builder  │  Project Detection  │  Recommendations │
└──────┬───────────────────────────────────┬───────────────┘
       │                                   │
       ▼                                   ▼
┌──────────────────┐          ┌───────────────────────────┐
│   Storage Layer   │          │      MCP Server           │
│  Postgres (rels)  │          │  Tools  │  Resources      │
│  Vector Store     │          │  Prompts  │  Transports   │
│  Graph Store      │          └───────────┬───────────────┘
│  Local Cache      │                      │
└──────────────────┘                      ▼
                                  ┌──────────────────┐
                                  │   AI Agents       │
                                  │  ───────────────  │
                                  │  Summarizer       │
                                  │  Organizer        │
                                  │  Researcher       │
                                  │  Planner          │
                                  │  Recommender      │
                                  └──────────────────┘
```

---

## Layer Descriptions

### 1. Capture Layer

Responsible for ingesting events from all user-facing applications. Each integration is a lightweight connector that publishes events via the Context Protocol.

| Connector | Source | Events |
|-----------|--------|--------|
| Browser Extension | Chrome, Firefox, Edge | URL visited, page content, downloads |
| VSCode Extension | VS Code, Cursor | File opened, code written, git commits |
| File Watcher | Filesystem | File created, modified, deleted |
| Activity Monitor | OS-level | Window focus, app usage, idle time |
| Media Connectors | Media players | Video watched, audio played, bookmarks |
| PDF Connectors | PDF viewers | Document opened, pages read, annotations |
| API Connectors | External services | Slack, Notion, GitHub, Linear, etc. |

### 2. Context Protocol

A typed, versioned protocol for publishing and consuming context events.

**Key components:**

- **Event Schemas** — TypeScript/JSON Schema definitions for every event type
- **Publish API** — Submit events from application connectors
- **Consume API** — Query context for agents and UI
- **Permissions** — Per-source, per-event-type access controls
- **Authentication** — Local-first; cloud token for sync

**Event envelope:**

```typescript
interface ContextEvent {
  id: string
  source: string        // e.g., "browser-extension", "vscode-extension"
  type: string           // e.g., "url.visited", "file.modified"
  timestamp: number
  payload: Record<string, unknown>
  project?: string       // inferred or explicit project association
  session?: string       // session grouping for context continuity
}
```

### 3. Knowledge Engine

The brain of the system. Transforms raw events into structured, queryable knowledge.

| Component | Responsibility |
|-----------|----------------|
| Embeddings | Generate vector embeddings for text content (pages, code, docs) |
| Entity Extraction | Identify people, places, topics, technologies, projects |
| Classification | Categorize events into types (learning, building, researching, etc.) |
| Graph Builder | Build and maintain the personal knowledge graph |
| Project Detection | Auto-detect project boundaries from event clusters |
| Recommendations | Suggest related content, next actions, relevant context |

### 4. Storage Layer

| Store | Purpose |
|-------|---------|
| Postgres | Events, relationships, projects, user settings |
| Vector Store | Semantic search over content (pgvector, Qdrant, or LanceDB) |
| Graph Store | Knowledge graph (DGraph, Neo4j, or in-memory with Postgres) |
| Local Cache | SQLite + duckdb for offline-first local operation |

### 5. MCP Server

Exposes the knowledge graph as MCP tools and resources so any MCP-compatible AI agent can consume context.

**MCP Tools:**

- `search_context(query)` — Semantic search over all user context
- `get_project(project_id)` — Get project details and related events
- `get_timeline(start, end, sources)` — Query timeline events
- `get_recommendations(context)` — Get content/action recommendations
- `query_graph(query)` — Structured graph queries

**MCP Resources:**

- `context://current/project` — Current active project
- `context://user/preferences` — User preferences and patterns
- `context://recent/activity` — Recent activity across all sources
- `context://session/current` — Current session context

### 6. UI Layer

Native applications that present context to the user. Built with Tauri (Rust backend + React webview).

| App | Description |
|-----|-------------|
| Timeline | Chronological view of all activity across applications |
| Projects | Project-centric organization of files, conversations, notes |
| Graph View | Interactive visualization of the personal knowledge graph |
| Command Bar | Universal search and command palette (Ctrl+K style) |
| Agent Panel | Dashboard for background agents, tasks, and automations |
| Context Sidebar | Embeddable sidebar showing relevant context for the current task |

### 7. Sync Layer

| Component | Description |
|-----------|-------------|
| Cloud Sync | Encrypted sync between devices |
| Backup | Periodic versioned backups of the knowledge graph |
| Replication | Multi-device replication with conflict resolution |

---

## Data Flow

### Event ingestion flow:

```text
Application Event
    → Capture Connector
    → Context Protocol (validated, authenticated)
    → Event Bus
    → Knowledge Engine (async processing)
        → Embeddings generated
        → Entities extracted
        → Graph updated
        → Project association
    → Storage (events + graph + vectors persisted)
    → UI updated (real-time via subscriptions)
```

### Query flow:

```text
User Query / Agent Request
    → Context Protocol (Consume API)
    → Knowledge Engine
        → Intent classification
        → Multi-store query (vector + graph + relational)
        → Result ranking
    → Formatted response
    → UI / Agent
```

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Local-first | Yes | User owns data; cloud is optional sync |
| Event sourcing | Core pattern | Full history enables replay, debugging, audit |
| Graph as source of truth | Knowledge graph | Relationships are as important as entities |
| Pluggable storage | Abstraction layer | Avoid vendor lock-in; optimize per use case |
| Protocol-first | Schemas before code | Encourage ecosystem adoption |
| MCP-native | Built-in MCP server | AI agents are first-class consumers |

---

## Security & Privacy

- All data encrypted at rest and in transit
- Local processing by default; cloud only with explicit consent
- Per-connector permission grants (revocable)
- No data leaves the device without user approval
- Export and delete API for full data portability
