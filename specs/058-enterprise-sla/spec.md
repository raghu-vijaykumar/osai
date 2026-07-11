# Feature Specification: Enterprise SLA & Support

**Feature Branch**: `058-enterprise-sla`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Create enterprise SLA and support tier with guaranteed uptime, response times, and dedicated support"

## User Scenarios & Testing

### User Story 1 - Support Ticket System (Priority: P1)

Enterprise customers have access to a dedicated support ticket system integrated into the admin panel. Users can submit tickets with: severity (critical/high/medium/low), category (bug/feature request/account/question), subject, description, and optional attachments (screenshots, logs). Tickets are tracked with status, priority, assignee, and SLA timer.

**Why this priority**: A support ticket system is the foundation of the enterprise SLA. Without it, there's no way to track and measure response times.

**Independent Test**: As an Enterprise Admin, navigate to Support in the admin panel. Click "New Ticket", select severity "High", category "Bug", enter subject "Sync failing after update", describe the issue, attach a log file. Submit. Verify the ticket appears in the list with: ticket ID (ENT-1234), status "Open", priority "High", SLA timer showing "Response due in 2h". Verify an email notification is sent confirming ticket creation.

**Acceptance Scenarios**:

1. **Given** the Support page, **When** an Enterprise user submits a ticket with High severity, **Then** the ticket is created with SLA timer, status "Open", and a confirmation email is sent with the ticket ID
2. **Given** an open ticket, **When** a support agent responds, **Then** the ticket status changes to "In Progress", the user receives an email notification, and the response is visible in the ticket thread

---

### User Story 2 - SLA Monitoring and Breach Alerts (Priority: P2)

The system monitors SLA targets: first response time (Critical: 1h, High: 4h, Medium: 8h, Low: 24h), resolution time (Critical: 4h, High: 24h, Medium: 72h, Low: 5 business days), and uptime (99.9% monthly). SLA breaches trigger alerts: the support team is notified and the ticket is flagged.

**Why this priority**: SLA monitoring ensures contractual commitments are met. Breach alerts enable proactive escalation before customers are affected.

**Independent Test**: Submit a Critical severity ticket. After 55 minutes, verify the ticket shows "SLA: 5 min remaining" with an orange indicator. After 61 minutes (breach), verify the ticket shows "SLA BREACHED — First response overdue by 1 min" in red, and a notification is sent to the support team.

**Acceptance Scenarios**:

1. **Given** a ticket within SLA, **When** the SLA timer is below 10% remaining, **Then** the ticket shows an orange warning indicator
2. **Given** a ticket exceeds its SLA, **When** the SLA is breached, **Then** the ticket is flagged red, the support team is notified, and the breach is recorded for monthly SLA reporting

---

### User Story 3 - Status Page and Incident Management (Priority: P2)

Enterprise customers have access to a status page (`status.osai.app`) showing: current service status, incident history, scheduled maintenance, and uptime metrics. Incidents are created, updated, and resolved with communications. Status page is public or private (SSO-protected for enterprise customers).

**Why this priority**: A status page provides transparency during incidents. It reduces support ticket volume during outages by giving users a place to check.

**Independent Test**: Navigate to `status.osai.app`. Verify it shows the current status of all services: OSAI Cloud (Operational), Sync Service (Operational), Auth Service (Operational), API (Operational). Create a test incident (simulate): "Sync Service Degraded — investigating increased latency." Verify the status page updates to show Sync Service as "Degraded Performance" with an incident timeline. Resolve the incident, verify the page updates to "Operational" with a post-incident report.

**Acceptance Scenarios**:

1. **Given** the status page, **When** an Enterprise user visits, **Then** they see the current status of all services with 30-day uptime percentages
2. **Given** an active incident, **When** the status page loads, **Then** it shows the incident with description, affected services, start time, and latest update
3. **Given** scheduled maintenance, **When** the status page loads, **Then** it shows upcoming maintenance with date, time, expected duration, and affected services

---

### User Story 4 - Monthly SLA Report (Priority: P3)

Enterprise customers receive a monthly SLA report via email. The report includes: uptime percentage for the month, incident summary (number, duration, impact), ticket volume (by severity, by category), SLA compliance rate (first response, resolution), and top issues. Reports are also available in the admin panel.

**Why this priority**: Monthly SLA reports provide contractual evidence of SLA compliance. They also give customers visibility into the support relationship.

**Independent Test**: Access the monthly SLA report for the previous month. Verify it shows: Uptime: 99.95% (target: 99.9%), Incidents: 2 (total duration: 45 min), Tickets: 47 (Critical: 2, High: 5, Medium: 15, Low: 25), SLA Compliance: First Response 100%, Resolution 97.8%, Top Issues: "Sync latency" (5 tickets), "Login issues" (3 tickets).

**Acceptance Scenarios**:

1. **Given** the monthly SLA report, **When** an Enterprise Admin views it, **Then** they see all SLA metrics with target vs. actual comparisons
2. **Given** the monthly report, **When** the admin exports it as PDF, **Then** a formatted PDF is downloaded suitable for internal compliance reporting

---

### User Story 5 - Dedicated Support and Account Management (Priority: P3)

Enterprise plans include: dedicated support channel (Slack Connect or private channel), named account manager, quarterly business reviews (QBRs), and priority feature requests. Account manager contact information is visible in the admin panel.

**Why this priority**: Dedicated support and account management are key differentiators for enterprise plans. They provide a human relationship alongside the product.

**Independent Test**: Navigate to the admin panel's "Support" section. Verify it shows: "Your Account Manager: Jane Smith (jane@osai.app)" with calendar link for QBR scheduling. Click "Contact Support" and verify options: "Slack Channel (#osai-enterprise-acme)" and "Email (enterprise-support@osai.app)".

**Acceptance Scenarios**:

1. **Given** an Enterprise plan, **When** an Admin views the Support page, **Then** they see their dedicated account manager's name, email, and calendar booking link
2. **Given** feature request request, **When** an Enterprise user submits it, **Then** it's tagged with "Enterprise" priority and the account manager is notified

---

### Edge Cases

- What happens when an SLA breach is caused by a third-party dependency (e.g., AWS outage)?
- How are severity levels escalated if response targets are missed?
- What happens during holidays and after-hours support?
- How are Enterprise customers verified for support access?
- What happens when the support team itself is unavailable (PTO, incident)?
- How are multiple contacts per Enterprise account handled?

## Requirements

### Functional Requirements

- **FR-001**: Enterprise customers MUST have access to a support ticket system in the admin panel
- **FR-002**: Ticket severity levels MUST be: Critical, High, Medium, Low
- **FR-003**: Ticket categories MUST be: Bug, Feature Request, Account Issue, Question
- **FR-004**: Tickets MUST have SLA timers based on severity
- **FR-005**: SLA targets MUST be: First Response (Critical: 1h, High: 4h, Medium: 8h, Low: 24h)
- **FR-006**: SLA targets MUST be: Resolution (Critical: 4h, High: 24h, Medium: 72h, Low: 5 business days)
- **FR-007**: SLA breaches MUST trigger alerts to the support team
- **FR-008**: A status page MUST show: current service status, incident history, maintenance, uptime
- **FR-009**: Incidents MUST be creatable with description, affected services, and timeline updates
- **FR-010**: Monthly SLA reports MUST be generated and delivered via email
- **FR-011**: SLA reports MUST include: uptime, incident summary, ticket metrics, compliance rate
- **FR-012**: Enterprise plans MUST include named account manager and dedicated support channel
- **FR-013**: Enterprise feature requests MUST be flagged with priority
- **FR-014**: All support interactions MUST be logged for audit and training

### Key Entities

- **SupportTicket**: A support ticket. Attributes: id (ENT-XXXX), orgId, userId, severity, category, subject, description, attachments, status (open/in-progress/resolved/closed), priority, assignee, slaFirstResponse (target + actual), slaResolution (target + actual), createdAt, resolvedAt.
- **SLAPolicy**: SLA policy configuration. Attributes: id, plan (enterprise), severityLevel, firstResponseTarget (minutes), resolutionTarget (minutes), escalationContact.
- **Incident**: A service incident. Attributes: id, title, description, services (array of affected services), severity, status (investigating/identified/monitoring/resolved), createdAt, resolvedAt, timeline (array of updates), postIncidentReport.
- **SLAReport**: Monthly SLA report. Attributes: id, orgId, month, uptime (percentage), incidents (count + total duration), tickets (by severity + category), compliance (firstResponse%, resolution%), topIssues.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Ticket creation completes in under 3 seconds
- **SC-002**: SLA timer accuracy: within 1 second of actual elapsed time
- **SC-003**: Status page reflects incident changes within 30 seconds
- **SC-004**: Monthly SLA report generates in under 30 seconds
- **SC-005**: SLA compliance: 95%+ of tickets meet first response SLA
- **SC-006**: Uptime SLA: 99.9% monthly uptime (excluding scheduled maintenance)

## Assumptions

- Support ticket system built as part of the admin panel (spec 054) or as a standalone service
- SLA timers are server-side (not client-side) for accuracy
- Status page is a separate deployment (status.osai.app) for reliability
- Status page can be public (read-only) or SSO-protected (Enterprise)
- SLA reports generated on the 1st of each month for the previous month
- Dedicated support channels via Slack Connect or Microsoft Teams
- Account manager assignment managed internally (CRM integration)
- Severity escalation: if first response SLA is breached, the ticket auto-escalates to next tier
- Source code lives at `services/enterprise-support/` in the monorepo