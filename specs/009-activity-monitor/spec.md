# Feature Specification: Activity Monitor

**Feature Branch**: `009-activity-monitor`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an OS-level activity monitor that tracks window focus, application usage, idle time, and publishes activity events"

## User Scenarios & Testing

### User Story 1 - Track Active Window and Application (Priority: P1)

The activity monitor polls the OS for the currently focused window and foreground application. When the active app changes, it publishes a `app.focus_changed` event with the application name, window title, and process details.

**Why this priority**: Window focus is the universal signal for "what is the user doing right now." It ties together all other capture sources — if the user is in VSCode, file events are expected; if in a PDF reader, document events should follow.

**Independent Test**: Switch between Chrome, VSCode, and a terminal. Verify that each switch produces an `app.focus_changed` event with the correct application name and window title within 2 seconds.

**Acceptance Scenarios**:

1. **Given** the activity monitor is running, **When** the user switches from Chrome to VSCode, **Then** an `app.focus_changed` event is published with `payload.appName: "Code"`, `payload.windowTitle: "*.ts — osai"`, `payload.prevApp: "chrome"`
2. **Given** a window title change within the same application (e.g., new tab in Chrome), **When** the title changes, **Then** an `app.focus_changed` event is published with the updated title

---

### User Story 2 - Track Idle Time (Priority: P1)

The monitor tracks system idle time (no keyboard, mouse, or touch input). When the user goes idle, it publishes `user.idle` and when they return, `user.active`. This enables session segmentation.

**Why this priority**: Idle tracking enables the system to distinguish between active work sessions and inactivity breaks. It powers session detection and attention-aware features.

**Independent Test**: Stop interacting with the computer for the idle threshold (e.g., 5 minutes), verify `user.idle` is published. Resume interacting, verify `user.active` is published.

**Acceptance Scenarios**:

1. **Given** the user is active, **When** no input is detected for 5 minutes (configurable), **Then** a `user.idle` event is published with `payload.duration: 300` (seconds since last input)
2. **Given** the user is idle, **When** keyboard or mouse input resumes, **Then** a `user.active` event is published with `payload.idleDuration` (total idle seconds)

---

### User Story 3 - Track Application Usage Time (Priority: P2)

The monitor accumulates time spent per application per session. When an app focus changes, it publishes how long the previous app was in focus, building an app usage timeline.

**Why this priority**: App usage duration is a high-level productivity signal. It answers "how long did I spend in the browser today?" and powers time-tracking insights.

**Independent Test**: Use Chrome for 2 minutes, switch to VSCode for 3 minutes. Verify two `app.usage` events with durations of approximately 120 and 180 seconds.

**Acceptance Scenarios**:

1. **Given** Chrome is focused for 2 minutes and 15 seconds, **When** switching to VSCode, **Then** an `app.usage` event is published with `payload.appName: "chrome"`, `payload.duration: 135`, `payload.sessionStart`
2. **Given** the user unlocks the screen after sleep, **When** the activity monitor detects resumed interaction, **Then** a `user.active` event is published with `payload.idleDuration`

---

### User Story 4 - Track System Power and Lock State (Priority: P3)

The monitor captures system sleep, wake, lock, and unlock events. These frame work sessions and help distinguish between intentional breaks and system-forced pauses.

**Why this priority**: Sleep/wake events explain gaps in the timeline. Without them, a 6-hour gap between events looks like missing data rather than a night's sleep.

**Independent Test**: Lock the workstation, wait 10 seconds, unlock it. Verify `system.locked` and `system.unlocked` events bracket the gap.

**Acceptance Scenarios**:

1. **Given** the computer is active, **When** the user locks the screen (Win+L / Ctrl+Cmd+Q), **Then** a `system.locked` event is published with a timestamp
2. **Given** the computer was asleep, **When** it wakes, **Then** a `system.wake` event is published with `payload.sleepDuration`

---

### User Story 5 - Configurable Sampling and Privacy Controls (Priority: P3)

The user can configure which applications are tracked, disable title capture for sensitive apps, set polling interval, and pause/resume monitoring. Sensitive applications (e.g., password managers, banking apps) can be hidden.

**Why this priority**: Activity monitoring is the most privacy-sensitive capture source. Users must have fine-grained control.

**Independent Test**: Add "banking" to the hidden applications list, switch to a banking app, and verify that `app.focus_changed` shows `appName: "Hidden"` instead of the actual app name.

**Acceptance Scenarios**:

1. **Given** a configured list of hidden applications (e.g., `"1Password"`, `"chrome"` with URL pattern `*bank*`), **When** those apps are focused, **Then** the published event shows `payload.appName: "Hidden"` and no window title
2. **Given** capture is paused via CLI (`osai activity pause`), **When** time passes, **Then** no activity events are published until resume

---

