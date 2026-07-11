# Feature Specification: Agent Scheduling & Lifecycle

**Feature Branch**: `031-agent-scheduling`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an agent scheduling and lifecycle management system that manages when agents run, their states, and resource allocation"

## User Scenarios & Testing

### User Story 1 - Agent Lifecycle Management (Priority: P1)

The scheduling system manages the full lifecycle of each agent: registered → loaded → initialized → active → paused → error → stopped. Users can see all agents and their current state in a Settings > Agent Manager view. Agents are automatically started when the app launches and gracefully stopped on shutdown.

**Why this priority**: Without lifecycle management, agents are unreliable — they might not start, might crash silently, or might not clean up resources.

**Independent Test**: Open Settings > Agent Manager and verify all registered agents are listed with their state: Summarizer (active), Organizer (active), Researcher (active), etc. Click "Pause" on the Researcher agent, verify its state changes to "paused" within 2 seconds. Click "Resume", verify it returns to "active".

**Acceptance Scenarios**:

1. **Given** the OSAI app starts, **When** the scheduling system initializes, **Then** all enabled agents transition from "loaded" → "initialized" → "active" within 10 seconds
2. **Given** an active agent, **When** the user clicks "Pause", **Then** the agent state changes to "paused" within 2 seconds and it stops processing
3. **Given** an agent encounters an error, **When** it fails, **Then** the agent state changes to "error" with the error message visible in the panel, and the system attempts recovery (up to 3 retries)

---

### User Story 2 - Scheduled Agent Runs (Priority: P1)

Agents can be scheduled to run on cron-like schedules. The Summarizer runs daily at 9 PM, the Organizer runs every 15 minutes, and the Recommendation Agent runs continuously. Users can view the schedule, see which agents are due to run next, and manually trigger runs.

**Why this priority**: Scheduling is the backbone of autonomous agent operation. Without it, agents only work when manually triggered.

**Independent Test**: Open the schedule view in Agent Manager (Settings). Verify: Summarizer is scheduled "Daily at 9 PM", Organizer is scheduled "Every 15 minutes", Recommendation Agent is "Continuous". Wait for the Organizer's next scheduled run and verify it completes and the "Last Run" timestamp updates.

**Acceptance Scenarios**:

1. **Given** an agent with a cron schedule, **When** the scheduled time is reached, **Then** the agent run starts within 5 seconds of the scheduled time
2. **Given** a manually triggered run, **When** the user clicks "Run Now" on an agent, **Then** the agent starts immediately regardless of its schedule
3. **Given** an agent is currently running, **When** its next scheduled time arrives, **Then** the second run is queued (not skipped, not concurrent)

---

### User Story 3 - Resource Management and Throttling (Priority: P2)

The scheduling system manages resource allocation: CPU, memory, and API rate limits. Agents are classified by resource intensity (lightweight: tagging; medium: classification; heavy: research, summarization). The system ensures that heavy agents don't run simultaneously unless resources permit, and API rate limits are respected across agents.

**Why this priority**: Without resource management, background agents can slow down the user's machine or hit API rate limits, causing a poor experience.

**Independent Test**: While the Research agent is running (heavy), try to start the Summarizer (medium). Verify the scheduling system queues the Summarizer run with a message: "Waiting for Research agent to complete — estimated wait: 30s." When Research completes, verify the Summarizer starts automatically.

**Acceptance Scenarios**:

1. **Given** a heavy agent is running, **When** another heavy agent is scheduled to start, **Then** it's queued with an estimated wait time and starts when resources are available
2. **Given** multiple agents use the same external API, **When** they all need to make requests, **Then** the scheduling system ensures total API calls stay under the rate limit, queuing excess requests
3. **Given** an agent has been running for >5 minutes, **When** the system checks resource usage, **Then** if CPU or memory exceeds thresholds (80% CPU, 500MB memory), the agent is paused and the user is notified

---

### User Story 4 - Health Monitoring and Recovery (Priority: P2)

The scheduling system monitors agent health: heartbeat checks, crash detection, and automatic restart with exponential backoff. Agents that crash 3 times within an hour are disabled and the user is notified. Health metrics (uptime, runs completed, error rate) are visible in the Agent Manager (Settings).

**Why this priority**: Self-healing agents reduce support burden. Users shouldn't need to manually restart crashed agents.

**Independent Test**: Simulate a crash of the Organizer agent. Verify the scheduling system detects it within 10 seconds, restarts it, and shows a notification: "Organizer agent recovered from crash (attempt 1/3)." Crash it 3 more times within an hour and verify it's disabled with notification: "Organizer agent disabled due to repeated crashes."

**Acceptance Scenarios**:

1. **Given** an agent stops sending heartbeats, **When** 10 seconds pass without a heartbeat, **Then** the scheduling system marks it as "crashed" and initiates restart
2. **Given** an agent crashes repeatedly, **When** 3 crashes occur within 1 hour, **Then** the agent is disabled and the user sees "Disabled (too many crashes)" with a "Enable" button
3. **Given** an agent is disabled, **When** the user clicks "Enable", **Then** the agent is re-registered, initialized, and set to active

---

### User Story 5 - Agent Dependencies and Ordering (Priority: P3)

