# Feature Specification: Capture Controls

**Feature Branch**: `063-capture-controls`

**Created**: 2026-07-11

**Status**: Draft

**Input**: Centralized UI and IPC API for per-connector enable/disable, pause/resume, schedule, and configuration. Replaces scattered per-connector controls with a single management surface.

---

## User Scenarios & Testing

### User Story 1 - See All Connectors in One Place (Priority: P1)

The user opens Settings > Capture and sees every registered connector (browser extension, VS Code, file watcher, activity monitor, media players, API connectors) as a list with name, icon, status indicator, events today, and last event time. Each row has a toggle switch.

**Why this priority**: Without a centralized view, users must open each tool's individual settings to check its status. A single view builds trust and enables control.

**Independent Test**: Register 3 connectors (browser, VS Code, file watcher). Open Settings > Capture. Verify all 3 appear with correct names, status (active), and events-today count.

**Acceptance Scenarios**:

1. **Given** 3 connectors are running (browser, VS Code, watcher), **When** the user opens Settings > Capture, **Then** all 3 are listed with names, icons, green status dot, events-today count, and last event timestamp
2. **Given** a connector has not sent a heartbeat in 5+ minutes, **When** viewing the list, **Then** its status dot shows yellow with tooltip "Last seen: [time]"
3. **Given** a connector has errored (heartbeat contained error), **When** viewing the list, **Then** its status dot shows red with tooltip showing the error message

---

### User Story 2 - Disable a Connector (Priority: P1)

The user toggles a connector OFF to stop it from capturing entirely. The connector remains installed and registered but produces no events until toggled back ON.

**Why this priority**: Users may want to stop a specific connector (e.g., file watcher during a large file sync) without uninstalling it or affecting other connectors.

**Independent Test**: Toggle "Browser Extension" OFF. Visit 3 URLs. Verify no URL events appear in the timeline. Toggle ON. Visit a URL. Verify a URL event appears.

**Acceptance Scenarios**:

1. **Given** the browser extension is toggled ON, **When** the user toggles it OFF in Settings, **Then** the Rust core sends a `disable` control signal to the browser extension via the native messaging host, the icon badge turns gray, and no further events are accepted from that source
2. **Given** a connector is disabled, **When** it sends a publish request, **Then** the Rust core rejects it with `SOURCE_DISABLED` (no buffering, no retry)
3. **Given** a connector is disabled, **When** the user toggles it back ON, **Then** the Rust core sends an `enable` control signal and the connector resumes normal operation

---

### User Story 3 - Pause/Resume a Connector (Priority: P1)

The user pauses a specific connector temporarily. Unlike disable, pause preserves state — the connector stays connected and buffering may be allowed. Resume returns it to active capture.

**Why this priority**: Pausing is lighter than disable — the connector stays warm (socket connected, buffers ready), suitable for short breaks.

**Independent Test**: Pause the VS Code extension. Edit and save a file. Verify no file.modified events. Resume. Edit and save a file. Verify the event appears.

**Acceptance Scenarios**:

1. **Given** the VS Code extension is active, **When** the user pauses it from Settings, **Then** the Rust core sends a `pause` signal, the connector stops publishing but keeps the socket open, and the status shows "Paused"
2. **Given** a connector is paused, **When** it receives new activity, **Then** it MAY buffer up to 100 events locally and flush them on resume
3. **Given** a paused connector, **When** the user resumes it, **Then** buffered events are flushed and new events are published normally

---

### User Story 4 - Set a Capture Schedule (Priority: P2)

The user configures a schedule for when a connector should capture: "always" (default), "work hours only" (Mon-Fri 9-5), "custom" (cron expression), or "mute until" (temporary pause with auto-resume like privacy mode).

**Why this priority**: Users may not want work-related capture during evenings/weekends, or personal browsing captured during work hours.

**Independent Test**: Set browser extension schedule to "M-F 9 AM – 5 PM" on a Saturday. Browse 5 pages. Verify no events appear. Wait until Monday 9 AM. Browse 1 page. Verify the event appears.

**Acceptance Scenarios**:

1. **Given** a connector's schedule is set to "M-F 9 AM – 5 PM" and it's currently Saturday, **When** the connector tries to publish, **Then** the Rust core rejects with `SOURCE_SCHEDULED_OFF` (no buffering)
2. **Given** the same schedule and it's Monday at 9 AM, **When** the connector publishes, **Then** the event is accepted normally
3. **Given** a connector's schedule is set to "mute until 3 PM", **When** the user clicks "Mute for 1 hour" on the connector row, **Then** a countdown timer shows on the connector row and capture resumes automatically when the timer expires

---

### User Story 5 - Configurable Per-Connector Privacy Settings (Priority: P2)

Each connector exposes its privacy-relevant settings inline in the capture controls page (not buried in a separate options page). For example, the browser extension shows its domain blocklist, the activity monitor shows its app exclusion list.

**Why this priority**: Privacy settings are the primary reason users open capture controls. Having them inline reduces friction.

**Independent Test**: Open Settings > Capture, click "Configure" on the browser extension row. See the domain blocklist inline. Add `*.bank.com` to the blocklist. Visit a bank page. Verify no event is published.

