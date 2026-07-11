# Feature Specification: Agent Marketplace & Plugin System

**Feature Branch**: `033-agent-marketplace`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an agent marketplace and plugin system for discovering, installing, and managing third-party agents"

## User Scenarios & Testing

### User Story 1 - Browse and Install Agents (Priority: P1)

Users can open the Agent Marketplace from Settings > Agent Manager and browse available agents. Agents are listed with name, description, author, version, rating, and download count. Each agent has a detail page with screenshots, permission requirements, reviews, and an "Install" button. Installation is one-click and sets up the agent with default permissions.

**Why this priority**: The marketplace is the entry point for the entire plugin ecosystem. Without it, users can't discover or install third-party agents.

**Independent Test**: Open the Agent Marketplace from Settings, browse to "Trending" tab. Find an agent "Code Review Assistant", click it, verify the detail page shows: description ("Automatically reviews your code changes"), author ("Community"), version (1.0.0), rating (4.5 stars, 23 reviews), required permissions (read: file events, write: review comments). Click "Install" and verify the agent appears in the Agent Manager within 5 seconds.

**Acceptance Scenarios**:

1. **Given** the marketplace is open, **When** the user views the agent list, **Then** agents are shown in a grid with name, author icon, rating, and install count, sorted by "Featured" by default
2. **Given** an agent detail page, **When** the user clicks "Install", **Then** a permission review dialog shows the agent's required permissions with Accept/Decline buttons
3. **Given** the user accepts permissions, **When** installation completes, **Then** the agent appears in the Agent Manager with "new" badge and is ready to use

---

### User Story 2 - Agent Development Kit (Priority: P2)

The plugin system includes an Agent Development Kit (ADK) — an SDK and CLI for building custom agents. Developers scaffold a new agent with `npx osai create-agent`, implement handlers, declare permissions in a manifest, and publish via `npx osai publish-agent`. The ADK handles lifecycle, scheduling, MCP tool registration, and permission enforcement automatically.

**Why this priority**: The ADK is essential for ecosystem growth. Third-party developers need clear tooling to build agents.

**Independent Test**: Run `npx osai create-agent my-agent` and verify a scaffolded agent directory is created with: `agent.js`, `manifest.json`, `README.md`. The manifest already has permission declarations and a hello-world handler. Run `npx osai validate-agent` in the directory and verify it passes.

**Acceptance Scenarios**:

1. **Given** the ADK CLI, **When** the user runs `npx osai create-agent`, **Then** an interactive prompt asks for agent name, description, capabilities, and creates a scaffolded project with all required files
2. **Given** a scaffolded agent project, **When** the user runs `npx osai validate-agent`, **Then** it validates: manifest JSON schema, permission declarations, handler exports, and dependency existence
3. **Given** a valid agent package, **When** the user runs `npx osai publish-agent`, **Then** the agent is packaged and uploaded to the marketplace registry

---

### User Story 3 - Agent Sandboxing and Isolation (Priority: P2)

Third-party agents run in a sandboxed environment with limited system access. The sandbox enforces: no direct file system access outside the agent's data directory, network access only to declared APIs, memory limits (default 200MB), and CPU limits. Sandbox violations are logged and the agent is terminated if it exceeds limits.

**Why this priority**: Sandboxing is critical for security. Third-party code should never be able to access arbitrary user data or system resources.

**Independent Test**: Install a test agent that attempts to read a file outside its data directory. Verify the access is blocked with a sandbox violation logged: "Agent 'test-agent' attempted to read C:\Users\...\passwords.txt — blocked by sandbox." Then exceed the agent's memory limit and verify it's terminated with "Agent terminated: memory limit exceeded (200MB)."

**Acceptance Scenarios**:

1. **Given** a third-party agent is running, **When** it attempts to access a file outside its assigned directory, **Then** the sandbox blocks the access and logs a violation
2. **Given** a third-party agent, **When** it attempts to make a network request to an undeclared API, **Then** the sandbox blocks the request and logs a violation with the attempted URL
3. **Given** an agent exceeds its memory limit, **When** the limit is reached, **Then** the agent is terminated with an "out of memory" error and the Agent Manager shows "Crashed (OOM)"

---

### User Story 4 - Agent Updates and Versioning (Priority: P3)

The marketplace supports semantic versioning for agents. Users receive notifications when updates are available. Updates can be applied automatically or manually. The system checks permission changes in updates and prompts for re-approval if new permissions are required. Rollback to a previous version is supported.

**Why this priority**: Versioning ensures stability. Users can choose when to update and can roll back if an update causes issues.

**Independent Test**: An installed agent has an update (1.0.0 → 1.1.0). Verify a notification appears: "Update available: Code Review Assistant 1.1.0". Click "Update" and verify the update installs and the agent restarts. If the update adds new permissions, verify a permission review dialog appears before the update completes.

**Acceptance Scenarios**:

1. **Given** an installed agent has a new version, **When** the marketplace registry is checked, **Then** a notification appears "Update available for [agent name]" with version number and changelog summary
2. **Given** an update changes permissions, **When** the user clicks "Update", **Then** a permission diff is shown ("New permissions: read:git-events") with Accept/Decline before the update proceeds
3. **Given** an update was applied, **When** the user clicks "Rollback", **Then** the previous version is reinstalled and the agent restarts with the old version

