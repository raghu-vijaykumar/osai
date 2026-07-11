# Feature Specification: System Tray Application

**Feature Branch**: `010-status-tray`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a system tray application showing capture status, controls, and recent activity for all ingestion connectors"

## User Scenarios & Testing

### User Story 1 - See Capture Status at a Glance (Priority: P1)

The user sees a system tray icon that indicates the overall OSAI capture status — green (all connectors active), yellow (some connectors down), red (OSAI not running), or gray (paused). A tooltip shows a summary.

**Why this priority**: The tray icon is the primary user-facing presence of OSAI. It assures the user that capture is working and provides at-a-glance status without opening any window.

**Independent Test**: Start OSAI, verify the tray icon appears green. Pause capture, verify it turns gray. Stop the OSAI process, verify the icon disappears.

**Acceptance Scenarios**:

1. **Given** OSAI is running with all connectors active, **When** the user looks at the system tray, **Then** the icon is green with tooltip "OSAI — All connectors active"
2. **Given** the browser extension disconnected, **When** the tray app detects the missing heartbeat, **Then** the icon turns yellow with tooltip "OSAI — Browser extension disconnected"

---

### User Story 2 - Pause and Resume Capture (Priority: P1)

The user right-clicks the tray icon and selects "Pause Capture" or "Resume Capture" from the context menu. This pauses/resumes all ingestion connectors globally.

**Why this priority**: Instant global pause is essential for privacy. The user needs a single action to stop ALL capture immediately.

**Independent Test**: Right-click tray icon, select "Pause Capture", verify icon turns gray. Verify no new events appear in the event log. Select "Resume Capture", verify icon turns green and events resume.

**Acceptance Scenarios**:

1. **Given** the tray app is open, **When** the user clicks "Pause Capture", **Then** all connectors receive a pause signal and the icon turns gray within 1 second
2. **Given** capture is paused, **When** the user clicks "Resume Capture", **Then** all connectors resume and the icon turns green

---

### User Story 3 - View Recent Events (Priority: P2)

The user clicks the tray icon to open a popup showing the 10 most recent events across all connectors in a compact list. Clicking an event shows more detail.

**Why this priority**: Recent events provide immediate feedback that capture is working and what's being recorded. Transparency builds trust.

**Independent Test**: Publish 15 events from various connectors, click the tray icon, and verify the popup shows the 10 most recent events with source, type, and timestamp.

**Acceptance Scenarios**:

1. **Given** 20 events have been published, **When** the user clicks the tray icon, **Then** a popup shows the 10 most recent, each displaying `[TIME] [SOURCE] [TYPE] [SUMMARY]`
2. **Given** no events have been published yet, **When** the user clicks the tray icon, **Then** the popup shows "No recent activity — OSAI is ready and waiting"

---

### User Story 4 - Connector Health Dashboard (Priority: P2)

The user opens the tray menu and selects "Connectors..." to see a list of all registered connectors, their status (active/paused/error), events published today, and last heartbeat time.

**Why this priority**: When something goes wrong, the user needs to diagnose which connector is failing. Individual connector health enables targeted troubleshooting.

**Independent Test**: Start OSAI with only the file watcher running (browser extension not installed). Open the connectors view and verify the file watcher shows "Active" and the browser extension shows "Not connected".

**Acceptance Scenarios**:

1. **Given** 3 connectors registered, **When** the user opens the connectors view, **Then** each connector shows name, status (Active/Paused/Error/Disconnected), events today, last heartbeat
2. **Given** a connector is in error state, **When** viewing the connectors list, **Then** an error message is shown (e.g., "File watcher: Permission denied on ~/Downloads")

---

### User Story 5 - Quick Open OSAI Dashboard (Priority: P3)

The tray menu provides quick links to open the OSAI desktop dashboard, open the event timeline, access settings, and quit OSAI entirely.

**Why this priority**: The tray becomes the launch point for all OSAI interactions. One-click access to the dashboard reduces friction.

**Independent Test**: Right-click tray icon, click "Open Dashboard", and verify the OSAI desktop application opens (or a browser tab if the dashboard is web-based).

**Acceptance Scenarios**:

1. **Given** the tray app is running, **When** the user selects "Open Dashboard", **Then** the OSAI desktop app launches (or gets focus if already open)
2. **Given** the user wants to quit OSAI entirely, **When** selecting "Quit OSAI", **Then** a confirmation dialog appears and all OSAI processes shut down on confirm

---

### Edge Cases

- What happens when the tray app is started before the OSAI daemon is ready?
- How does the tray app handle being killed and restarted by the OS?
- What happens on systems without system tray support (Wayland, some Linux DEs)?
- How does the tray app handle multiple displays with different DPI settings?
- What happens when the tray icon cache is stale (common Windows issue)?
- How are notifications handled on macOS (no native tray, uses menu bar extra)?
- What happens when the OS is in dark mode / light mode (icon adaptation)?

## Requirements

### Functional Requirements

