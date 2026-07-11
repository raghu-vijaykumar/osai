# Feature Specification: Entity Extraction

**Feature Branch**: `012-entity-extraction`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Extract entities like people, technologies, topics, and projects from event text content"

## User Scenarios & Testing

### User Story 1 - Extract Technologies and Topics (Priority: P1)

When a `page.content` event arrives about "Kubernetes pod deployment with Istio service mesh", the entity extractor identifies "Kubernetes" and "Istio" as technologies and stores them as entities linked to the event.

**Why this priority**: Technology extraction is the highest-value entity type. It powers "what is the user learning about" queries and enables the recommendation engine to suggest related content.

**Independent Test**: Publish a `page.content` event with text about "React 18 server components with Next.js 13", then query entities and verify "React", "Next.js" are extracted with type "technology".

**Acceptance Scenarios**:

1. **Given** a page about "TypeScript 5.0 decorators and Node.js 20 performance", **When** entity extraction runs, **Then** entities `TypeScript`, `Node.js` are extracted with type `technology` and confidence > 0.8
2. **Given** the same page, **When** processed, **Then** entities are stored with a relationship `mentions` linking the entity to the source event

---

### User Story 2 - Extract People and Organizations (Priority: P1)

From a page about a blog post or news article, the extractor identifies mentioned people (authors, contributors) and organizations (companies, projects, foundations).

**Why this priority**: People and organization entities link the user's research across sources — "I've been reading about xAI, Anthropic, and OpenAI across multiple tabs and papers."

**Independent Test**: Publish a `page.content` event about "Anthropic's Claude 3.5 Sonnet model outperforms GPT-4o on coding benchmarks", then verify "Anthropic" is extracted as an organization and "Claude" as a product/technology.

**Acceptance Scenarios**:

1. **Given** text mentioning "Satya Nadella announced Microsoft Copilot", **When** entity extraction runs, **Then** `Microsoft` is extracted as `organization` and `Satya Nadella` as `person`
2. **Given** a mention of "Distil-Whisper by Hugging Face", **When** processed, **Then** `Hugging Face` is extracted as `organization` and `Distil-Whisper` as `technology`

---

### User Story 3 - Frequency and Confidence Tracking (Priority: P2)

Entities track how many times they've been seen across events and the confidence of each extraction. High-confidence entities that appear across multiple events are promoted as "strong interests."

**Why this priority**: Frequency signals importance. A technology seen once in a passing mention is less significant than one seen 20 times across browser, IDE, and PDF sources.

**Independent Test**: Publish 5 events mentioning "Rust" across browser pages and code files, then query the entity and verify `mentionCount: 5` and `lastSeen: <recent timestamp>`.

**Acceptance Scenarios**:

1. **Given** "WebAssembly" is mentioned in 3 different events, **When** querying the entity, **Then** `mentionCount: 3`, `firstSeen` and `lastSeen` timestamps are correct
2. **Given** "WebAssembly" was mentioned with confidence 0.95 in 2 events and 0.6 in 1 event, **When** querying, **Then** `avgConfidence: 0.83`

---

### User Story 4 - Cross-Event Entity Resolution (Priority: P2)

The same entity mentioned with different casing, abbreviations, or aliases is resolved to a single canonical entity. E.g., "JS", "JavaScript", and "ECMAScript" are recognized as related but distinct entities; "AI", "ML", "artificial intelligence" are linked.

**Why this priority**: Without resolution, the graph would contain duplicate nodes for the same real-world entity. This fragment the knowledge graph.

**Independent Test**: Publish events mentioning "JS" and "JavaScript" and verify they are stored as separate entities but linked with a `related` relationship and a note that they may refer to the same concept.

**Acceptance Scenarios**:

1. **Given** events mentioning "MCP" and "Model Context Protocol", **When** entity extraction runs, **Then** both are extracted and linked with a `related` edge with `type: abbreviation`
2. **Given** events mentioning "Claude" (the AI assistant) and "Claude" (a person's name), **When** processed, **Then** they are disambiguated by context into separate entities with different types

---

### User Story 5 - Custom Entity Definitions (Priority: P3)

Users can define custom entity patterns (regex or keywords) for domain-specific terms relevant to their work. These are merged with the default NLP-based extraction.

**Why this priority**: Users working on specialized domains (bioinformatics, finance, law) need to extract domain-specific terminology that general-purpose NLP models don't recognize.

**Independent Test**: Define a custom entity pattern for "CRISPR-Cas9" as a technology, publish a page mentioning it, and verify it's extracted with the user-defined type.

**Acceptance Scenarios**:

1. **Given** a custom entity pattern `{ "pattern": "CRISPR-*", "type": "technology", "domain": "biotech" }`, **When** a page mentions "CRISPR-Cas9", **Then** it's extracted with the configured type
2. **Given** a custom entity defined in `~/.osai/entities.json`, **When** the extractor starts, **Then** custom patterns are merged with the default extractors

---

### Edge Cases

- What happens when entity extraction text exceeds the NLP model's input length (512 tokens)?
- How are false positives handled — entities extracted from code snippets that aren't real technologies?
- What happens when the extractor encounters text in a language not supported by the model?
- How are very common words that look like entities (e.g., "Apple" the fruit vs "Apple" the company) disambiguated?
- What happens when an entity is mentioned across 1000+ events (performance of mention counting)?
- How are entities in URL paths extracted (e.g., `github.com/vercel/next.js` → "next.js")?
- What happens when the same entity is extracted with different types from different contexts?

## Requirements

### Functional Requirements

- **FR-001**: System MUST extract entities from event text content with types: `technology`, `person`, `organization`, `topic`, `product`, `language`, `framework`, `library`, `concept`
- **FR-002**: System MUST use a local NLP pipeline (compromise/tokenizer + custom NER patterns, or a small transformer model like `dslim/bert-base-NER`)
- **FR-003**: System MUST assign a confidence score (0.0–1.0) to each extracted entity
- **FR-004**: System MUST store entities in an `entities` table with columns: `id` (TEXT PK), `name` (TEXT), `type` (TEXT), `canonicalName` (TEXT), `mentionCount` (INT), `avgConfidence` (REAL), `firstSeen` (TEXT), `lastSeen` (TEXT)
- **FR-005**: System MUST store entity-event links in an `entity_mentions` table: `entityId`, `eventId`, `confidence`, `context` (surrounding text snippet), `position` (char offset in source text)
- **FR-006**: System MUST support entity aliases — alternative names that refer to the same canonical entity
- **FR-007**: System MUST support entity relationships — edges between entities with types: `related`, `abbreviation_of`, `part_of`, `depends_on`, `alternative_to`
- **FR-008**: System MUST support custom entity patterns defined by the user in config as `{ pattern: string (glob/regex), type: string, confidence?: number }`
- **FR-009**: System MUST run entity extraction asynchronously after event storage (like embeddings)
- **FR-010**: System MUST support batch backfilling — extract entities from all existing events
- **FR-011**: System MUST deduplicate entities — the same entity name+type combination maps to one canonical entity row
- **FR-012**: System MUST publish `entity.extracted` and `entity.merged` (when aliases are resolved) events for observability
- **FR-013**: System MUST support entity extraction config: `enabled` (bool), `customPatterns` (array), `minConfidence` (default: 0.5), `models` (array of extractor names)

### Key Entities

- **Entity**: A canonical entity in the knowledge graph. Attributes: `id`, `name`, `type`, `canonicalName` (normalized form), `description`, `mentionCount`, `avgConfidence`, `firstSeen`, `lastSeen`, `aliases` (array of strings).
- **EntityMention**: A link between an entity and an event where it was mentioned. Attributes: `entityId`, `eventId`, `confidence`, `context` (50-char surrounding text), `position` (start offset in source).
- **EntityRelation**: A typed relationship between two entities. Attributes: `sourceEntityId`, `targetEntityId`, `type`, `weight` (0.0–1.0), `discoveredAt`.
- **CustomEntityPattern**: A user-defined extraction rule. Attributes: `pattern` (glob string or regex), `type`, `confidence`, `domain` (optional context tag).
- **EntityExtractor**: An NLP pipeline component. Types: `ner` (named entity recognition), `keyword` (TF-IDF based), `pattern` (regex/glob), `custom` (user-defined).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Entity extraction for a single event completes in under 200ms
- **SC-002**: Batch extraction of 100 events completes in under 30 seconds
- **SC-003**: Precision > 0.85 on technology entity extraction (measured against a test set of 100 pages)
- **SC-004**: Recall > 0.75 on technology entity extraction
- **SC-005**: Entity deduplication merges > 90% of same-entity variants (e.g., "JS" → "JavaScript")
- **SC-006**: Custom pattern matching completes in under 10ms per event regardless of pattern count

## Assumptions

- Primary NER uses `compromise` (lightweight, client-side NLP for English) with custom patterns for technology names
- Technology entity patterns are seeded from a built-in dictionary of ~1000 known technologies (languages, frameworks, tools, platforms) — expandable via user config
- Person names are extracted using NNP (proper noun) patterns and capitalization heuristics
- Confidence scores are computed from: extractor reliability (0.8 for NER, 0.6 for keyword, 1.0 for exact custom pattern match), frequency across corpus, and context quality
- Entity normalization: lowercase, strip trailing punctuation, resolve Unicode normalization form NFC
- Maximum 50 entities extracted per event (to limit noise from generic content)
- Source code lives at `knowledge-engine/entity-extraction/` in the monorepo
