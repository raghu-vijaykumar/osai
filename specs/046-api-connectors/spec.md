# Feature Specification: API Connectors

**Feature Branch**: `046-api-connectors`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build API connectors for Slack, Notion, GitHub, Linear, and Google services to capture external activity"

## User Scenarios & Testing

### User Story 1 - GitHub Activity Capture (Priority: P1)

The GitHub connector captures activity across GitHub: commits pushed, PRs opened/closed/reviewed, issues created/commented, and repository stars. Events include full context: repo name, branch, PR/issue title, and relevant code snippets (for commits). Authentication via GitHub OAuth or personal access token.

**Why this priority**: GitHub is a primary platform for developer activity. Capturing it provides rich context about coding work, code reviews, and project management.

**Independent Test**: Connect GitHub account to OSAI. Push a commit to a repository, open a PR, and comment on an issue. Verify events appear: "Pushed 3 commits to osai/main: 'Fix sync bug', 'Add tests', 'Update docs'", "Opened PR #42: 'Add E2E encryption'", "Commented on issue #15: 'I think this is a CRDT issue'". Verify each event links to the GitHub URL.

**Acceptance Scenarios**:

1. **Given** GitHub is connected via OAuth, **When** the user pushes commits, **Then** "github.push" events appear within 2 minutes with repo, branch, commit messages, and author
2. **Given** GitHub is connected, **When** a PR is opened or reviewed, **Then** "github.pr.opened" or "github.pr.reviewed" events appear with PR title, description, and files changed
3. **Given** a GitHub event, **When** the user clicks the event, **Then** it opens the relevant GitHub URL in the browser

---

### User Story 2 - Slack Activity Capture (Priority: P2)

The Slack connector captures: messages sent in channels the user participates in, thread replies, reactions, file uploads, and channel joins/leaves. Events include channel name, message preview, thread context, and workspace name. The connector respects Slack's 90-day message history limit for free workspaces.

**Why this priority**: Slack is a primary communication tool. Capturing work conversations provides context about decisions, discussions, and collaboration.

**Independent Test**: Connect Slack workspace to OSAI. Send a message in a channel, reply in a thread, and react to a message. Verify events: "Sent message in #engineering: 'The sync protocol is ready for review'", "Replied in thread in #engineering", "Reacted with 🚀 to message in #general". Verify private channels are excluded by default.

**Acceptance Scenarios**:

1. **Given** Slack is connected, **When** the user sends a message, **Then** a "slack.message" event appears within 2 minutes with channel name, message preview (first 200 chars), and workspace name
2. **Given** Slack is connected, **When** the user receives a direct message, **Then** a "slack.dm" event appears with the sender's name and message preview
3. **Given** Slack connection, **When** the connector syncs, **Then** private channels are excluded by default (user can opt-in per channel)

---

### User Story 3 - Notion Activity Capture (Priority: P2)

The Notion connector captures: pages viewed, pages edited, comments added, and database interactions. Events include page title, parent page/database, workspace name, and content preview. The connector uses the Notion API with OAuth.

**Why this priority**: Notion is widely used for documentation, project management, and knowledge management. Capturing Notion activity connects documentation work to development activity.

**Independent Test**: Connect Notion to OSAI. View a page, edit a page, and add a comment. Verify events: "Viewed page: 'System Architecture' in 'OSAI Docs'", "Edited page: 'API Reference'", "Commented on page: 'Meeting Notes'". Verify the events include workspace name and page URL.

**Acceptance Scenarios**:

1. **Given** Notion is connected, **When** the user views a page, **Then** a "notion.page.viewed" event appears with page title, parent, workspace, and URL within 2 minutes
2. **Given** Notion is connected, **When** the user edits a page, **Then** a "notion.page.edited" event appears with the page title and a summary of changes (if available via API)

---

### User Story 4 - Linear Activity Capture (Priority: P3)

The Linear connector captures: issues created/updated/completed, comments added, sprint changes, and project updates. Events include: issue title, team, project, sprint, status, and priority. The connector uses the Linear GraphQL API with OAuth.

**Why this priority**: Linear is a popular issue tracker for startups and tech teams. Capturing issue activity connects task management to development context.

**Independent Test**: Connect Linear to OSAI. Create an issue, update its status, and add a comment. Verify events: "Created issue: 'Implement CRDT merge' in OSAI/Backend (priority: High)", "Updated issue status: 'Implement CRDT merge' → In Progress", "Commented on issue: 'Implement CRDT merge'".

**Acceptance Scenarios**:

1. **Given** Linear is connected, **When** an issue is created, **Then** a "linear.issue.created" event appears with title, team, project, priority, and assignee within 2 minutes
2. **Given** Linear is connected, **When** the user completes an issue, **Then** a "linear.issue.completed" event appears with the issue title and cycle/sprint info

