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

- **FR-001**: Each API connector MUST authenticate via OAuth 2.0 with PKCE
- **FR-002**: All connectors MUST handle OAuth token refresh automatically (store refresh token in OS keychain)
- **FR-003**: All connectors MUST respect API rate limits (exponential backoff, queuing)
- **FR-004**: Connectors MUST poll for new events at configurable intervals (default: 2 minutes)
- **FR-005**: Sensitive content MUST be handled according to user privacy settings
- **FR-006**: Each connector MUST publish events as its own Context Protocol source via `@osai/protocol` SDK over named pipe / Unix socket
- **FR-007**: Each connector MUST accept control signals (`enable`, `disable`, `pause`, `resume`) from the Rust core via IPC — see spec 063. On `disable`, stop all API polling and clear timers. On `pause`, stop polling but keep OAuth tokens alive. On `resume`, resume polling from the last checkpoint.
- **FR-008**: Each connector MUST send a heartbeat to the Rust core every 60 seconds via IPC, containing `events_today`, `last_event_at`, `services_connected`, and any errors (rate limit hits, auth failures) — see spec 063 FR-027
- **FR-009**: Each connector MUST register a `config_schema` at source registration time exposing its service-specific settings (polling interval, DM inclusion toggle) as configurables — see spec 063 FR-014

### Per-Tool Connector Specifications

#### GitHub

| Property | Detail |
|----------|--------|
| **App ID** | `com.github` |
| **OAuth scopes** | `repo`, `read:org`, `read:user` |
| **Auth flow** | OAuth device flow (no redirect URL needed) — user gets a code at `https://github.com/login/device`. OSAI polls `https://github.com/login/oauth/access_token` until authorized. |
| **API used** | REST API (`GET /user/events`, `GET /repos/{owner}/{repo}/commits`, `GET /repos/{owner}/{repo}/pulls`, `GET /notifications`) |
| **Polling** | `GET /user/events` every 2 minutes. Events deduplicated by `event.id`. Commits fetched per-repo after push event detected. |
| **Events captured** | `github.push` (commits, repo, branch, messages), `github.pr.opened`/`.closed`/`.reviewed` (title, description, files), `github.issue.opened`/`.commented` (title, body), `github.star` |
| **Dedup key** | GitHub event ID (`event.id`) |
| **Rate limit** | 5,000 req/hr authenticated. OSAI stays under 200 req/hr per user (polling 2 min = 30 req/hr + sync overhead). |
| **Complexity** | ~400 lines — OAuth device flow + event polling + rate limit tracking |

#### Slack

| Property | Detail |
|----------|--------|
| **App ID** | `com.slack` |
| **OAuth scopes** | `channels:history`, `channels:read`, `groups:history` (private channels), `users:read`, `reactions:read`, `team:read` |
| **Auth flow** | OAuth 2.0 with redirect to OSAI's local HTTP callback server (`http://127.0.0.1:8400/oauth/slack/callback`). User clicks "Install to Workspace" in browser. |
| **API used** | Web API (`conversations.history`, `conversations.list`, `users.info`). Supports Slack Events API (real-time via WebSocket or webhook) but for MVP, polling is simpler. |
| **Polling** | `GET /conversations.history` for each selected public channel every 2 minutes. Cursor-based pagination using `response_metadata.next_cursor`. |
| **Events captured** | `slack.message` (channel, user, text preview, thread_ts), `slack.reaction` (emoji, message, channel), `slack.file_uploaded` (filename, type, channel) |
| **Dedup key** | Slack event `ts` (timestamp-based unique ID per channel) |
| **Private channels** | Excluded by default. User must explicitly opt-in per channel via the OSAI connector settings UI. |
| **Rate limit** | "Tier 3" — 50+ req/min. OSAI stays under 30 req/min. |
| **Complexity** | ~500 lines — OAuth callback server + paginated conversation history + dedup |

#### Notion