---

### User Story 5 - Custom Local Agents (Priority: P3)

Users can develop and run custom agents locally without publishing to the marketplace. Local agents live in a user-specified directory (~/.osai/agents/) and are automatically detected by the scheduling system. They have the same capabilities as marketplace agents but are marked as "local" and have a yellow badge.

**Why this priority**: Local agents enable power users to build custom automation without needing to publish. It also serves as a development workflow for marketplace publishing.

**Independent Test**: Create a custom agent in ~/.osai/agents/my-tools/ with a valid manifest.json. Restart the scheduling system or run "osai scan-agents". Verify the agent appears in the Agent Manager with a "local" badge and can be enabled/configured like any other agent.

**Acceptance Scenarios**:

1. **Given** a valid agent directory in the local agents path, **When** the scheduling system scans for agents, **Then** the agent is automatically registered with a "local" badge
2. **Given** a local agent, **When** the user modifies its code, **Then** the changes take effect on the next agent run (no restart needed) or on manual "Reload" action
3. **Given** a local agent, **When** the user runs `npx osai publish-agent` from its directory, **Then** the agent is packaged and submitted to the marketplace

---

### Edge Cases

- What happens when the marketplace registry is unreachable (offline)?
- How are malicious or low-quality agents detected and removed?
- What happens when an installed agent is removed from the marketplace?
- How are agent dependencies handled (agent A depends on agent B)?
- What happens when an update fails partway through?
- How are agent credentials and API keys managed securely?
- What happens when two agents conflict (e.g., both register the same MCP tool)?

## Requirements

### Functional Requirements

- **FR-001**: Agent Marketplace MUST allow browsing agents with name, description, author, version, rating, downloads
- **FR-002**: Agent detail pages MUST show: description, screenshots, permissions required, reviews, changelog
- **FR-003**: Installation MUST be one-click with a permission review step
- **FR-004**: ADK CLI MUST scaffold new agent projects with `create-agent` command
- **FR-005**: ADK MUST validate agent packages with `validate-agent` command
- **FR-006**: ADK MUST publish agents with `publish-agent` command
- **FR-007**: Third-party agents MUST run in a sandboxed environment
- **FR-008**: Sandbox MUST restrict: file system (to agent data dir), network (to declared APIs), memory (configurable, default 200MB), CPU (configurable)
- **FR-009**: Sandbox violations MUST be logged and, if repeated, result in agent termination
- **FR-010**: Marketplace MUST support semantic versioning for agents
- **FR-011**: Users MUST be notified of available updates
- **FR-012**: Updates that add new permissions MUST require re-approval
- **FR-013**: Rollback to previous version MUST be supported
- **FR-014**: Local custom agents MUST be supported via a configurable directory (~/.osai/agents/)
- **FR-015**: Local agents MUST be auto-detected on app start or via `scan-agents` command
- **FR-016**: Local agents MUST be marked with a "local" badge in the Agent Manager
- **FR-017**: Agent manifests MUST follow a published JSON schema
- **FR-018**: Agent manifests MUST declare: name, version, description, author, permissions, dependencies, entry point, capabilities

### Key Entities

- **MarketplaceAgent**: An agent listing in the marketplace. Attributes: id, name, description, author, authorUrl, iconUrl, version, latestVersion, rating, reviewCount, downloadCount, screenshots (array), permissions (array), tags, createdAt, updatedAt.
- **InstalledAgent**: An installed agent instance. Attributes: id, marketplaceId (optional), version, installPath, status (installed/updating/error), installedAt, updatedAt, source (marketplace/local).
- **AgentManifest**: An agent's package manifest. Attributes: name, version, description, author, license, entryPoint, permissions (array of Permission), dependencies (array of agent ids), capabilities (array of MCP tool names), sandbox (resource limits).
- **SandboxViolation**: A sandbox enforcement event. Attributes: id, agentId, type (fileAccess/networkAccess/memory/cpu), details, timestamp, action (blocked/terminated).
- **MarketplaceRegistry**: The remote registry service. Attributes: agents (indexed by id), categories, featured, trending, search index.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Agent installation completes within 10 seconds (download + setup)
- **SC-002**: Marketplace browse loads within 2 seconds (first load), 500ms (cached)
- **SC-003**: Agent detail page loads within 1 second
- **SC-004**: Sandbox overhead: <5ms per permission check
- **SC-005**: ADK scaffolding completes in under 2 seconds
- **SC-006**: Agent update/rollback completes within 10 seconds
- **SC-007**: Local agent auto-detection completes within 5 seconds of scan

## Assumptions

- Marketplace registry is a separate cloud service (hosted at marketplace.osai.app)
- Marketplace registry can be self-hosted for enterprise/offline use
- ADK is distributed as an npm package (`@osai/agent-kit`)
- Agent sandboxing uses Node.js `vm` module with additional restrictions (or isolated workers)
- Sandbox limits are configurable by the user (advanced settings)
- Agent manifests are validated against a published JSON Schema
- Marketplace includes automated security scanning for submitted agents
- Local agents directory is `~/.osai/agents/` (configurable)
- Agents can declare dependencies on other agents (dependency resolution handled by scheduler)
- Source code lives at `services/marketplace/` and `packages/agent-kit/` in the monorepo