**Acceptance Scenarios**:

1. **Given** the browser extension's configure panel is open, **When** the user adds `*.bank.com` to the blocklist, **Then** the blocklist is saved to the connector's config and future visits to `bank.com` pages are not captured
2. **Given** the activity monitor's configure panel is open, **When** the user toggles "Capture window titles" OFF, **Then** the activity monitor stops sending title fields in `app.focused` events

---

### Edge Cases

- What happens when a connector is disabled mid-event (race condition between disable signal and in-flight publish)?
- How are schedules evaluated — on the Rust core side (reject at publish time) or on the connector side (don't send)?
- What happens when multiple schedules overlap (e.g., global pause is active AND a connector is disabled)?
- How are connector settings stored and synced across devices?
- What happens when a connector goes offline — does its toggle state persist?
- How does a newly installed connector appear in the capture controls list for the first time?
- What happens when the user disables a connector that hasn't registered yet?
- How are per-connector schedules migrated if the user changes timezone?

---

## Requirements

### Functional Requirements

#### Capture Settings UI

- **FR-001**: System MUST provide a Capture Settings page accessible from Settings > Capture (desktop app) and from the tray menu ("Capture Settings...")
- **FR-002**: The Capture Settings page MUST display a list of all registered connectors with: icon, display name, status indicator (green/yellow/red/gray), toggle switch (ON/OFF), events today count, last event timestamp, and a "Configure" button
- **FR-003**: Status indicator MUST show: green (active + connected + within schedule), yellow (active but no heartbeat for 5+ minutes), red (error reported in heartbeat), gray (paused or disabled or outside schedule window)
- **FR-004**: Toggle switch MUST have three states: ON (enabled + capturing), OFF (disabled — connector should disconnect or refuse events), PAUSED (temporarily stopped — connector keeps connection, may buffer)
- **FR-005**: At the top of the Capture Settings page, a global "Pause All" / "Resume All" toggle MUST pause/resume ALL connectors at once, matching the tray menu behavior
- **FR-006**: The global "Privacy Mode" button with auto-resume timer options (5/15/30/60 min) MUST be present at the top of the page as well

#### Per-Connector Schedule

- **FR-007**: Each connector MUST support a schedule configuration with options: `always` (default), `work-hours` (configurable start/end time + days), `custom` (cron expression), `pause-until` (timestamp-based auto-resume)
- **FR-008**: Work-hours schedule MUST default to Mon-Fri 9:00–17:00 in the system timezone, with configurable start time, end time, and day selection checkboxes
- **FR-009**: Custom schedule MUST accept a standard 5-field cron expression (minute hour day-of-month month day-of-week)
- **FR-010**: Schedule evaluation MUST happen on the Rust core side at publish time — if outside the window, return `SOURCE_SCHEDULED_OFF` and do NOT buffer the event
- **FR-011**: If the connector is paused or disabled AND outside its schedule window, the more restrictive state wins (no double rejection)
- **FR-012**: Connector schedule state MUST be re-evaluated on timezone change and system clock jump (NTP sync)

#### Per-Connector Configuration

- **FR-013**: Each connector MUST expose its privacy-relevant settings in a collapsible "Configure" panel inline in the Capture Settings page
- **FR-014**: The configure panel MUST be populated dynamically from the connector's `config_schema` — a JSON Schema that the connector registers alongside its source registration
- **FR-015**: If a connector does not register a `config_schema`, the configure panel shows only "No configurable settings for this connector" with the toggle and schedule
- **FR-016**: Connector config changes made in the Capture Settings page MUST be persisted by the Rust core and forwarded to the connector via a `config_update` IPC message
- **FR-017**: The Rust core MUST expose an IPC API for connector config:

#### IPC API

- **FR-018**: Rust core MUST expose a `GET /connectors` endpoint returning the full list of registered connectors with status, config, and schedule:

```json
{
  "connectors": [
    {
      "app": "com.google.Chrome",
      "name": "Browser Extension",
      "icon": "chrome-icon",
      "status": "active",
      "events_today": 47,
      "last_event_at": "2026-07-11T14:30:00Z",
      "last_heartbeat_at": "2026-07-11T14:31:00Z",
      "status_detail": null,
      "enabled": true,
      "paused": false,
      "schedule": { "type": "always" },
      "config": { "blocklist": ["*.bank.com"] },
      "config_schema": { ... }
    }
  ]
}
```

- **FR-019**: Rust core MUST expose a `PATCH /connectors/{app}` endpoint to update:

```json
{ "enabled": false }
{ "paused": true }
{ "schedule": { "type": "work-hours", "start": "09:00", "end": "17:00", "days": [1,2,3,4,5] } }
{ "config": { "blocklist": ["*.bank.com", "mail.google.com"] } }
```

- **FR-020**: On receiving `PATCH /connectors/{app}`, the Rust core MUST:
  1. Persist the update to the `connector_config` SQLite table
  2. If `enabled` or `paused` changed, send a control signal (`enable`, `disable`, `pause`, `resume`) to the connector via its IPC connection
  3. If `config` changed, send a `config_update` message with the new config blob
  4. If `schedule` changed, update in-memory schedule evaluator

- **FR-021**: Control signal messages MUST use the IPC NDJSON protocol (see context-protocol.md §7.2):

```json
{
  "type": "control",
  "id": "...",
  "payload": {
    "command": "disable" | "enable" | "pause" | "resume",
    "reason": "user_toggle" | "schedule" | "privacy_mode" | "global_pause"
  }
}
```

- **FR-022**: On receiving a control signal, the connector MUST:
  - `disable`: Close any active connection, stop all capture, do not buffer. To resume, user must toggle back ON.
  - `enable`: Reconnect, resume normal capture.
  - `pause`: Stop publishing new events. MAY buffer in memory (up to 100 events). Keep socket open.
  - `resume`: Flush buffered events (if any), resume normal capture.

- **FR-023**: Connector MUST publish a `connector.state_changed` event when its state changes due to a control signal:

```json
{
  "app": "com.google.Chrome",
  "event": "connector",
  "action": "state_changed",
  "payload": {
    "previous_state": "active",
    "new_state": "disabled",
    "reason": "user_toggle",
    "source": "capture_settings"
  }
}
```

#### Storage

- **FR-024**: System MUST store connector configuration in a `connector_config` SQLite table:

```sql
CREATE TABLE IF NOT EXISTS connector_config (
    app         TEXT PRIMARY KEY,
    enabled     INTEGER NOT NULL DEFAULT 1,
    paused      INTEGER NOT NULL DEFAULT 0,
    schedule    TEXT NOT NULL DEFAULT '{"type":"always"}',
    config      TEXT NOT NULL DEFAULT '{}',
    updated_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
```

- **FR-025**: Connector config MUST be persisted locally and NOT synced to the cloud (privacy-sensitive)
- **FR-026**: On first registration of a new connector, the Rust core MUST insert a default row into `connector_config` with `enabled=1`, `paused=0`, `schedule=always`

#### Heartbeat

- **FR-027**: Each connector MUST send a periodic heartbeat message to the Rust core every 60 seconds:

```json
{
  "type": "heartbeat",
  "payload": {
    "app": "com.google.Chrome",
    "events_today": 47,
    "last_event_at": "2026-07-11T14:30:00Z",
    "errors": [],
    "status": "active"
  }
}
```

- **FR-028**: If the Rust core does not receive a heartbeat from a connector for 5 minutes, it MUST mark the connector's status as `disconnected` (yellow) in the connector list
- **FR-029**: If a connector's heartbeat includes errors, the Rust core MUST mark its status as `error` (red) and surface the error messages in the connector list tooltip

### Key Entities

- **ConnectorSettings**: Per-connector configuration from `connector_config` table. Attributes: `app`, `enabled`, `paused`, `schedule` (JSON), `config` (JSON), `updatedAt`.
- **ConnectorStatus**: Runtime status aggregated from heartbeats. Attributes: `app`, `status` (active/paused/disabled/disconnected/error), `eventsToday`, `lastEventAt`, `lastHeartbeatAt`, `errors`.
- **ControlSignal**: A command sent from Rust core to a connector. Attributes: `command` (enable/disable/pause/resume), `reason`, `configUpdate` (optional JSON).
- **Schedule**: A capture schedule definition. Types: `always` (always capture), `work-hours` (days + start/end), `custom` (cron), `pause-until` (ISO 8601 timestamp).

### Schedule Evaluation

```
function should_accept(app, event):
    config = get_connector_config(app)
    if not config.enabled:        return REJECT(SOURCE_DISABLED)
    if is_global_paused():        return REJECT(GLOBAL_PAUSED)
    if config.paused:             return REJECT(SOURCE_PAUSED)
    if not in_schedule(config):   return REJECT(SOURCE_SCHEDULED_OFF)
    return ACCEPT
```

Priority order: `disabled > global_paused > paused > scheduled_off`

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Capture Settings page loads in under 200ms with 10 registered connectors
- **SC-002**: Toggle ON/OFF takes effect in under 1 second (signal sent, acknowledged by connector)
- **SC-003**: Privacy mode pause-all takes effect in under 1 second across all connectors
- **SC-004**: Schedule window transition (e.g., 5:00 PM on a work-day schedule) is evaluated within 1 second of the clock change
- **SC-005**: Connector heartbeat is processed and stored in under 50ms

---

## Assumptions

- Capture Settings is a page inside the desktop app Settings (accessible from tray menu and Chat Bar)
- Each connector runs in its own process and maintains a persistent IPC connection to the Rust core
- Connectors that cannot receive push signals (e.g., browser extensions via native messaging) are polled by the native messaging host, which relays the control signal
- Schedule evaluation is server-side (Rust core) — the connector does not need to know its own schedule
- The global pause (tray) and privacy mode (tray/keyboard) are upstream of per-connector controls — they override all per-connector settings
- Connector config schemas are registered at source registration time via an optional `config_schema` field
- The `connector_config` table is part of the main `osai.db` SQLite database from spec 002
- Source code for the Capture Settings page lives at `ui/settings/capture/` and the IPC handlers at `crates/osai-core/src/connector_control/`
