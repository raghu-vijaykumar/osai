# Feature Specification: Cloud Dashboard

**Feature Branch**: `038-cloud-dashboard`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a web-based cloud dashboard for account management, sync monitoring, and read-only access to the knowledge base"

## User Scenarios & Testing

### User Story 1 - Account Overview (Priority: P1)

The cloud dashboard is a web application accessible from any browser. It shows an account overview: plan and billing status, storage used, devices connected, last backup time, and recent activity. It's read-only — users can view their data but editing/adding requires the desktop app.

**Why this priority**: The account overview is the landing page and provides immediate value — users can check their account status from anywhere.

**Independent Test**: Navigate to cloud dashboard (app.osai.app), sign in. Verify the overview shows: plan (Free / Pro), storage used (245MB / 1GB), devices (2 connected, last sync 2 min ago), last backup (Today at 2:01 AM), recent events (3 events in last hour). Verify none of the overview widgets have edit buttons.

**Acceptance Scenarios**:

1. **Given** the user signs into the cloud dashboard, **When** the overview loads, **Then** it shows account status, usage stats, device list, and backup info within 2 seconds
2. **Given** the dashboard is read-only, **When** the user clicks anywhere, **Then** no inline editing is possible (all links open desktop-app or settings pages)

---

### User Story 2 - Read-Only Timeline View (Priority: P2)

The cloud dashboard provides a read-only timeline of synced events. Users can scroll through recent events, filter by date, source, and type. Each event shows: timestamp, source, title, and preview. Clicking an event shows full details. Events cannot be edited or deleted from the web dashboard.

**Why this priority**: A read-only timeline lets users check their activity history from any device (phone, work computer, borrowed laptop).

**Independent Test**: Open the cloud dashboard, navigate to Timeline. Verify events from the last 7 days are shown in reverse chronological order. Filter by source "VSCode" and verify only VSCode events appear. Click an event and verify full details are shown in a side panel with no edit/delete buttons.

**Acceptance Scenarios**:

1. **Given** the user has synced events, **When** they open the Timeline view, **Then** events from the last 7 days are paginated (50 per page) with date grouping headers
2. **Given** the Timeline view, **When** the user applies a date range filter (start date + end date), **Then** only events within that range are shown

---

### User Story 3 - Device Management (Priority: P2)

The dashboard shows all registered devices with: name, model, OS, last sync time, events synced, and current sync status. Users can revoke device access directly from the dashboard. Revoking a device immediately invalidates its sync token.

**Why this priority**: Device management from the cloud dashboard is useful when a device is lost or stolen — users can revoke access without having access to that device.

**Independent Test**: Open Dashboard > Devices. Verify devices are listed: "Desktop-Work (Windows, last sync 2 min ago, 15,230 events synced)", "Laptop-Home (macOS, last sync 1 hour ago, 8,450 events synced)". Click "Revoke" on Laptop-Home, confirm, verify status changes to "Revoked" and the laptop is blocked from syncing.

**Acceptance Scenarios**:

1. **Given** the Devices page, **When** it loads, **Then** all registered devices are shown with name, OS, last sync, and event count
2. **Given** a device is revoked, **When** the page refreshes, **Then** the device shows "Revoked (2026-07-11)" and can be re-registered if needed

---

### User Story 4 - Usage and Billing Dashboard (Priority: P3)

Users can view their usage statistics: events captured per day/week/month, storage used over time, API calls made, and active devices. For paid plans, billing information is shown: current plan, next billing date, invoice history, and the ability to update payment method.

**Why this priority**: Usage transparency helps users understand their consumption patterns. Billing views are essential for paid plan management.

**Independent Test**: Navigate to Dashboard > Usage. Verify a chart shows events per day for the last 30 days (bar chart). Verify storage used is shown as a progress bar (245MB / 1GB). Navigate to Billing (paid plan), verify current plan, next billing date ($12/mo on Aug 11), and invoice history (3 paid invoices) are shown.

**Acceptance Scenarios**:

1. **Given** the Usage page, **When** it loads, **Then** interactive charts show events/day, storage over time, and active devices/day with period selectors (7d/30d/90d)
2. **Given** a paid plan, **When** the user views Billing, **Then** current plan details, payment method (masked), next billing date, and invoice history are displayed

---

### User Story 5 - Cloud Data Export (Priority: P3)

