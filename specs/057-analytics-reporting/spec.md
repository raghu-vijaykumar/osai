# Feature Specification: Analytics & Usage Reporting

**Feature Branch**: `057-analytics-reporting`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build analytics and usage reporting for enterprise administrators to track adoption, engagement, and ROI"

## User Scenarios & Testing

### User Story 1 - Organization Adoption Dashboard (Priority: P1)

The analytics dashboard shows organization-wide adoption metrics: active users (daily, weekly, monthly), adoption rate (new users vs. total), feature usage (which features are most used), and engagement trends. Metrics are shown as interactive charts with period-over-period comparison.

**Why this priority**: Adoption metrics help enterprise admins understand if OSAI is being used across the organization and identify teams that may need additional training or support.

**Independent Test**: Open the Analytics dashboard in the admin panel. Verify it shows: DAU (42), WAU (85), MAU (120) with 7-day trend charts. Adoption rate: 80% (120/150 invited). Feature usage pie chart: Timeline (45%), Search (25%), Dashboard (15%), Agents (10%), Other (5%). Switch to "Growth" tab and verify new user signups per day for the last 30 days.

**Acceptance Scenarios**:

1. **Given** the Analytics dashboard, **When** an Admin views it, **Then** DAU/WAU/MAU metrics are shown with sparklines and week-over-week change percentages
2. **Given** the Analytics dashboard, **When** an Admin views Feature Usage, **Then** a breakdown shows which features are used most, with trend arrows (↑↓) compared to the previous period

---

### User Story 2 - Per-Team and Per-User Analytics (Priority: P2)

Admins can drill down into analytics per team and per user. Team analytics show: team size, active members, top projects, shared events count, and engagement score. User analytics show: individual activity (events/day, active time), feature usage, connected sources, and sharing activity.

**Why this priority**: Per-team and per-user analytics help identify high-engagement teams and users who might need support. They also provide data for ROI analysis.

**Independent Test**: Navigate to Teams analytics. Select "Engineering" team. Verify: 25 members, 18 active this week, top projects: "Frontend Sprint" (1,247 events), "Backend API" (892 events), engagement score: 85/100. Navigate to a specific user "Alice" and verify: 47 events/day avg, 4h 12m active time/day, features used (Timeline 40%, Search 30%, Agents 20%), connected sources (4), projects shared (2).

**Acceptance Scenarios**:

1. **Given** the Analytics dashboard, **When** an Admin drills into a team, **Then** team-level metrics are shown with member list sorted by engagement score
2. **Given** the Analytics dashboard, **When** an Admin drills into a user, **Then** individual activity metrics are shown with daily event count chart (30-day), top sources, and sharing activity

---

### User Story 3 - Custom Report Builder (Priority: P3)

Admins can create custom reports by selecting metrics, dimensions, filters, and date ranges. Reports can be saved, scheduled (daily/weekly/monthly email delivery), and exported (PDF, CSV, PNG for charts). A report builder UI provides drag-and-drop metric selection with preview.

**Why this priority**: Different organizations have different reporting needs. A custom report builder eliminates the need for manual data extraction and spreadsheet creation.

**Independent Test**: Open the Report Builder. Select metrics: DAU, Events Captured, Storage Used. Dimension: by Team. Filter: date range last 30 days. Preview the report. Verify it shows a table with teams as rows and metrics as columns, plus a chart. Save as "Monthly Adoption Report". Schedule for monthly delivery to admin@company.com. Verify the report is emailed on the scheduled date.

**Acceptance Scenarios**:

1. **Given** the Report Builder, **When** an Admin selects metrics, dimensions, and filters, **Then** a live preview of the report updates as selections change
2. **Given** a saved report, **When** the Admin schedules it for delivery, **Then** the report is generated and emailed as a PDF attachment on the configured schedule

---

### User Story 4 - Export and API Access (Priority: P3)

All analytics data is accessible via API for integration with external BI tools (Tableau, Power BI, Metabase, Looker). The analytics API supports: raw event queries, aggregated metrics, and pre-built report endpoints. API responses are in JSON format with pagination for large datasets.

