# Feature Specification: SSO/SAML Authentication

**Feature Branch**: `055-sso-saml`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Implement SSO/SAML authentication for enterprise single sign-on integration"

## User Scenarios & Testing

### User Story 1 - SAML 2.0 SSO Configuration (Priority: P1)

Enterprise admins can configure SAML 2.0 SSO in the organization settings. Configuration requires: Identity Provider (IdP) metadata URL or XML, entity ID, ACS URL (provided by OSAI), certificate for signing, and attribute mapping (email, name, role). After configuration, all org members must sign in via SSO.

**Why this priority**: SAML SSO is a requirement for most enterprise deployments. It enables centralized identity management and aligns with existing corporate security policies.

**Independent Test**: As an Org Owner, navigate to Settings > SSO. Select SAML 2.0. Enter IdP metadata URL from a test IdP (e.g., Okta, Azure AD), map email attribute to "email", name to "name". Save. Sign out and verify the login page now shows "Sign in with Company SSO" instead of email/password. Sign in via SSO and verify successful authentication with correct name and email.

**Acceptance Scenarios**:

1. **Given** the SSO settings page, **When** an Admin enters valid SAML metadata, **Then** the configuration is validated (metadata parsed, certificates checked) and saved with a "Test SSO" button
2. **Given** SSO is configured, **When** a user clicks "Test SSO", **Then** they are redirected to the IdP, sign in, and are redirected back. A success/failure message is shown.
3. **Given** SSO is enabled, **When** a user visits the login page, **Then** only "Sign in with SSO" is shown (email/password login is disabled for org members)

---

### User Story 2 - OIDC/Google Workspace SSO (Priority: P2)

In addition to SAML, OSAI supports OpenID Connect (OIDC) for SSO providers like Google Workspace, Microsoft Entra ID, and Okta OIDC. Configuration requires: client ID, client secret, issuer URL, and scopes. OIDC is configured similarly to SAML with a test flow.

**Why this priority**: OIDC is simpler to configure than SAML and is the preferred protocol for many modern identity providers.

**Independent Test**: Configure Google Workspace OIDC SSO with client ID and secret from the Google Cloud Console. Sign in via "Sign in with Google" and verify the user is authenticated and automatically added to the org (if domain matches).

**Acceptance Scenarios**:

1. **Given** the SSO settings page, **When** an Admin selects OIDC and enters valid client credentials, **Then** the configuration is validated (token endpoint discovered, scopes verified) and saved
2. **Given** OIDC is configured with domain restriction "@company.com", **When** a user with a matching email domain signs in via Google, **Then** they are automatically added to the org with the default member role

---

### User Story 3 - Just-In-Time (JIT) Provisioning (Priority: P2)

When SSO is enabled, users who sign in for the first time via the corporate IdP are automatically provisioned: an OSAI account is created, they're added to the org with a default role, and they receive an onboarding email. No admin invitation is required. JIT provisioning can be restricted to specific email domains or IdP groups.

**Why this priority**: JIT provisioning eliminates the need for admin invite workflows. Employees get access simply by signing in with their corporate credentials.

**Independent Test**: Configure JIT provisioning with domain "@company.com". As a new user, navigate to the OSAI login page, click "Sign in with SSO", authenticate with company credentials. Verify: an OSAI account is auto-created, the user is added to the org as a "Member", they receive an onboarding email, and they can immediately access shared projects.

**Acceptance Scenarios**:

1. **Given** JIT provisioning is enabled with domain "@company.com", **When** a new user with that email domain signs in via SSO, **Then** they are auto-provisioned within 10 seconds and added to the org
2. **Given** JIT provisioning with IdP group restriction "Engineering", **When** a user in the Engineering group signs in, **Then** they are provisioned with the "Member" role. **When** a user not in Engineering signs in, **Then** they are denied access with "Your account is not authorized for this organization"

---

### User Story 4 - SCIM User Provisioning (Priority: P3)

OSAI supports SCIM 2.0 for automated user provisioning and deprovisioning. When a user is added/removed from the corporate directory (Okta, Azure AD, Google Workspace), SCIM automatically creates/enables/disables the OSAI account. SCIM syncs: user identity, group membership, and account status.

