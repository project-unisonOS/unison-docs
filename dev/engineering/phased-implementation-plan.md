# UnisonOS Orchestration + Interaction Framework — Phased Plan

This plan maps the **current workspace** to the **target framework** and breaks implementation into PR-sized work items with acceptance criteria.

## Step 1 — Current-state mapping (factual)

### 1.1 Repo inventory + runtime topology

Most services in this workspace are **Python/FastAPI** communicating via **HTTP+JSON**; the renderer also provides **SSE** for streaming, and some IO services expose **WebSocket** endpoints for low-latency streaming.

| Repo | Purpose | Languages | Runtime entrypoints | How it communicates today |
|---|---|---|---|---|
| `unison-orchestrator` | Central intent gateway; skill routing; policy integration; emits experiences to renderer. | Python (FastAPI) | `unison-orchestrator/src/server.py` | HTTP `POST /event` (EventEnvelope), HTTP to policy/context/storage/inference; best-effort HTTP to renderer `POST /experiences`. |
| `unison-experience-renderer` | Presence-first UI surface; stores envelopes; streams via SSE. | Python (FastAPI) + static web | `unison-experience-renderer/src/main.py` | HTTP `POST /events|/experiences`; SSE `GET /events/stream`; proxy endpoints for wakeword and speech. |
| `unison-common` | Shared primitives (auth, envelope validation, tracing middleware, replay helpers). | Python | library | Imported by services; includes OpenTelemetry-based tracing (export optional). |
| `unison-policy` | Safety/consent decisions and audit (called by orchestrator). | Python (FastAPI) | `unison-policy/src/server.py` | HTTP request/response from orchestrator. |
| `unison-auth` | JWT issuance/validation and RBAC support. | Python (FastAPI) | `unison-auth/src/auth_service.py` | HTTP token issuance/introspection; services validate JWTs. |
| `unison-consent` | Consent grant issuance/introspection. | Python (FastAPI) | `unison-consent/src/main.py` | HTTP request/response. |
| `unison-context` | Profile + KV context store. | Python (FastAPI) | `unison-context/src/server.py` | HTTP request/response; used by orchestrator/renderer. |
| `unison-storage` | Storage/vault for artifacts. | Python (FastAPI) | `unison-storage/src/server.py` | HTTP request/response; used by orchestrator and VDI agent. |
| `unison-context-graph` | Early context graph + replay “traces” (SQLite-backed). | Python (FastAPI) | `unison-context-graph/src/main.py` | HTTP `POST /context/update` and `POST /traces/replay`; used best-effort by orchestrator companion paths. |
| `unison-intent-graph` | Early intent graph stub (optional Neo4j). | Python (FastAPI) | `unison-intent-graph/src/main.py` | HTTP endpoints for capability reports and gesture selection. |
| `unison-inference` | Inference gateway (LLM providers). | Python (FastAPI) | `unison-inference/src/server.py` | HTTP request/response from orchestrator. |
| `unison-agent-vdi` | Desktop/VDI surface and task runner. | Python (FastAPI) | `unison-agent-vdi/src/main.py` | HTTP (tasks/telemetry), plus renderer integration. |
| `unison-io-speech` | Speech IO service; streaming protocols. | Python (FastAPI) | `unison-io-speech/src/server.py` | WebSocket `/stream` (client-facing), HTTP endpoints; doc references NATS but no NATS client code is present in this workspace. |

Runtime topology (dev): `unison-devstack/docker-compose.yml` wires these services with HTTP.

### 1.2 Existing message/event patterns

Observed patterns in code:
- **Event ingress**: orchestrator accepts `POST /event` with the current `EventEnvelope` (schema: `unison-docs/dev/specs/event-envelope.schema.json`; validator: `unison-common/src/unison_common/envelope.py`).
- **Renderer contract**: renderer ingests envelopes via `POST /events` (alias `/experiences`) and streams them via SSE (`GET /events/stream`).
- **Policy evaluation**: orchestrator calls policy via `evaluate_capability(...)` and denies/permits per intent.
- **Actuation**: orchestrator uses an action envelope contract for deterministic actuation (`unison-docs/dev/specs/action-envelope.md`), consumed by `unison-actuation`.
- **Tracing**: OpenTelemetry exists (`unison-common/src/unison_common/tracing.py` + `TracingMiddleware`), but there is no repository-wide standard for **local trace artifacts** (files) and no unified span set for end-to-end interaction latency.

### 1.3 Missing components vs target framework (factual)

Not currently implemented (as first-class, framework-defined modules/contracts):
- **Event Graph** as a canonical append-only interaction ledger (separate from context-graph’s replay traces).
- **Trace artifacts** written per interaction with standardized spans across boundaries.
- **Separate planner stage** that outputs a structured `Plan` (`Intent` + `ActionEnvelope[]`) as a stable contract.
- **ROM** as a stable renderer contract (current renderer accepts generic envelopes; orchestrator emits ad hoc “experience” payloads).
- **Write-behind context update batching** with explicit contract and lifecycle events.

## Step 2 — Target architecture (what will be defined/added)

Canonical contracts (JSON/Pydantic) will live in:
- `unison-common/src/unison_common/contracts/v1/*`

Trace artifact writer will live in:
- `unison-common/src/unison_common/trace_artifacts/*` (Phase 0/1)

## Step 3 — Phased implementation plan (PR-sized work)

### Phase 0 — Observability + contracts + docs

**Objective**
- Establish shared contracts and a local trace artifact capability so later work is measurable and compatible.

