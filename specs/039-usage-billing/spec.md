# Feature Specification: Usage Quotas & Billing

**Feature Branch**: `039-usage-billing`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Implement usage quotas, tiered plans, and Stripe billing integration"

## User Scenarios & Testing

### User Story 1 - Free and Paid Plan Tiers (Priority: P1)

OSAI offers tiered plans: Free (limited events, 1 device, local-only backup), Pro (unlimited events, 5 devices, cloud sync + backup, all agents), and Team (everything in Pro + team sharing, centralized billing). Users on the Free plan see upgrade prompts and usage limits. Upgrading is instant via Stripe checkout.

**Why this priority**: Plan tiers monetize the cloud features while keeping the core local experience free.

**Independent Test**: Sign up for a Free account. Verify usage shows "247 / 10,000 events this month" and "1 / 1 devices connected". Click "Upgrade to Pro", complete Stripe checkout. Verify within 10 seconds the account is upgraded: plan shows "Pro", usage limits updated to "Unlimited", device limit shows "2 / 5".

**Acceptance Scenarios**:

1. **Given** a Free plan account, **When** the user views the dashboard, **Then** usage bars show limits with "Upgrade to Pro" call-to-action
2. **Given** a Free plan user exceeds 10,000 events in a month, **When** new events are synced, **Then** they are accepted but the user sees a warning: "You've exceeded your Free plan's event limit. Upgrade to Pro for unlimited events."
3. **Given** a user completes Stripe checkout for Pro, **When** the payment succeeds, **Then** the account is upgraded within 10 seconds and the user sees a success notification

---

### User Story 2 - Usage Tracking and Enforcement (Priority: P2)

Usage is tracked per-user across: events stored, storage used (MB), devices connected, API calls per month, and backup storage. When a user approaches their limit, they receive warnings at 80%, 90%, and 100%. At 100%, the feature is paused (e.g., sync stops) but local functionality continues working.

**Why this priority**: Usage tracking enables fair enforcement of plan limits. Soft enforcement (pause, not delete) preserves user trust.

**Independent Test**: On a Free plan, generate 8,000 events. Verify a warning appears: "You've used 80% of your monthly event limit (8,000/10,000)." At 9,000 events, verify a stronger warning. At 10,000 events, verify sync is paused with message "Sync paused — upgrade to Pro for unlimited events." Verify the desktop app continues working locally.

**Acceptance Scenarios**:

1. **Given** usage reaches 80% of a limit, **When** the user views the dashboard, **Then** an orange warning is shown with exact percentage and an "Upgrade" link
2. **Given** usage reaches 100% of a limit, **When** the user attempts to sync, **Then** sync is paused with a clear error message and the feature is re-enabled when the plan is upgraded or the billing period resets
3. **Given** a feature is paused due to limit, **When** the user upgrades, **Then** the feature is re-enabled within 10 seconds

---

### User Story 3 - Stripe Subscription Management (Priority: P2)

Billing is managed via Stripe. Users can: subscribe to Pro or Team plans, cancel subscription (access continues until end of billing period), reactivate a canceled subscription, update payment method, and view invoice history. All billing actions are self-serve from the dashboard.

**Why this priority**: Self-serve billing reduces support costs. Stripe handles payment processing securely.

**Independent Test**: Navigate to Billing settings on a Free plan. Click "Upgrade to Pro", complete Stripe checkout (test card 4242...). Verify the plan changes to Pro. Cancel the subscription, verify plan shows "Pro (canceled — expires Aug 11, 2026)". Reactivate, verify it shows "Pro (active)". View invoices, verify the Pro invoice is listed.

**Acceptance Scenarios**:

1. **Given** the user clicks "Upgrade", **When** the Stripe checkout is completed, **Then** the account is upgraded immediately and a confirmation email is sent
2. **Given** an active subscription, **When** the user cancels, **Then** access continues until the end of the billing period and the plan shows "canceled" with an expiration date
3. **Given** a canceled subscription, **When** the user clicks "Reactivate", **Then** the subscription resumes and the user is charged on the next billing date

---

### User Story 4 - Team Plan and Seats (Priority: P3)

The Team plan supports multiple seats with centralized billing. The admin can: invite team members via email, assign roles (admin/member), view seat usage, and manage billing. Each seat has the same features as Pro. Seat count is billed per active member per month.

**Why this priority**: The Team plan addresses organizational use cases and increases revenue per customer.

**Independent Test**: On a Team plan, invite user "colleague@example.com" via email. Verify they receive an invitation email. When they accept, verify they appear as a team member. Verify the seat count increases to 2/5. Remove the team member, verify the seat count decreases and they lose access.

**Acceptance Scenarios**:

1. **Given** a Team plan admin, **When** they invite a new member, **Then** an invitation email is sent with a sign-up/accept link and the seat is marked as "pending"
2. **Given** a team member accepts the invitation, **When** they sign in, **Then** they have access to all Team plan features and the admin sees "active" status
3. **Given** a team member is removed, **When** the admin confirms, **Then** the member loses access immediately and the seat becomes available

