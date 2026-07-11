# Feature Specification: LLM Integration & Provider Management

**Feature Branch**: `062-llm-integration`

**Created**: 2026-07-11

**Status**: Draft

## Overview

OSAI requires LLM access for embeddings, entity extraction, classification, agent conversations, summarization, and planning. This spec defines a centralized provider abstraction so all features use a consistent interface for model configuration, API key management, token tracking, and fallback behavior.

The LLM integration layer sits between the infrastructure layer (spec 003 — secret management, logging) and all feature specs that use AI (specs 011, 012, 013, 022, 024, 026–030). Those specs reference this one instead of making their own LLM assumptions.

## User Scenarios & Testing

### User Story 1 - BYOK: Add Provider API Key (Priority: P1)

A user opens Settings > LLM Providers, selects OpenAI, enters their API key and preferred model (gpt-4o). The key is stored in the OS keychain. All features that use OpenAI (agents, summarization, research) immediately use this key without any per-feature configuration.

**Why this priority**: Without API keys, agents and AI features don't work. BYOK is the entry point for all LLM functionality.

**Independent Test**: Navigate to Settings > LLM Providers. Click "Add Provider", select OpenAI, enter a key. Verify the key is stored (masked display showing last 4 chars). Open the Chat Bar (Ctrl+K) and ask a question — verify it responds (confirming the key is used).

**Acceptance Scenarios**:

1. **Given** no LLM provider is configured, **When** the user opens the Chat Bar, **Then** it shows "Configure an LLM provider in Settings" with a direct link
2. **Given** an OpenAI API key is entered, **When** the user saves, **Then** the key is stored in the OS keychain (not in config files) and a connectivity test runs automatically — success shows a green checkmark
3. **Given** an API key fails the connectivity test, **When** saving, **Then** the user sees an error message with the specific failure reason (invalid key, insufficient quota, network error)

--- 

### User Story 2 - Per-Capability Model Routing (Priority: P1)

The user can configure which provider and model handles each capability: summarization, research, classification, entity extraction, embedding, agent chat. Each capability shows the available providers and lets the user pick model + parameters (temperature, max tokens).

**Why this priority**: Different tasks need different models. Classification is cheap with a small local model. Summarization needs a powerful model. Users should optimize for cost and quality per task.

**Independent Test**: Set "classification" to use local Ollama, "summarization" to use GPT-4o, "agent chat" to use Claude 3.5 Sonnet. Run classification on 10 events — verify it uses Ollama (no network calls). Run a summarization — verify it calls OpenAI. Chat with an agent — verify it calls Anthropic.

**Acceptance Scenarios**:

1. **Given** two providers configured (OpenAI and Ollama), **When** the user opens capability routing settings, **Then** each capability (summarization, research, classification, entity extraction, agent chat, embedding) shows a dropdown of available provider:model pairs
2. **Given** the user sets a capability to a specific provider+model, **When** that feature is used, **Then** the request is routed to the configured model
3. **Given** a capability has no provider configured, **When** that feature is used, **Then** the system tries the default provider (first configured) and logs a warning if none is available

--- 

### User Story 3 - Local Inference via Ollama (Priority: P2)

The user installs Ollama locally and pulls a model (llama3.2). OSAI detects Ollama on the default port (11434) and adds it as an available provider automatically. The user can use Ollama for classification, entity extraction, and other lightweight tasks without any API key. Works fully offline.

**Why this priority**: Local inference preserves privacy, works offline, and reduces API costs. It makes OSAI usable without any cloud dependency.

**Independent Test**: Install Ollama, pull llama3.2. Launch OSAI — verify Ollama appears in LLM Providers as an available provider with status "Connected". Set classification to Ollama. Run classification offline — verify it completes without network calls.

**Acceptance Scenarios**:

1. **Given** Ollama is running on localhost:11434, **When** OSAI starts, **Then** it auto-discovers Ollama, runs a health check, and adds it as a provider with available models listed
2. **Given** the user sets a capability to Ollama, **When** the network is disconnected, **Then** the feature works normally (all inference is local)
3. **Given** Ollama is configured but not running, **When** a feature tries to use it, **Then** the system shows "Ollama is not running" with instructions to start it

--- 

### User Story 4 - Fallback Chain (Priority: P2)

The user configures a primary provider (OpenAI) and a secondary fallback (Ollama). When the primary is rate-limited or unavailable, the system automatically falls back to the secondary. A notification shows "Fell back to Ollama — OpenAI rate-limited".

**Why this priority**: Reliability. One provider going down should not block user workflows.

