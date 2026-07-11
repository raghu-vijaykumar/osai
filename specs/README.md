# Spec Index

64 specs organized by feature area. Specs in **bold** are in MVP 1.0 scope.

---

## Foundation
Core infrastructure everything depends on.

| # | Spec | Why |
|---|------|-----|
| **003** | **Monorepo Setup** | Build system, CI, package scaffolding |
| **059** | **Design System** | Color tokens, typography, 22 shared components, theming |
| 060 | Auto-Update | GitHub Releases, channels, crash rollback |
| 061 | Onboarding | First-run tooltips, contextual tips |
| **062** | **LLM Integration** | Provider abstraction, model routing, cost tracking |
| 000 | Implementation Control | MVP scope, gate checklist, milestones, ordering |

---

## Capture
Connectors that observe digital activity and publish Context Protocol events.

| # | Spec | What it captures |
|---|------|-----------------|
| **006** | **Browser Extension** | URL visits, page titles, navigation |
| **007** | **VS Code Extension** | File opens, edits, git operations |
| **008** | **File Watcher** | File creates, modifications, deletions |
| **009** | **Activity Monitor** | App focus, idle detection, window titles |
| **063** | **Capture Controls** | Centralized per-connector enable/disable, pause/resume, schedules, Settings UI |

---

## Protocol & Storage
The event backbone and persistence layer.

| # | Spec | Role |
|---|------|------|
| **001** | **Context Protocol** | Event envelope (app/event/action), schemas, publish/consume APIs |
| **004** | **SDK Packages** | `@osai/protocol`, `@osai/storage` — typed libraries for all consumers |
| **002** | **Local Storage** | SQLite database, FTS5 search, schema migrations, data retention |
| 048 | Protocol Specification | Published open standard at spec.osai.app |

---

## Knowledge Engine
Understanding extracted from raw events.

| # | Spec | What it produces |
|---|------|-----------------|
| **011** | **Embeddings Pipeline** | Vector embeddings for semantic search |
| **012** | **Entity Extraction** | Named entities (people, tech, topics, places) |
| **013** | **Event Classification** | Activity labels (learning, building, researching...) |
| **014** | **Graph Builder** | Entity-entity relationship graph |
| **015** | **Project Detection** | Automatic project grouping of related events |
| **016** | **Session Detection** | Work session boundaries from activity clusters |
| **017** | **Recommendation Engine** | Related content, gap detection, digests |

---

## Desktop UI
The frontend experiences.

| # | Spec | What it shows |
|---|------|--------------|
| **010** | **Status Tray** | System tray icon, privacy mode, quick actions |
| **018** | **History** | Chronological event stream, session-organized |
| **019** | **Topics** | Auto-detected attention themes and clusters |
| **020** | **Explore** | Interactive knowledge graph discovery |
| **021** | **Chat Bar** | Conversational interface (⌘K, slides up), streaming responses |
| **022** | **Ask** | Conversation history archive, search, resume, rename, delete |
| **023** | **Now** | Awareness bar — active app, goal progress, suggestion chip |
| **024** | **Home** | Today summary, suggestion feed, quick note |

---

## CLI
Command-line tool for power users and scripting.

| # | Spec | Role |
|---|------|------|
| **005** | **CLI Tool** | `osai` commands — ingest, query, configure, export |

---

## Agents
AI agents that operate on the knowledge base.

| # | Spec | What it does |
|---|------|-------------|
| **064** | **Agent Host** | Background runtime — event intake, proxy to LLM (spec 062), proactive suggestions, Save-to-KB, chat dispatch |
| 025 | MCP Server | Model Context Protocol bridge for all agents |
| 026 | Summarizer Agent | Daily/weekly narrative summaries |
| 027 | Organizer Agent | Auto-tagging, dedup, cleanup suggestions |
| 028 | Researcher Agent | Web + knowledge base research queries |
| 029 | Recommendation Agent | Proactive content suggestions |
| 030 | Planner Agent | Task planning, goal tracking, time estimation, roadmaps |
| 031 | Agent Scheduling | Cron-based agent run scheduling |
| 032 | Agent Permissions | Scoped resource access per agent |
| 033 | Agent Marketplace | Install, publish, scaffold third-party agents |

---

## Sync & Cloud
Multi-device and cloud features.

| # | Spec | Role |
|---|------|------|
| 034 | Sync Protocol | CRDT-based event replication |
| 035 | Cloud Sync Service | Cloud-hosted sync relay |
| 036 | Backup Service | Encrypted cloud backup |
| 037 | User Accounts | Registration, auth, profile |
| 038 | Cloud Dashboard | Web-based activity view |
| 039 | Usage & Billing | Plan tiers, metering, invoicing |
| 040 | E2E Encryption | Client-side encryption for sync/backup |

---

## SDKs
Client libraries for publishing events from any language.

| # | Spec | Language |
|---|------|---------|
| 041 | Python SDK | `pip install osai` |
| 042 | Rust SDK | `cargo add osai` |
| 043 | Go SDK | `go get github.com/osai/sdk-go` |

---

## Connectors
Additional data sources beyond desktop capture.

| # | Spec | What it connects to |
|---|------|-------------------|
| 044 | Media Connectors | Camera, microphone, screen recording |
| 045 | PDF Connector | Document text extraction |
| 046 | API Connectors | GitHub, Slack, Jira, Notion via OAuth |

---

## Ecosystem
Developer and community surface.

| # | Spec | Role |
|---|------|------|
| 047 | Mobile App | iOS/Android companion viewer |
| 048 | Protocol Specification | Published open standard at spec.osai.app |
| 049 | Community Site | Docs, showcase, forums |

---

## Enterprise
Org-scale deployment features.

| # | Spec | Role |
|---|------|------|
| 050 | Team Context Sharing | Shared workspaces |
| 051 | Org Knowledge Graph | Cross-user entity graph |
| 052 | RBAC | Role-based access control |
| 053 | Audit Logging | Admin event trail |
| 054 | Team Dashboard | Org-level activity view |
| 055 | SSO/SAML | Identity provider integration |
| 056 | On-Premise Deployment | Self-hosted infrastructure |
| 057 | Analytics & Reporting | Usage metrics, exports |
| 058 | Enterprise SLA | Uptime, support tiers |

---

## Legend

- **Bold** = MVP 1.0 scope ("Personal Memory")
- Normal = post-MVP milestone
- Implementation order: `003 → 001 → 002 → 004 → 059 → 005 → 006-010 → 063 → 011-017 → 018-024 → 064 → 025 → 026-033`
- Spec 063 (Capture Controls) is implemented after capture connectors — it controls them all via the Settings UI
- Spec 064 (Agent Host) runs after knowledge engine — it subscribes to the event log and powers all proactive features