---

### User Story 5 - Promotion Codes and Trials (Priority: P3)

The billing system supports: promotional/discount codes (percentage or fixed amount), free trials (e.g., 14-day Pro trial), and custom plans (enterprise). Promotion codes are applied at checkout. Trials automatically convert to paid subscriptions unless canceled.

**Why this priority**: Promotions drive conversions. Trials let users evaluate paid features before committing.

**Independent Test**: Apply promo code "PRO14" at checkout. Verify the Pro plan shows "14-day free trial, then $12/mo". Complete checkout with the promo. Verify the account shows "Pro (trial — expires Jul 25, 2026)" with no charge. After 14 days (simulated), verify the first invoice is created for $12/mo (or subscription is canceled if trial wasn't converted).

**Acceptance Scenarios**:

1. **Given** a promo code exists, **When** the user enters it at checkout, **Then** the discount is applied and the checkout total reflects it
2. **Given** a trial subscription, **When** the trial ends, **Then** the first payment is processed automatically and the user receives a receipt
3. **Given** a trial subscription, **When** the user cancels during the trial, **Then** no payment is processed and access continues until the trial end date

---

### Edge Cases

- What happens when a Stripe payment fails (expired card, insufficient funds)?
- How are refunds handled via Stripe?
- What happens when a user downgrades from Pro to Free mid-cycle?
- How is VAT/GST handled for different regions?
- What happens when a user has multiple subscriptions (upgrade/downgrade)?
- How are billing cycles handled across timezones?
- What happens when a promo code is used on an existing subscription?

## Requirements

### Functional Requirements

- **FR-001**: OSAI MUST offer at least three plan tiers: Free, Pro, and Team
- **FR-002**: Free plan MUST have usage limits: events per month, devices, storage, backup count
- **FR-003**: Pro plan MUST remove all usage limits and add cloud sync + backup
- **FR-004**: Team plan MUST include everything in Pro plus team management and centralized billing
- **FR-005**: Usage MUST be tracked per-user across: events, storage, devices, API calls, backup storage
- **FR-006**: Usage warnings MUST be shown at 80%, 90%, and 100% of limits
- **FR-007**: At 100%, affected features MUST be paused (not deleted) and resume when limit resets
- **FR-008**: Local OSAI functionality MUST NOT be affected by any plan limits
- **FR-009**: Billing MUST be handled via Stripe (checkout, subscriptions, invoices)
- **FR-010**: Users MUST be able to upgrade, cancel, and reactivate subscriptions self-serve
- **FR-011**: Canceled subscriptions MUST retain access until the end of the billing period
- **FR-012**: Team plan MUST support member invitation, role assignment, and removal
- **FR-013**: Team billing MUST be per active seat per month
- **FR-014**: Promotion codes MUST be supported (percentage, fixed amount, trial)
- **FR-015**: Free trials MUST be supported with automatic conversion to paid
- **FR-016**: Failed payments MUST trigger retry logic (3 retries over 7 days)
- **FR-017**: Plan changes MUST take effect within 10 seconds

### Key Entities

- **Plan**: A billing plan. Attributes: id, name, price, interval (month/year), features (map of feature flags and limits), stripePriceId.
- **Subscription**: A user's subscription. Attributes: id, userId, planId, status (active/canceled/past_due/trialing), currentPeriodStart, currentPeriodEnd, canceledAt, stripeSubscriptionId.
- **UsageRecord**: A usage record. Attributes: id, userId, metric (events/storage/devices/api/backup), value, periodStart, periodEnd, limit.
- **Team**: A team/organization. Attributes: id, name, ownerUserId, subscriptionId, seats (total), seatsUsed.
- **TeamMember**: A team member. Attributes: teamId, userId, role (admin/member), status (active/pending/removed), invitedEmail, acceptedAt.
- **PromoCode**: A promotional code. Attributes: id, code, type (percentage/fixed/trial), value, maxUses, usedCount, expiresAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Plan upgrade/downgrade takes effect in under 10 seconds
- **SC-002**: Stripe checkout flow completes in under 30 seconds (including redirect)
- **SC-003**: Usage tracking updates within 1 minute of event ingestion
- **SC-004**: Usage warnings are accurate within 1% of actual usage
- **SC-005**: Payment failure retry logic recovers 70%+ of initially failed payments
- **SC-006**: Team invitation accept flow completes in under 5 seconds
- **SC-007**: Zero local functionality is ever blocked by billing limits

## Assumptions

- Stripe is the sole payment processor (extensible to others later)
- Plans are monthly by default; annual plans offered at a discount
- Free plan limits: 10,000 events/month, 1 device, 1GB storage, local backup only
- Pro plan: $12/month or $120/year
- Team plan: $12/seat/month (min 3 seats)
- Usage tracking uses the cloud sync service's event counts
- Local events are counted toward limits only if synced to the cloud
- VAT/GST handling via Stripe Tax
- Refunds handled manually via Stripe dashboard (not self-serve for v1)
- Source code lives at `services/billing/` in the monorepo