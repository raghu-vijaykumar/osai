# Feature Specification: Event Classification

**Feature Branch**: `013-event-classification`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Classify events into categories like learning, building, researching, planning, communicating"

## User Scenarios & Testing

### User Story 1 - Classify Events by Activity Type (Priority: P1)

Every event is classified into an activity type: `learning` (reading docs, watching tutorials), `building` (writing code, creating files), `researching` (comparing options, browsing multiple sources), `planning` (design docs, architecture), `communicating` (Slack, email, meetings), `entertainment` (videos, games), or `other`.

**Why this priority**: Classification transforms raw events into meaningful activity categories. It powers the timeline summary ("3 hours learning, 2 hours building") and enables activity-based filtering.

**Independent Test**: Publish a `url.visited` event to a documentation page, verify it's classified as `learning`. Publish a `file.modified` event for a TypeScript file, verify it's classified as `building`.

**Acceptance Scenarios**:

1. **Given** a `url.visited` event to `https://react.dev/learn`, **When** classification runs, **Then** the event is tagged `activity: learning` with confidence > 0.7
2. **Given** a `file.modified` event for `src/components/Button.tsx`, **When** classification runs, **Then** the event is tagged `activity: building` with confidence > 0.8

---

### User Story 2 - Multi-Label Classification (Priority: P1)

Events can belong to multiple activity categories simultaneously. A `page.content` event about "how to deploy React apps on AWS" is both `learning` and `building`. Each label has an independent confidence score.

**Why this priority**: Real-world activities are rarely single-purpose. Multi-label classification captures the nuance — "I was building while learning" is different from "I was just reading."

**Independent Test**: Publish a page about "Tutorial: Building a REST API with Node.js" and verify it's classified as both `learning` (confidence > 0.7) and `building` (confidence > 0.5).

**Acceptance Scenarios**:

1. **Given** a page titled "How to deploy Next.js to AWS Lambda — Step by Step", **When** classified, **Then** labels include `learning` (>0.7) and `building` (>0.5)
2. **Given** a GitHub pull request page, **When** classified, **Then** labels include `collaborating` (>0.8) and optionally `building` if code files are mentioned

---

### User Story 3 - Source-Based Classification Heuristics (Priority: P2)

The classifier uses source-specific heuristics to boost accuracy. Pages from `docs.example.com` are more likely `learning`. Files with `.test.ts` extension are more likely `testing`. `git.commit` events with `"fix:"` prefix are `maintaining`.

**Why this priority**: Classification accuracy improves dramatically when source context is used. A URL is more informative than raw text for determining intent.

**Independent Test**: Visit a page on `stackoverflow.com` — verify it's classified as `researching` with higher confidence than if the same content appeared on a blog.

**Acceptance Scenarios**:

1. **Given** a `url.visited` event to `github.com/org/repo/pull/123`, **When** classified, **Then** `collaborating` confidence is boosted by 0.2 due to PR URL pattern
2. **Given** a `file.modified` event for `*.test.ts`, **When** classified, **Then** `testing` label is added with confidence > 0.7

---

### User Story 4 - Session-Level Classification (Priority: P2)

Beyond individual events, the classifier computes session-level activity distribution. A session where 80% of events are `building` and 20% are `learning` is tagged as a "building session" with a summary.

**Why this priority**: Session-level classification provides higher-level context than individual events. It answers "what did I spend my morning on?" without reading 200 individual events.

**Independent Test**: Create a session with 8 `building` events and 2 `learning` events, then query the session classification and verify it reports "80% building, 20% learning."

**Acceptance Scenarios**:

1. **Given** a session with 10 events across 3 activity types, **When** session classification runs, **Then** the session has `activityDistribution: { building: 0.6, learning: 0.3, researching: 0.1 }`
2. **Given** a session with dominant activity > 60%, **When** computing the session label, **Then** the session is assigned the dominant activity as its primary label

---

### User Story 5 - Custom Classification Rules (Priority: P3)

Users can define custom classification rules using patterns on event type, source, URL, file path, or text content. Rules can assign, boost, or suppress specific labels.

**Why this priority**: Classification needs are personal. A user working in fintech may want a `compliance` label for certain activities. Custom rules make the system adaptable.

**Independent Test**: Define a rule "if source is 'linear-app' then add label 'planning'", create a Linear ticket, and verify the event is classified as `planning`.

**Acceptance Scenarios**:

1. **Given** a user-defined rule `{ pattern: "source == 'slack'", label: "communicating", boost: 0.3 }`, **When** a Slack event arrives, **Then** `communicating` confidence is boosted by 0.3
2. **Given** a user-defined rule `{ pattern: "url contains 'youtube.com'", label: "entertainment", confidence: 0.9 }`, **When** a YouTube URL is visited, **Then** the event is classified as `entertainment`

---

### Edge Cases

- What happens when an event type doesn't map to any known classification (e.g., a new connector)?
- How are very short events (1-2 word page titles, empty content) classified?
- What happens when the classifier output changes after model retraining — are existing classifications updated?
- How are events in non-English languages classified?
- What happens when source heuristics conflict with content-based classification?
- How are private/incognito events treated differently in classification?
- What happens when the classifier is too slow and blocks the event pipeline?

## Requirements

### Functional Requirements

- **FR-001**: System MUST classify events into activity types: `learning`, `building`, `researching`, `planning`, `communicating`, `collaborating`, `testing`, `maintaining`, `entertainment`, `other`
- **FR-002**: System MUST support multi-label classification — each event can have multiple activity labels with independent confidence scores (0.0–1.0)
- **FR-003**: System MUST use a combination of approaches: event type heuristics, source patterns, URL patterns, file extension patterns, and text content classification
- **FR-004**: System MUST store classifications in an `event_classifications` table: `eventId`, `activity` (TEXT), `confidence` (REAL), `classifier` (TEXT — which method produced this)
- **FR-005**: System MUST use source-specific heuristics: `docs.*` → `learning`, `stackoverflow.com` → `researching`, `github.com/*/pull/*` → `collaborating`, `*.test.*` files → `testing`
- **FR-006**: System MUST use text content classification via a lightweight Naive Bayes or keyword-based classifier (initial) with option to upgrade to transformer-based classifier
- **FR-007**: System MUST compute session-level activity distribution by aggregating per-event classifications within a session
- **FR-008**: System MUST support user-defined classification rules in config: `{ pattern: string (CEL or glob), label: string, confidence: number, action: 'assign'|'boost'|'suppress' }`
- **FR-009**: System MUST run classification asynchronously after event storage
- **FR-010**: System MUST support batch backfilling — classify all existing events
- **FR-011**: System MUST publish `event.classified` events for observability
- **FR-012**: System MUST handle events with no text content gracefully — classify based on event type and source only
- **FR-013**: System MUST be configurable: `enabled`, `minConfidence` (default: 0.3), `classifiers` (ordered list of classifier methods to use)

### Key Entities

- **EventClassification**: A label assigned to an event. Attributes: `eventId`, `activity` (string), `confidence` (0.0–1.0), `classifier` (string — `heuristic`, `keyword`, `transformer`, `custom_rule`), `classifiedAt`.
- **ActivityType**: One of the defined activity categories. Each has a description and color for UI rendering. Configurable in `~/.osai/activities.json`.
- **ClassificationRule**: A user-defined or built-in rule. Attributes: `name`, `pattern` (CEL expression or glob), `label`, `confidence` (override value), `action` (`assign`, `boost`, `suppress`), `priority`.
- **SessionActivityDistribution**: Aggregated activity distribution for a session. Attributes: `sessionId`, `distribution` (map of activity → fraction 0.0–1.0), `primaryActivity`, `eventCount`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Single event classification completes in under 50ms (heuristic + keyword)
- **SC-002**: Batch classification of 1000 events completes in under 10 seconds
- **SC-003**: Overall classification accuracy > 85% (measured against hand-labeled test set of 500 events)
- **SC-004**: Source heuristic accuracy > 95% for well-known patterns (documentation, code review, etc.)
- **SC-005**: User-defined rules execute in under 5ms per event with 100 rules configured
- **SC-006**: Session-level aggregation for 1000 events completes in under 1 second

## Assumptions

- Initial classifier uses keyword-based approach with per-category keyword dictionaries + source heuristics
- Keywords are seeded per category: `learning` → ["tutorial", "guide", "docs", "learn", "documentation", "how to"], `building` → ["implement", "code", "build", "deploy", "PR"], etc.
- Source heuristics take precedence over keyword classifier (higher confidence weight)
- Text content classification is optional — if disabled, falls back to event type + source only
- Classification runs in a background worker queue, not in the event publishing path
- Activity types are configurable — users can add, remove, or rename categories
- English-first classification with basic support for other languages via URL patterns
- Any LLM-based classification uses the provider abstraction layer (spec 062) — keyword-based classifier is the default, with optional LLM-backed classification for ambiguous categories
- Source code lives at `knowledge-engine/classification/` in the monorepo
