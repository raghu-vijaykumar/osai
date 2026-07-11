# Feature Specification: Embeddings Pipeline

**Feature Branch**: `011-embeddings-pipeline`

**Created**: 2026-07-11

**Status**: Draft

**Input**: User description: "Build an embedding pipeline that generates vector embeddings for event content using local models"

## User Scenarios & Testing

### User Story 1 - Auto-Embed New Events (Priority: P1)

When a new event is stored, the embedding pipeline automatically generates a vector embedding for its text content and stores it in the vector store. This happens asynchronously so event publishing is not blocked.

**Why this priority**: Automatic embedding is the foundation of semantic search. Without it, users can only search by exact text match or metadata filters.

**Independent Test**: Publish a `page.content` event with text "Kubernetes pod deployment strategies", wait for embedding, then search "container orchestration" and verify the event is returned with a similarity score.

**Acceptance Scenarios**:

1. **Given** a new event with text content is published, **When** the embedding pipeline processes it, **Then** a vector embedding is stored in the `event_embeddings` table linked to the event ID within 5 seconds
2. **Given** an event with no text content (e.g., `tab.activated`), **When** the pipeline processes it, **Then** no embedding is generated and the event is skipped

---

### User Story 2 - Batch Embedding of Existing Events (Priority: P1)

The pipeline supports batch embedding of existing events. On first run (or after a schema change), all un-embedded events are processed in batches with progress tracking.

**Why this priority**: When the system starts for the first time with existing events, all un-embedded content must be backfilled. Batch processing is essential for scale.

**Independent Test**: Store 100 events without embeddings running, then trigger a batch embed. Verify all 100 events have embeddings within 60 seconds.

**Acceptance Scenarios**:

1. **Given** 500 un-embedded events in storage, **When** the batch embedding job runs, **Then** all 500 events are embedded within 5 minutes
2. **Given** the batch job is interrupted mid-way, **When** it restarts, **Then** it resumes from where it left off (no double-embedding)

---

### User Story 3 - Configurable Embedding Model (Priority: P2)

The pipeline supports swapping the embedding model via configuration. The default is a local model (all-MiniLM-L6-v2 via Transformers.js), but users can configure an alternative model or an external API (OpenAI, Ollama).

**Why this priority**: Different use cases need different models. Local models prioritize privacy. Cloud models may have higher accuracy. Pluggability enables both.

**Independent Test**: Configure the pipeline to use a different local model (e.g., `intfloat/e5-small-v2`), embed a document, and verify the embedding dimensions match the new model's expected output.

**Acceptance Scenarios**:

1. **Given** the default model is `all-MiniLM-L6-v2` (384 dimensions), **When** an event is embedded, **Then** the stored embedding has exactly 384 float32 values
2. **Given** the model is configured to `text-embedding-3-small` (OpenAI API), **When** an event is embedded, **Then** the embedding is fetched from the OpenAI API and stored with `model: "text-embedding-3-small"` and `dimensions: 1536`

---

### User Story 4 - Embedding Queue and Retry (Priority: P2)

Failed embeddings are retried with exponential backoff (up to 3 retries). The pipeline uses a persistent queue so no events are lost if the embedding service is temporarily unavailable.

**Why this priority**: Embedding models (especially local) can fail due to OOM, model loading issues, or API rate limits. A persistent queue prevents data loss.

**Independent Test**: Simulate an embedding failure (e.g., point to an invalid model path), verify the event goes to a retry queue, then fix the model path and verify the event is embedded on the next retry attempt.

**Acceptance Scenarios**:

1. **Given** an event that fails to embed, **When** the first attempt fails, **Then** the event is queued for retry with backoff (5s, 30s, 120s intervals)
2. **Given** 3 retry attempts all fail, **When** the max retries are exhausted, **Then** the event is marked as `embedding_failed` with the error message stored for debugging

---

### User Story 5 - Embedding Model Lifecycle Management (Priority: P3)

The pipeline handles model downloading, caching, and loading/unloading. Models are downloaded on first use and cached locally for offline operation.

**Why this priority**: Local models are large (50-500MB). Managing download progress, disk cache, and memory loading is essential for a good user experience.

**Independent Test**: Configure a model not yet downloaded, trigger an embedding, and verify the model is downloaded with progress reported before the embedding is computed.

**Acceptance Scenarios**:

1. **Given** a model that hasn't been downloaded yet, **When** the first embedding request arrives, **Then** the model is downloaded with progress events published and cached to `~/.osai/models/`
2. **Given** a model is loaded in memory, **When** no embedding requests arrive for 10 minutes, **Then** the model is unloaded to free memory

