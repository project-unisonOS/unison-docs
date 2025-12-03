# Unison Architecture Deep Dive

Detailed view of the control plane, experience surfaces, data stores, and runtime packaging. Pair with
`unison-architecture-overview.md` for the short version.

## Control plane
- **unison-intent-graph** — Normalizes user intents (from renderer, shell, VDI, or device I/O), performs light routing, and feeds the orchestrator.
- **unison-orchestrator** — Central planner: enforces auth/consent, orchestrates skills, calls inference, and manages conversational/task state.
- **unison-policy** / **unison-consent** — Safety and consent enforcement; audit and policy evaluation.
- **unison-auth** — Issues/validates JWTs for service-to-service and user-bound flows.
- **unison-inference** — Gateway to LLMs/model providers; invoked by orchestrator/intent-graph for generation and planning.
- **unison-platform** — Narrative and installer glue that complement service READMEs (docs only, no runtime dependency).

## Experience and I/O surfaces
- **unison-experience-renderer** — Renders UI/UX, mediates wake-word UX, and exchanges intents/responses with intent-graph.
- **unison-shell** — Electron-based onboarding/dev shell; proxies to renderer/intent-graph for local flows.
- **unison-agent-vdi** — Thin desktop/VDI agent that fronts renderer and intent-graph.
- **unison-io-core / unison-io-speech / unison-io-vision** — Device-side emitters of `EventEnvelope` payloads; simulate or mirror edge devices in devstack.

## Data plane and shared libs
- **unison-storage** — Encrypted working memory, vault, and long-term store.
- **unison-context** / **unison-context-graph** — Fused session/context graph plus profile/KV store with consent-aware reads/writes.
- **unison-common** — Shared Python helpers (auth middleware, tracing, HTTP client, idempotency, envelope validation) packaged once and reused across services.
- **unison-docs** — Canonical specs and cross-cutting docs; schemas live under `dev/specs/`.

## Runtime and packaging
- **unison-devstack** — Docker Compose for local/e2e: brings up control plane, inference gateway, renderer, I/O stubs, and backing services (Redis/Postgres).
- **unison-os** — Base container images used by service Dockerfiles.
- Service Dockerfiles pull the packaged `unison-common` and the schemas from `unison-docs/dev/specs/` rather than duplicating copies.

## Typical request flow (expanded)
1. Client (renderer, shell, VDI, or I/O stub) emits an **EventEnvelope** defined in `unison-docs/dev/specs/event-envelope.md`.
2. **unison-intent-graph** normalizes/expands the intent and forwards it to **unison-orchestrator**.
3. Orchestrator steps:
   - Authenticates via **unison-auth** and checks consent/policy via **unison-policy**/**unison-consent**.
   - Retrieves fused state from **unison-context-graph** and profile/KV data from **unison-context**/**unison-storage**.
   - Calls **unison-inference** for LLM/model calls when needed.
   - Writes updated state back through **unison-context**/**unison-storage** as needed.
4. Response is returned to the originating client (renderer/shell/VDI/I/O stub) to render UI or produce speech/vision outputs.

## Companion session flow (voice, alpha)

The Natural Multimodal Companion builds on the core request flow to support voice-first interactions:

1. **Speech input** — `unison-io-speech` receives audio and produces a transcript via `/speech/stt`.
2. **Voice ingest** — The transcript (plus `person_id` and `session_id`) is POSTed to `unison-orchestrator` at `/voice/ingest`.
3. **Companion turn** — The voice API wraps the request as a `companion.turn` envelope and delegates to `CompanionSessionManager`:
   - Loads recent conversation state from **unison-context**.
   - Builds LLM messages and tool schemas from the registry.
   - Calls **unison-inference** with tools enabled; attachments (e.g., images) trigger the multimodal model preset.
   - Executes any selected tools (native skills or MCP tools).
   - Stores the updated turn back into **unison-context**.
4. **Outputs and logging** — The companion manager:
   - Emits a best-effort TTS request to `unison-io-speech` and an experience payload to the renderer.
   - Logs conversation summaries and tool activity into **unison-context-graph** for later retrieval and analysis.

This flow is exercised in devstack by combining `unison-io-speech` with the orchestrator `/voice/ingest` endpoint and the multimodal inference gateway.

## Data and secrets
- Long-term and sensitive data live in **unison-storage**; transient session/graph data is managed by **unison-context** and **unison-context-graph**.
- **Profiles** are stored by **unison-context** in an encrypted-at-rest SQLite table (`person_profiles`) with an optional Fernet key (`UNISON_CONTEXT_PROFILE_KEY`); profile CRUD endpoints require consent scopes and admin/operator/service roles and are used by orchestrator skills such as `person.enroll` and `person.update_prefs`.
- **Context graph durability** is implemented via a shared `DurabilityManager` used by **unison-context-graph**:
  - Durability endpoints: `GET /durability/status`, `POST /durability/run_ttl`, `POST /durability/run_pii`, and `GET /metrics`.
  - Features: WAL mode, TTL cleanup, PII scrubbing, and recovery checks for the replay store.
- JWT secrets, encryption keys, and provider tokens are injected via `.env` files or Compose overrides; see `dev/developer-guide.md` and service READMEs for env expectations.

## Where to start
- Short version: `unison-architecture-overview.md`.
- Running locally: `developer-guide.md` plus `unison-devstack/docker-compose.yml`.
- Repo inventory: `unison-repo-map.md` for entry points and test commands.