**Why this priority**: SCIM automates the full user lifecycle. When an employee leaves the company, their OSAI access is automatically revoked without admin intervention.

**Independent Test**: Configure SCIM in Okta to point to OSAI's SCIM endpoint. In Okta, assign a user to the OSAI app. Verify the user is auto-created in OSAI with correct attributes. In Okta, deactivate the user. Verify the user's OSAI account is disabled within 5 minutes.

**Acceptance Scenarios**:

1. **Given** SCIM is configured, **When** a user is assigned to the OSAI app in the IdP, **Then** they are created in OSAI with the correct name, email, and role within 5 minutes
2. **Given** SCIM is configured, **When** a user is deactivated in the IdP, **Then** their OSAI account is disabled within 5 minutes and they lose access
3. **Given** SCIM is configured, **When** a user's group membership changes, **Then** their OSAI role is updated accordingly (e.g., moved to "Admin" group → OSAI Admin role)

---

### Edge Cases

- What happens when the IdP is unavailable (can users use backup login)?
- How are IdP certificate rotations handled?
- What happens when a user's email changes in the IdP?
- How are multiple SSO providers handled (e.g., different IdPs for different orgs)?
- What happens when SSO is misconfigured (lockout prevention)?
- How are existing password-based users migrated to SSO?

## Requirements

### Functional Requirements

- **FR-001**: SSO MUST support SAML 2.0 (IdP-initiated and SP-initiated)
- **FR-002**: SSO MUST support OpenID Connect (OIDC)
- **FR-003**: Supported IdPs MUST include: Okta, Azure AD, Google Workspace, OneLogin
- **FR-004**: Configuration MUST support: IdP metadata URL/XML, entity ID, ACS URL, certificate, attribute mapping
- **FR-005**: SSO configuration MUST include a "Test" flow before enabling
- **FR-006**: When SSO is enforced, email/password login MUST be disabled for org members
- **FR-007**: Just-In-Time (JIT) provisioning MUST be supported
- **FR-008**: JIT MUST support domain restriction and IdP group restriction
- **FR-009**: JIT-provisioned users MUST get a default role (configurable)
- **FR-010**: SCIM 2.0 MUST be supported for automated provisioning/deprovisioning
- **FR-011**: SCIM MUST sync: user identity, group membership, account status
- **FR-012**: SCIM changes MUST take effect within 5 minutes
- **FR-013**: A backup login method MUST be available for IdP outage (configurable by Admin)
- **FR-014**: IdP certificate rotation MUST be handled without downtime
- **FR-015**: SSO misconfiguration MUST NOT lock out existing Admins (emergency backup login)
- **FR-016**: Existing users MUST be migratable to SSO (link existing account to IdP identity)

### Key Entities

- **SSOConfig**: SSO configuration for an organization. Attributes: orgId, provider (saml/oidc), metadata (provider-specific config), enforced (bool), jitProvisioning (bool), jitDomainRestrictions (array), jitDefaultRole, scimEnabled, createdAt, updatedAt.
- **SCIMEndpoint**: SCIM API endpoint configuration. Attributes: orgId, enabled, token (hashed), supportedFeatures (user/group), lastSyncAt.
- **IdPUserMapping**: Mapping from IdP identity to OSAI user. Attributes: idpUserId, idpEmail, osaiUserId, provider, linkedAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: SSO configuration completes in under 5 minutes (typical admin workflow)
- **SC-002**: SSO authentication completes in under 3 seconds (including IdP redirect)
- **SC-003**: JIT provisioning completes in under 10 seconds
- **SC-004**: SCIM updates take effect within 5 minutes
- **SC-005**: SSO availability: 99.9% (excluding IdP outages)
- **SC-006**: Zero lockouts due to SSO misconfiguration (emergency backup always available)

## Assumptions

- Built as a cloud service integrated with the auth service
- SAML 2.0 support via a library (e.g., samlify or passport-saml)
- OIDC support via a library (e.g., openid-client)
- SCIM 2.0 implemented as a REST API endpoint
- Multiple IdPs supported per organization (primary + backup)
- Emergency backup login: a recovery code or password-based login that bypasses SSO
- Existing users migrated by matching email addresses between IdP and OSAI
- SCIM token is generated by OSAI and configured in the IdP
- Source code lives at `services/sso/` in the monorepo