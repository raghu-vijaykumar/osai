# Feature Specification: Recommendation Agent

**Feature Branch**: `029-recommendation-agent`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a recommendation agent that proactively suggests relevant content, actions, and connections based on user context"

## User Scenarios & Testing

### User Story 1 - Proactive Content Recommendations (Priority: P1)

The recommendation agent watches the user's current activity and proactively suggests related content. When the user is reading about a topic, the agent surfaces a toast notification: "You read about this 2 weeks ago — see your notes." Recommendations appear in the dashboard "Recommended" section and as subtle in-app notifications.

**Why this priority**: Proactive recommendations transform OSAI from a passive recorder into an active assistant. Users discover connections they'd otherwise miss.

**Independent Test**: While the user browses a page about "CRDT conflict resolution", verify a recommendation appears within 30 seconds: "You read about CRDTs on July 5th — 3 related events" with a clickable link to those events.

**Acceptance Scenarios**:

1. **Given** the user is viewing content about "Rust ownership", **When** the recommendation agent processes the current context, **Then** within 30 seconds a recommendation card appears showing "Related: Your Rust learning session from last week" with a link
2. **Given** no related content exists, **When** the user views new content, **Then** no recommendation is shown (no false positives)

---

### User Story 2 - Next Action Suggestions (Priority: P2)

Based on user patterns and current context, the recommendation agent suggests next actions: "You usually review PRs after lunch — 3 PRs need your attention", "You were in the middle of debugging issue #42 — want to continue?", "It's been 2 hours since your last break."

**Why this priority**: Next action suggestions help users maintain flow and avoid forgetting interrupted tasks.

**Independent Test**: After a user has been coding for 2 hours without a break, verify the recommendation agent shows "Time for a break? You've been focused for 2 hours." After the user pauses a debugging session, verify a suggestion appears: "You left off debugging issue #42. Resume?" within 5 minutes.

**Acceptance Scenarios**:

1. **Given** the user typically opens GitHub at 2 PM, **When** it's 2 PM and they're idle, **Then** a suggestion appears: "You usually check GitHub around now — 5 unread notifications"
2. **Given** the user was reading a page about "Kubernetes networking" and closed it, **When** they open the knowledge base later, **Then** a suggestion appears: "You were reading about Kubernetes networking — here's a related guide"

---

### User Story 3 - Knowledge Gap Detection (Priority: P3)

The agent analyzes the user's knowledge graph and identifies gaps — topics the user frequently encounters but hasn't saved or explored deeply. For example, if the user often reads about "WebAssembly" but has no saved notes or projects about it, the agent suggests: "You've encountered WebAssembly 15 times but haven't saved anything about it. Want to create a project?"

**Why this priority**: Knowledge gap detection helps users identify blind spots and areas they should invest more time in understanding.

**Independent Test**: After 10+ events mentioning "Tauri" across browser and VSCode, verify the recommendation agent suggests: "You've encountered Tauri 12 times — consider creating a project to track your learning." Click "Create Project" and verify a project is pre-filled.

**Acceptance Scenarios**:

1. **Given** an entity appears in 10+ events but has no project or notes, **When** the agent runs gap analysis, **Then** a recommendation appears: "Entity X appears 12 times without dedicated project. Create one?"
2. **Given** the user dismisses the same gap recommendation 3 times, **When** the agent detects the same gap, **Then** it stops suggesting that particular gap (learns from dismissal)

---

### User Story 4 - Weekly Digest Recommendations (Priority: P3)

At the end of each week, the recommendation agent compiles a "Weekly Digest" of recommendations: content to revisit, connections discovered, gaps identified, and patterns observed. This is delivered alongside the weekly summary.

**Why this priority**: The weekly digest gives users a curated set of insights and actions, not just raw statistics.

**Independent Test**: After a week of activity, check the weekly digest. Verify it includes: "Content to Revisit" (3 items with reasons), "Connections Discovered" (2 unexpected connections), "Gaps Identified" (2 topics to explore), "Patterns" (1 work pattern observation).

**Acceptance Scenarios**:

1. **Given** a week of activity with gaps detected, **When** the weekly digest is generated, **Then** it includes a "Gaps to Explore" section with entity names, appearance counts, and "Create Project" buttons
2. **Given** the user has patterns (e.g., always researches on Friday afternoons), **When** the digest is generated, **Then** it notes the pattern: "You tend to do research on Friday afternoons — here's what you explored this week"

---

### User Story 5 - Interactive Recommendation Feedback (Priority: P3)

Users can provide feedback on recommendations: 👍 (relevant), 👎 (not relevant), "Don't show this type again". The agent learns from feedback, adjusting its recommendation model. Feedback is used to improve both content and timing of future recommendations.

