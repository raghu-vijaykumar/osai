# Feature Specification: Auto-Update

**Feature Branch**: `060-auto-update`

**Created**: 2026-07-11

**Status**: Draft

## Overview

OSAI uses Tauri's built-in updater with GitHub Releases as the update server. The system supports three release channels (stable, beta, nightly), code-signed binaries, percentage-based rollout, and automatic rollback on crash.

## User Scenarios & Testing

### User Story 1 - Silent Background Update (Priority: P1)

When an update is available and the user has auto-update enabled, the app downloads the update in the background. Once downloaded, a toast notification appears: "Update ready — restart to apply v1.2.0". The user can click to restart now or dismiss to install on next launch. Downloads resume if interrupted.

**Independent Test**: Enable auto-update. Wait for a pending update notification. Verify the toast appears. Verify clicking "Restart" closes and reopens the app. Verify dismissing defers to next launch.

**Acceptance Scenarios**:

1. **Given** a new version is published on GitHub Releases, **When** the app checks for updates (every 6 hours), **Then** the update metadata is fetched in the background without blocking the UI
2. **Given** an update is downloading, **When** the user quits the app, **Then** the download resumes on next launch (range requests)
3. **Given** an update is downloaded, **When** the user clicks "Restart", **Then** the app closes, runs the installer, and reopens within 15 seconds
4. **Given** auto-update is disabled, **When** an update is available, **Then** a badge appears on the settings menu with no background download

### User Story 2 - Manual Check (Priority: P1)

Users can check for updates manually via Settings > Updates > "Check for Updates". This displays the current version, latest available version, changelog (fetched from GitHub Releases body), and a "Download & Install" button. If already up to date, a green "Up to date" indicator is shown.

**Independent Test**: Navigate to Settings > Updates. Verify current version and latest version are shown. Verify clicking "Check for Updates" fetches fresh data. Verify the changelog renders markdown from the GitHub release body.

**Acceptance Scenarios**:

1. **Given** the user opens Settings > Updates, **When** the page loads, **Then** current version and latest available version are displayed with timestamps
2. **Given** the app is up to date, **When** checking for updates, **Then** a green checkmark + "Up to date" is shown with the last-checked timestamp
3. **Given** an update is available, **When** viewing the update page, **Then** the GitHub release body is rendered as formatted changelog with headings, lists, and links

### User Story 3 - Release Channels (Priority: P2)

Users can opt into beta or nightly release channels in Settings. Stable channel receives updates every 2–4 weeks. Beta receives updates weekly (release candidates). Nightly receives builds from the latest `main` branch (may be unstable). Channel descriptions explain the trade-offs.

**Independent Test**: Switch to "Beta" channel. Verify an update prompt appears (or "up to date" for current beta). Switch to "Nightly" channel. Verify the update check uses the new channel's release tag pattern. Switch back to "Stable".

**Acceptance Scenarios**:

1. **Given** the current channel is "Stable", **When** the user switches to "Beta", **Then** a confirmation dialog warns: "Beta releases are feature-complete but not fully tested. You can switch back to Stable anytime."
2. **Given** the current channel is "Nightly", **When** the app checks for updates, **Then** it uses the nightly release tag format (`nightly-YYYYMMDD-*`)
3. **Given** the user switches from "Nightly" back to "Stable", **Then** the app may prompt to downgrade with a warning if the stable version is older

### User Story 4 - Rollout Percentage & Rollback (Priority: P2)

Updates can be rolled out gradually. The app checks its `device_id` against a rollout percentage embedded in the release metadata. If the device is not in the rollout, it shows "Update pending — rolling out gradually". If the app crashes twice within 5 minutes of update, the update is rolled back automatically.

**Independent Test**: Create a release with rollout percentage set to 0%. Verify the app shows "Update pending — rolling out gradually". Set rollout to 100%. Verify the update becomes available.

**Acceptance Scenarios**:

