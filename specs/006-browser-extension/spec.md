# Feature Specification: Browser Extension

**Feature Branch**: `006-browser-extension`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build Chrome and Firefox browser extension that captures page visits, tab context, page content, and publishes events via the context protocol"

## User Scenarios & Testing

### User Story 1 - Capture Page Visits (Priority: P1)

When the user visits a URL, the extension captures the visit as a `url.visited` event with URL, title, and timestamp. Events are published to the local OSAI store via the native messaging bridge.

**Why this priority**: URL visits are the most fundamental browsing event. Everything else builds on this.

**Independent Test**: Visit 5 different URLs in sequence and verify 5 `url.visited` events appear in the OSAI event log with correct URLs, titles, and timestamps.

**Acceptance Scenarios**:

1. **Given** the extension is installed and active, **When** the user navigates to `https://example.com`, **Then** a `url.visited` event is published with `payload.url: "https://example.com"` within 2 seconds
2. **Given** the user is already on a page, **When** the page title changes dynamically, **Then** a `url.title_changed` event is published with the new title

---

### User Story 2 - Capture Page Content (Priority: P1)

The extension captures page content (text, metadata, OpenGraph tags) and publishes it as a `page.content` event. Content is used later for embeddings and semantic search.

**Why this priority**: URLs alone are useless for semantic search. Page content enables the knowledge engine to understand what the user was reading.

**Independent Test**: Visit a documentation page with known headings and paragraphs, then query the stored `page.content` event and verify the extracted text contains the page's main headings.

**Acceptance Scenarios**:

1. **Given** a page with OpenGraph meta tags, **When** visited, **Then** the `page.content` event includes `payload.og: { title, description, image }`
2. **Given** a page with article content, **When** visited, **Then** the `page.content` event includes `payload.textContent` with extracted visible text (truncated to 10KB)

---

### User Story 3 - Tab Context Tracking (Priority: P2)

The extension tracks tab state — tab switches, tab close, tab pin/unpin — and publishes `tab.activated`, `tab.closed`, and `tab.updated` events. This provides session continuity.

**Why this priority**: Tab context fills the gaps between page visits. Tab switching indicates attention shifts. Tab closure indicates end of a research thread.

**Independent Test**: Open 3 tabs, switch between them, close one, and verify the event log shows activate/deactivate/close events in correct order.

**Acceptance Scenarios**:

1. **Given** 2 open tabs, **When** switching from tab A to tab B, **Then** a `tab.activated` event is published for tab B and a `tab.deactivated` event for tab A
2. **Given** a tab is closed, **When** the close event fires, **Then** a `tab.closed` event is published with `payload.url` and `payload.activeDuration`

---

### User Story 4 - Permission Controls (Priority: P2)

The extension shows a popup UI where the user can see what's being captured, toggle capture on/off, pause/resume, and view recent events. Users control which sites are excluded.

**Why this priority**: Privacy by design requires visible controls and easy opt-out. Without this, users won't trust the extension.

**Independent Test**: Open the extension popup, toggle capture off, visit a site, toggle back on, and verify no events were published during the paused period.

**Acceptance Scenarios**:

1. **Given** the extension popup is open, **When** the user toggles "Pause capture", **Then** no events are published until capture is resumed
2. **Given** a site is added to the blocklist (e.g., `bank.com`), **When** visiting that site, **Then** no events are published for that URL

---

### User Story 5 - Download Events (Priority: P3)

The extension captures file downloads — filename, URL, size, MIME type — as `file.downloaded` events. This connects browsing activity to local files.

**Why this priority**: Downloads bridge browser and filesystem. They allow the system to link "visited paper page" with "downloaded PDF."

**Independent Test**: Download a PDF from a research site and verify a `file.downloaded` event with correct filename and source URL is published.

**Acceptance Scenarios**:

1. **Given** a file download completes, **When** the download event fires, **Then** `file.downloaded` is published with `payload.filename`, `payload.url`, `payload.size`, `payload.mimeType`
2. **Given** a download is cancelled by the user, **When** the download.determine fails, **Then** no download event is published

---

### Edge Cases

