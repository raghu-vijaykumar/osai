# Feature Specification: Media Player Connectors

**Feature Branch**: `044-media-connectors`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build media player connectors for mpv, VLC, Plex, and Jellyfin that capture what the user is watching"

## User Scenarios & Testing

### User Story 1 - Watching Events from Media Players (Priority: P1)

When the user watches or listens to media (video, music, podcast), the connector captures events: media started, media paused, media stopped, chapter/scene change, and progress updates. Events include: title, artist/creator, URL (if applicable), duration, progress, and media type (movie/episode/song/podcast).

**Why this priority**: Media consumption is a significant part of digital activity. Capturing it gives a complete picture of how users spend their time.

**Independent Test**: Open a video in VLC media player, play it for 30 seconds, then close it. Verify an event appears in the timeline: "Watched: Big Buck Bunny (00:00:30 / 00:10:34)" with type "media.played" and source "vlc".

**Acceptance Scenarios**:

1. **Given** VLC is open and playing a video, **When** the connector detects playback, **Then** a "media.played" event is published with title, duration, progress, and media type within 10 seconds
2. **Given** the user pauses media, **When** the connector detects the pause, **Then** a "media.paused" event is published with the current progress
3. **Given** the user skips to a different chapter/scene, **When** the connector detects the change, **Then** a "media.chapter" event is published with the new chapter info

---

### User Story 2 - Plex/Jellyfin Scrobbling (Priority: P2)

The connector integrates with Plex and Jellyfin media servers via their APIs. It tracks what's being watched across all devices on the server, including: user, device, media item, progress, and watch time. This works even when streaming to a smart TV or other non-computer device.

**Why this priority**: Plex/Jellyfin users watch media on TVs and streaming devices. Server-side integration captures this activity without needing a client-side connector.

**Independent Test**: Watch a movie on Plex via a smart TV. Verify an event appears in the timeline: "Watched: Inception (01:20:00 / 02:28:00)" with source "plex" within 2 minutes of starting. Verify the event includes the progress and watch duration.

**Acceptance Scenarios**:

1. **Given** Plex/Jellyfin server is configured with the connector, **When** a user starts playing media on any device, **Then** a "media.played" event is published within 2 minutes with source "plex" or "jellyfin"
2. **Given** media is playing on Plex/Jellyfin, **When** the connector polls for status, **Then** progress updates are published every 5 minutes as "media.progress" events

---

### User Story 3 - mpv IPC Integration (Priority: P2)

The mpv connector uses mpv's JSON IPC interface to get real-time playback information. It captures: file path, title, time position, duration, pause state, and playback speed. The connector starts automatically with mpv (via `--input-ipc-server`) or runs as a background watcher.

**Why this priority**: mpv is popular among power users and developers. Its IPC interface enables high-quality, low-latency capture.

**Independent Test**: Launch mpv with `mpv --input-ipc-server=/tmp/mpv-socket video.mp4`. Verify an event appears: "Watched: video.mp4 (00:00:00 / 01:30:00)" with source "mpv". Pause and resume, verify pause/resume events are captured.

**Acceptance Scenarios**:

1. **Given** mpv is running with an IPC socket, **When** a file starts playing, **Then** the connector publishes a "media.played" event with the file path and title within 3 seconds
2. **Given** mpv playback is paused, **When** the connector detects the state change, **Then** a "media.paused" event is published with current position

---

### User Story 4 - Music and Podcast Detection (Priority: P3)

The connectors detect the media type (movie, episode, music, podcast) and capture appropriate metadata. For music: artist, album, track title, genre. For podcasts: show name, episode title, publisher. Metadata is extracted from file tags, API responses, or the media player's now-playing info.

**Why this priority**: Different media types have different metadata. Music and podcasts benefit from rich metadata for better search and recommendations.

**Independent Test**: Play a music file in VLC. Verify the event shows: "Listened: Song Title by Artist (Album Name)" with type "media.music" and includes artist, album, and genre fields. Play a podcast episode on Plex, verify it shows as "media.podcast" with show name and episode title.

**Acceptance Scenarios**:

1. **Given** a music file is played, **When** the connector captures the event, **Then** the event type is "media.music" and includes artist, album, title, genre, and track number
2. **Given** a podcast episode is played via Plex, **When** the connector captures it, **Then** the event type is "media.podcast" and includes show name, episode title, publisher, and publish date

---

### Edge Cases

