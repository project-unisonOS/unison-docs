# Unison Architecture Overview

High-level view of how the repos in this workspace cooperate. Pair this with `unison-repo-map.md` for per-repo details
and commands.

## Core Control Plane

- **unison-intent-graph** — first stop for user intents (from renderer, shell, VDI, or device I/O), normalizes them, and
  forwards to the orchestrator.
- **unison-orchestrator** — routes intents, calls policy/auth/context/storage/inference services, and returns responses
  back through the originating channel.
- **unison-policy** and **unison-consent** — validate safety and user consent before actions are executed; provide audit
  records.
- **unison-auth** — issues/validates JWTs for service-to-service auth and user-bound flows.
- **unison-context-graph** and **unison-context** — fuse signals/preferences into a graph view and expose KV/profile
  reads/writes with consent checks.
- **unison-storage** — encrypted working memory, vault, and long-term store consumed by orchestrator and context graph.
- **unison-inference** — gateway to LLMs/model providers; invoked by orchestrator/intent-graph for generation/planning.

## Experience + Edge I/O

- **unison-experience-renderer** — renders experiences/UI and mediates wake-word UX. Sends intents to intent-graph and
  receives responses to display/speak.
- **unison-agent-vdi** — thin desktop/VDI agent that fronts renderer and intent-graph.
- **unison-io-core / unison-io-speech / unison-io-vision** — device-side emitters of EventEnvelopes (speech/vision/IO)
  that the orchestrator consumes; useful for simulated edge devices in devstack.

## Shared Contracts and Libraries

- **unison-docs** — canonical specs and schemas (e.g., EventEnvelope, consent grants) referenced by all services
  (`dev/specs/`).
- **unison-common** — shared Python helpers (auth middleware, tracing, HTTP client, idempotency, envelope validation).
- **unison-os** — base container images used by service Dockerfiles.

## Deployment and DX

- **unison-devstack** — Docker Compose wiring for local e2e runs; brings up the core control plane, inference gateway,
  renderer, I/O stubs, and backing data services (Redis/Postgres).
- **unison-platform** — platform-level narrative and installer notes that complement the service READMEs.
- **unison-docs** — primary cross-cutting docs and specs repo.

## Typical Request Flow

1. Client (renderer, shell, VDI, or I/O stub) emits an **EventEnvelope** defined in `unison-docs/dev/specs`.
2. **unison-intent-graph** normalizes/expands the intent and forwards it to **unison-orchestrator**.
3. Orchestrator:
   - Authenticates via **unison-auth** and checks consent/policy via **unison-policy**/**unison-consent**.
   - Retrieves fused state from **unison-context-graph** and profile/KV data from **unison-context**/**unison-storage**.
   - Calls **unison-inference** for LLM/model calls when needed.
4. Response is returned to the originating client (renderer/shell/VDI/I/O stub).

## Data and Secrets

- Long-term and sensitive data live in **unison-storage**; transient session/graph data is managed by **unison-context**
  and **unison-context-graph**.
- **Profiles** are stored in **unison-context** in an encrypted-at-rest table (`person_profiles`) with optional Fernet
  keys; profile APIs enforce consent scopes and role checks, and are used by orchestrator skills for enrollment and
  preference updates.
- **Context Graph durability** is provided by a shared `DurabilityManager`, exposing `/durability/status`,
  `/durability/run_ttl`, `/durability/run_pii`, and `/metrics` so replay, TTL, and PII scrubbing can be monitored and
  controlled explicitly.
- JWT secrets, encryption keys, and provider tokens are injected via `.env` files or Compose overrides; see each service
  README and `developer-guide.md` for env expectations.

## Where to Start

- `developer-guide.md` — clone, bootstrap, run devstack/renderer, and run tests.
- `unison-repo-map.md` — repo inventory and commands.
- Service READMEs — API/feature specifics and test guidance.
