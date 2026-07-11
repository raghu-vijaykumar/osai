# Feature Specification: On-Premise Deployment

**Feature Branch**: `056-on-premise-deployment`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an on-premise deployment option for enterprises that require self-hosted infrastructure"

## User Scenarios & Testing

### User Story 1 - Single-Command Deployment (Priority: P1)

Enterprise admins can deploy the full OSAI stack on their own infrastructure with a single command. A deployment script (docker-compose or Helm chart) sets up all services: storage (PostgreSQL, vector store), sync service, auth service, MCP server, knowledge engine, and the web UI. The deployment script handles configuration, secrets generation, and health checks.

**Why this priority**: Easy deployment is the most important factor for on-premise adoption. If deployment is complex, enterprises will not adopt it.

**Independent Test**: On a clean Linux server with Docker and Docker Compose installed, run `osai deploy --env production` (or equivalent one-liner). Verify all services start within 5 minutes. Verify health check endpoint returns 200 OK for all services. Verify the web UI is accessible and a user can sign in and see the timeline.

**Acceptance Scenarios**:

1. **Given** a clean server with Docker installed, **When** the admin runs `osai deploy --env production`, **Then** all services are deployed within 5 minutes with auto-generated secrets and healthy status
2. **Given** the deployment, **When** the admin runs `osai status`, **Then** a dashboard shows each service's status (running/stopped/error), version, resource usage, and uptime

---

### User Story 2 - Configuration and Customization (Priority: P2)

The on-premise deployment supports configuration via environment variables or a config file. Key configuration options: database connection (external or managed), storage backend (local, S3-compatible, NFS), encryption keys, network settings (ports, TLS certificates), resource limits per service, and feature flags.

**Why this priority**: Enterprises have diverse infrastructure requirements. Configuration flexibility ensures OSAI can fit into existing environments.

**Independent Test**: Deploy with an external PostgreSQL database (instead of the managed container). Configure S3-compatible storage (MinIO) for event storage. Set custom TLS certificates. Verify all services connect to the external database and storage, and the web UI is served over HTTPS with the custom certificate.

**Acceptance Scenarios**:

1. **Given** the deployment configuration, **When** an admin sets `DATABASE_URL=postgres://external:5432/osai`, **Then** services use the external database instead of the managed container
2. **Given** the deployment, **When** an admin configures custom TLS certificates, **Then** all HTTPS endpoints use the custom certificate and auto-renewal is configured (via Let's Encrypt or manual)

---

### User Story 3 - Backup and Restore for On-Premise (Priority: P2)

The on-premise deployment includes built-in backup and restore commands. `osai backup` creates a consistent snapshot of all databases and configuration. `osai restore` restores from a backup. Backups include: PostgreSQL dump, vector store index files, configuration, and encryption keys.

**Why this priority**: On-premise deployments require self-managed disaster recovery. Built-in backup tools ensure admins can recover from failures.

**Independent Test**: Run `osai backup --output ./backup-2026-07-11`. Verify a backup file is created containing all data. Delete the deployment with `osai down --volumes`. Redeploy with `osai deploy`, then run `osai restore --input ./backup-2026-07-11`. Verify all data is restored: users, events, entities, and settings.

**Acceptance Scenarios**:

1. **Given** a running deployment, **When** an admin runs `osai backup`, **Then** a complete backup is created with all data, configuration, and keys within a configurable time window
2. **Given** a fresh deployment, **When** an admin runs `osai restore`, **Then** all data is restored and the system is fully functional within 10 minutes

---

### User Story 4 - Monitoring and Logging (Priority: P3)

The deployment includes built-in monitoring and logging: Prometheus metrics (service health, request latency, storage usage), structured logging (JSON format, configurable log levels), and integration with external monitoring systems (Datadog, Grafana, New Relic). A health check endpoint (`/health`) reports the status of all services.

**Why this priority**: Production deployments require monitoring. Built-in metrics and logging enable integration with existing enterprise observability stacks.

**Independent Test**: Deploy OSAI with monitoring enabled. Access the Prometheus metrics endpoint (`/metrics`) and verify it exposes: service health (1/0), request count, request latency (p50/p95/p99), storage usage, and active users. Configure log level to "debug" for the sync service and verify verbose logs are emitted. Access `/health` and verify it returns JSON with status per service.

**Acceptance Scenarios**:

1. **Given** an on-premise deployment, **When** an admin accesses `/metrics`, **Then** Prometheus-formatted metrics are returned with all key indicators
2. **Given** structured logging is enabled, **When** the admin views logs, **Then** they are JSON-formatted with service, level, timestamp, message, and request ID fields
3. **Given** the health endpoint, **When** an admin accesses `/health`, **Then** it returns `{"status": "ok", "services": {"postgres": "ok", "sync": "ok", "auth": "ok", "ui": "ok"}}` with individual service status

---

### User Story 5 - Updates and Maintenance (Priority: P3)

On-premise deployments support zero-downtime updates. `osai update` pulls the latest images, runs migrations, and restarts services with rolling updates. The update includes: database migrations (automated, with rollback), configuration schema migrations, and service restarts. Admins are notified of available updates via the admin panel.

**Why this priority**: Regular updates are essential for security and feature access. Zero-downtime updates minimize disruption.

**Independent Test**: Run `osai update`. Verify services are updated one by one (rolling update) without downtime. Verify database migrations run automatically. Verify the web UI remains accessible throughout the update. Verify `osai version` now shows the new version.

**Acceptance Scenarios**:

1. **Given** a new version is available, **When** an admin runs `osai update`, **Then** the update proceeds with rolling restarts, no service experiences more than 5 seconds of downtime
2. **Given** an update includes a database migration, **When** the migration runs, **Then** it runs automatically with a backup taken before migration (for rollback)
3. **Given** an update fails, **When** the system detects the failure, **Then** it automatically rolls back to the previous version and notifies the admin

---

### Edge Cases

- What are the minimum hardware requirements for on-premise deployment?
- How is high availability configured (multi-node, load balancing)?
- How are secrets (encryption keys, database passwords) managed?
- How is the deployment updated when the host OS is updated?
- What happens when disk space is low?
- How are network proxies and firewalls configured?

## Requirements

### Functional Requirements

- **FR-001**: On-premise deployment MUST be available via Docker Compose and Kubernetes (Helm chart)
- **FR-002**: Deployment MUST be achievable with a single command
- **FR-003**: Deployment MUST auto-generate secrets and configuration on first run
- **FR-004**: All service configurations MUST be overridable via environment variables
- **FR-005**: External databases (PostgreSQL) MUST be supported
- **FR-006**: External storage (S3-compatible, NFS) MUST be supported
- **FR-007**: Custom TLS certificates MUST be supported
- **FR-008**: Backup command MUST create a complete, consistent snapshot
- **FR-009**: Restore command MUST restore from a backup with data integrity verification
- **FR-010**: Prometheus metrics MUST be exposed at `/metrics`
- **FR-011**: Structured JSON logging MUST be supported with configurable log levels
- **FR-012**: Health check endpoint MUST report per-service status
- **FR-013**: Updates MUST support zero-downtime rolling updates
- **FR-014**: Database migrations MUST be automated with rollback capability
- **FR-015**: Update failure MUST trigger automatic rollback
- **FR-016**: Admins MUST be notified of available updates in the admin panel
- **FR-017**: All inter-service communication MUST be encrypted (TLS)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Fresh deployment completes in under 5 minutes (on a standard Linux server)
- **SC-002**: Backup of 10GB data completes in under 10 minutes
- **SC-003**: Restore completes in under 15 minutes
- **SC-004**: Zero-downtime update has < 5 seconds of service interruption per service
- **SC-005**: Health check responds in under 100ms
- **SC-006**: Deployment resource usage: < 4GB RAM, < 4 CPU cores idle

## Assumptions

- Target platform: Linux (x86_64, aarch64)
- Container runtime: Docker (20.10+) or containerd
- Orchestration: Docker Compose (small deployments) or Kubernetes/Helm (large deployments)
- Minimum requirements: 4 CPU cores, 8GB RAM, 50GB disk
- PostgreSQL 15+ required (external or managed container)
- Vector store: LanceDB or Qdrant as a sidecar container
- Object storage: local filesystem, S3-compatible, or NFS
- TLS certificates: auto-generated (self-signed for dev), Let's Encrypt (production), or custom
- Secrets management: environment variables or mounted volumes (Vault integration optional)
- Monitoring: Prometheus metrics endpoint + integrations for Datadog/Grafana
- Source code lives at `deploy/on-premise/` in the monorepo