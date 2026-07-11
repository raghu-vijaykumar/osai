# Feature Specification: Cloud Sync Service

**Feature Branch**: `035-cloud-sync-service`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a cloud sync service that provides encrypted event replication between devices via the sync protocol"

## User Scenarios & Testing

### User Story 1 - Encrypted Event Replication (Priority: P1)

The cloud sync service acts as a relay between devices. Device A pushes encrypted sync batches to the service; device B pulls them. The service never sees decrypted content — encryption happens client-side. The service handles: device registration, batch storage, batch retrieval, and garbage collection of old batches.

**Why this priority**: Encrypted replication is the primary function. The service must be secure by design — zero-knowledge of user data.

**Independent Test**: Register two devices under the same account. On device A, create 10 events and let them sync. On device B, pull the latest sync batches. Verify device B receives and decrypts all 10 events. Verify the cloud service (by inspecting its database) cannot read event content — only encrypted blobs and metadata.

**Acceptance Scenarios**:

1. **Given** two devices registered to the same account, **When** device A pushes a sync batch, **Then** the service stores the encrypted batch and device B can pull it within 5 seconds
2. **Given** a sync batch is stored, **When** inspecting the service's database, **Then** event payloads are encrypted and the service only has access to: batch ID, device ID, timestamp, size, checksum

---

### User Story 2 - Device Registration and Management (Priority: P2)

Users register each device with the cloud service. Registration creates a device identity (key pair) and links it to the user's account. Devices are listed in the user's account settings with name, last sync time, and the option to revoke (remove) a device. Revoked devices can no longer sync.

**Why this priority**: Device management is essential for security. Users need to control which devices access their data and revoke access for lost/stolen devices.

**Independent Test**: Open Account Settings, go to "Devices" tab. Verify "Desktop-Work" and "Laptop-Home" are listed with last sync times. Click "Revoke" on "Laptop-Home". Verify the laptop shows a "Device revoked" error on next sync attempt and cannot sync until re-registered.

**Acceptance Scenarios**:

1. **Given** the user's account, **When** viewing the Devices tab, **Then** all registered devices are shown with name, model, last sync time, and a "Revoke" button
2. **Given** a device is revoked, **When** it attempts to sync, **Then** the service rejects the request with "Device revoked" error and logs the attempt
3. **Given** a new device, **When** the user completes registration, **Then** the device generates a key pair, registers the public key with the service, and receives a device token

---

### User Story 3 - Sync Queue and Delivery (Priority: P2)