Users can request a full data export from the cloud dashboard. The export includes all synced events, entities, projects, sessions, and settings in JSON format. Large exports are prepared asynchronously — the user receives an email when the export is ready for download.

**Why this priority**: Data export from the web dashboard ensures users can always retrieve their data, even without the desktop app.

**Independent Test**: Click "Export Data" in dashboard settings. Verify a confirmation dialog shows: "Your export is being prepared. You'll receive an email at user@example.com when it's ready (typically within 5 minutes)." Check email, click the download link, verify a .zip file is downloaded with all data.

**Acceptance Scenarios**:

1. **Given** the user requests an export, **When** the export is prepared, **Then** the user receives an email with a one-time download link (expires in 24 hours)
2. **Given** an export is in progress, **When** the user checks the dashboard, **Then** a status indicator shows "Export in progress" with an estimated completion time

---

### Edge Cases

- What happens when the user has no synced data (new account)?
- How are very large exports handled (email attachment size limits)?
- What happens when the user is on a free plan with limited history?
- How is the dashboard optimized for mobile browsers?
- What happens when the sync service is down — does the dashboard still load?
- How are user permissions handled for multi-user accounts (future)?
- What happens when the user clears their browser cache/cookies?

## Requirements

### Functional Requirements

- **FR-001**: Cloud dashboard MUST be a web application accessible from any modern browser
- **FR-002**: Dashboard MUST be read-only — no event creation, editing, or deletion
- **FR-003**: Dashboard MUST show account overview: plan, storage, devices, last backup
- **FR-004**: Dashboard MUST provide a read-only timeline of synced events
- **FR-005**: Timeline MUST support filtering by date range, source, and event type
- **FR-006**: Timeline MUST support pagination (50 events per page)
- **FR-007**: Dashboard MUST show device list with name, OS, last sync, event count, and revoke action
- **FR-008**: Device revocation MUST take effect immediately (token invalidated)
- **FR-009**: Dashboard MUST show usage statistics: events/day, storage over time, active devices
- **FR-010**: Usage charts MUST be interactive with period selectors
- **FR-011**: Dashboard MUST show billing information for paid plans
- **FR-012**: Users MUST be able to request data export from the dashboard
- **FR-013**: Data export MUST be asynchronous with email notification
- **FR-014**: Export download link MUST be one-time use and expire in 24 hours
- **FR-015**: Dashboard MUST be responsive (works on desktop and mobile browsers)
- **FR-016**: Dashboard MUST show appropriate empty states for new users

### Key Entities

- **DashboardOverview**: The main dashboard data. Attributes: plan (plan name, status, features), usage (storageUsed, storageLimit, eventCount, deviceCount), lastBackup (timestamp, status), recentActivity (array of recent events).
- **UsageStats**: Usage statistics for charts. Attributes: period (day/week/month), eventsPerDay (array of {date, count}), storageOverTime (array of {date, bytes}), activeDevices (array of {date, count}).
- **ExportRequest**: A data export request. Attributes: id, userId, status (pending/processing/completed/failed), requestedAt, completedAt, downloadUrl (one-time), expiresAt.
- **BillingInfo**: Billing information. Attributes: plan, status, nextBillingDate, paymentMethod (masked), invoices (array of {id, date, amount, status, url}).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Dashboard overview loads in under 2 seconds (cold cache)
- **SC-002**: Timeline view loads in under 3 seconds (50 events per page)
- **SC-003**: Device list loads in under 1 second
- **SC-004**: Usage charts render in under 2 seconds (30 days of data)
- **SC-005**: Data export completes in under 5 minutes (for 500MB of data)
- **SC-006**: Dashboard is usable on mobile screens (320px+ width)
- **SC-007**: Read-only guarantee: zero write endpoints exposed from dashboard

## Assumptions

- Built as a Next.js web application (deployed on Vercel or similar)
- Uses the same auth service (spec 037) for authentication
- Reads data from the cloud sync service's database (read replicas)
- No write access to the sync service — dashboard uses read-only API tokens
- Charts use a lightweight charting library (e.g., recharts or Chart.js)
- Data export uses a queue worker for async processing
- Export files stored in object storage with one-time signed URLs
- Dashboard is deployed at a subdomain (e.g., app.osai.app or dashboard.osai.app)
- Mobile responsive is a priority — dashboard works on phone browsers
- Source code lives at `apps/cloud-dashboard/` in the monorepo