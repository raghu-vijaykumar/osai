# Feature Specification: CLI Tool

**Feature Branch**: `005-cli-tool`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a CLI tool for event ingestion, querying, storage management, and administrative tasks"

## User Scenarios & Testing

### User Story 1 - Publish an Event from CLI (Priority: P1)

A developer or integration script publishes a context event directly from the command line by providing event type, source, and payload as JSON.

**Why this priority**: CLI publishing is the simplest integration path. It enables scripting, testing, and ad-hoc event injection without writing code.

**Independent Test**: Run `osai publish url.visited --source cli --payload '{"url":"https://example.com","title":"Example"}'` and verify the event is stored and queryable.

**Acceptance Scenarios**:

1. **Given** valid arguments, **When** running `osai publish url.visited --source cli --payload '{"url":"https://x.com"}''`, **Then** the CLI outputs the event ID and exits 0
2. **Given** invalid JSON in `--payload`, **When** running the publish command, **Then** the CLI exits with a parse error message and non-zero exit code

---

### User Story 2 - Query Events from CLI (Priority: P1)

A developer queries stored events using filters from the command line. Results are displayed as a formatted table or JSON for piping to other tools.

**Why this priority**: Querying from CLI enables exploration, debugging, and integration with shell pipelines (jq, grep, etc.).

**Independent Test**: After publishing 3 events, run `osai query --type url.visited --limit 10` and verify all 3 matching events are displayed as a formatted table.

**Acceptance Scenarios**:

1. **Given** 5 stored events, **When** running `osai query --source browser-extension --format json`, **Then** output is valid JSON array with matching events
2. **Given** 100 events across 3 projects, **When** running `osai query --project osai --limit 5`, **Then** output shows 5 events filtered by project

---

### User Story 3 - List and Manage Sources (Priority: P2)

A user registers a new event source, lists all registered sources, and revokes a source's permission to publish.

**Why this priority**: Source management is required for the permission model. Without it, any caller could publish arbitrary events.

**Independent Test**: Register a source, verify it appears in `osai source list`, publish an event from the source, then revoke it and verify publish is rejected.

**Acceptance Scenarios**:

1. **Given** no sources configured, **When** running `osai source register my-app "My Application"`, **Then** the source is created and `osai source list` shows it
2. **Given** a registered source with publish permissions, **When** running `osai source revoke my-app`, **Then** the source can no longer publish events

---

### User Story 4 - Storage Management Commands (Priority: P2)

A user runs commands to view storage stats, clear old events, and check database integrity.

**Why this priority**: Storage management is essential for production use. Users need visibility into storage usage and the ability to manage data lifecycle.

**Independent Test**: Publish events, run `osai storage stats` to see event count and size, run `osai storage prune --older 7d`, and verify old events are removed.

**Acceptance Scenarios**:

1. **Given** 1000 stored events, **When** running `osai storage stats`, **Then** output shows total events, storage size, and per-source breakdown
2. **Given** events older than 30 days, **When** running `osai storage prune --older 30d`, **Then** events older than 30 days are deleted

---

### User Story 5 - Semantic Search from CLI (Priority: P3)

A user runs a natural language search query from the command line and gets semantically relevant events ranked by similarity.

**Why this priority**: Semantic search demonstrates the knowledge engine's value from day one, even before the UI is built.

**Independent Test**: Publish events about different topics, run `osai search "container orchestration"` and verify the Kubernetes-related event ranks highest.

**Acceptance Scenarios**:

1. **Given** events with varied content, **When** running `osai search "kubernetes deployment"`, **Then** results are returned sorted by relevance score descending
2. **Given** a search with no relevant results, **When** running `osai search "zzzznotfound"`, **Then** CLI returns empty results and exits 0

---

### Edge Cases

- What happens when the database file doesn't exist and the user runs a query?
- How does the CLI handle very large result sets (10,000+ events) without freezing the terminal?
- What happens when the user passes conflicting flags (`--limit 0`)?
- How are non-ASCII characters displayed in terminal output?
- What happens when the user interrupts a long-running command (Ctrl+C)?
- How does the CLI handle missing or corrupted config file?

