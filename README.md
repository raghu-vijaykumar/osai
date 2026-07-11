# OSAI — Context Operating System

**The context layer for the AI era.**

OSAI is a user-owned context operating system that continuously captures, organizes, understands, and exposes your digital activity as a persistent knowledge layer for both humans and AI agents.

---

## Core Philosophy

```text
Applications come and go. Your context should persist.
```

Applications are temporary participants in a persistent personal knowledge graph. You own your context — not Chrome, not VSCode, not Claude.

---

## What It Does

- **Captures** activity across applications (browser, IDE, files, media, docs, chat)
- **Organizes** everything into a personal knowledge graph
- **Understands** entities, topics, projects, and relationships automatically
- **Exposes** context via human UI (timeline, projects, graph) and agent APIs (MCP)

---

## Architecture

```text
Applications → Capture Layer → Context Protocol → Knowledge Engine → Knowledge Graph → UI + Agent APIs
```

| Layer | Role |
|-------|------|
| Capture | Connectors for browser, IDE, file system, media, APIs |
| Context Protocol | Open, typed schema for publishing/consuming context events |
| Knowledge Engine | Embeddings, entity extraction, classification, graph building |
| Storage | Postgres + Vector Store + Graph Store + Local Cache |
| MCP Server | Exposes knowledge graph to AI agents via MCP |
| UI | Timeline, Projects, Graph View, Command Bar, Agent Panel |

---

## Getting Started

_Coming soon — Phase 0 (Foundation) is in progress._

---

## Repository Structure

```
apps/            — Desktop, mobile, web, dashboard
protocol/        — Schemas, events, permissions, SDK
ingestion/       — Browser extension, VSCode, file watcher, connectors
knowledge-engine/— Embeddings, entities, graph, recommendations
storage/         — Postgres, vector store, graph store, cache
mcp/             — MCP server, tools, adapters
agents/          — Summarizer, organizer, researcher, planner
ui/              — Timeline, projects, graph view, command bar
permissions/     — Policies, consent, access control
sync/            — Cloud sync, backup, replication
docs/            — Architecture, protocol spec, integrations, roadmap
examples/        — Integration examples for each connector type
```

---

## Roadmap

| Phase | Timeline | Focus |
|-------|----------|-------|
| 0: Foundation | Q1 2026 | Monorepo, protocol schemas, local storage, CLI |
| 1: Capture | Q2 2026 | Browser/VSCode/file watcher connectors |
| 2: Knowledge Engine | Q2 2026 | Embeddings, entities, graph, projects |
| 3: UI | Q3 2026 | Desktop app with timeline, projects, graph |
| 4: AI Agents | Q3 2026 | Background agents, MCP server |
| 5: Sync & Cloud | Q4 2026 | Multi-device sync, encrypted backup |
| 6: Ecosystem | Q4 2026 | SDKs, mobile app, third-party integrations |
| 7: Enterprise | Q1 2027 | Team memory, RBAC, SSO, on-premise |

---

## License

_To be determined._