- What happens when the media player is closed abruptly?
- How are very long media sessions handled (e.g., 10-hour music playlist)?
- What happens when multiple media players are running simultaneously?
- How is private/incognito media viewing handled?
- What happens when the media file has no metadata tags?
- How are ads or non-content segments filtered?
- What happens when Plex/Jellyfin requires authentication?

## Requirements

### Functional Requirements

- **FR-001**: Connectors MUST capture media playback events: started, paused, stopped, progress, chapter change
- **FR-002**: Events MUST include: title, creator/artist, media type, duration, progress, source, and player app (e.g., `com.videolan.vlc`)
- **FR-003**: Each connector MUST communicate with its player via the player's documented IPC or API protocol
- **FR-004**: Progress updates MUST be throttled to at most once per 30 seconds
- **FR-005**: Connectors MUST handle player process termination gracefully (process exit, crash, kill)
- **FR-006**: Connectors MUST detect media type: movie, episode, music, podcast, other
- **FR-007**: Music events MUST include: artist, album, title, genre, track number
- **FR-008**: Podcast events MUST include: show name, episode title, publisher, publish date
- **FR-009**: Connectors MUST respect user privacy settings (opt-out for specific players)
- **FR-010**: Each connector MUST register as its own source via the Context Protocol and publish events through the `@osai/protocol` SDK over named pipe / Unix socket
- **FR-011**: Each connector MUST accept control signals (`enable`, `disable`, `pause`, `resume`) from the Rust core via IPC — see spec 063. On `disable`, stop all player polling and drop timers. On `pause`, stop publishing new media events (may buffer last known state). On `resume`, resume polling and publishing.
- **FR-012**: Each connector MUST send a heartbeat to the Rust core every 60 seconds via IPC, containing `events_today`, `last_event_at`, `players_detected`, and any errors — see spec 063 FR-027
- **FR-013**: Each connector MAY register a `config_schema` at source registration time exposing its player-specific settings (e.g., VLC port, Plex webhook URL) as configurables — see spec 063 FR-014

### Per-Tool Connector Specifications

#### VLC

| Property | Detail |
|----------|--------|
| **App ID** | `com.videolan.vlc` |
| **Integration method** | VLC HTTP remote control API (built into VLC, no plugin needed) |
| **Setup** | User enables "Web interface" in VLC settings → Tools > Preferences > Main interfaces > Web. Default port: `8080`. Optional: password. |
| **API used** | HTTP GET `http://127.0.0.1:8080/requests/status.xml` — returns XML with `state` (playing/paused/stopped), `information` (title, artist, album), `time` (current position seconds), `length` (duration) |
| **Polling** | Every 5 seconds when VLC process is detected running |
| **Events published** | `media.played`, `media.paused`, `media.stopped`, `media.progress` |
| **Process detection** | Scan running processes for `vlc.exe` (Windows), `VLC` (macOS), `vlc` (Linux) |
| **Complexity** | ~150 lines — HTTP client + XML parser + state machine |

#### mpv

| Property | Detail |
|----------|--------|
| **App ID** | `com.mpv.player` |
| **Integration method** | mpv built-in JSON IPC (`--input-ipc-server=<path>`) — no plugin needed |
| **Setup** | User adds to `mpv.conf`: `input-ipc-server=/tmp/mpv-socket` (Linux/macOS) or `\\.\pipe\mpv-pipe` (Windows). Or the OSAI installer creates a wrapper script that starts mpv with the flag. |
| **API used** | JSON command/response over Unix socket or named pipe. Send `{"command": ["get_property", "playback-time"]}`, receive `{"data": 123.45, "error": "success"}`. Properties: `filename`, `metadata` (title, artist, album), `media-title`, `duration`, `playback-time`, `pause`, `chapter`. |
| **Polling** | Push-based — mpv sends observe_property events. Fallback: poll every 5 seconds. |
| **Events published** | `media.played`, `media.paused`, `media.stopped`, `media.progress`, `media.chapter` |
| **Process detection** | Scan for `mpv.exe`/`mpv` process OR connect to the IPC socket |
| **Complexity** | ~200 lines — JSON socket client + property observer |

#### Plex