## Requirements

### Functional Requirements

- **FR-001**: CLI binary MUST be named `osai` and be installable via `npm install -g @osai/cli`
- **FR-002**: CLI MUST support `--help` flag on every command and subcommand with usage, examples, and option descriptions
- **FR-003**: CLI MUST support `--version` flag to display the current version
- **FR-004**: CLI MUST have the following top-level commands: `publish`, `query`, `search`, `source`, `storage`, `config`
- **FR-005**: `osai publish` MUST accept `--type`, `--source`, `--payload`, `--project`, `--session` flags
- **FR-006**: `osai publish` MUST accept payload from stdin when no `--payload` is provided (pipe support)
- **FR-007**: `osai query` MUST accept `--type`, `--source`, `--project`, `--session`, `--start-time`, `--end-time`, `--text`, `--limit`, `--offset`, `--order` flags
- **FR-008**: `osai query` MUST support `--format` flag with values `table` (default), `json`, `jsonl`, `csv`
- **FR-009**: `osai search` MUST accept `--query` (positional), `--limit`, `--min-score` flags
- **FR-010**: `osai search` MUST output results as a table with `SCORE`, `TYPE`, `SOURCE`, `TIMESTAMP`, `SUMMARY` columns
- **FR-011**: `osai source` MUST have subcommands: `list`, `register`, `revoke`, `permissions`
- **FR-012**: `osai storage` MUST have subcommands: `stats`, `prune`, `vacuum`, `check`
- **FR-013**: `osai config` MUST have subcommands: `show`, `set`, `get`, `reset`
- **FR-014**: CLI MUST use `osai` config file at `~/.osai/config.json` (auto-created with defaults)
- **FR-015**: CLI MUST respect `OSAI_DB_PATH` environment variable, falling back to `~/.osai/data/osai.db`
- **FR-016**: CLI MUST exit with non-zero code on errors and print error messages to stderr
- **FR-017**: CLI MUST support `--quiet` flag to suppress non-output log messages
- **FR-018**: CLI MUST colorize output when stdout is a TTY, and disable colors when piped
- **FR-019**: CLI MUST use `commander` or `yargs` for argument parsing
- **FR-020**: CLI MUST use `chalk` or `kleur` for colored output and `cli-table3` or `marked` for table rendering

### Key Entities

- **CLI Command**: A top-level verb (`publish`, `query`, `search`, `source`, `storage`, `config`) with its own set of flags and subcommands.
- **Config**: User configuration stored at `~/.osai/config.json`. Keys: `dbPath`, `format`, `defaultLimit`, `colorEnabled`.
- **osai binary**: The entry point. Installed globally or via npx. Entry: `packages/cli/bin/osai.js`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `osai --help` displays in under 200ms
- **SC-002**: `osai publish` with valid args completes in under 100ms
- **SC-003**: `osai query --limit 10` on a database with 10,000 events returns in under 50ms
- **SC-004**: `osai search "test"` on 1,000 embedded events returns in under 200ms
- **SC-005**: CLI passes all integration tests across Windows, macOS, and Linux in CI
- **SC-006**: Every command has `--help` output that includes at least one usage example

## Assumptions

- CLI is built with `commander` (most popular, well-maintained Node.js CLI framework)
- Table output uses `cli-table3` for consistent cross-platform formatting
- Color output uses `kleur` (zero-dependency, smaller than chalk)
- The CLI is distributed as `@osai/cli` npm package and can be run via `npx @osai/cli`
- Config file follows XDG conventions on Linux/macOS, `%USERPROFILE%\.osai\` on Windows
- The CLI is built after `@osai/protocol` and `@osai/storage` packages are published (depends on both)
- JSON output is parseable by `jq` and other standard JSON tools
- Pipe support for `osai publish` enables `curl https://api.github.com/events | osai publish github-event --source github`