### Edge Cases

- What happens when the user has multiple monitors and switches between them?
- How are virtual desktops/spaces handled?
- What happens when the screen saver activates?
- How does the monitor distinguish between a locked screen and sleep?
- What happens on fast user switching (multiple OS user accounts)?
- How are remote desktop sessions (RDP, VNC, TeamViewer) handled?
- What happens when the polling interval conflicts with OS power management?
- How does the monitor handle applications with rapidly changing window titles (e.g., terminals running commands)?

## Requirements

### Functional Requirements

- **FR-001**: Monitor MUST poll the active window and foreground application at a configurable interval (default: 2 seconds)
- **FR-002**: Monitor MUST publish `app.focus_changed` event when the foreground application or window title changes, with `appName`, `windowTitle`, `pid`, `prevApp`, `prevTitle`, `focusDuration`
- **FR-003**: Monitor MUST publish `app.usage` event on focus change or periodically (every 5 minutes) with `appName`, `duration` (seconds in foreground this session), `sessionStart`
- **FR-004**: Monitor MUST publish `user.idle` event after a configurable idle threshold (default: 5 minutes) with `duration` (seconds since last input)
- **FR-005**: Monitor MUST publish `user.active` event when idle state ends with `idleDuration`
- **FR-006**: Monitor MUST publish `system.locked` event on workstation lock
- **FR-007**: Monitor MUST publish `system.unlocked` event on workstation unlock
- **FR-008**: Monitor MUST publish `system.sleep` event on system suspend/sleep
- **FR-009**: Monitor MUST publish `system.wake` event on system resume with `sleepDuration`
- **FR-010**: Monitor MUST support a configurable list of hidden applications whose names and window titles are redacted to `"Hidden"`
- **FR-011**: Monitor MUST NOT capture window content — only application name and window title
- **FR-012**: Monitor MUST support pause/resume — no events published while paused
- **FR-013**: Monitor MUST use native OS APIs: Windows (`GetForegroundWindow` + `GetWindowText` via Win32), macOS (NSWorkspace), Linux (X11 via `xdotool` or `xprop`, or Wayland via KWin/D-Bus)
- **FR-014**: Monitor MUST handle permissions gracefully — if OS accessibility permissions are denied, publish a `monitor.error` event and retry
- **FR-015**: Monitor MUST publish `monitor.ready` and `monitor.stopped` lifecycle events
- **FR-016**: Monitor MUST respect system power state — stop polling during sleep, resume on wake

### Key Entities

- **app.focus_changed**: Foreground application changed. Payload: `appName`, `windowTitle`, `pid`, `bundleId` (macOS), `prevApp`, `prevTitle`, `focusDuration` (seconds the previous app was focused).
- **app.usage**: Accumulated time per app per session. Payload: `appName`, `duration`, `sessionStart`, `sessionDate`.
- **user.idle**: User stopped interacting. Payload: `duration` (idle seconds), `timestamp`.
- **user.active**: User resumed interacting. Payload: `idleDuration`, `timestamp`.
- **system.locked/unlocked/sleep/wake**: System power and security state changes. Payload: `sleepDuration` (for wake), `timestamp`.
- **HiddenApplication**: An app or window title pattern excluded from detail capture. Attributes: `namePattern` (glob), `titlePattern` (glob, optional), `redactTo` (string, default `"Hidden"`).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Focus change detected and published within 2 seconds (polling interval + processing)
- **SC-002**: Idle detection accurate within ±10 seconds of the configured threshold
- **SC-003**: Monitor consumes under 0.5% CPU during normal operation
- **SC-004**: Monitor memory usage under 20MB
- **SC-005**: No events missed during rapid app switching (10 switches in 5 seconds)
- **SC-006**: Hidden application redaction matches 100% of configured patterns
- **SC-007**: Monitor correctly handles system sleep/wake cycles with zero data loss

## Assumptions

- Cross-platform support requires platform-specific native modules
- On Windows, uses a Rust or Zig native addon for `GetForegroundWindow` / `GetWindowText` / `GetLastInputInfo` (or falls back to PowerShell polling)
- On macOS, uses `osascript -e 'tell application "System Events" to get {name, title} of first process whose frontmost is true'` (or a Swift helper)
- On Linux/X11, uses `xdotool getactivewindow getwindowname`; on Wayland this may require KWin D-Bus API or `wlr-foreign-toplevel-management`
- Idle detection on Windows: `GetLastInputInfo`; macOS: `CGEventSourceSecondsSinceLastEventType`; Linux/X11: `xss` or `xidle`
- The activity monitor process runs as a child of the main OSAI daemon
- Window title is truncated to 200 characters
- Application name is normalized (lowercased, `.app` extension stripped on macOS)
- Source code lives at `ingestion/activity-monitor/` in the monorepo