- **FR-001**: App MUST display a system tray icon (menu bar icon on macOS) with status-based coloring: green (all active), yellow (partial), red (daemon down), gray (paused)
- **FR-002**: App MUST show a tooltip on hover with overall status summary and event count today
- **FR-003**: App MUST provide a right-click context menu with: Toggle Capture (pause/resume), Connectors, Open Dashboard, Open Timeline, Settings, Quit
- **FR-004**: App MUST pause all connectors when the user selects "Pause Capture" — publishes a `capture.paused` event
- **FR-005**: App MUST resume all connectors on "Resume Capture" — publishes a `capture.resumed` event
- **FR-006**: App MUST show a popup on left-click with the 10 most recent events (source, type, timestamp, summary)
- **FR-007**: App MUST periodically (every 5 seconds) query the OSAI daemon for connector health status
- **FR-008**: App MUST show a connector list view with: name, status badge, events today count, last heartbeat, error message (if any)
- **FR-009**: App MUST publish `capture.start` and `capture.stop` lifecycle events on startup and shutdown
- **FR-010**: App MUST support auto-start with the OS (installable as a login item)
- **FR-011**: App MUST use OS-native notifications for connector errors (e.g., "Browser extension disconnected")
- **FR-012**: App MUST communicate with the OSAI daemon via a local HTTP API or named pipe
- **FR-013**: App MUST respect OS dark mode and provide both light and dark icon variants
- **FR-014**: App MUST handle daemon disconnection gracefully — show "Disconnected" icon and retry connection every 3 seconds
- **FR-015**: App MUST have a settings accessible from the tray menu to configure notification preferences and auto-start

#### Privacy Mode

- **FR-016**: App MUST support a global Privacy Mode that pauses ALL capture (browser, IDE, file watcher, activity monitor) with a single action
- **FR-017**: Privacy Mode MUST be toggleable via: tray menu ("Privacy Mode"), keyboard shortcut (configurable, default: Ctrl+Shift+P / Cmd+Shift+P), and command bar (`> privacy mode on`)
- **FR-018**: When Privacy Mode is active, the tray icon MUST change to a distinctive "shield" or "eye-off" icon variant (not gray — clearly different from paused state)
- **FR-019**: When Privacy Mode is active, a persistent notification MUST show: "Privacy Mode — capture paused. Resume in Settings or click the tray icon."
- **FR-020**: Privacy Mode events MUST NOT be logged or stored — no `capture.paused` event is published (privacy from the system itself)
- **FR-021**: App MUST support an auto-resume timer: user can set "Resume in 5 / 15 / 30 / 60 minutes" when enabling Privacy Mode
- **FR-022**: When auto-resume timer expires, capture resumes silently and the tray icon returns to its normal state
- **FR-023**: Privacy Mode state MUST NOT be persisted across app restarts — always resume in normal mode (the user chose to pause, the system respects that choice on each session)
- **FR-024**: A Privacy Mode history log (local only, never synced) MUST track: `enabled_at`, `duration`, `source` (shortcut/tray/command bar), and `auto_resumed` (boolean)

### Key Entities

- **TrayIcon**: The system tray/menu bar icon. States: `active` (green), `partial` (yellow), `paused` (gray), `disconnected` (red), `error` (red with exclamation).
- **TrayMenu**: The right-click context menu with: Toggle Capture, Connectors, separator, Open Dashboard, Open Timeline, separator, Settings, Quit.
- **ConnectorStatus**: Health info for each connector. Attributes: `id`, `name`, `status` (active/paused/error/disconnected), `eventsToday`, `lastHeartbeat`, `errorMessage`.
- **EventPopup**: Left-click popup showing recent events. Updates every 3 seconds. Shows up to 10 events with auto-scroll.
- **Notification**: OS-native notification for connector errors, capture paused by idle, or daily summary.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Tray icon appears within 2 seconds of OSAI daemon startup
- **SC-002**: Context menu opens in under 100ms
- **SC-003**: Event popup loads in under 200ms (including query to daemon)
- **SC-004**: Pause/resume takes effect within 1 second across all connectors
- **SC-005**: Memory usage under 50MB
- **SC-006**: CPU usage under 0.5% during steady state
- **SC-007**: App passes OS-specific accessibility and sandboxing requirements

## Assumptions

- Built with Tauri (Rust backend + React webview) for small binary size and native tray support
- On macOS, uses menu bar extra (NSStatusBar) instead of system tray
- On Linux, uses libappindicator or StatusNotifierItem spec (KDE/GNOME)
- Communicates with OSAI daemon via localhost HTTP (localhost:3487) or a Unix domain socket
- The tray app is a separate process from the OSAI daemon but is managed by it (started/stopped by the daemon)
- Icon assets: SVG for high-DPI support across all platforms
- Auto-start registered via OS mechanisms: LaunchAgents (macOS), Registry Run keys (Windows), .desktop file autostart (Linux)
- Source code lives at `apps/tray/` in the monorepo