**Why this priority**: Feedback loops make recommendations smarter over time. Without it, the agent repeats irrelevant suggestions.

**Independent Test**: Give a 👎 on a recommendation about "Project: WebAssembly". Verify similar recommendations about project creation for WebAssembly stop appearing. Give a 👍 on a recommendation about "Revisit: Rust borrow checker". Verify more "revisit" style recommendations appear.

**Acceptance Scenarios**:

1. **Given** a recommendation is visible, **When** the user clicks 👎, **Then** the recommendation dismisses with a "Thanks for feedback" animation and similar recommendations are suppressed
2. **Given** the user clicks "Don't show this type again" on a gap detection recommendation, **When** future gap detections occur, **Then** they are not shown to the user

---

### Edge Cases

- What happens when the user has no activity (first-time user)?
- How are recommendations throttled to avoid notification fatigue?
- What happens when the recommendation engine is still building its model?
- How are time-sensitive recommendations vs. evergreen ones differentiated?
- What happens when the user is in a deep work session — should recommendations be suppressed?
- How are multiple competing recommendations prioritized?

## Requirements

### Functional Requirements

- **FR-001**: Recommendation agent MUST proactively surface related content based on current user activity
- **FR-002**: Content recommendations MUST appear within 30 seconds of relevant activity
- **FR-003**: Recommendations MUST be shown as in-app notifications and in the dashboard "Recommended" section
- **FR-004**: Agent MUST suggest next actions based on user patterns and context
- **FR-005**: Next action suggestions MUST include: description, reason, and action button
- **FR-006**: Agent MUST detect knowledge gaps — entities with high appearance count but no project/notes
- **FR-007**: Knowledge gap recommendations MUST include: entity name, appearance count, and "Create Project" action
- **FR-008**: Agent MUST generate a weekly digest of recommendations
- **FR-009**: Weekly digest MUST include: content to revisit, connections discovered, gaps identified, patterns observed
- **FR-010**: Users MUST be able to provide feedback: 👍, 👎, "Don't show this type again"
- **FR-011**: Agent MUST learn from feedback and adjust future recommendations
- **FR-012**: Agent MUST throttle recommendations to avoid notification fatigue (max 3 per hour by default)
- **FR-013**: Agent MUST suppress recommendations during deep work sessions (configurable)
- **FR-014**: Recommendation priority MUST be based on: relevance score, time sensitivity, user feedback history, and recency
- **FR-015**: Agent MUST defer to the recommendation engine (spec 017) for content similarity computation
- **FR-016**: Agent MUST be available as an MCP tool via the MCP server

### Key Entities

- **Recommendation**: A single recommendation item. Attributes: id, type (content/action/gap/digest), title, description, reason, sourceEntityId, targetAction (optional: link/button config), priority, deliveredAt, feedback (enum: like/dislike/dismiss/learned).
- **RecommendationFeedback**: User feedback on a recommendation. Attributes: recommendationId, userId, feedback (like/dislike/dismiss/dontShowAgain), reason (optional), createdAt.
- **KnowledgeGap**: A detected knowledge gap. Attributes: entityId, entityName, appearanceCount, firstSeen, lastSeen, hasProject (bool), hasNotes (bool), dismissed (bool), dismissedCount.
- **WeeklyDigest**: Weekly compilation of recommendations. Attributes: weekStart, weekEnd, contentToRevisit (array of items), connectionsDiscovered (array), gapsIdentified (array), patternsObserved (array), generatedAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Content recommendations appear within 30 seconds of relevant activity
- **SC-002**: Recommendation relevance: 60%+ of recommendations receive 👍 or no feedback (not 👎)
- **SC-003**: Notification frequency: <3 recommendations per hour (respects throttle)
- **SC-004**: Weekly digest generation completes in under 10 seconds
- **SC-005**: Agent learns from feedback: repeated 👎 on a type reduces its frequency by 50% within 1 week
- **SC-006**: User satisfaction: 70%+ of users find recommendations "useful" in periodic surveys

## Assumptions

- Built as an OSAI agent running in the background process
- Uses the recommendation engine (spec 017) for content similarity computation
- Uses entity extraction (spec 012) for gap detection
- Uses the session detection (spec 016) for deep work session awareness
- Recommendations stored in a local queue with delivery timestamps for throttling
- Feedback stored in user preferences and used to weight future recommendations
- Weekly digest generated on the same schedule as the weekly summary (spec 026)
- Notifications use the in-app notification system
- ML model for recommendations is simple (weighted scoring) initially, can be upgraded later
- Source code lives at `agents/recommender/` in the monorepo