**Independent Test**: Configure OpenAI as primary, Anthropic as secondary. Trigger a rate limit on OpenAI (configure a low RPM). Verify the request automatically goes to Anthropic and completes. Verify a notification appears showing the fallback.

**Acceptance Scenarios**:

1. **Given** a fallback chain of OpenAI → Anthropic → Ollama, **When** OpenAI returns a 429 rate limit, **Then** the request is retried on Anthropic within 500ms
2. **Given** all providers in the fallback chain fail, **When** a request is made, **Then** the user sees "All LLM providers unavailable" with details of each failure

--- 

### User Story 5 - Token Usage & Cost Visibility (Priority: P3)

The user can view token usage and estimated cost in Settings > LLM Providers > Usage. Shows tokens used per capability per day/week/month, estimated cost, and trend chart. Users can set monthly budget alerts.

**Why this priority**: LLM costs can add up. Users need visibility into consumption to manage budgets and choose appropriate models.

**Independent Test**: Use the Chat Bar for 10 conversations, then open Usage. Verify token counts are shown per capability with estimated cost. Verify a weekly trend chart is visible.

**Acceptance Scenarios**:

1. **Given** LLM usage across 3 capabilities, **When** viewing Usage, **Then** a table shows capability, provider, prompt tokens, completion tokens, estimated cost, and total for the selected period
2. **Given** a monthly budget of $50 is set, **When** usage reaches 80%, **Then** a warning notification is shown; at 100%, the user is prompted to increase budget or switch to cheaper models

### Edge Cases

- What happens when an API key expires — does the system detect this proactively?
- How are streaming tokens counted — real-time or batched?
- What happens when two capabilities use the same provider with different rate limits?
- How are provider health checks handled — periodic or on-demand?
- What happens when local Ollama has no models pulled?
- How are provider-specific parameters (top_p, frequency_penalty) handled in the abstraction layer?

## Requirements

### Functional Requirements

#### Provider Abstraction

- **FR-001**: System MUST define an `LLMProvider` interface with methods: `chat()` (completion with messages), `chatStream()` (streaming completion), `embed()` (text embedding), `models()` (list available models)
- **FR-002**: Provider interface MUST accept common parameters: `model`, `temperature` (0–2), `maxTokens`, `stop` (sequences), `topP`, `frequencyPenalty`, `presencePenalty`
- **FR-003**: Provider implementations MUST be available for: **OpenAI** (GPT-4o, GPT-4o-mini, o3-mini, text-embedding-3-small/large), **Anthropic** (Claude 3.5 Sonnet, Claude 3 Haiku, Claude 3 Opus), **Ollama** (any pulled model — llama3, mistral, codellama, etc.), **Transformers.js** (local embedding — all-MiniLM-L6-v2)
- **FR-004**: Each provider MUST have a health check method that verifies connectivity and returns: `status` (connected/error/timeout), `latencyMs`, `availableModels`, `errorMessage` (if any)
- **FR-005**: Provider config MUST be stored in the OS keychain via the secret store (spec 003 — FR-053–059) — keys never written to disk unencrypted

#### BYOK & Settings UI

- **FR-006**: Settings MUST include an "LLM Providers" section with: Add/Edit/Remove provider, API key input (masked), model selection per provider, connectivity test button, status indicator
- **FR-007**: API key input MUST validate basic format (non-empty, expected pattern per provider) and run a connectivity test before saving
- **FR-008**: If no LLM provider is configured, features that require one MUST show a consistent "Configure LLM" inline prompt with a link to Settings
- **FR-009**: Users MUST be able to add multiple providers — at least one is required for agent features, local Ollama is optional but recommended as fallback

#### Capability Routing

- **FR-010**: System MUST support per-capability provider+model configuration with these capability keys: `summarization`, `research`, `classification`, `entity_extraction`, `agent_chat`, `embedding`, `planning`
- **FR-011**: Default routing: if a capability has no specific config, the system uses the first configured provider with a sensible default model (GPT-4o for chat, text-embedding-3-small for embeddings, Ollama for classification if available)
- **FR-012**: Capability config MUST be stored in a local config file (`~/.osai/llm-config.json`) — separate from API keys
- **FR-013**: System MUST expose a `getLLM(capability)` function that returns the resolved provider+model for the given capability, applying fallback logic if the primary is unavailable

#### Fallback Chain

