# Feature Specification: File Watcher Service

**Feature Branch**: `008-file-watcher`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a file system watcher service that captures file create, modify, delete events across configured directories"

## User Scenarios & Testing

### User Story 1 - Watch Configured Directories (Priority: P1)

The file watcher monitors user-configured directories (e.g., `~/Documents`, `~/Projects`, `~/Downloads`) and publishes events when files are created, modified, or deleted. The watcher runs as a background process.

**Why this priority**: File events are essential for the knowledge graph to understand what the user is working on, outside of VSCode. Design files, documents, and downloads all create filesystem signals.

**Independent Test**: Create a file in a watched directory, wait 2 seconds, modify it, delete it, and verify three events (`file.created`, `file.modified`, `file.deleted`) appear with correct file paths.

**Acceptance Scenarios**:

1. **Given** `~/Projects` is a watched directory, **When** a new file `notes.md` is created in `~/Projects/osai/`, **Then** a `file.created` event is published with `payload.path` containing the full path
2. **Given** an existing file in a watched directory, **When** content is modified and saved, **Then** a `file.modified` event is published with `payload.path`, `payload.size`, `payload.mtime`

---

### User Story 2 - Recursive Directory Watching (Priority: P1)

The watcher recursively monitors all subdirectories within configured watch paths. New directories created inside a watched path are automatically added to the watch list.

**Why this priority**: Projects have nested directory structures. Manual configuration of every subdirectory is impractical.

**Independent Test**: Create 3 levels of nested directories under a watched path and create a file at the deepest level — verify the `file.created` event captures the full nested path.

**Acceptance Scenarios**:

1. **Given** a watched directory `~/Projects`, **When** a file is created at `~/Projects/a/b/c/file.txt`, **Then** the event includes the full path, not just the top-level watch root
2. **Given** a new subdirectory is created inside a watched directory, **When** files are later created inside that subdirectory, **Then** they are detected without requiring a restart

---

### User Story 3 - Debounce Rapid Changes (Priority: P2)

When files change rapidly (e.g., npm install, git clone, compiler output), the watcher debounces events to avoid event storms. Multiple changes to the same file within 5 seconds are coalesced into a single event.

**Why this priority**: Rapid file changes can generate thousands of events per second during builds or git operations. Debouncing protects the storage layer and knowledge engine from overload.

**Independent Test**: Write to the same file 10 times in 1 second and verify that at most 2 `file.modified` events are published for that file.

**Acceptance Scenarios**:

1. **Given** a file being rapidly modified, **When** 50 write events occur within 3 seconds, **Then** the watcher publishes at most 2 coalesced `file.modified` events for that file
2. **Given** a `node_modules` directory under a watched project, **When** `npm install` runs, **Then** the watcher recognizes the `node_modules` pattern and suppresses events for that subtree

---

### User Story 4 - Exclusion Patterns (Priority: P2)

Users configure glob-based exclusion patterns to skip certain directories or file types (e.g., `node_modules`, `.git`, `*.log`, `*.tmp`). Exclusions are matched against the full path.

**Why this priority**: Many directories contain volatile or machine-generated files that add noise. Exclusions keep the signal clean.

**Independent Test**: Configure `*.log` as excluded, create a `build.log` file, and verify no `file.created` event is published. Then create a `readme.md` file and verify the event is published.

**Acceptance Scenarios**:

1. **Given** `**/node_modules/**` is excluded, **When** files are created under `node_modules`, **Then** no events are published
2. **Given** `*.tmp` is excluded, **When** a `.tmp` file is modified, **Then** no `file.modified` event is published

---

### User Story 5 - Initial Scan and State Sync (Priority: P3)

On first start, the watcher scans all watched directories and publishes the initial file state as a baseline. This allows the knowledge graph to know what files exist before any modifications.

**Why this priority**: Without an initial scan, the system only knows about files that change after the watcher starts. The initial scan provides complete filesystem awareness.

**Independent Test**: Start the watcher with a directory containing 100 existing files, and verify that all 100 appear as `file.scanned` events in the event log.

**Acceptance Scenarios**:

1. **Given** a watched directory with 50 existing files, **When** the watcher starts, **Then** 50 `file.scanned` events are published within 30 seconds
2. **Given** the initial scan is complete, **When** a new file is created, **Then** subsequent events transition from `file.scanned` to `file.created`

---

### Edge Cases

