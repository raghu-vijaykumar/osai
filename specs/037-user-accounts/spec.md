# Feature Specification: User Accounts & Authentication

**Feature Branch**: `037-user-accounts`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Implement user accounts and authentication for cloud sync and premium features"

## User Scenarios & Testing

### User Story 1 - Account Creation and Sign-In (Priority: P1)

Users can create an account with email and password, or sign in with Google/GitHub OAuth. Account creation requires email verification. Password reset is supported via email. Sessions persist across app restarts. The account is optional — OSAI works fully offline without one.

**Why this priority**: Accounts are required for cloud features (sync, backup). Making them optional respects OSAI's local-first philosophy.

**Independent Test**: Open OSAI settings, navigate to "Account" tab. Verify "Sign In" and "Create Account" options are shown. Create an account with email+password, verify email verification email is sent. Verify sign-in works and session persists across app restart. Verify all features continue to work when signed out.

**Acceptance Scenarios**:

1. **Given** the user has no account, **When** they navigate to Account settings, **Then** they see "Sign In" and "Create Account" options with Google, GitHub, and email+password methods
2. **Given** the user creates an account with email+password, **When** they submit the form, **Then** a verification email is sent and the account is in "unverified" state until the email link is clicked
3. **Given** the user signs in, **When** they restart the app, **Then** the session is restored without requiring re-authentication

---

### User Story 2 - Account Settings and Profile (Priority: P2)

Users can manage their account settings: profile (name, avatar), email preferences (notification settings), connected accounts (Google, GitHub OAuth links), security (password change, 2FA), and data management (export all data, delete account). Account deletion is a two-step confirmation process with a 7-day grace period.

**Why this priority**: Account management is standard functionality. Data export and deletion are required for data portability compliance.

**Independent Test**: Open Account Settings, navigate to Security tab, change password. Verify the new password works on next sign-in. Navigate to Data Management, click "Export All Data", verify a download starts with a .zip file containing all events, entities, and settings in JSON format. Click "Delete Account", verify a confirmation dialog appears, confirm, and verify the account is scheduled for deletion with a 7-day cancellation option.

**Acceptance Scenarios**:

1. **Given** the user is signed in, **When** they navigate to Account Settings, **Then** they can update their name, avatar, and email preferences
2. **Given** the user clicks "Delete Account", **When** they confirm, **Then** the account is deactivated immediately with a 7-day grace period during which they can cancel deletion
3. **Given** the user requests data export, **When** the export is ready, **Then** a .zip file is downloaded containing all user data in machine-readable format (JSON)

---

### User Story 3 - Session and Token Management (Priority: P2)

The auth system manages sessions and API tokens. Sessions are visible in account settings: current session (this device), other active sessions, and the ability to revoke sessions. Users can create API tokens (for CLI and integrations) with scoped permissions and expiration dates.

**Why this priority**: Session management is essential for security. Users need visibility into active sessions and the ability to revoke access.

**Independent Test**: Sign in on two devices. On device A, go to Account Settings > Sessions. Verify both sessions are listed. Revoke device B's session. Verify device B is signed out on its next API call. Create an API token with "read:events" scope and 30-day expiration. Use the token to authenticate a CLI command and verify it works. After 30 days, verify the token is rejected.

**Acceptance Scenarios**:

1. **Given** multiple active sessions, **When** the user views Sessions, **Then** all sessions are listed with device name, last active time, and a "Revoke" button
2. **Given** a session is revoked, **When** the revoked device makes an API request, **Then** it receives a 401 Unauthorized response
3. **Given** the user creates an API token, **When** they specify scope and expiration, **Then** the token is generated with those restrictions and shown once (with a "Copy" button)

---

### User Story 4 - Two-Factor Authentication (Priority: P3)

Users can enable two-factor authentication (2FA) via authenticator app (TOTP). Setup involves scanning a QR code with an authenticator app (Google Authenticator, Authy, 1Password). Backup codes are provided for recovery. 2FA can be disabled with password confirmation.

**Why this priority**: 2FA significantly improves account security for users who store sensitive data in the cloud.

**Independent Test**: Enable 2FA in Security settings. Verify a QR code is displayed. Scan with an authenticator app and enter the generated code. Verify 2FA is enabled. Sign out and sign in again. Verify the 2FA code is required after entering email+password. Use a backup code to sign in, then verify that backup code is marked as used.

**Acceptance Scenarios**:

1. **Given** the user enables 2FA, **When** they scan the QR code and enter a valid TOTP code, **Then** 2FA is enabled and backup codes are displayed with a "Download" button
2. **Given** 2FA is enabled, **When** the user signs in, **Then** after entering email+password, a TOTP input field is shown
3. **Given** the user loses access to their authenticator app, **When** they enter a backup code, **Then** they are signed in and the backup code is marked as used (each code can be used once)

---