Some agents depend on others. For example, the Recommendation Agent depends on the Organizer (for tags) and the Knowledge Engine (for entities). The scheduling system resolves dependencies: it ensures required agents are active before starting dependent ones and warns if a dependency is disabled.

**Why this priority**: Dependency management prevents agents from producing poor results because their dependencies aren't ready.

**Independent Test**: Disable the Organizer agent. Try to enable the Recommendation Agent. Verify the system shows a warning: "Recommendation Agent depends on Organizer (disabled). Enable anyway?" If the user enables anyway, verify the Recommendation Agent runs with limited functionality and a status note.

**Acceptance Scenarios**:

1. **Given** agents with declared dependencies, **When** the system starts, **Then** agents are initialized in dependency order (dependencies first)
2. **Given** a dependency is disabled, **When** the dependent agent tries to run, **Then** it runs in "degraded" mode with a status note about the missing dependency

---

### Edge Cases

- What happens when the system is under extreme load (user gaming, video rendering)?
- How are agent updates handled (code changes while running)?
- What happens when an agent run exceeds its expected duration 10x?
- How are overlapping schedules handled (two agents scheduled at exactly the same time)?
- What happens when the user's machine goes to sleep?
- How is state persisted across app restarts?

## Requirements

### Functional Requirements

- **FR-001**: Scheduling system MUST manage agent lifecycle: registered → loaded → initialized → active → paused → error → stopped
- **FR-002**: Agent state MUST be visible in the Agent Manager (Settings) for all registered agents
- **FR-003**: Agents MUST auto-start on app launch (if enabled)
- **FR-004**: Agents MUST gracefully stop on app shutdown (within 5 seconds per agent)
- **FR-005**: Agents MUST support cron-based scheduling for periodic runs
- **FR-006**: Users MUST be able to manually trigger agent runs
- **FR-007**: Concurrent runs of the same agent MUST be queued, not skipped
- **FR-008**: Agents MUST be classified by resource intensity: lightweight, medium, heavy
- **FR-009**: Heavy agents MUST NOT run concurrently unless sufficient resources are available
- **FR-010**: API rate limits MUST be managed centrally across all agents
- **FR-011**: Scheduling system MUST monitor agent health via heartbeat (every 10 seconds)
- **FR-012**: Agent crashes MUST be detected within 10 seconds of missed heartbeat
- **FR-013**: Crashed agents MUST be auto-restarted with exponential backoff (1s, 2s, 4s, 8s, max 60s)
- **FR-014**: Agents that crash 3 times within 1 hour MUST be disabled
- **FR-015**: Disabled agents MUST show error reason and have a manual "Enable" button
- **FR-016**: Agents MUST declare dependencies on other agents and system components
- **FR-017**: Dependency resolution MUST initialize agents in dependency order
- **FR-018**: Missing dependencies MUST result in "degraded" mode (not complete failure)
- **FR-019**: Health metrics MUST be tracked per agent: uptime, runs, errors, avg duration
- **FR-020**: Scheduling system MUST persist agent state across restarts

### Key Entities

- **AgentRegistration**: An agent registered with the scheduling system. Attributes: id, name, version, dependencies (array of agent ids), resourceIntensity (light/medium/heavy), schedule (cron expression), state, health.
- **AgentState**: The current state of an agent. Attributes: agentId, status (registered/loaded/initialized/active/paused/error/stopped), since (timestamp when state was entered), message (optional status message), lastHeartbeat.
- **AgentRun**: A single execution of an agent. Attributes: id, agentId, trigger (scheduled/manual/startup), startedAt, completedAt, status (running/completed/failed/timeout), result, error.
- **AgentHealth**: Health metrics for an agent. Attributes: agentId, uptime (total), runsCompleted, runsFailed, lastError, avgDuration, crashCount (last hour), heartbeatInterval.
- **ResourceProfile**: Current system resource profile. Attributes: cpuUsage, memoryUsage, availableMemory, activeHeavyAgents, rateLimitState (per API).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Agent auto-start completes within 10 seconds for all agents combined
- **SC-002**: Scheduled runs start within 5 seconds of scheduled time
- **SC-003**: Crash detection completes within 10 seconds
- **SC-004**: Auto-restart completes within 30 seconds (including backoff delay)
- **SC-005**: Resource management prevents CPU >80% and memory >500MB per agent
- **SC-006**: Health monitoring overhead is <1% CPU
- **SC-007**: Agent state persistence and recovery completes in under 2 seconds on restart

## Assumptions

- Built using the Tauri sidecar mechanism — Node.js processes spawned and managed by the Rust core
- Each agent runs in its own isolated Node.js child process, spawned by the Rust scheduler
- The Rust core monitors agent processes via IPC heartbeat (every 10 seconds)
- Heartbeat via IPC message every 10 seconds
- Resource monitoring via `sysinfo` crate (Rust) for the Tauri core, and Node.js `process.cpuUsage()` / `process.memoryUsage()` for agent sidecars`
- Cron scheduling via `node-cron` or similar library
- Rate limiting uses a shared token bucket
- Agent state persisted to SQLite (via storage layer)
- Dependencies are declared in agent manifest (package.json or agent config)
- Resource intensity classification is configured per agent, not auto-detected
- Source code lives at `services/agent-scheduler/` in the monorepo