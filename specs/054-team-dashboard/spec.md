# Feature Specification: Team Dashboard & Admin Panel

**Feature Branch**: `054-team-dashboard`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a team dashboard and admin panel for managing organization settings, members, and monitoring team activity"

## User Scenarios & Testing

### User Story 1 - Organization Overview (Priority: P1)

The admin panel's Organization Overview shows: total members, active members (30d), projects shared, storage used, plan details, and recent activity. Key metrics are shown as cards with trends. The overview is the landing page for admins.

**Why this priority**: The overview gives admins a quick pulse on the organization's OSAI usage. It's the starting point for all administration.

**Independent Test**: As an Admin, open the admin panel. Verify the overview shows: Members (25 total, 18 active in 30d), Shared Projects (12), Storage Used (2.4GB / 10GB), Plan (Enterprise), and Recent Activity (latest 5 events from across the org). Verify clicking "Members" navigates to the member management page.

**Acceptance Scenarios**:

1. **Given** the admin panel, **When** the Overview loads, **Then** it shows key metrics as interactive cards with sparkline trends (30-day view)
2. **Given** the Overview, **When** an Admin clicks a metric card, **Then** they navigate to the detailed view for that section

---

### User Story 2 - Member Management (Priority: P1)

Admins can manage organization members: invite new members (via email), view member list (name, email, role, status, last active, projects shared), edit roles, remove members, and transfer ownership. Invitations can be revoked. Bulk operations are supported (invite CSV upload, bulk role change).

**Why this priority**: Member management is the most frequent admin task. Efficient tools reduce administrative overhead.

**Independent Test**: As an Admin, navigate to Members. Click "Invite Member", enter email "newuser@example.com", select role "Member", send. Verify the member appears in the list with status "Pending". Accept the invitation as the new user, verify status changes to "Active". Change the role to "Admin", verify the change takes effect immediately. Remove the member, verify they are removed from the list and can no longer access the org.

**Acceptance Scenarios**:

1. **Given** the Members page, **When** an Admin invites a new member, **Then** an invitation email is sent and the member appears as "Pending" with an option to resend or revoke
2. **Given** the Members page, **When** an Admin changes a member's role, **Then** the change is logged in the audit log and the member's permissions update immediately
3. **Given** the Members page, **When** an Admin removes a member, **Then** a confirmation dialog appears, and after confirmation the member is immediately removed and loses access

---

### User Story 3 - Team Activity Monitoring (Priority: P2)

Admins can view org-wide activity: a real-time feed of shared events from all members, filtered by team, project, member, and time range. Activity can be exported. Usage patterns are shown: peak activity times, most active members, most shared projects.

**Why this priority**: Activity monitoring helps admins understand adoption, identify power users, and spot declining engagement.

**Independent Test**: Open the Activity page in the admin panel. Verify a real-time feed shows shared events from all org members, updating as new events arrive. Filter by member "Alice" and see only her events. Switch to "Analytics" tab and verify: most active times (10 AM - 12 PM peak), most active members (Alice: 1,247 events), most shared projects (Frontend Sprint: 3,421 events).

**Acceptance Scenarios**:

1. **Given** the Activity page, **When** an Admin views it, **Then** a live feed of org-wide shared events is shown with auto-refresh (every 30 seconds)
2. **Given** the Activity page, **When** an Admin switches to Analytics, **Then** usage patterns are shown with charts for member activity, project activity, and time-of-day distribution

---

### User Story 4 - Organization Settings (Priority: P2)

Admins can manage organization-wide settings: SSO configuration (SAML/OIDC), security policies (password requirements, session timeout, 2FA enforcement), branding (org logo, name, colors for shared views), data retention policies, and integration settings (webhook URLs for audit alerts).

**Why this priority**: Centralized settings ensure consistent policy enforcement across the organization.

**Independent Test**: Navigate to Settings > Security. Enable "Enforce 2FA for all members". Verify all members are prompted to set up 2FA on next login. Set session timeout to 4 hours. Verify sessions are terminated after 4 hours of inactivity. Navigate to Settings > Branding, upload an org logo, verify it appears on shared views.

