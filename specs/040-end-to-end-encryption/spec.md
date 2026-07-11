# Feature Specification: End-to-End Encryption

**Feature Branch**: `040-end-to-end-encryption`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Add end-to-end encryption for cloud-synced data so the service never has access to plaintext user content"

## User Scenarios & Testing

### User Story 1 - E2E Encryption for Cloud Sync (Priority: P1)

All data synced to the cloud is encrypted end-to-end. Encryption happens on the sending device before the data leaves. Decryption happens on the receiving device after download. The cloud service only sees encrypted blobs. The encryption key is derived from the user's account password and never sent to the server.

**Why this priority**: E2E encryption is the foundation of OSAI's zero-knowledge promise. Without it, users must trust the cloud provider with their plaintext data.

**Independent Test**: Enable E2E encryption in settings (requires account password). After enabling, sync events from device A to the cloud. Inspect the cloud service's database — verify event payloads are encrypted binary blobs (not readable text). On device B, pull the events and verify they are decrypted correctly and readable.

**Acceptance Scenarios**:

1. **Given** E2E encryption is enabled, **When** device A pushes events to the cloud, **Then** the event payloads are encrypted before transmission and the server stores only ciphertext
2. **Given** E2E encryption is enabled, **When** device B pulls events from the cloud, **Then** they are decrypted client-side and the user sees plaintext
3. **Given** E2E encryption is enabled, **When** inspecting the cloud service's data storage, **Then** event payloads are binary ciphertext and metadata (timestamps, IDs, sizes) is minimal

---

### User Story 2 - Key Management (Priority: P1)

Encryption keys are managed entirely client-side. The key hierarchy: a master key is derived from the user's account password via Argon2id. The master key encrypts a device-specific key pair (X25519) and a symmetric storage key (AES-256). Device keys are used for device-to-device encryption. Keys are stored in the OS keychain (or an encrypted local file).

**Why this priority**: Proper key management is critical for security. The key hierarchy ensures that changing the password re-encrypts keys without re-encrypting all data.

**Independent Test**: Enable E2E encryption, verify a key file is created in the OS keychain (or ~/.osai/keys/). Change the account password, verify the keys are re-encrypted with the new password. On another device, sign in with the new password, verify the device generates its own key pair and can decrypt synced data.

**Acceptance Scenarios**:

1. **Given** E2E encryption is enabled, **When** the user views Security settings, **Then** they see "Encryption: Active" with key creation date and an option to rotate keys
2. **Given** the user changes their password, **When** the password change completes, **Then** the local key store is re-encrypted with the new password (data itself is not re-encrypted)
3. **Given** a new device signs in, **When** the account password is entered, **Then** the master key is derived, and the device generates its own key pair for device-to-device encryption

---

### User Story 2 (duplicate number, should be 3) - Secure Device Addition (Priority: P2)