- **FR-014**: Users MUST be able to order providers in a fallback chain (drag-and-drop in Settings)
- **FR-015**: On failure (HTTP 429, 5xx, network error, timeout > 30s), the system MUST retry on the next provider in the chain within 500ms
- **FR-016**: On total fallback failure, the system MUST return a structured error: `{ error: "all_providers_unavailable", failed: [{ provider, reason }] }`
- **FR-017**: On fallback, a non-blocking notification MUST inform the user: "Fell back to {provider} — {reason}"

#### Token & Cost Tracking

- **FR-018**: System MUST track prompt tokens and completion tokens per request, per capability, per provider
- **FR-019**: Token counts MUST be persisted to SQLite in a `llm_usage` table: `id`, `capability`, `provider`, `model`, `promptTokens`, `completionTokens`, `durationMs`, `timestamp`
- **FR-020**: System MUST estimate cost per request using bundled price tables per provider (updated periodically)
- **FR-021**: Usage dashboard MUST show: tokens per capability, estimated cost, trend chart (7/30/90 day), provider breakdown
- **FR-022**: Users MUST be able to set a monthly budget alert (notification at 80%, warning at 100%)

#### Rate Limiting

- **FR-023**: System MUST enforce rate limits per provider using a configurable token bucket: `requestsPerMinute` (RPM), `tokensPerMinute` (TPM)
- **FR-024**: Default RPM/TPM limits: OpenAI 500/200000, Anthropic 50/200000, Ollama 1000/1000000 (unlimited locally)
- **FR-025**: Rate-limited requests MUST enter a queue and be retried with exponential backoff (1s, 2s, 4s, max 30s) before triggering fallback
- **FR-026**: Rate limit config MUST be editable in Settings > LLM Providers > Advanced

#### Local Inference (Ollama)

- **FR-027**: System MUST auto-detect Ollama on localhost:11434 at startup — health check GET /api/tags
- **FR-028**: If Ollama is detected, it MUST be automatically added as an available provider with no user configuration needed
- **FR-029**: System MUST NOT require an API key for Ollama — all local inference has zero cost and works fully offline

#### Offline Degradation

- **FR-030**: If no provider is reachable (all cloud providers fail and Ollama is not running), features MUST gracefully degrade with a banner: "LLM features unavailable — check your provider configuration"
- **FR-031**: Local-only features (classification, entity extraction via local models) MUST continue working even without a cloud provider

### Key Entities

- **LLMProvider**: A configured LLM provider. Attributes: `id` (internal), `type` (openai/anthropic/ollama/transformers), `name` (user label), `status` (connected/error/disabled), `models` (array of available model names), `config` (model, temperature, maxTokens, RPM, TPM, fallbackOrder).
- **CapabilityRoute**: Maps a capability to a provider+model. Attributes: `capability` (string key), `providerId`, `model`, `overrideParams` (temperature, maxTokens, etc.).
- **ProviderInterface**: The abstract interface all providers implement — `chat()`, `chatStream()`, `embed()`, `models()`, `health()`.
- **LLMUsageRecord**: A token usage record. Attributes: `id`, `capability`, `provider`, `model`, `promptTokens`, `completionTokens`, `durationMs`, `estimatedCost`, `timestamp`.
- **FallbackChain**: Ordered list of provider IDs to try for a given capability. Attributes: `capability`, `providers[]` (ordered by priority), `currentProvider` (index of successfully resolved provider).

## Success Criteria

- **SC-001**: Provider health check completes in under 2 seconds per provider
- **SC-002**: Fallover to secondary provider completes in under 1 second from failure detection
- **SC-003**: Token tracking overhead is under 5ms per request
- **SC-004**: First token latency is within 10% of direct provider API latency (no measurable abstraction overhead)
- **SC-005**: Ollama auto-detection completes in under 3 seconds at startup
- **SC-006**: BYOK flow (enter key → save → test → ready) completes in under 5 seconds

## Assumptions

- The abstraction layer lives at `services/llm-provider/` with one file per provider implementation
- Rate limits are best-effort on the client side — they prevent rapid retries but don't guarantee provider-side quota enforcement
- Token counting uses the provider's returned usage metadata — no client-side tokenizer needed
- Cost estimates use bundled CSV price tables updated per release (not fetched live)
- Ollama is installed and managed by the user — OSAI does not bundle or install it
- Transformers.js embedding runs in-process in the sidecar (already specified in spec 011)
- The secret store (spec 003) handles key encryption — this spec does not reinvent key management
- Fallback chains are evaluated client-side — no server-side routing needed

## Dependencies

- Depends on spec 003 (secret management via OS keychain — FR-053–059)
- Depended on by: specs 011, 012, 013, 021 (Chat Bar), 024 (Home), 026, 027, 028, 029, 030, 031, 064 (Agent Host)
