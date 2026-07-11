# Feature Specification: Backup Service

**Feature Branch**: `036-backup-service`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build a backup service that creates periodic versioned snapshots of the user's entire knowledge base"

## User Scenarios & Testing

### User Story 1 - Automatic Periodic Backups (Priority: P1)

The backup service automatically creates snapshots of the user's knowledge base on a configurable schedule (default: daily). A snapshot includes: all events, entities, graph relationships, tags, projects, sessions, and settings. Backups are compressed, encrypted, and stored to a user-configurable location (local disk, cloud storage, or both).

**Why this priority**: Automatic backups prevent catastrophic data loss. This is a core reliability feature.

**Independent Test**: Configure backups to run daily to a local directory. After a day of activity, trigger a manual backup. Verify the backup file exists at the configured path, is compressed (e.g., .zst), and can be verified with the backup verification tool. Verify the backup includes all events, entities, and settings.

**Acceptance Scenarios**:

1. **Given** backup is configured for daily at 2 AM, **When** 2 AM arrives, **Then** a backup starts automatically and completes within the expected time window
2. **Given** a backup completes, **When** the user checks the backup location, **Then** a compressed, encrypted backup file exists with a filename containing the date and version (e.g., `osai-backup-2026-07-11-v123.enc.zst`)

---

### User Story 2 - Backup Verification and Integrity (Priority: P2)

Each backup includes a manifest and checksum for integrity verification. The user can run `osai verify-backup <path>` to check: file integrity, checksum match, manifest completeness, and that the backup can be decrypted with the current key. Corrupted backups are detected and reported.

**Why this priority**: A backup is only useful if it can be restored. Verification ensures backups aren't silently corrupted.

**Independent Test**: Create a backup, then corrupt a byte in the backup file (e.g., using a hex editor). Run `osai verify-backup backup.enc.zst` and verify it reports "Backup corrupted — checksum mismatch at offset 1234" with a non-zero exit code. Verify the original (uncorrupted) backup passes verification.

**Acceptance Scenarios**:

1. **Given** a valid backup file, **When** the user runs `osai verify-backup`, **Then** the verification passes with output "Backup OK — 1,247 events, 342 entities, 89 projects, 12 MB"
2. **Given** a corrupted backup file, **When** the user runs `osai verify-backup`, **Then** the verification fails with a specific error describing the corruption and its location

---

### User Story 3 - Selective Restore (Priority: P2)

Users can restore from a backup with granularity: full restore (replace all data), selective restore (choose what to restore: events only, entities only, settings only), and time-range restore (restore events from a specific date range). Restore is a guided process with a dry-run mode that shows what will be affected.

**Why this priority**: Full restore is destructive. Selective restore gives users flexibility to recover specific data without losing recent changes.

**Independent Test**: Run `osai restore-backup --dry-run backup.enc.zst` and verify it shows: "Would restore: 1,247 events, 342 entities, 89 projects, 25 sessions, settings. Current data would be replaced. Proceed? [y/N]" Then run a selective restore with `--type events --date-from 2026-07-01 --date-to 2026-07-07` and verify only events from that week are restored.

**Acceptance Scenarios**:

1. **Given** a backup file, **When** the user runs restore with `--dry-run`, **Then** a summary is shown of what will be restored without making any changes
2. **Given** a backup and current data, **When** the user runs `--type entities`, **Then** only entities are restored (events, projects, settings remain unchanged)
3. **Given** a restore in progress, **When** it completes, **Then** a summary is shown: "Restored 1,247 events, 342 entities. 15 events from current data were preserved (not in backup)."

---

### User Story 4 - Cloud Backup Destination (Priority: P3)

Users can configure backup destinations beyond local disk: S3-compatible storage (AWS S3, Cloudflare R2, MinIO), Google Drive, or a custom SFTP server. The backup service encrypts data client-side before uploading. Destinations are configured in settings with authentication (API keys, OAuth).

**Why this priority**: Cloud backups protect against local disk failure (the most common cause of data loss).

**Independent Test**: Configure an S3-compatible backup destination (e.g., Cloudflare R2) with access key and secret. Trigger a backup. Verify the backup file appears in the configured S3 bucket with the correct key prefix. Delete the local backup and verify it can be restored from the cloud destination.

**Acceptance Scenarios**:

1. **Given** an S3 destination is configured, **When** a backup completes, **Then** the encrypted backup file is uploaded to S3 at the configured path and the upload is verified
2. **Given** multiple backup destinations are configured (local + S3), **When** a backup completes, **Then** the backup is stored in all configured destinations

---