The service maintains a per-device sync queue. When device A pushes batches, they are stored and made available for device B to pull. The service supports: push-only (device A sends, doesn't wait), pull (device B fetches when ready), and optional push-notification (device B is notified of new data). Batches have TTL (30 days by default) and are garbage-collected after all devices have pulled them.

**Why this priority**: Async queue decouples devices — they don't need to be online simultaneously. TTL prevents unbounded storage growth.

**Independent Test**: Device A pushes 3 sync batches. Device B is offline. Verify the service stores all 3 batches. 7 days later, device B comes online and pulls them. Verify device B receives all 3 batches. If device B doesn't pull for 31 days, verify the batches are garbage-collected after 30 days.

**Acceptance Scenarios**:

1. **Given** device A pushes batches, **When** device B is offline, **Then** batches are stored in device B's sync queue with a TTL of 30 days
2. **Given** a batch in the queue, **When** all target devices have pulled it, **Then** the batch is immediately eligible for garbage collection
3. **Given** a batch exceeds its TTL, **When** garbage collection runs, **Then** the batch is deleted regardless of whether all devices pulled it

---

### User Story 4 - Conflict Log and Resolution History (Priority: P3)

When the CRDT protocol resolves conflicts during sync, the cloud service logs the conflict metadata (which fields, which devices, resolution strategy). Users can view a conflict resolution history in their account settings. This helps debug unexpected sync behavior.

**Why this priority**: Conflict transparency helps users understand sync behavior and debug issues.

**Independent Test**: Trigger a conflict (edit same event tag on two devices offline). After sync, open the conflict log. Verify it shows: "Event E1: field 'tags' merged via add-wins set — device A added 'important', device B added 'review' — result: {'important', 'review'}"

**Acceptance Scenarios**:

1. **Given** a CRDT conflict was resolved, **When** the user views the conflict log, **Then** it shows: event ID, field, resolution strategy, devices involved, and the merge result
2. **Given** the conflict log, **When** the user filters by device, **Then** only conflicts involving that device are shown

---

### User Story 5 - Bandwidth and Storage Controls (Priority: P3)

Users can configure sync behavior: sync only on Wi-Fi (not cellular), limit bandwidth usage (e.g., max 1Mbps), choose which data types to sync (e.g., events only, not embeddings), and set a storage limit for the cloud queue. The service respects these preferences.

**Why this priority**: Bandwidth and storage controls prevent unexpected data charges and give users fine-grained control.

**Independent Test**: Configure sync to "Wi-Fi only" on a laptop. Verify sync pauses when on cellular and resumes when Wi-Fi is available. Set bandwidth limit to 500Kbps and verify the sync throttles to approximately that rate.

**Acceptance Scenarios**:

1. **Given** sync is set to "Wi-Fi only", **When** the device is on cellular, **Then** sync is paused (events queued locally) and resumes when Wi-Fi is available
2. **Given** a bandwidth limit of 500Kbps, **When** sync is active, **Then** the measured throughput does not exceed 500Kbps averaged over 10 seconds

---

### Edge Cases

- What happens when the cloud service is down for maintenance?
- How are very large files (e.g., screenshots, PDFs) handled in sync?
- What happens when a device has been revoked but has pending data to push?
- How is the initial full sync of a new device handled efficiently?
- What happens when the user exceeds their storage quota?
- How are partial failures handled (some batches succeed, some fail)?
- What happens when two devices have incompatible protocol versions?

## Requirements

### Functional Requirements

- **FR-001**: Cloud sync service MUST provide encrypted event relay between devices
- **FR-002**: Service MUST be zero-knowledge — cannot read decrypted event content
- **FR-003**: Service MUST support device registration with public key authentication
- **FR-004**: Users MUST be able to view and revoke registered devices
- **FR-005**: Revoked devices MUST be immediately blocked from sync
- **FR-006**: Service MUST maintain a per-device sync queue with TTL-based garbage collection
- **FR-007**: Sync queue MUST support: push (sender), pull (receiver), and notification (web push)
- **FR-008**: Batches MUST be removed from the queue after all target devices have pulled them
- **FR-009**: Default batch TTL MUST be 30 days (configurable)
- **FR-010**: Service MUST log conflict resolution metadata for user review
- **FR-011**: Service MUST support user-configurable sync preferences: Wi-Fi only, bandwidth limit, data type filter
- **FR-012**: Service MUST compress sync batches for efficient transfer
- **FR-013**: Service MUST handle partial failures with retry logic (exponential backoff, max 5 retries)
- **FR-014**: Service MUST enforce per-user storage quotas
- **FR-015**: Service MUST be horizontally scalable — stateless sync workers

### Key Entities

- **DeviceRegistration**: A registered device. Attributes: deviceId, deviceName, deviceModel, publicKey, userId, registeredAt, lastSyncAt, status (active/revoked), preferences (wiFiOnly, bandwidthLimit, dataTypeFilters).
- **SyncBatch**: A batch of synced events stored in the queue. Attributes: batchId, sourceDeviceId, targetDeviceIds (array), encryptedPayload, checksum, size, compressed, createdAt, ttl, status (pending/partial/consumed/expired).
- **ConflictRecord**: A logged conflict resolution. Attributes: id, eventId, field, strategy, devices (array of deviceIds), mergeResult (summary), timestamp.
- **UserQuota**: Storage quota for a user. Attributes: userId, storageUsed, storageLimit, eventCount, deviceLimit, createdAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Batch push+pull round-trip completes in under 1 second (for <100KB batch)
- **SC-002**: Service handles 10,000 concurrent sync connections without degradation
- **SC-003**: P99 latency for batch storage < 200ms
- **SC-004**: Zero-knowledge guarantee: no plaintext event content leaks in service logs or DB
- **SC-005**: Queue TTL enforcement: 100% of expired batches are garbage collected within 1 hour
- **SC-006**: Device revocation takes effect within 10 seconds

## Assumptions

- Built as a cloud service (Node.js/TypeScript on a serverless or container platform)
- Uses PostgreSQL for device registration, queue metadata, and conflict logs
- Encrypted blobs stored in object storage (S3/R2) with metadata pointers in PostgreSQL
- Authentication via JWT tokens issued by the auth service (spec 037)
- Push notifications via Web Push API (or Firebase Cloud Messaging)
- Compression via zstd at the application layer
- Service is deployed with TLS everywhere; internal traffic also encrypted
- Service is stateless — scales horizontally behind a load balancer
- Source code lives at `services/cloud-sync/` in the monorepo
- Infrastructure as code via Terraform/Pulumi (separate repo or directory)