**Acceptance Scenarios**:

1. **Given** the Settings page, **When** an Admin enables "Enforce 2FA", **Then** all org members are required to set up 2FA within 7 days or lose access
2. **Given** the Settings > Branding page, **When** an Admin uploads a logo and sets org colors, **Then** the branding is applied to shared views (shared project pages, org graph) within 60 seconds

---

### User Story 5 - Invitation and Onboarding Management (Priority: P3)

Admins can manage the member onboarding flow: customize invitation emails, set default roles for new members, configure required onboarding steps (install desktop app, connect first source, share first project), and view onboarding completion status per member.

**Why this priority**: Structured onboarding improves member activation rates. Admins can see who has completed the setup process and who needs help.

**Independent Test**: Customize the invitation email template with org name and a custom message. Invite a new member. Verify the email includes the custom message. After they accept, view their onboarding status: "Steps completed: 2/4 (Account created, Desktop app installed. Pending: Connect source, Share first project)."

**Acceptance Scenarios**:

1. **Given** the Onboarding settings, **When** an Admin customizes the invitation email, **Then** all new invitations use the customized template
2. **Given** the Members page, **When** an Admin views a member's profile, **Then** their onboarding progress is shown with completion percentage and pending steps

---

### Edge Cases

- What happens when an org reaches its member limit?
- How are pending invitations handled when the inviter leaves the org?
- What happens when an org Admin is the only Owner and wants to leave?
- How are member lists exported for HR/IT systems?
- What happens when SSO is enabled and a user is deprovisioned from the IdP?

## Requirements

### Functional Requirements

- **FR-001**: Admin panel MUST show an Organization Overview with key metrics
- **FR-002**: Admin panel MUST support member management: invite, view, edit role, remove
- **FR-003**: Member invitations MUST be sent via email with accept/decline
- **FR-004**: Pending invitations MUST be resendable and revocable
- **FR-005**: Bulk member operations MUST be supported (CSV invite, bulk role change)
- **FR-006**: Admin panel MUST show a real-time org-wide activity feed
- **FR-007**: Activity analytics MUST show: peak times, most active members, most shared projects
- **FR-008**: Organization settings MUST include: SSO, security policies, branding, retention, integrations
- **FR-009**: Security policies MUST include: password requirements, session timeout, 2FA enforcement
- **FR-010**: Branding MUST be customizable: logo, name, colors applied to shared views
- **FR-011**: Onboarding management MUST track member setup progress
- **FR-012**: Invitation emails MUST be customizable
- **FR-013**: Admin panel MUST respect RBAC permissions (only Admins and Owners can access)
- **FR-014**: All admin actions MUST be recorded in the audit log

### Key Entities

- **Organization**: An OSAI organization. Attributes: id, name, logoUrl, brandColors, plan, memberCount, storageUsed, createdAt.
- **OrgSettings**: Organization settings. Attributes: orgId, ssoConfig, securityPolicy, branding, retentionPolicy, integrationWebhooks, updatedAt.
- **MemberInvitation**: A pending member invitation. Attributes: id, orgId, email, role, invitedBy, createdAt, expiresAt, status (pending/accepted/expired/revoked).
- **MemberOnboarding**: A member's onboarding status. Attributes: userId, orgId, steps (array of {step, completed, completedAt}), completionPercentage.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Admin panel loads in under 2 seconds
- **SC-002**: Member list loads in under 1 second (for 500 members)
- **SC-003**: Invitation email is sent within 10 seconds
- **SC-004**: Role changes take effect within 10 seconds
- **SC-005**: Activity feed updates within 30 seconds of new events
- **SC-006**: Branding changes apply to shared views within 60 seconds

## Assumptions

- Built as a web application (part of the cloud dashboard or separate)
- Accessible only to users with Admin or Owner roles
- Real-time activity feed uses the same infrastructure as the audit log
- Email invitations sent via the transactional email service
- Branding stored in the organization settings and cached on shared views
- Onboarding steps are tracked via analytics events
- Settings changes are recorded in the audit log
- Source code lives at `apps/admin-panel/` in the monorepo