| Property | Detail |
|----------|--------|
| **App ID** | `com.notion` |
| **OAuth scopes** | Notion OAuth grants access to specific workspaces + pages. No fine-grained scope selection — user controls page access during OAuth. |
| **Auth flow** | OAuth 2.0 with redirect to OSAI's local callback server (`http://127.0.0.1:8400/oauth/notion/callback`). User selects which pages/workspaces to share. |
| **API used** | Notion REST API (`POST /search` to find accessible pages, `GET /blocks/{id}/children` for content, `POST /comments` for comments). |
| **Polling** | `POST /search` every 2 minutes to find recently updated pages (filter: `{timestamp: "last_edited_time", direction: "descending"}`). Then fetch content for changed pages + check comments. |
| **Events captured** | `notion.page_viewed` (page title, workspace, URL, last editor), `notion.page_edited` (page ID, changes summary), `notion.comment_added` (page, comment text, author) |
| **Dedup key** | Page `last_edited_time` (ISO 8601 string, compare timestamps) |
| **Limitations** | Notion API is slow (~1-3s per page content fetch). No webhook support — polling only. Text content is limited (Notion API returns block-level content, no full page text). |
| **Rate limit** | 3 req/sec per integration. OSAI stays under 1 req/sec. |
| **Complexity** | ~350 lines — OAuth + search-based polling + block content fetching |

#### Linear

| Property | Detail |
|----------|--------|
| **App ID** | `com.linear` |
| **OAuth scopes** | `read`, `issues:read`, `comments:read` |
| **Auth flow** | OAuth 2.0 with redirect to OSAI's local callback server (`http://127.0.0.1:8400/oauth/linear/callback`). |
| **API used** | Linear GraphQL API (`issues(filter: {updatedAt: {gt: "..."}}) { nodes { title, description, state, assignee, team, project, priority, labels, comments { nodes { body } } } }`). |
| **Polling** | GraphQL query every 2 minutes: `issues(filter: {updatedAt: {after: $lastSync}})` ordered by `updatedAt`. Cursor pagination with `first: 50`. |
| **Events captured** | `linear.issue.created`, `.updated`, `.completed` (title, team, project, status, priority, assignee), `linear.comment.added` (issue, comment body preview) |
| **Dedup key** | Issue `updatedAt` timestamp (polling catches all changes since last check) |
| **Rate limit** | 1,000 req/min per token. OSAI stays under 30 req/min. |
| **Complexity** | ~350 lines — OAuth + GraphQL client + cursor pagination |

#### Google

| Property | Detail |
|----------|--------|
| **App ID** | `com.google` (sub-source per service: `.gmail`, `.calendar`, `.drive`, `.docs`) |
| **OAuth scopes** | `https://www.googleapis.com/auth/gmail.readonly`, `https://www.googleapis.com/auth/calendar.events.readonly`, `https://www.googleapis.com/auth/drive.readonly`, `https://www.googleapis.com/auth/documents.readonly` |
| **Auth flow** | OAuth 2.0 with redirect to OSAI's local callback server (`http://127.0.0.1:8400/oauth/google/callback`). User selects which scopes to grant via Google's consent screen. |
| **API used** | Gmail: `GET /gmail/v1/users/me/messages?q=after:{timestamp}` (message IDs + snippet). Calendar: `GET /calendar/v3/calendars/primary/events?timeMin={lastSync}`. Drive: `GET /drive/v3/changes?pageToken={token}` (push-based via `changes.watch` where available). Docs: `GET /docs/v1/documents/{id}` (content on demand). |
| **Polling** | Gmail: every 2 minutes, fetch message IDs since last sync, then fetch full message content for new ones. Calendar: every 5 minutes, fetch events updated since last check. Drive: use `changes` API with stored `pageToken` — push-based, or fall back to 5 min polling. Docs: on-demand when a Drive change notification triggers. |
| **Events captured** | `google.gmail.message` (subject, from, snippet, thread), `google.calendar.event` (title, start, end, attendees, description), `google.drive.file_changed` (name, mimeType, modifiedTime), `google.docs.opened`/.`edited` (title, collaborator count, word count) |
| **Dedup key** | Service-specific: Gmail `message.id`, Calendar `event.id` + `updated`, Drive `change.id` |
| **Rate limit** | Gmail: 250 quota units/user/sec. Calendar: 10,000 requests/day. Drive: 10,000 requests/day. OSAI usage is well under all limits. |
| **Complexity** | ~800 lines (all 4 services combined) — shared OAuth + per-service poller + push channel management |

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