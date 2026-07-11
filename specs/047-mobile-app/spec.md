# Feature Specification: Mobile App

**Feature Branch**: `047-mobile-app`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a mobile app with timeline view and basic capture for iOS and Android"

## User Scenarios & Testing

### User Story 1 - Read-Only Timeline on Mobile (Priority: P1)

The mobile app provides a read-only view of the user's timeline. Users can scroll through recent events, filter by source and type, search, and tap events for details. The timeline syncs from the cloud and is available offline (cached recent events). The UI is optimized for mobile touch interaction.

**Why this priority**: The timeline is the most valuable read-only view on mobile. Users can check their activity history from anywhere.

**Independent Test**: Open the mobile app, sign in. Verify the timeline shows events from the last 7 days in reverse chronological order. Tap an event to see full details. Search for a keyword and verify matching events are shown. Go offline, verify the cached timeline is still viewable.

**Acceptance Scenarios**:

1. **Given** the mobile app is signed in, **When** the timeline loads, **Then** the last 7 days of events are displayed with date headers, paginated (50 events per page), optimized for touch scrolling
2. **Given** a timeline event, **When** the user taps it, **Then** a detail view slides up with full event data: timestamp, source, type, content preview, and related entities
3. **Given** the user is offline, **When** they open the app, **Then** cached events from the last 24 hours are viewable with an "Offline — last synced 2h ago" indicator

---

### User Story 2 - Dashboard Overview (Priority: P2)

The mobile app has a dashboard tab showing: today's activity summary (events count, active time, top apps), recent projects, and daily summary (if available from the Summarizer agent). The dashboard is a condensed, mobile-optimized version of the desktop dashboard.

**Why this priority**: The dashboard provides a quick daily overview without needing to scroll through the full timeline.

**Independent Test**: Open the mobile app, navigate to the Dashboard tab. Verify it shows: "Today: 347 events, 2h 15m active" with a breakdown bar showing top apps (VSCode 45%, Chrome 30%, Slack 15%, Other 10%). Verify "Recent Projects" shows the last 3 projects with event counts.

**Acceptance Scenarios**:

1. **Given** the mobile app, **When** the user opens the Dashboard tab, **Then** a condensed activity summary is shown with total events, active time, and top apps (horizontal bar chart)
2. **Given** a daily summary exists, **When** the dashboard loads, **Then** the summary narrative is shown at the top (truncated to 3 lines with "Read more" expand)

---

### User Story 3 - Mobile Capture (Priority: P2)

The mobile app supports basic capture: manual event creation (notes, photos, voice memos, location check-ins), and background capture (app usage tracking, browser history via SafariViewController/Chrome Tabs). Captured events sync to the cloud and appear on the desktop timeline.

**Why this priority**: Mobile capture extends OSAI's reach to on-the-go activity — meetings, locations, voice notes, and spontaneous thoughts.

**Independent Test**: Open the mobile app, tap the "+" button, select "Quick Note", type "Meeting with team about sync protocol", save. Verify the note event appears in the mobile timeline immediately and on the desktop timeline within 30 seconds (after sync).

**Acceptance Scenarios**:

1. **Given** the mobile app, **When** the user creates a Quick Note, **Then** a "note.created" event appears in the timeline with the note content, timestamp, and source "mobile-app"
2. **Given** the mobile app, **When** the user captures a photo and adds a caption, **Then** a "photo.captured" event appears with the photo thumbnail, caption, and location (if available)
3. **Given** the mobile app, **When** the user records a voice memo, **Then** a "voice.memo" event appears with duration and transcription (processed async)

---

### User Story 4 - Background App Usage Tracking (Priority: P3)

The mobile app tracks which apps the user opens and how long they use them (similar to Screen Time). Data is captured locally and synced when online. App names and categories are captured; specific content within apps is only captured with explicit permission.

**Why this priority**: App usage tracking provides activity context even when the specific content within apps isn't accessible.

**Independent Test**: Enable app usage tracking on iOS. Use Safari, Slack, and Notes apps for a few minutes each. Verify the mobile timeline shows: "Used Safari (5m)", "Used Slack (3m)", "Used Notes (2m)" with app icons and total daily time per app on the dashboard.

**Acceptance Scenarios**:

1. **Given** app usage tracking is enabled, **When** the user opens an app, **Then** a "app.usage.started" event is captured with app name and category within 1 minute
2. **Given** the user switches apps or the app goes to background, **When** usage ends, **Then** a "app.usage.ended" event is captured with duration

---

### User Story 5 - Push Notifications and Alerts (Priority: P3)

The mobile app supports push notifications for: daily summary ready, sync issues, permission requests (from agents), and scheduled research results. Notifications are configurable in settings. Tapping a notification opens the relevant view in the app.

**Why this priority**: Push notifications keep users engaged and informed about their OSAI activity without needing to open the app.

**Independent Test**: Enable daily summary notifications. At the scheduled summary time, verify a push notification appears: "Your Daily Summary is ready — 4h 32m active, 3 projects". Tap the notification, verify it opens the dashboard with the daily summary visible.

**Acceptance Scenarios**:

1. **Given** push notifications are enabled, **When** a daily summary is generated, **Then** a push notification is delivered within 1 minute with the summary title and key stats
2. **Given** push notifications are enabled, **When** an agent requests a permission, **Then** a notification appears: "Researcher needs access to your location. Tap to review."

---

### Edge Cases

- What happens when the device has no internet connection?
- How are large photo/video uploads handled (compression, background upload)?
- What happens when the app is killed by the OS (background tasks)?
- How is battery impact minimized?
- What happens when the user has multiple devices syncing?
- How is offline capture queued and synced?
- What happens on low-storage devices?

## Requirements

### Functional Requirements

- **FR-001**: Mobile app MUST provide a read-only timeline of synced events
- **FR-002**: Timeline MUST be paginated (50 events per page) with date grouping
- **FR-003**: Events MUST be searchable by keyword
- **FR-004**: Timeline MUST work offline with cached events (last 24 hours)
- **FR-005**: Mobile app MUST have a dashboard tab with activity summary
- **FR-006**: Mobile app MUST support manual capture: notes, photos, voice memos
- **FR-007**: Captured events MUST sync to the cloud and appear on desktop
- **FR-008**: Mobile app MUST support background app usage tracking (opt-in)
- **FR-009**: App usage events MUST include: app name, category, duration
- **FR-010**: Mobile app MUST support push notifications for: summaries, sync issues, permissions, research results
- **FR-011**: Notifications MUST be configurable per-type in settings
- **FR-012**: Mobile app MUST support dark/light theme following system setting
- **FR-013**: Mobile app MUST support biometric authentication (Face ID / fingerprint)
- **FR-014**: Background sync MUST happen at least every 15 minutes when the app is backgrounded

### Key Entities

- **MobileEvent**: A manually captured mobile event. Attributes: id, type (note/photo/voice/location), content, mediaUrl (photo/voice), duration (voice), location, deviceId, synced (bool), createdAt.
- **AppUsageSession**: A mobile app usage session. Attributes: id, appName, appBundleId, category, startedAt, endedAt, duration, deviceId, synced.
- **CachedTimeline**: Locally cached timeline data. Attributes: events (array of up to 24h), lastSyncAt, userId.

## Success Criteria

### Measurable Outcomes

- **SC-001**: App cold start loads timeline in under 2 seconds
- **SC-002**: Timeline scrolling maintains 60fps
- **SC-003**: Manual capture (note/photo) completes in under 5 seconds
- **SC-004**: Background sync completes within 30 seconds of trigger
- **SC-005**: App battery usage: < 5% per day with background capture enabled
- **SC-006**: App binary size: < 50MB (iOS), < 30MB (Android)

## Assumptions

- Built with React Native or Flutter for cross-platform (iOS + Android)
- Timeline data synced from the cloud sync service (spec 035)
- Offline cache uses SQLite (via React Native SQLite or similar)
- Manual capture uses device APIs: camera, microphone, location services
- Background app usage tracking uses Screen Time API (iOS) or UsageStatsManager (Android)
- Push notifications via Firebase Cloud Messaging (Android) and APNs (iOS)
- Photo uploads are compressed (max 2MB per photo)
- Voice memos are transcribed on the server (whisper or similar)
- Biometric auth uses platform-native APIs (LocalAuthentication on iOS, Biometric on Android)
- Source code lives at `apps/mobile/` in the monorepo