### User Story 5 - Offline Authentication and Local Mode (Priority: P3)

OSAI works fully offline without an account. When the user creates or signs into an account, local data is optionally merged with cloud data. The auth system handles offline scenarios: cached credentials, token refresh when online, and graceful degradation when the auth service is unreachable.

**Why this priority**: Local-first means accounts must never be a requirement. Authentication should degrade gracefully without blocking local functionality.

**Independent Test**: Use OSAI for a week without an account — all features work. Then create an account and sign in. Verify local data is preserved and optionally offered for sync. Disconnect the network, verify the app continues working (cached session). Reconnect, verify the session refreshes automatically.

**Acceptance Scenarios**:

1. **Given** the user is not signed in, **When** they use OSAI, **Then** all local features (capture, timeline, knowledge engine, agents) work without any account requirement
2. **Given** the user signs in while offline, **When** credentials are cached, **Then** the app accepts the cached sign-in and syncs when online
3. **Given** the user signs in with existing local data, **When** the account is created, **Then** the user is prompted: "You have local data — would you like to sync it to the cloud?" with "Sync" and "Keep Local Only" options

---

### Edge Cases

- What happens when the auth service is down during sign-in?
- How are OAuth provider outages handled?
- What happens when a user's email is already registered (social sign-in vs. email)?
- How are very long sessions handled (token rotation)?
- What happens when a user unlinks their only OAuth provider with no password set?
- How are brute-force login attempts mitigated?
- What happens when the user's 2FA device is permanently lost (no backup codes)?

## Requirements

### Functional Requirements

- **FR-001**: Users MUST be able to create an account with email + password
- **FR-002**: Users MUST be able to sign in with Google and GitHub OAuth
- **FR-003**: Email verification MUST be required before cloud features are enabled
- **FR-004**: Password reset MUST be supported via email
- **FR-005**: An account MUST NOT be required for local OSAI functionality
- **FR-006**: Users MUST be able to view and manage their profile (name, avatar)
- **FR-007**: Users MUST be able to change their password
- **FR-008**: Users MUST be able to delete their account (with 7-day grace period)
- **FR-009**: Account deletion MUST include option to export data before deletion
- **FR-010**: Users MUST be able to export all their data (JSON format, .zip archive)
- **FR-011**: Users MUST be able to view and revoke active sessions
- **FR-012**: Users MUST be able to create scoped API tokens with expiration
- **FR-013**: Two-factor authentication (TOTP) MUST be supported
- **FR-014**: 2FA backup codes MUST be provided on setup (10 codes, single-use)
- **FR-015**: Offline authentication MUST work via cached session tokens
- **FR-016**: Token refresh MUST happen automatically when online
- **FR-017**: Existing local data MUST be preserved and optionally synced on account creation
- **FR-018**: Rate limiting MUST be applied to sign-in attempts (5 attempts per 15 minutes)

### Key Entities

- **User**: A user account. Attributes: id, email, name, avatarUrl, emailVerified, createdAt, twoFactorEnabled, status (active/deactivated/scheduled-for-deletion).
- **Session**: An authenticated session. Attributes: id, userId, deviceId, deviceName, refreshToken (hashed), expiresAt, createdAt, lastActiveAt.
- **ApiToken**: A scoped API token. Attributes: id, userId, name, token (hashed prefix), scope (array of permissions), expiresAt, lastUsedAt, createdAt.
- **OAuthConnection**: A linked OAuth provider. Attributes: id, userId, provider (google/github), providerAccountId, email, linkedAt.
- **BackupCode**: A 2FA recovery code. Attributes: id, userId, code (hashed), used (bool), usedAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Account creation completes in under 3 seconds (including email sending)
- **SC-002**: Sign-in completes in under 1 second (API + token generation)
- **SC-003**: Session refresh completes in under 500ms
- **SC-004**: Data export of 100MB generates and downloads in under 5 minutes
- **SC-005**: 2FA setup completes in under 10 seconds (QR code + verification)
- **SC-006**: Brute-force protection blocks >99% of automated attacks (rate limiting)
- **SC-007**: Auth service uptime: 99.9% (excluding planned maintenance)

## Assumptions

- Auth service built as a separate cloud service (or uses a third-party auth provider like Clerk/Auth0)
- Email delivery via a transactional email service (Resend, SendGrid, AWS SES)
- OAuth via Google and GitHub (extensible to more providers)
- Sessions use JWT with refresh tokens (short-lived access token: 15min, long-lived refresh: 30 days)
- API tokens are hashed on storage (only prefix visible to user)
- 2FA TOTP follows the standard RFC 6238 (30-second window, 6 digits)
- Backup codes are generated client-side, hashed before storage
- Auth service is separate from the sync service for security isolation
- Rate limiting uses a token bucket per IP + per user
- Source code lives at `services/auth/` in the monorepo