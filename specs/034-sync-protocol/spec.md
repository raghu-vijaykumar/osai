# Feature Specification: Sync Protocol

**Feature Branch**: `034-sync-protocol`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Design a CRDT-based sync protocol for conflict-free multi-device event replication"

## User Scenarios & Testing

### User Story 1 - Multi-Device Event Sync (Priority: P1)

A user works on two devices — a desktop at work and a laptop at home. Events captured on device A are replicated to device B via the sync protocol. The protocol handles: offline periods (events queued and sent when online), concurrent edits (CRDT merge), and ordering guarantees (causal consistency). Sync happens in the background without user intervention.

**Why this priority**: Multi-device sync is the core value of Phase 5. Without it, users are locked to a single device.

**Independent Test**: Publish 100 events on device A while offline. Go online. Verify device B receives all 100 events in causal order within 30 seconds. Publish events concurrently on both devices and verify all events appear on both without data loss or corruption.

**Acceptance Scenarios**:

1. **Given** device A has 100 unsynced events, **When** it comes online, **Then** the sync protocol uploads all events within 30 seconds (for 100KB of events)
2. **Given** two devices each produce events concurrently, **When** they sync, **Then** both devices end up with the same set of events (eventually consistent) with no data loss
3. **Given** a network interruption during sync, **When** the connection is restored, **Then** the sync resumes from the interruption point without duplicating already-synced events

---

### User Story 2 - CRDT Conflict Resolution (Priority: P2)

When the same event is modified on two devices (e.g., both devices tag an event with different tags), the CRDT protocol resolves the conflict automatically. For event metadata (tags, notes, project assignment), the last-writer-wins (LWW) register is used. For event content, the merge strategy depends on the field type: add-wins set for tags, LWW for scalar values, and mergeable JSON for structured fields.

**Why this priority**: Automatic conflict resolution is essential for offline-first operation. Users shouldn't see merge conflicts.

**Independent Test**: On device A, tag event E1 with "important". On device B (offline), tag event E1 with "review". When both come online and sync, verify E1 has both tags "important" AND "review" (set merge), not one overwriting the other.

**Acceptance Scenarios**:

1. **Given** two devices add different tags to the same event, **When** they sync, **Then** the event's tag set is the union of both (no tags lost)
2. **Given** two devices modify the same scalar field (e.g., event title) on the same event, **When** they sync, **Then** the last-writer-wins rule is applied (deterministic based on timestamp + device ID tiebreaker)
3. **Given** an event is deleted on device A but modified on device B (offline), **When** they sync, **Then** the tombstone/delete marker wins (delete is treated as the final operation)

---

### User Story 3 - Causal Ordering and Dependencies (Priority: P2)

Events can depend on other events (e.g., a "file modified" event depends on a "file created" event; a tag depends on the event it tags). The sync protocol preserves causal dependencies: dependent events are not applied on the receiving device until their dependencies are present.

**Why this priority**: Causal ordering ensures that the event log makes sense across devices. Without it, a "file modified" event might appear before its "file created" event.

**Independent Test**: Create event E1 ("file created"), then event E2 ("file modified" with dependency on E1). Sync to device B, but simulate a delay where E2 arrives before E1. Verify E2 is held in a pending queue until E1 arrives, then both are applied in causal order.

**Acceptance Scenarios**:

1. **Given** event E2 depends on event E1, **When** E2 arrives at device B before E1, **Then** E2 is queued as pending and not applied until E1 arrives
2. **Given** a chain of 10 dependent events, **When** they are synced, **Then** they are applied in dependency order with causal consistency

---

### User Story 4 - Sync Status and Monitoring (Priority: P3)

Users can view sync status per device: last sync time, pending events, conflicts resolved, and bandwidth used. A sync indicator in the system tray shows sync status (in-sync / syncing / offline / error). Users can force a sync or pause/resume sync.

**Why this priority**: Sync visibility builds trust. Users need to know their data is being replicated correctly.

**Independent Test**: Open sync status panel and verify it shows: device name (Desktop-Work), last sync (2 minutes ago), pending (0), conflicts resolved today (3), bandwidth today (15MB). Go offline and verify indicator changes to "offline" and pending counter increases as events are captured.

**Acceptance Scenarios**:

1. **Given** sync is active, **When** the user opens sync status, **Then** per-device sync statistics are shown with last sync time and pending event count
2. **Given** the network is disconnected, **When** the user looks at the system tray, **Then** the sync indicator shows "offline" with pending event count
3. **Given** a sync error occurs (auth failure, server error), **When** the indicator updates, **Then** it shows "error" with a description and retry button

---

### Edge Cases

- What happens when two devices have the same device ID (cloned config)?
- How are very large event payloads handled (fragmentation)?
- What happens when the sync protocol version differs between devices?
- How is the initial sync (first-time, full history) handled vs. incremental sync?
- What happens when a device has been offline for months?
- How are deleted events handled during sync (tombstones)?
- What happens when the CRDT state grows too large?

## Requirements

### Functional Requirements

- **FR-001**: Sync protocol MUST use CRDTs for conflict-free merging of concurrent edits
- **FR-002**: Protocol MUST support: add-wins sets, last-writer-wins registers, and mergeable JSON
- **FR-003**: Protocol MUST provide causal consistency — dependent events are ordered correctly
- **FR-004**: Protocol MUST support offline operation — events queued locally and synced when online
- **FR-005**: Protocol MUST support resumable sync — interrupted syncs continue from the last checkpoint
- **FR-006**: Protocol MUST deduplicate events — same event synced twice is idempotent
- **FR-007**: Protocol MUST support event tombstones for deletion (soft delete with sync propagation)
- **FR-008**: Protocol MUST version the sync format — incompatible versions are detected and rejected
- **FR-009**: Protocol MUST support initial (full history) sync and incremental (differential) sync
- **FR-010**: Protocol MUST assign each event a unique ID (UUID v7, time-sortable) and device origin
- **FR-011**: Protocol MUST include event-level version vectors for causal tracking
- **FR-012**: Protocol MUST support encryption at the payload level (end-to-end)
- **FR-013**: Protocol MUST be bandwidth-efficient — delta compression for incremental sync
- **FR-014**: Protocol MUST expose sync statistics: pending count, last sync, bandwidth, conflicts
- **FR-015**: Sync status MUST be visible in the UI via an indicator and detail panel

### Key Entities

- **SyncEvent**: The sync protocol envelope for an event. Attributes: id (UUID v7), deviceId, timestamp, causalDependencies (array of event IDs), crdtType (lww/set/json), payload (encrypted), checksum.
- **VersionVector**: Causal tracking state. Attributes: deviceId, version (monotonic counter per device), eventId (last event from this device).
- **CRDTState**: The CRDT state for a mergeable data type. Types: LWWRegister (value, timestamp, deviceId), AddWinsSet (elements with add/remove tombstones), MergeableJSON (recursive merge strategy).
- **DeviceState**: Sync state per device. Attributes: deviceId, deviceName, lastSyncTime, pendingCount, totalSynced, lastError, status (in-sync/syncing/offline/error).
- **SyncBatch**: A batch of events for sync. Attributes: batchId, deviceId, events (array), versionVector, checksum, compressed (bool).

## Success Criteria

### Measurable Outcomes

- **SC-001**: Sync of 1000 events (100KB) completes in under 30 seconds over a 5Mbps connection
- **SC-002**: Conflict resolution completes in under 100ms per conflict
- **SC-003**: Causal ordering preserves 100% of dependencies
- **SC-004**: Protocol overhead is <10% of payload size (headers, metadata)
- **SC-005**: Initial sync of 100MB of data completes in under 5 minutes
- **SC-006**: Zero data loss in concurrent edit scenarios (verified by CRDT math property tests)

## Assumptions

- Protocol designed as a binary format (using Protocol Buffers or CBOR) for efficiency
- UUID v7 used for event IDs (time-sortable, unique across devices)
- Each device has a unique device ID generated at first run
- CRDT implementation uses well-known algorithms: LWW-Register, Observed-Remove Set, and JSON CRDTs (e.g., automerge or yjs-inspired)
- Causal dependencies tracked via version vectors (one per device)
- Encryption is payload-level (event content encrypted, metadata minimally visible)
- Sync batches are compressed with zstd or brotli
- Protocol spec will be published as a standalone document
- Source code lives at `protocol/sync/` in the monorepo