**Why this priority**: Enterprise customers often have existing BI investments. API access allows them to integrate OSAI data into their centralized reporting.

**Independent Test**: Call the analytics API endpoint `GET /api/v1/analytics/dau?from=2026-07-01&to=2026-07-11`. Verify response returns daily active user counts in JSON format. Connect Metabase to the analytics API and create a custom dashboard showing OSAI adoption alongside other business metrics.

**Acceptance Scenarios**:

1. **Given** the analytics API, **When** an Admin calls `GET /api/v1/analytics/events?group_by=source&from=2026-07-01&to=2026-07-11`, **Then** results are returned with event counts grouped by source
2. **Given** the analytics API, **When** an Admin uses an API key for authentication, **Then** they can access all analytics data their role permits

---

### Edge Cases

- What happens when there is no data (new org, first day)?
- How are timezones handled for global organizations?
- How are deleted users handled in historical analytics?
- What happens when metric definitions change (breaking changes)?
- How are very large datasets aggregated (sampling, rollups)?
- How is analytics data privacy maintained (PII in reports)?

## Requirements

### Functional Requirements

- **FR-001**: Analytics dashboard MUST show organization-wide adoption metrics: DAU, WAU, MAU
- **FR-002**: Adoption metrics MUST include trend charts and period-over-period comparison
- **FR-003**: Feature usage breakdown MUST be shown (percentage of users using each feature)
- **FR-004**: Per-team analytics MUST show: team metrics, member list, top projects, engagement scores
- **FR-005**: Per-user analytics MUST show: activity, feature usage, connected sources, sharing activity
- **FR-006**: Custom report builder MUST support: metric selection, dimensions, filters, date ranges
- **FR-007**: Reports MUST be savable, schedulable, and exportable (PDF, CSV, PNG)
- **FR-008**: Analytics API MUST be available for BI tool integration
- **FR-009**: API MUST support: raw event queries, aggregated metrics, pre-built reports
- **FR-010**: API responses MUST be paginated for large datasets
- **FR-011**: Analytics data MUST exclude individual event content (metadata only)
- **FR-012**: Analytics MUST respect RBAC permissions (admins only)
- **FR-013**: Data retention for analytics: configurable (default 2 years)

### Key Entities

- **AdoptionMetrics**: Organization adoption metrics. Attributes: date, dau, wau, mau, totalUsers, activeUsers, newUsers, churnedUsers, engagementScore.
- **FeatureUsage**: Feature usage metrics. Attributes: date, feature (timeline/search/dashboard/agents/command-bar/org-graph), userCount, eventCount, totalDuration.
- **TeamAnalytics**: Team-level analytics. Attributes: teamId, dateRange, memberCount, activeMembers, topProjects, sharedEventCount, engagementScore.
- **SavedReport**: A saved report configuration. Attributes: id, orgId, name, metrics (array), dimensions, filters, schedule (cron), recipients (array of emails), lastRunAt, format (pdf/csv).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Analytics dashboard loads in under 2 seconds (for 500 users, 90 days)
- **SC-002**: Custom report generation completes in under 30 seconds
- **SC-003**: Analytics API responds in under 1 second (for 30-day aggregated queries)
- **SC-004**: Scheduled reports are delivered within 5 minutes of scheduled time
- **SC-005**: Metrics accuracy: within 1% of ground truth (verified by reconciliation)
- **SC-006**: No PII (individual event content) is exposed in analytics

## Assumptions

- Built as a cloud service with its own database (aggregated metrics, not raw events)
- Metrics computed from event metadata (no content access needed for analytics)
- Daily aggregation jobs compute DAU/WAU/MAU and feature usage
- Engagement score computed from: active days, events captured, features used, projects shared
- Report builder uses a drag-and-drop UI library
- Scheduled reports use a cron-based job queue
- Analytics API uses a separate API key scope
- BI tool integration tested with: Metabase, Tableau, Power BI, Google Data Studio
- Metrics definitions are versioned — breaking changes are communicated via changelog
- Source code lives at `services/analytics/` in the monorepo