### User Story 5 - Backup History and Retention (Priority: P3)

The backup service maintains a history of all backups with metadata: timestamp, size, event count, version, and destination. Retention policies can be configured: keep all backups, keep last N, keep daily for 7 days + weekly for 4 weeks, or custom. Old backups are automatically pruned according to the policy.

**Why this priority**: Without retention management, backups consume unbounded storage. Automated pruning keeps storage predictable.

**Independent Test**: Configure retention policy "keep last 5 backups". Trigger 6 backups. Verify that after the 6th backup, only the 5 most recent backups exist in the backup history and old ones have been pruned from all destinations.

**Acceptance Scenarios**:

1. **Given** a retention policy of "keep daily for 7 days, weekly for 4 weeks", **When** backups are created, **Then** backups older than 7 days but same week are kept, and backups older than 4 weeks are pruned
2. **Given** the backup history panel, **When** the user views it, **Then** all backups are listed with date, size, event count, version, and destinations with a "Restore" button

---

### Edge Cases

- What happens when the backup destination is full or unavailable?
- How are very large knowledge bases backed up (100GB+)?
- What happens when a backup is interrupted (power loss, crash)?
- How are encryption keys managed for backup decryption?
- What happens when restoring to a different OSAI version?
- How are in-flight events (not yet committed) handled during backup?
- What happens when the user has never configured backup — is there a default?

## Requirements

### Functional Requirements

- **FR-001**: Backup service MUST create full snapshots of the knowledge base on a configurable schedule
- **FR-002**: A snapshot MUST include: all events, entities, graph relationships, tags, projects, sessions, and user settings
- **FR-003**: Backups MUST be compressed (zstd) and encrypted (AES-256-GCM) before storage
- **FR-004**: Backup files MUST include a manifest with checksum for integrity verification
- **FR-005**: Users MUST be able to verify backup integrity via CLI command
- **FR-006**: Users MUST be able to restore from backup — full or selective
- **FR-007**: Selective restore MUST support: by data type (events/entities/projects/settings), by date range, and by project
- **FR-008**: Restore MUST have a dry-run mode showing what will be affected
- **FR-009**: Backup destinations MUST support: local disk, S3-compatible, SFTP, and Google Drive
- **FR-010**: Backup destinations MUST be configurable in settings with authentication
- **FR-011**: Backup data MUST be encrypted client-side before uploading to any destination
- **FR-012**: Backup service MUST maintain a history of all backups with metadata
- **FR-013**: Retention policies MUST be configurable: count-based, time-based, or custom
- **FR-014**: Old backups MUST be automatically pruned according to retention policy
- **FR-015**: Pruning MUST remove backups from all configured destinations
- **FR-016**: Backup service MUST handle interruptions gracefully (partial files discarded on next run)
- **FR-017**: User MUST be notified on backup success and failure

### Key Entities

- **BackupSnapshot**: A backup snapshot. Attributes: id, version (integer, monotonic), createdAt, size, checksum, eventCount, entityCount, projectCount, sessionCount, compression, encryption, manifest.
- **BackupDestination**: A configured backup destination. Attributes: id, type (local/s3/sftp/gdrive), path/bucket, config (encrypted), status (active/error), lastSuccessAt.
- **BackupConfig**: User's backup configuration. Attributes: schedule (cron), retentionPolicy (type: count/time/custom, value), destinations (array of destination ids), enabled, lastBackupAt.
- **RestoreOperation**: A restore operation. Attributes: id, snapshotId, type (full/selective), selectors (data types, date range, projects), dryRun (bool), startedAt, completedAt, status, summary.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Backup of 1GB knowledge base completes in under 5 minutes (local disk)
- **SC-002**: Backup verification completes in under 30 seconds for a 1GB file
- **SC-003**: Restore of 1GB completes in under 10 minutes (local)
- **SC-004**: Selective restore query returns in under 2 seconds
- **SC-005**: Cloud backup upload completes within 2x the time of compression+encryption
- **SC-006**: Backup integrity: 100% of verified backups are restorable without error

## Assumptions

- Built as an OSAI service running locally (background process)
- Encryption key derived from user's master password (or stored in OS keychain)
- Backup files are append-only log-style snapshots (not incremental diffs for v1)
- Compression uses zstd at default level; encryption uses AES-256-GCM with random nonce
- S3-compatible storage via the AWS SDK (works with S3, R2, MinIO, Backblaze B2)
- Google Drive via their REST API with OAuth
- Backup history stored in local SQLite
- Retention policy evaluated daily after successful backup
- Default retention: keep last 30 daily backups
- Source code lives at `services/backup/` in the monorepo