| Property | Detail |
|----------|--------|
| **App ID** | `com.plex.plex` |
| **Integration method** | Plex Webhook (sends POST to a configured URL when playback starts/stops) + Plex API polling for progress |
| **Setup** | User creates a webhook in Plex Settings > Webhooks > Add: `http://127.0.0.1:8400/plex-webhook`. The OSAI media connector runs a tiny HTTP server on port 8400. |
| **API used** | Webhook payload format: `{"event": "media.play"|"media.pause"|"media.resume"|"media.stop"|"media.scrobble", "Metadata": {"title", "grandparentTitle" (show), "artist", "album", "type" (episode/movie/track), "duration", "guid", "librarySectionType"}}`. API: `GET /library/metadata/{ratingKey}` for current progress polling. |
| **Polling** | Webhook fires on play/pause/stop events. Status polling every 30 seconds for progress (API via `GET /status/sessions`). |
| **Events published** | `media.played`, `media.paused`, `media.stopped`, `media.progress` |
| **Auth** | Plex token from Plex Settings > Your Account > Plex Web > Token. Stored via OS keychain (spec 003 FR-059). |
| **Complexity** | ~300 lines — HTTP webhook receiver + Plex API client |

#### Jellyfin

| Property | Detail |
|----------|--------|
| **App ID** | `org.jellyfin.jellyfin` |
| **Integration method** | Jellyfin Webhook plugin (community plugin) + Jellyfin API polling |
| **Setup** | User installs Jellyfin Webhook plugin, creates a webhook pointing to `http://127.0.0.1:8400/jellyfin-webhook` |
| **API used** | Webhook JSON payload with `NotificationType` (PlaybackStart/PlaybackStop/PlaybackProgress) and `Item` (Name, SeriesName, Artists, Album, Type, RunTimeTicks). API: `GET /Users/{userId}/Items/{itemId}` for metadata, `GET /Sessions` for active sessions. |
| **Polling** | Webhook + status polling every 30 seconds via `/Sessions` endpoint |
| **Events published** | `media.played`, `media.paused`, `media.stopped`, `media.progress` |
| **Auth** | Jellyfin API key from Dashboard > API Keys. Stored via OS keychain. |
| **Complexity** | ~300 lines — HTTP webhook receiver + Jellyfin API client |

#### Spotify

| Property | Detail |
|----------|--------|
| **App ID** | `com.spotify.client` |
| **Integration method** | Spotify Web API `currently-playing` endpoint |
| **Setup** | User authorizes via OAuth — the OSAI desktop app opens a Spotify OAuth flow, gets a refresh token. The token is stored in the OS keychain. |
| **API used** | `GET https://api.spotify.com/v1/me/player/currently-playing` — returns `item` (name, artists, album, duration_ms), `progress_ms`, `is_playing`, `currently_playing_type` (track/episode/ad). |
| **Polling** | Every 10 seconds. Ad segments (type=ad) are filtered out. |
| **Events published** | `media.played`, `media.paused`, `media.stopped`, `media.progress` |
| **Auth** | OAuth 2.0 with refresh token. Scopes: `user-read-playback-state`, `user-read-currently-playing`. |
| **Limitations** | Spotify API only returns current playback state — no chapter support, no local file playback, no history for offline periods. |
| **Complexity** | ~250 lines — OAuth token manager + REST API poller |

### Key Entities

- **MediaEvent**: A media playback event. Attributes: id, type (media.played/media.paused/media.stopped/media.progress/media.chapter), source (com.videolan.vlc/com.mpv.player/com.plex.plex/org.jellyfin.jellyfin/com.spotify.client), title, creator, album, duration, progress, mediaType (movie/episode/music/podcast), url, chapter.
- **MediaSession**: A continuous media playback session. Attributes: id, source, mediaId, title, mediaType, startedAt, lastProgressAt, totalPlayedDuration, events (related event IDs).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Playback detection latency: < 5 seconds for local players (mpv/VLC), < 2 minutes for server players (Plex/Jellyfin)
- **SC-002**: Progress update accuracy: within 5 seconds of actual playback position
- **SC-003**: Metadata completeness: 90%+ of events include title and creator
- **SC-004**: Connector CPU usage: < 1% while idle, < 5% while capturing

## Assumptions

- All connectors run as part of a single Node.js sidecar process (`connectors/media/`)
- The sidecar connects to the Rust core via `@osai/protocol` SDK over named pipe / Unix socket
- VLC HTTP interface must be enabled by user (single checkbox in VLC settings). OSAI installer can automate this on first run by writing to VLC's config file (`vlcrc`: `http-host=127.0.0.1`, `http-port=8080`).
- mpv IPC socket is configured by the OSAI installer via a wrapper script or `mpv.conf` drop-in (`input-ipc-server=/tmp/mpv-socket`)
- Plex/Jellyfin webhooks point to a local HTTP server on port 8400 that the media connector sidecar runs
- All cloud credentials (Plex token, Jellyfin API key, Spotify refresh token) are stored in the OS keychain — see spec 003 FR-059
- Source code lives at `connectors/media/` in the monorepo, one subdirectory per player