- What happens when the user is in incognito/private browsing mode?
- How are single-page application (SPA) navigations detected (pushState/replaceState)?
- What happens when the native messaging host is not installed?
- How does the extension handle very large pages (100MB+ DOM)?
- What happens when the user has 50+ tabs open (memory/throttling)?
- How are browser-native pages (chrome://, about:, file://) handled?
- What happens when the extension updates and the content script needs to reinitialize?

## Requirements

### Functional Requirements

- **FR-001**: Extension MUST support both Chrome (Manifest V3) and Firefox (Manifest V3 compatible)
- **FR-002**: Extension MUST publish a `url.visited` event on every page navigation with `url`, `title`, `referrer`, `timestamp`
- **FR-003**: Extension MUST publish a `page.content` event with extracted visible text, OpenGraph meta, and page metadata within 5 seconds of page load
- **FR-004**: Extension MUST publish `tab.activated`, `tab.deactivated`, `tab.closed`, `tab.updated` events reflecting tab state changes
- **FR-005**: Extension MUST publish `download.started`, `download.completed` events reflecting browser download state
- **FR-006**: Extension MUST communicate with the local OSAI process via `chrome.runtime.connectNative("com.osai.native-host")` (Chrome nativeMessaging API) — the native host binary translates the browser's framed messages to OSAI's NDJSON over named pipe / Unix socket
- **FR-007**: Extension MUST include a popup UI showing: capture status toggle, recent events list, blocklist management, connection status
- **FR-008**: Extension MUST support a user-configurable blocklist of domains/URLs that are excluded from capture
- **FR-009**: Extension MUST respect incognito mode — no events published from incognito windows unless explicitly enabled by user
- **FR-010**: Extension MUST detect SPA navigations via History API (`pushState`/`replaceState`/`popstate`) and publish corresponding `url.visited` events
- **FR-011**: Extension MUST debounce rapid navigations (redirect chains, 302s) to avoid event storms — maximum 1 `url.visited` per 2 seconds per tab
- **FR-012**: Extension MUST truncate page text content to 10,000 characters to avoid oversized events
- **FR-013**: Extension MUST include an options page for: native messaging host path, capture toggle defaults, blocklist management, data retention preferences
- **FR-014**: Extension MUST publish `browser.session.start` when browser opens and `browser.session.end` on idle timeout or browser close
- **FR-015**: Extension MUST have an icon badge showing: green (active), gray (paused), red (error/disconnected)
- **FR-016**: Extension MUST handle native messaging host disconnection gracefully — buffer events in local storage and replay on reconnection
- **FR-017**: Extension MUST NOT capture authenticated pages (banking, email, etc.) unless explicitly whitelisted by user
- **FR-018**: Extension MUST accept control signals (`enable`, `disable`, `pause`, `resume`) relayed by the native messaging host from the Rust core — see spec 063 for signal format and behavior
- **FR-019**: Extension MUST send a heartbeat to the Rust core every 60 seconds via the native messaging host, containing `events_today` count, `last_event_at`, and any errors — see spec 063 FR-027 for heartbeat format
- **FR-020**: Extension MUST register a `config_schema` at source registration time exposing its blocklist and whitelist as configurables — see spec 063 FR-014
- **FR-021**: Extension MUST provide a "Save to Knowledge Base" context menu item on pages and links — clicking publishes a `kb.save` event with `url`, `title`, `textContent` to the agent host (spec 064) for classification and storage

### Key Entities

- **url.visited**: Event published on page navigation. Payload: `url`, `title`, `referrer`, `timestamp`, `tabId`.
- **page.content**: Event published after page load. Payload: `url`, `title`, `textContent` (truncated), `og` (meta tags), `meta` (keywords, description, author), `wordCount`, `language`.
- **tab.activated/deactivated/closed/updated**: Tab lifecycle events. Payload: `tabId`, `url`, `title`, `activeDuration` (for closed), `pinned`, `audible`.
- **download.started/completed**: Download lifecycle events. Payload: `filename`, `url`, `size`, `mimeType`, `downloadId`.
- **Blocklist**: User-configured list of URL patterns excluded from capture. Stored in `chrome.storage.sync`.
- **Native Messaging Host**: A small Rust executable (`com.osai.native-host`, < 5 MB) installed by the OSAI desktop app. It reads framed JSON from stdin (Chrome's nativeMessaging: 4-byte uint32 LE length prefix + UTF-8 JSON), translates each message to NDJSON, forwards it to the Rust core's named pipe / Unix socket (see protocol spec §7.4), reads the NDJSON response, re-frames it, and writes to stdout. It is registered via OS-level native messaging manifests that the OSAI installer creates.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Extension loads and activates in under 500ms from browser start
- **SC-002**: Page visit to event publish completes in under 2 seconds on a typical page
- **SC-003**: Extension memory usage is under 50MB in normal operation (5-10 tabs)
- **SC-004**: CPU usage is under 1% idle and under 5% during page load processing
- **SC-005**: Content extraction for a 500KB HTML page completes in under 500ms
- **SC-006**: Popup UI opens in under 100ms
- **SC-007**: All events pass protocol schema validation
- **SC-008**: Extension passes Chrome Web Store and Firefox Add-ons review guidelines

## Assumptions

- Manifest V3 for Chrome (MV3 is required by Google after 2024). Firefox also supports MV3
- Native messaging host is a Rust binary (single-file, no runtime dependency) bundled with the OSAI desktop app installer — see protocol spec §7.4 for full transport detail
- Native messaging host path: Windows: `%LOCALAPPDATA%\osai\native-host\com.osai.native-host.exe`, macOS: `/Applications/OSAI.app/Contents/Resources/native-host/com.osai.native-host`, Linux: `/opt/osai/native-host/com.osai.native-host`
- Chrome manifest installed at `HKEY_LOCAL_MACHINE\SOFTWARE\Google\Chrome\NativeMessagingHosts\com.osai.native-host` (Windows) or `/etc/opt/chrome/native-messaging-hosts/com.osai.native-host.json` (macOS/Linux)
- Page text extraction uses `document.body.innerText` with constraints (max length, no script/style content)
- SPA navigation detection uses a MutationObserver + interval poll fallback (since `pushState` can't be intercepted directly in MV3)
- Blocklist supports glob patterns (`*.bank.com`, `mail.google.com/*`)
- Events are buffered in `chrome.storage.local` if native messaging host is unavailable, and flushed when connection is restored
- The extension is distributed via Chrome Web Store and Firefox Add-ons
- Source code lives at `ingestion/browser-extension/` in the monorepo
