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
- **FR-002**: Events MUST include: title, creator/artist, media type, duration, progress, source (mpv/vlc/plex/jellyfin)
- **FR-003**: VLC connector MUST use VLC's HTTP or RC interface
- **FR-004**: mpv connector MUST use mpv's JSON IPC interface
- **FR-005**: Plex connector MUST use Plex Web API (scrobbling)
- **FR-006**: Jellyfin connector MUST use Jellyfin API
- **FR-007**: Connectors MUST detect media type: movie, episode, music, podcast, other
- **FR-008**: Music events MUST include: artist, album, title, genre, track number
- **FR-009**: Podcast events MUST include: show name, episode title, publisher, publish date
- **FR-010**: Connectors MUST handle player process termination gracefully
- **FR-011**: Progress updates MUST be throttled to at most once per 30 seconds
- **FR-012**: Connectors MUST respect user privacy settings (opt-out for specific players)

### Key Entities

- **MediaEvent**: A media playback event. Attributes: id, type (media.played/media.paused/media.stopped/media.progress/media.chapter), source (mpv/vlc/plex/jellyfin), title, creator, album, duration, progress, mediaType (movie/episode/music/podcast), url, chapter.
- **MediaSession**: A continuous media playback session. Attributes: id, source, mediaId, title, mediaType, startedAt, lastProgressAt, totalPlayedDuration, events (related event IDs).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Playback detection latency: < 5 seconds for local players (mpv/VLC), < 2 minutes for server players (Plex/Jellyfin)
- **SC-002**: Progress update accuracy: within 5 seconds of actual playback position
- **SC-003**: Metadata completeness: 90%+ of events include title and creator
- **SC-004**: Connector CPU usage: < 1% while idle, < 5% while capturing

## Assumptions

- VLC connector uses VLC's HTTP interface (port 8080 by default) or RC interface
- mpv connector uses mpv's JSON IPC (`--input-ipc-server`)
- Plex connector uses Plex's Web API (requires Plex token)
- Jellyfin connector uses Jellyfin's API (requires API key)
- Plex/Jellyfin connectors poll the server API every 30 seconds
- Local connectors (mpv/VLC) are event-driven via IPC
- Media type detection uses file extension, MIME type, and metadata tags
- Privacy: users can configure which players to monitor
- Source code lives at `connectors/media/` in the monorepo, one subdirectory per player