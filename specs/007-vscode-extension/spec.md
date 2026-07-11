# Feature Specification: VSCode Extension

**Feature Branch**: `007-vscode-extension`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a VSCode extension that captures file opens, code context, git events, editor activity, and publishes events via the context protocol"

## User Scenarios & Testing

### User Story 1 - Capture File Opens and Edits (Priority: P1)

When the user opens a file in VSCode, the extension publishes a `file.opened` event with the file path, language, and project context. Subsequent edits are captured as `file.modified` events.

**Why this priority**: File opens are the primary signal for "what the user is working on." This feeds project detection and session context.

**Independent Test**: Create a test file, open it in VSCode, make 3 edits, and verify the event log shows one `file.opened` and three `file.modified` events with correct file paths.

**Acceptance Scenarios**:

1. **Given** a TypeScript file is opened, **When** the editor loads the file, **Then** a `file.opened` event is published with `payload.path`, `payload.language: "typescript"`, `payload.project` (workspace folder name)
2. **Given** a file is modified by typing, **When** content changes are saved or autosaved, **Then** a `file.modified` event is published with `payload.lineCount` and `payload.charsChanged`

---

### User Story 2 - Capture Git Events (Priority: P1)

The extension captures git operations — commits, branch switches, pulls, pushes — and publishes them as typed events. This provides version control context to the knowledge graph.

**Why this priority**: Git events are high-signal context. Commits represent completed work units. Branch switches represent context shifts.

**Independent Test**: Create a commit in a test repo and verify a `git.commit` event is published with the commit message, hash, and changed files.

**Acceptance Scenarios**:

1. **Given** a git repository, **When** the user commits changes, **Then** a `git.commit` event is published with `payload.message`, `payload.hash`, `payload.filesChanged`, `payload.branch`
2. **Given** a git repository, **When** the user switches branches, **Then** a `git.branch_switch` event is published with `payload.from` and `payload.to` branch names

---

### User Story 3 - Active File and Cursor Context (Priority: P2)

The extension periodically publishes the active file path, cursor position, and visible range as `editor.heartbeat` events. This provides fine-grained attention tracking.

**Why this priority**: Heartbeat events enable "what is the user looking at right now" queries. With 30-second debounce, they build a heatmap of attention across the codebase.

**Independent Test**: Open file A, wait 60 seconds, switch to file B, wait 60 seconds, and verify two `editor.heartbeat` events with different file paths and timestamps.

**Acceptance Scenarios**:

1. **Given** an active editor, **When** the user is idle, **Then** an `editor.heartbeat` event is published every 30 seconds with `payload.filePath`, `payload.line`, `payload.column`, `payload.visibleRange`
2. **Given** the user stops typing for 5 minutes, **When** the idle timeout triggers, **Then** a `editor.idle` event is published

---

### User Story 4 - Project and Workspace Context (Priority: P2)

When VSCode opens a workspace, the extension publishes a `workspace.opened` event with workspace metadata, folder structure, and active project name.

**Why this priority**: Workspace opens frame all subsequent coding activity. They define the project context that other events inherit.

**Independent Test**: Open a workspace with 3 folders and verify a `workspace.opened` event with 3 folder paths is published.

**Acceptance Scenarios**:

1. **Given** VSCode starts and opens a workspace, **When** the workspace is ready, **Then** a `workspace.opened` event is published with `payload.folders` array and `payload.name`
2. **Given** a multi-root workspace, **When** opened, **Then** the `workspace.opened` event includes all workspace folder paths

---

### User Story 5 - Terminal and Task Events (Priority: P3)

The extension captures terminal commands run and task execution (build, test, lint) as events.

**Why this priority**: Terminal commands reveal intent — "what is the user trying to do?" Build/test commands indicate validation loops, debugging, or deployment.

**Independent Test**: Run `npm test` in the VSCode terminal and verify a `terminal.command` event with the command text and exit code appears.

**Acceptance Scenarios**:

1. **Given** the integrated terminal, **When** a command is executed, **Then** a `terminal.command` event is published with `payload.command`, `payload.cwd`, `payload.exitCode`
2. **Given** a VSCode task (build, test) is triggered, **When** the task completes, **Then** a `task.completed` event is published with `payload.name` and `payload.duration`

---

### Edge Cases

