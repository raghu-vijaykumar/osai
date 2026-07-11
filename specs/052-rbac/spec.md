# Feature Specification: Role-Based Access Control (RBAC)

**Feature Branch**: `052-rbac`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Implement role-based access control for team and enterprise features"

## User Scenarios & Testing

### User Story 1 - Organization Roles (Priority: P1)

The RBAC system defines roles at the organization level: Owner (full control), Admin (manage members, settings, billing), Member (standard access), and Viewer (read-only access). Each role has a predefined set of permissions. Owners can create custom roles with specific permission combinations.

**Why this priority**: Clear roles are essential for enterprise governance. They define who can do what within the organization.

**Independent Test**: As an Owner, invite three users: Alice (Admin), Bob (Member), Carol (Viewer). Verify Alice can manage members and settings, Bob can share projects and use all features, Carol can only view shared projects and the org graph. Verify Carol cannot share projects, invite members, or access billing.

**Acceptance Scenarios**:

1. **Given** an organization with roles defined, **When** a user with Admin role attempts to access billing, **Then** access is denied with "Insufficient permissions — billing requires Owner role"
2. **Given** an organization, **When** an Owner creates a custom role "Developer" with permissions (share projects, view org graph, search team), **Then** users assigned the Developer role have exactly those permissions

---

### User Story 2 - Permission Categories (Priority: P2)

Permissions are organized into categories: Organization (manage org, roles, billing), Team (manage teams, membership), Projects (create, share, view all), Content (view events, entities, search), and Admin (audit log, analytics, settings). Each permission is independently grantable.

**Why this priority**: Granular permissions enable precise access control. Different team members need different levels of access.

**Independent Test**: Create a custom role "Project Lead" with permissions: Projects/View All, Projects/Share, Content/Search, but not Organization/Manage. Assign it to a user. Verify they can view and share all projects and search content, but cannot access Organization Settings or Billing.

**Acceptance Scenarios**:

1. **Given** the permission categories, **When** an Owner creates a custom role, **Then** they can select individual permissions from each category with clear descriptions
2. **Given** a role with limited permissions, **When** the assigned user attempts an action outside their permissions, **Then** they see a clear "Access denied" message with the specific permission required

---

### User Story 3 - Team-Level Roles (Priority: P2)

In addition to org-level roles, teams can have team-specific roles: Team Admin (manage team membership, projects) and Team Member (standard team access). Team-level roles are independent of org roles — an org Member can be a Team Admin for a specific team.

**Why this priority**: Team-level roles allow decentralized management. Team leads can manage their own teams without needing org-wide admin access.

**Independent Test**: Create a team "Engineering" and assign Alice as Team Admin. Verify Alice can add/remove members from Engineering and manage Engineering's shared projects, but cannot modify other teams or org settings.

**Acceptance Scenarios**:

1. **Given** a team with a Team Admin, **When** the Team Admin adds a new member, **Then** the member gains access to that team's shared content
2. **Given** a user is an org Member but Team Admin of Engineering, **When** they manage Engineering team settings, **Then** they can do so without org Admin permissions

---

### User Story 4 - Permission Inheritance and Override (Priority: P3)

Permissions follow an inheritance model: Organization → Team → Project. More specific permissions override less specific ones. Deny always overrides allow. Users can see their effective permissions (computed from all roles) in their profile settings.

**Why this priority**: Clear inheritance rules prevent permission confusion. Users should know exactly what they can and can't do.

**Independent Test**: User is org Member (deny: view all projects) but Team Admin of Engineering (allow: view all Engineering projects). Verify the user can view Engineering projects (team-level allow overrides org-level deny for that team). Verify the user cannot view other teams' projects (org-level deny applies).

**Acceptance Scenarios**:

1. **Given** a user with multiple roles, **When** they view their effective permissions, **Then** the UI shows: "Your permissions: [list] with source role for each permission"
2. **Given** conflicting permissions, **When** the system evaluates an action, **Then** deny always overrides allow regardless of inheritance level

---

### Edge Cases

- What happens when a user is removed from the organization?
- How are permissions cached and how quickly do changes take effect?
- What happens when a role is deleted that users are assigned to?
- How are very large organizations with hundreds of roles handled?
- What happens when SSO groups map to OSAI roles?

## Requirements

### Functional Requirements

- **FR-001**: RBAC MUST support predefined roles: Owner, Admin, Member, Viewer
- **FR-002**: Owners MUST be able to create custom roles with specific permissions
- **FR-003**: Permissions MUST be categorized: Organization, Team, Projects, Content, Admin
- **FR-004**: Each permission MUST be independently grantable in custom roles
- **FR-005**: Team-level roles MUST be supported: Team Admin, Team Member
- **FR-006**: Team-level roles MUST be independent of org-level roles
- **FR-007**: Permissions MUST follow inheritance: Org → Team → Project
- **FR-008**: Deny MUST always override allow across all inheritance levels
- **FR-009**: Users MUST be able to view their effective permissions
- **FR-010**: Permission changes MUST take effect within 30 seconds
- **FR-011**: Role deletion MUST handle assigned users (fallback to Member role)
- **FR-012**: RBAC MUST integrate with SSO group mappings

### Key Entities

- **Role**: A collection of permissions. Attributes: id, orgId, name, type (system/custom), permissions (array), description, createdAt.
- **Permission**: A single permission. Attributes: id, category, name, description, effect (allow/deny).
- **RoleAssignment**: A role assigned to a user. Attributes: id, userId, roleId, scope (org/team), scopeId (team ID if applicable), grantedAt.
- **EffectivePermission**: Computed effective permissions for a user. Attributes: userId, permissions (map of permission → effect + source role), computedAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Permission check overhead: < 5ms per check
- **SC-002**: Effective permission computation: < 100ms for 50 roles
- **SC-003**: Permission changes take effect within 30 seconds
- **SC-004**: RBAC enforces 100% of access control decisions correctly
- **SC-005**: Custom role creation completes in under 5 seconds

## Assumptions

- Built as a cloud service integrated with the auth service
- Permissions evaluated centrally (cloud) with local caching
- Default role for new members: Member
- Teams are groups within an organization (not separate orgs)
- Custom roles limited to 50 per organization (configurable)
- Permission caching: 30-second TTL
- Source code lives at `services/rbac/` in the monorepo