---

### User Story 5 - Google Services Capture (Priority: P3)

Google connectors capture activity from: Gmail (email sent/received, label changes), Google Calendar (events created/attended, meeting details), Google Drive (files created/modified, shared), and Google Docs (documents edited, comments). Each Google service is a separate OAuth scope that users can selectively enable.

**Why this priority**: Google services are deeply integrated into many users' workflows. Email, calendar, and docs capture provides rich context about meetings, communications, and document work.

**Independent Test**: Connect Gmail to OSAI. Send an email and receive an email. Verify events: "Sent email to: 'Team' — Subject: 'Sprint review tomorrow'" and "Received email from: 'Alice' — Subject: 'RE: Architecture decisions'". Connect Google Calendar and verify a meeting event appears: "Attended: 'Sprint Planning' (10:00-11:00 AM)".

**Acceptance Scenarios**:

1. **Given** Gmail is connected, **When** the user sends an email, **Then** a "gmail.sent" event appears with recipients (domains only, not full emails for privacy), subject, and preview within 5 minutes
2. **Given** Google Calendar is connected, **When** a calendar event starts, **Then** a "calendar.event" event appears with event title, duration, and attendees (count only) within 5 minutes of the event start
3. **Given** multiple Google scopes are available, **When** the user configures the connector, **Then** they can selectively enable/disable Gmail, Calendar, Drive, and Docs independently

---

### Edge Cases

- What happens when API rate limits are hit?
- How are OAuth token refreshes handled?
- What happens when a service is temporarily unavailable?
- How is private/sensitive content handled (private repos, DMs, private channels)?
- What happens when the user revokes OAuth access?
- How are very active users handled (Slack power users sending 1000+ messages/day)?
- What happens when multiple users access the same shared resource?

## Requirements

### Functional Requirements

- **FR-001**: Each API connector MUST authenticate via OAuth 2.0
- **FR-002**: GitHub connector MUST capture: push, PR (open/close/review), issue (create/comment), star
- **FR-003**: GitHub events MUST include: repo, branch, title/description, URL, timestamp
- **FR-004**: Slack connector MUST capture: messages, thread replies, reactions, file uploads
- **FR-005**: Slack events MUST include: channel, workspace, message preview, thread info
- **FR-006**: Slack connector MUST exclude private/DM channels by default
- **FR-007**: Notion connector MUST capture: page views, edits, comments
- **FR-008**: Notion events MUST include: page title, parent, workspace, URL
- **FR-009**: Linear connector MUST capture: issue (create/update/complete), comments, sprint changes
- **FR-010**: Linear events MUST include: issue title, team, project, status, priority
- **FR-011**: Google connectors MUST support: Gmail, Calendar, Drive, Docs
- **FR-012**: Google scopes MUST be independently selectable by the user
- **FR-013**: All connectors MUST handle OAuth token refresh automatically
- **FR-014**: All connectors MUST respect API rate limits (exponential backoff, queuing)
- **FR-015**: Sensitive content MUST be handled according to user privacy settings
- **FR-016**: Connectors MUST poll for new events at configurable intervals (default: 2 minutes)

### Key Entities

- **APIConnection**: An API connector configuration. Attributes: id, service (github/slack/notion/linear/google), userId, status (connected/error/revoked), scopes (array), lastSyncAt, syncInterval, createdAt.
- **OAuthToken**: OAuth token storage. Attributes: connectionId, accessToken (encrypted), refreshToken (encrypted), expiresAt, scope, tokenType.
- **ConnectorEvent**: An event from an API connector. Attributes: source (e.g., "github"), type (e.g., "github.push"), serviceEventId (for deduplication), payload (service-specific), raw (optional, for debugging).

## Success Criteria

### Measurable Outcomes

- **SC-001**: OAuth connection setup completes in under 10 seconds (including redirect)
- **SC-002**: New event detection latency: < 2 minutes for all connectors
- **SC-003**: Rate limit adherence: zero 429 errors from API providers
- **SC-004**: Token refresh handles 100% of expiration events transparently
- **SC-005**: Connector CPU usage: < 2% while syncing, < 0.1% while idle

## Assumptions

- All connectors use OAuth 2.0 with PKCE for security
- Tokens stored encrypted in the local key store (spec 040)
- Connectors poll APIs at configurable intervals (default: 2 minutes for active, 15 minutes for idle)
- GitHub: REST API + webhooks (optional, for real-time capture)
- Slack: Events API + Web API (for historical sync)
- Notion: REST API (polling-based, no webhooks)
- Linear: GraphQL API (polling-based)
- Google: REST APIs for each service (polling-based, with push notifications via Pub/Sub where available)
- Privacy: DMs/private channels excluded by default; users opt-in per channel
- Source code lives at `connectors/api/` in the monorepo, one subdirectory per service