1. **Given** a release with `rollout_percentage: 25`, **When** the app checks, **Then** hash(device_id) % 100 < 25 determines eligibility
2. **Given** an app that was just updated, **When** it crashes twice within 5 minutes, **Then** on third launch the previous version is restored automatically
3. **Given** a rollback occurred, **When** the app launches, **Then** a toast says "Previous version restored due to instability" with option to report feedback

### Edge Cases

- What happens when the update server is unreachable (no internet)?
- How are large update files handled on metered connections?
- What happens if the user has unsaved work when "Restart" is clicked?
- How are updates handled on Linux (AppImage auto-update vs. package manager)?
- What happens when the code signing certificate expires?
- How are macOS notarization failures handled?

## Requirements

### Functional Requirements

- **FR-001**: App MUST check for updates on launch and every 6 hours thereafter (configurable interval)
- **FR-002**: Update download MUST happen in the background without blocking the UI
- **FR-003**: App MUST support three release channels: stable, beta, nightly
- **FR-004**: Channel selection MUST be persisted in app settings
- **FR-005**: Update metadata MUST be fetched from GitHub Releases (tag-based: `v{major}.{minor}.{patch}`, `beta-{version}`, `nightly-{YYYYMMDD}-{sha}`)
- **FR-006**: Release metadata MUST include: version, platform-specific download URLs, signature, changelog (release body in markdown), rollout_percentage (0–100)
- **FR-007**: App MUST verify the update signature against the embedded public key before installing
- **FR-008**: Update installation MUST be atomic — if install fails, the previous version is preserved
- **FR-009**: App MUST support crash rollback — track crash count post-update, auto-revert after 2 crashes in 5 minutes
- **FR-010**: Download MUST support resume (HTTP range requests) for interrupted downloads
- **FR-011**: Update UI MUST show: current version, latest version, changelog, download progress bar, channel label
- **FR-012**: Users MUST be able to defer updates — "Install on next launch" option
- **FR-013**: Manual "Check for Updates" button MUST be in Settings
- **FR-014**: App MUST detect metered connections and prompt before downloading large updates (>50MB)
- **FR-015**: Update MUST NOT interrupt the user during fullscreen mode — defer to exit

### Key Entities

- **UpdateManifest**: The update metadata from GitHub Releases. Attributes: version (semver), platform (win32/darwin/linux), url (download URL), signature (hex), rollout_percentage (0–100), changelog (markdown), channel (stable/beta/nightly), release_date (ISO 8601).
- **UpdateState**: Current update state. Attributes: status (idle/checking/available/downloading/downloaded/installing/error), progress (0–100), currentVersion, latestVersion, channel.
- **ReleaseChannel**: A named release track. Attributes: name (stable/beta/nightly), description, tagPrefix (e.g. "v", "beta-", "nightly-"), stability (stable/rc/unstable).

## Success Criteria

- **SC-001**: Background update check completes in under 2 seconds (metadata only)
- **SC-002**: Update download saturates available bandwidth (measured: >80% of connection speed)
- **SC-003**: Update install + restart completes in under 15 seconds
- **SC-004**: App never blocks the UI during update operations
- **SC-005**: Crash rollback catches 100% of update-induced crashes (2-strike rule)
- **SC-006**: Update icon/badge responds within 100ms

## Assumptions

- GitHub Releases is the update server (no custom backend)
- Tauri updater plugin (`tauri-plugin-updater`) handles the core flow
- Code signing: Windows Authenticode (EV cert), macOS Developer ID notarization
- Linux: AppImage with built-in update mechanism (or direct binary replacement)
- Release artifacts are generated by CI (`.github/workflows/release.yml`)
- Public key for signature verification is bundled with the app
- Rollout percentage is deterministic per device_id — no server-side tracking needed
- Metered connection detection uses the OS network API (Windows: `NetworkInformation`, macOS: `SCNetworkReachabilityFlagsIsWWAN`)

## Dependencies

- Depends on spec 003 (monorepo) for CI release pipeline
- Depends on spec 037 (user accounts) if user-specific channel preferences are synced