**PR-sized work items**
- PR0.1: Add v1 contracts in `unison-common` (Pydantic models + JSON schema export helper).
- PR0.2: Add trace artifact writer in `unison-common` (spans/events + JSON export) + unit tests.
- PR0.3: Add architecture docs (this repo’s `docs/architecture/*`) and plan (this file).

**Acceptance criteria**
- `unison-common` tests pass.
- A sample interaction can produce a trace JSON artifact with monotonic timestamps and standardized span names.

**Risks / fallback**
- If OpenTelemetry exporter setup is inconsistent across dev environments, the file-based trace artifact remains the source of truth for latency measurement.

### Phase 1 — Thin vertical slice (text → planner → tool → ROM → renderer emit)

**Objective**
- Prove the full pipeline works end-to-end with minimal stubs and deterministic tooling.

**PR-sized work items**
- PR1.1: Add a dev entrypoint (CLI or endpoint) in `unison-orchestrator` that:
  - accepts text input
  - creates an `IntentSession`
  - calls Planner stub returning one deterministic action (e.g., `tool.echo` or `tool.time`)
  - gates via Policy stub (allow/deny)
  - executes tool
  - builds ROM
  - emits a renderer envelope via existing renderer channel (`POST /events|/experiences`)
  - writes a trace artifact file
- PR1.2: Add trace “latency report” script under `tools/trace/` that prints:
  - time-to-first-feedback (first renderer emission)
  - total time
  - per-span durations
- PR1.3: Add unit tests + a minimal integration test for the thin slice.

**Acceptance criteria**
- Running the thin slice locally emits at least one renderer SSE event and writes `traces/<trace_id>.json`.
- Trace spans include: `input_received`, `planner_started/ended`, `policy_checked`, `tool_started/ended`, `rom_built`, `renderer_emitted`.

**Risks / fallback**
- If renderer is not reachable, the slice must still complete and record a trace event indicating renderer emission failure (non-fatal).

### Phase 2 — Real policy/auth gates + context reads + write-behind

**Objective**
- Replace stubs with real policy integration and incorporate context reads and asynchronous context write-behind.

**Work items**
- Add `ContextSnapshot` read path into router/planner inputs.
- Expand policy checks to evaluate per-action scopes and consent references.
- Implement a write-behind queue (in-process first; later durable).

**Acceptance criteria**
- Denied actions are represented in ROM with explicit reasons.
- Context updates are queued and flushed asynchronously with trace coverage.

**Current implementation (completed)**
- `unison-common`: `ContextSnapshot` contract (`unison_common.contracts.v1`).
- `unison-orchestrator`: `ContextReader` (profile+dashboard), `PolicyGate` calling `unison-policy /evaluate` when `ServiceClients` available, and `ContextWriteBehindQueue` flushing `kv.put` updates into `unison-context` with trace spans.

### Phase 3 — Event Graph append-only + replay tooling

**Objective**
- Implement Event Graph persistence and replay (local-first).

**Work items**
- Implement local JSONL or SQLite Event Graph store.
- Add replay tooling to reconstruct an interaction timeline and ROM reconstruction.

**Acceptance criteria**
- A trace can be replayed into an ordered event timeline.

**Current implementation (completed)**
- `unison-common`: `EventGraphEvent`/`EventGraphAppend`/`EventGraphQuery` contracts (`unison_common.contracts.v1`).
- `unison-orchestrator`: append-only JSONL store (`orchestrator.event_graph.JsonlEventGraphStore`) and event helper (`orchestrator.event_graph.store.new_event`).
- `unison-orchestrator`: thin slice appends Event Graph events (`orchestrator.dev_thin_slice`).
- `unison-orchestrator`: replay tool script `scripts/event_graph_replay.py` and optional API routes (enable with `UNISON_ENABLE_EVENT_GRAPH_ROUTES=true`).

### Phase 4 — IO modality pipeline (speech first)

**Objective**
- Integrate speech (VAD/STT/TTS) as IO adapters feeding `InputEventEnvelope`.

**Work items**
- Add speech→InputEvent mapping and trace propagation.
- Stream partial outputs to renderer (SSE) with trace events for first-token/first-feedback.

### Phase 5 — VDI agent integration (bounded tasks, streaming)

**Objective**
- Add bounded VDI tasks as tool executors with progress streaming and policy enforcement.

### Phase 6 — Performance/latency optimization

**Objective**
- Improve time-to-first-feedback and overall throughput (warm starts, caching, streaming ROM).

### Phase 7 — Hardening (security, privacy, regression tests)

**Objective**
- Add redaction, data boundaries, policy regression suites, and security tests.

## File-level targets (Phase 0/1)

Phase 0 (PR0.*):
- `unison-common/src/unison_common/contracts/v1/*`
- `unison-common/src/unison_common/trace_artifacts/*`
- `unison-common/tests/*`
- `docs/architecture/orchestration-interaction-framework.md`
- `docs/architecture/event-and-context-graphs.md`
- `docs/engineering/phased-implementation-plan.md`

Phase 1 (PR1.*):
- `unison-orchestrator/src/orchestrator/dev_thin_slice.py` (runner)
- `unison-orchestrator/src/orchestrator/interaction/*` (router/planner/policy/tools/ROM components)
- `unison-orchestrator/scripts/thin_slice.py` (no `PYTHONPATH` entrypoint)
- `unison-orchestrator/src/orchestrator/api/dev.py` (optional `POST /dev/thin-slice`)
- `unison-orchestrator/tests/test_dev_thin_slice.py`
- `unison-orchestrator/tests/test_dev_thin_slice_renderer_emit.py`
- `unison-experience-renderer/src/web/composer.js` (ROM adapter for display)
- `tools/trace/trace_report.py`