- What happens when a watched directory is on a network drive or removable media that disconnects?
- How does the watcher handle permission errors (can't read a directory)?
- What happens when the watcher process runs out of file descriptors (ulimit)?
- How are symlinks handled — follow or skip?
- What happens when two watched directories overlap (e.g., `~/Documents` and `~/Documents/Projects`)?
- How does the watcher handle file renames (atomic cross-directory moves)?
- What happens when the OS sends duplicate events (e.g., macOS fsevents)?

## Requirements

### Functional Requirements

- **FR-001**: Service MUST use `chokidar` (Node.js) for cross-platform file system watching
- **FR-002**: Service MUST support a list of directories to watch, configurable via config file
- **FR-003**: Service MUST recursively watch all subdirectories within each configured path
- **FR-004**: Service MUST publish `file.created` event when a new file appears with `path`, `size`, `mimeType`, `extension`
- **FR-005**: Service MUST publish `file.modified` event when an existing file changes with `path`, `size`, `mtime`, `previousSize`
- **FR-066**: Service MUST publish `file.deleted` event when a file is removed with `path`, `previousSize`, `age` (how long the file existed)
- **FR-007**: Service MUST publish `file.renamed` event when a file is renamed/moved with `oldPath`, `newPath`
- **FR-008**: Service MUST debounce `file.modified` events — coalesce rapid changes within a 5-second window per file
- **FR-009**: Service MUST support exclusion patterns (glob) in config — matching files/directories are skipped
- **FR-010**: Service MUST skip common noise directories by default: `node_modules`, `.git`, `.svn`, `__pycache__`, `.next`, `dist`, `build`, `.cache`
- **FR-011**: Service MUST skip temporary file patterns by default: `*.tmp`, `*.swp`, `*.swo`, `*.lock`, `*.log` (project logs, not system)
- **FR-012**: Service MUST run an initial scan on startup, publishing `file.scanned` events for all existing files
- **FR-013**: Service MUST publish a `watcher.ready` event when initial scan is complete
- **FR-014**: Service MUST publish `watcher.error` event on internal errors (permission denied, disk full, watch limit exceeded)
- **FR-015**: Service MUST run as a long-lived background process (daemon on Linux/macOS, Windows service or tray app)
- **FR-016**: Service MUST support hot-reload of config — changes to watched directories or exclusions take effect without restart
- **FR-017**: Service MUST limit concurrent watcher instances based on OS limits (`fs.inotify.max_user_watches` on Linux)
- **FR-018**: Service MUST NOT follow symlinks by default (configurable)

### Key Entities

- **file.created**: New file detected. Payload: `path`, `size` (bytes), `mimeType`, `extension`, `modifiedAt`.
- **file.modified**: Existing file changed. Payload: `path`, `size`, `previousSize`, `modifiedAt`.
- **file.deleted**: File removed. Payload: `path`, `previousSize`, `createdAt` (when file was first seen), `age` (seconds since created).
- **file.renamed**: File moved or renamed. Payload: `oldPath`, `newPath`, `size`.
- **file.scanned**: File discovered during initial scan. Payload: `path`, `size`, `mimeType`, `extension`, `modifiedAt`.
- **WatchedDirectory**: A configured directory to monitor. Attributes: `path` (absolute), `recursive` (bool), `exclusions` (glob array).
- **DebounceWindow**: Per-file coalescing window (5 seconds). Resets on each new write event.

## Success Criteria

### Measurable Outcomes

- **SC-001**: File create/modify/delete detected and published within 1 second of the OS event
- **SC-002**: Initial scan of 10,000 files completes in under 60 seconds
- **SC-003**: Memory usage stays under 100MB when watching 10,000 files across 5 directories
- **SC-004**: CPU usage under 1% during steady state (no active file changes)
- **SC-005**: Debounce coalesces 20 rapid writes into at most 3 events
- **SC-006**: Exclusion patterns correctly filter 100% of matched files
- **SC-007**: Adding/removing a watched directory takes effect without restart in under 5 seconds

## Assumptions

- `chokidar` is the file watching library (battle-tested, cross-platform, used by VSCode and webpack)
- The service runs as a separate process from the main OSAI daemon (or as a managed child process)
- Config file located at `~/.osai/config.json` under `watcher` key
- On Linux, `fs.inotify.max_user_watches` sysctl may need adjustment — the watcher prints a warning if approaching the limit
- `.git` directories are excluded by default since git events are captured by the VSCode extension
- Binary files are watched (metadata events) but file content is not read or stored
- The watcher registers as a `file-watcher` source in the OSAI permission system
- Source code lives at `ingestion/file-watcher/` in the monorepo