- What happens when the user opens a file outside any workspace (single file mode)?
- How are binary files (images, PDFs) detected and excluded from content capture?
- What happens when git is not installed or the repo is not tracked?
- How does the extension handle very large files (100K+ lines) without performance impact?
- What happens when the user has multiple VSCode windows open with different workspaces?
- How are editor heartbeat events throttled when the user is actively switching files rapidly?
- What happens when the OSAI native messaging host is not found?

## Requirements

### Functional Requirements

- **FR-001**: Extension MUST publish `file.opened` event when a file is opened in the editor, with `path`, `language`, `size`, `project` (workspace folder name)
- **FR-002**: Extension MUST publish `file.modified` event on document save with `path`, `language`, `charsAdded`, `charsRemoved`, `lineCount`
- **FR-003**: Extension MUST publish `file.closed` event when a file tab is closed with `path` and `openDuration`
- **FR-004**: Extension MUST publish `git.commit` event on successful commit with `message`, `hash`, `branch`, `filesChanged`, `timestamp`
- **FR-005**: Extension MUST publish `git.branch_switch` event on branch change with `from`, `to`, `timestamp`
- **FR-006**: Extension MUST publish `git.push` and `git.pull` events on sync operations
- **FR-007**: Extension MUST publish `editor.heartbeat` events every 30 seconds while active, with `filePath`, `line`, `column`, `selection`, `visibleRange`
- **FR-008**: Extension MUST publish `editor.idle` event after 5 minutes of inactivity
- **FR-009**: Extension MUST publish `workspace.opened` event on workspace load with `name`, `folders`, `workspaceType` (single/multi-root)
- **FR-010**: Extension MUST publish `terminal.command` event when a terminal command finishes, with `command`, `cwd`, `exitCode`, `duration`
- **FR-011**: Extension MUST publish `task.completed` event for VSCode tasks with `name`, `type`, `duration`, `exitCode`
- **FR-012**: Extension MUST NOT capture file content for binary files (determined by language ID or file extension)
- **FR-013**: Extension MUST throttle `editor.heartbeat` — maximum one event per 30 seconds regardless of activity frequency
- **FR-014**: Extension MUST debounce `file.modified` events — no more than one per 5 seconds per file
- **FR-015**: Extension MUST include a status bar item showing capture status (active/paused/error)
- **FR-016**: Extension MUST provide a `OSAI: Toggle Capture` command accessible from command palette
- **FR-017**: Extension MUST provide a `OSAI: Show Recent Activity` command showing last 20 published events
- **FR-018**: Extension MUST reconnect to native messaging host if the process restarts
- **FR-019**: Extension MUST contribute configuration settings: `osai.enabled`, `osai.capture.gitEvents`, `osai.capture.heartbeat`, `osai.capture.terminal`

### Key Entities

- **file.opened/modified/closed**: File lifecycle events. Payload: `path` (absolute), `relativePath`, `language`, `project`, `size`, `lineCount`.
- **git.commit/push/pull/branch_switch**: Git operation events. Payload: `message`, `hash`, `branch`, `filesChanged` (array), `stats` (insertions/deletions).
- **editor.heartbeat/idle**: Editor attention events. Payload: `filePath`, `line`, `column`, `selection` (start/end), `visibleRange` (start/end line), `project`.
- **workspace.opened**: Workspace lifecycle. Payload: `name`, `folders` (array of paths), `workspaceType`.
- **terminal.command**: Terminal execution. Payload: `command` (sanitized, no env vars), `cwd`, `exitCode`, `duration`.
- **task.completed**: VSCode task lifecycle. Payload: `name`, `type` (npm, shell, etc.), `duration`, `exitCode`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Extension activates in under 1 second from VSCode start
- **SC-002**: File open to event publish completes in under 500ms
- **SC-003**: Extension adds less than 50ms to file save latency
- **SC-004**: Heartbeat CPU usage is under 0.5% during active typing
- **SC-005**: Extension memory usage stays under 30MB
- **SC-006**: All published events pass protocol schema validation
- **SC-007**: Extension passes VSCE (VS Code Extension) packaging and validation

## Assumptions

- Extension targets VSCode 1.85+ and Cursor
- Published to VS Code Marketplace
- Communication with OSAI via native messaging host (same binary as browser extension)
- Git events use VSCode's built-in Git extension API (`git` API from `vscode.git`)
- File content is NOT stored in events — only metadata (path, language, size, line count)
- Terminal command sanitization strips environment variables and arguments that look like secrets (tokens, passwords, keys)
- Extension registers as a `workspace` event source in the OSAI permission system
- Source code lives at `ingestion/vscode-extension/` in the monorepo