---

### Edge Cases

- What happens when the embedding model requires more RAM than available (OOM)?
- How are GPU-accelerated models handled vs CPU-only fallback?
- What happens when the user switches embedding models — are existing embeddings re-computed or kept?
- How are multilingual texts handled — does the model support all languages the user encounters?
- What happens when the embedding text exceeds the model's token limit (512 tokens)?
- How are embeddings for very short texts (1-2 words) handled — do they produce meaningful vectors?

## Requirements

### Functional Requirements

- **FR-001**: Pipeline MUST automatically generate embeddings for new events with text content (events types: `page.content`, `file.opened`, `file.modified`, `conversation.*`, `note.*`)
- **FR-002**: Pipeline MUST process events asynchronously via a work queue — event publishing is not blocked by embedding generation
- **FR-003**: Pipeline MUST store embeddings in the `event_embeddings` table with columns: `event_id` (TEXT FK), `embedding` (BLOB), `model` (TEXT), `dimensions` (INT), `created_at` (TEXT)
- **FR-004**: Pipeline MUST support a batch processing mode that processes all un-embedded events in configurable batch sizes (default: 50)
- **FR-005**: Pipeline MUST track embedding state per event: `pending`, `completed`, `failed`, `skipped` (no text content)
- **FR-006**: Pipeline MUST use Transformers.js (`@xenova/transformers`) for local embedding by default — all-MiniLM-L6-v2 model (384 dimensions)
- **FR-007**: Pipeline MUST support configurable model — local models via Transformers.js and remote models via OpenAI API or Ollama API
- **FR-008**: Pipeline MUST handle model lifecycle — download on first use, cache to `~/.osai/models/`, unload after inactivity (configurable timeout)
- **FR-009**: Pipeline MUST retry failed embeddings with exponential backoff (5s, 30s, 120s) up to 3 attempts
- **FR-010**: Pipeline MUST truncate input text to the model's maximum token limit (default: 512 tokens) before embedding
- **FR-011**: Pipeline MUST normalize embedding vectors to unit length after generation for cosine similarity compatibility
- **FR-012**: Pipeline MUST publish `embedding.completed` and `embedding.failed` events for observability
- **FR-013**: Pipeline MUST support graceful shutdown — finish in-progress embeddings before exit
- **FR-014**: Pipeline MUST be configurable via `embedding` key in OSAI config: `model`, `provider` (local/openai/ollama), `batchSize`, `unloadTimeout`, `retryMax`

### Key Entities

- **EmbeddingQueueItem**: A pending embedding job. Attributes: `eventId`, `text` (the text to embed), `model`, `retryCount`, `nextRetryAt`, `status`.
- **EventEmbedding**: Stored vector embedding. Attributes: `eventId`, `embedding` (Float32Array as BLOB), `model`, `dimensions`, `createdAt`.
- **EmbeddingModel**: A loaded model instance managed by the model lifecycle. Attributes: `name`, `provider`, `dimensions`, `loadedAt`, `lastUsedAt`, `modelHandle`.
- **EmbeddingPipeline**: The orchestrator. Listens for new events, manages the queue, calls the model, stores results.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Single event embedding completes in under 500ms on a modern CPU (Apple M-series or Intel i7)
- **SC-002**: Batch embedding of 50 events completes in under 10 seconds
- **SC-003**: Model loads in under 5 seconds from disk cache (first download: under 60 seconds on 100Mbps)
- **SC-004**: Embedding accuracy: cosine similarity between two semantically identical texts > 0.9
- **SC-005**: Pipeline memory usage: idle < 50MB, active (model loaded) < 300MB
- **SC-006**: Zero events lost due to pipeline crashes (persistent queue + retry)

## Assumptions

- Default model: `Xenova/all-MiniLM-L6-v2` (384-dim, 80MB quantized, runs in Node.js via ONNX runtime)
- GPU acceleration: auto-detected via ONNX runtime. Falls back to CPU if no GPU available
- Input text > 512 tokens is truncated to the first 512 tokens (most semantic information is in the beginning)
- Model cache directory: `~/.osai/models/` with subdirectories per model
- Transformers.js handles model downloading with Hugging Face Hub
- Remote embedding provider credentials (e.g., OpenAI API key) are managed by the provider layer (spec 062) rather than stored directly in config
- Embedding vectors are stored as binary Float32 arrays (4 bytes per dimension) for space efficiency
- Source code lives at `knowledge-engine/embeddings/` in the monorepo