Adding a new device with E2E encryption requires verifying the user's identity. The new device derives the master key from the user's password. For devices that should have access without the password (e.g., a spouse's shared device), a key escrow or share mechanism is used: the existing device generates a one-time enrollment code that authorizes the new device.

**Why this priority**: Secure device enrollment prevents unauthorized devices from accessing encrypted data while making legitimate enrollment convenient.

**Independent Test**: On device A (already enrolled), go to Settings > Encryption > "Authorize New Device". A one-time code is displayed: "OSAI-2F3K-8X7P". On device B (not enrolled), enter the code. Verify device B receives the encryption keys and can decrypt synced data. Verify the code is single-use and expires after 5 minutes.

**Acceptance Scenarios**:

1. **Given** an enrolled device, **When** the user generates an enrollment code, **Then** a one-time code (8 alphanumeric characters) is displayed with a 5-minute timer
2. **Given** a new device, **When** the user enters a valid enrollment code, **Then** the device receives the encryption keys and is authorized
3. **Given** an enrollment code has been used or has expired, **When** someone tries to use it, **Then** the server rejects it with "Invalid or expired enrollment code"

---

### User Story 3 (should be 4) - Encrypted Backup (Priority: P3)

Backups are encrypted with the same E2E keys as synced data. Backup files stored in the cloud (S3, etc.) are encrypted client-side before upload. The backup service cannot read backup contents. Restoring a backup requires the user's account password (to derive the master key).

**Why this priority**: E2E-encrypted backups ensure that even if the cloud storage is breached, backup data remains confidential.

**Independent Test**: Enable E2E encryption. Create a backup to cloud storage (S3). Download the backup file and inspect it — verify it's encrypted binary (header identifies it as an OSAI encrypted backup). Restore the backup on a different device by providing the account password. Verify all data is restored correctly.

**Acceptance Scenarios**:

1. **Given** E2E encryption is enabled, **When** a backup is created to the cloud, **Then** the backup file is encrypted with the user's master key before upload
2. **Given** an encrypted backup, **When** the user attempts to restore it, **Then** they are prompted for their account password to derive the decryption key
3. **Given** the wrong password is entered during restore, **When** decryption fails, **Then** the user sees "Incorrect password — backup could not be decrypted"

---

### User Story 4 (should be 5) - Key Rotation and Recovery (Priority: P3)

Users can rotate their encryption keys. Key rotation generates new keys and re-encrypts data with the new keys (background process for existing data). If a user forgets their password, a recovery key (generated at account creation) can be used. The recovery key is a 24-word BIP39 mnemonic that must be stored securely offline.

**Why this priority**: Key rotation mitigates the impact of potential key compromise. Recovery keys prevent permanent data loss from forgotten passwords.

**Independent Test**: In Security settings, click "Rotate Encryption Keys". Verify existing data is re-encrypted with the new key (background process). During account creation with E2E enabled, verify a 24-word recovery phrase is displayed — download/store it. After rotating keys, use the recovery phrase on a new device and verify it can decrypt the data.

**Acceptance Scenarios**:

1. **Given** the user clicks "Rotate Keys", **When** they confirm, **Then** new keys are generated and existing data is re-encrypted in the background (progress is shown)
2. **Given** a recovery phrase was saved, **When** the user forgets their password, **Then** they can enter the 24-word phrase to regain access and set a new password
3. **Given** the user enters an incorrect recovery phrase, **When** verification fails, **Then** they see "Invalid recovery phrase — please check and try again" with remaining attempts

---

### Edge Cases

- What happens when E2E encryption is enabled mid-sync (previously unencrypted data)?
- How are very large encryption/decryption operations handled (background, non-blocking)?
- What happens when a device's key store is corrupted?
- How is encryption algorithm agility handled (upgrading algorithms)?
- What happens when all devices are lost and the user has no recovery phrase?
- How are metadata leaks minimized (timestamps, event counts, device IDs)?
- What happens when the OS keychain is unavailable?

## Requirements

### Functional Requirements

- **FR-001**: ALL cloud-synced data MUST be encrypted end-to-end before leaving the device
- **FR-002**: Cloud service MUST be zero-knowledge — no access to plaintext event content
- **FR-003**: Encryption keys MUST be derived from the user's account password
- **FR-004**: Key derivation MUST use Argon2id (memory-hard, iteration count configurable)
- **FR-005**: Key hierarchy MUST include: master key, device key pair (X25519), symmetric storage key (AES-256-GCM)
- **FR-006**: Keys MUST be stored in the OS keychain (or encrypted local file fallback)
- **FR-007**: Password changes MUST re-encrypt the key store (not re-encrypt all data)
- **FR-008**: New device enrollment MUST support: password-based and one-time enrollment code methods
- **FR-009**: Enrollment codes MUST be single-use and expire in 5 minutes
- **FR-010**: Cloud backups MUST be E2E encrypted with the same key hierarchy
- **FR-011**: Backup restore MUST require the account password or recovery phrase
- **FR-012**: Key rotation MUST be supported — generate new keys and re-encrypt data
- **FR-013**: Key rotation MUST run as a background process with progress tracking
- **FR-014**: A recovery phrase (BIP39, 24 words) MUST be generated during E2E setup
- **FR-015**: Recovery phrase MUST allow full data recovery without the account password
- **FR-016**: Encrypted data MUST include a version header for algorithm agility
- **FR-017**: Metadata exposure MUST be minimized — encrypt event types and content, keep only timestamps and IDs in plaintext

### Key Entities

- **KeyStore**: Client-side key storage. Attributes: masterKeySalt, encryptedDeviceKeyPair (X25519), encryptedStorageKey (AES-256), keyVersion, createdAt.
- **DeviceKeyPair**: A device-specific X25519 key pair. Attributes: deviceId, publicKey, privateKey (encrypted), createdAt.
- **EncryptedPayload**: An E2E-encrypted data payload. Attributes: payloadId, encryptionVersion, algorithm, iv/nonce, ciphertext, authTag, senderDeviceId, recipientDeviceId (optional, for device-specific encryption).
- **EnrollmentCode**: A one-time device enrollment code. Attributes: code, userId, createdByDeviceId, expiresAt, used (bool), usedByDeviceId.
- **RecoveryPhrase**: A BIP39 recovery phrase. Attributes: userId, phraseHash (for verification), createdAt, lastVerifiedAt.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Encryption of a 1KB event payload completes in under 10ms
- **SC-002**: Decryption of a 1KB event payload completes in under 10ms
- **SC-003**: Key derivation (Argon2id) completes in under 1 second
- **SC-004**: Key rotation for 100MB of data completes in under 5 minutes
- **SC-005**: Enrollment code generation and verification completes in under 100ms
- **SC-006**: Zero plaintext event content is ever stored in cloud service logs or databases
- **SC-007**: Recovery phrase provides 128 bits of entropy (BIP39, 24 words)

## Assumptions

- Encryption is implemented client-side (not in the cloud service)
- Uses well-known cryptographic libraries: libsodium or Web Crypto API
- Key derivation: Argon2id (memory: 64MB, iterations: 3, parallelism: 4)
- Symmetric encryption: AES-256-GCM with random 96-bit nonce
- Asymmetric encryption: X25519 + XSalsa20-Poly1305 (libsodium crypto_box)
- Key storage: OS keychain (Windows: Credential Manager, macOS: Keychain, Linux: libsecret)
- Fallback key storage: encrypted file at ~/.osai/keys/master.key (AES-256-GCM with password-derived key)
- Recovery phrase follows BIP39 standard (24 words, no passphrase)
- Metadata (event IDs, timestamps, sizes) is visible to the cloud service for queue management
- Algorithm agility: encryption version header allows future algorithm upgrades
- Source code lives at `packages/e2e-encryption/` in the monorepo