# UnisonOS Orchestration + Interaction Framework (Target)

This document defines the **target** orchestration/interaction pipeline for UnisonOS and the responsibilities and contracts at each boundary. It is written to fit the **current workspace reality** (Python/FastAPI services, JSON over HTTP/SSE/WebSocket) while introducing missing primitives (planner stage, ROM, Event Graph, trace artifacts).

## Non-negotiable constraints (enforced by design)

- **Modular system**: IO services, orchestrator, policy, auth, context, storage, renderer, VDI, tools remain decoupled.
- **Separate planning stage**: a small/fast **Router/Classifier** + a **Planner** component exist as distinct steps (even if stubbed initially).
- **Untrusted brain model**: multimodal model output is **untrusted for side effects**; it can only *propose* actions. The orchestrator enforces **policy + auth** and executes tools.
- **Trace early**: end-to-end trace instrumentation is available from the start with timings for critical latency metrics.

## Target pipeline (end-to-end)

**IO → Intent → Policy/Auth → Actions/Tools/VDI → ROM → Renderer → Write-behind**

1. **IO Ingress**
   - Accepts input events from:
     - text (CLI/dev entrypoint, renderer POST, VDI)
     - speech/vision/sign/braille/etc. (service adapters)
   - Outputs: `InputEventEnvelope` (v1) + `TraceContext`.

2. **Router / Classifier (fast)**
   - Purpose: quick classification and routing decisions with a small latency budget.
   - Inputs: `InputEventEnvelope`, current `ContextSnapshot` (optional), capability manifest (optional).
   - Outputs:
     - `IntentSession` (created/updated)
     - `Intent` classification (coarse) and a `PlannerRequest` hint (model budget, modality, strictness).
   - Notes:
     - This stage can be rules-based initially; later becomes a small model.

3. **Planner (separate component)**
   - Purpose: generate a structured plan: `Intent` + `ActionEnvelope[]`.
   - Inputs: Router output, context snapshot, tool registry/capabilities.
   - Output: `Plan` (v1) containing:
     - one `Intent`
     - zero or more `ActionEnvelope` items (proposals)
   - Trust:
     - Planner output is treated as **proposals** only (no side effects).

4. **Policy Gate + AuthZ**
   - Evaluates each proposed action for:
     - required scopes / consent references
     - risk level / cost / data sensitivity
     - tool capability boundaries
   - Inputs: `ActionEnvelope`, actor identity (JWT/baton), `PolicyContext`.
   - Outputs: `PolicyDecision` (allow/deny/require_confirmation) per action.

5. **Tool / VDI Execution (orchestrator-owned)**
   - Executes only **allowed** actions.
   - Tool execution is deterministic (where possible) and side-effect-bounded.
   - Inputs: `ActionEnvelope` + `TraceContext`.
   - Outputs: `ActionResult` + tool telemetry events.

6. **Response Object Model (ROM)**
   - Stable, versioned response contract for renderer and other modalities.
   - Built by orchestrator from:
     - planner intent
     - tool results
     - policy decisions (including denials/confirmations)
   - Output: `ResponseObjectModel` (v1).

7. **Renderer Emission**
   - Renderer receives an envelope and renders experiences/presence-first UI.
   - Orchestrator emits:
     - `RendererEventEnvelope` containing `ResponseObjectModel` (or an adapter to current renderer envelopes).
   - Renderer streams updates (SSE) to surfaces.

8. **Context Write-behind (queued)**
   - Orchestrator enqueues context updates derived from the interaction:
     - preferences, task focus pointers, summaries, session metadata
   - Output: `ContextWriteBehindBatch` (v1).
   - Execution:
     - write-behind is asynchronous and policy-aware; failures do not block UI response.

9. **Event Graph Append (append-only)**
   - Every interaction emits an append-only timeline:
     - input received, routing decision, planner output, policy decisions, tool calls/results, ROM built, renderer emitted, context write queued/flushed
   - Output: `EventGraphAppend` (v1) (initially stored as local JSONL/SQLite).

## Service/module responsibilities (target)

- **IO services (`unison-io-*`)**: modality capture/processing; produce `InputEventEnvelope`; no policy decisions.
- **Orchestrator (`unison-orchestrator`)**: pipeline owner; enforces auth + policy; executes tools; builds ROM; emits to renderer; queues write-behind; appends to Event Graph.
- **Policy (`unison-policy`)**: policy evaluation + audit; no tool execution.
- **Auth/Consent (`unison-auth`, `unison-consent`)**: identity, grants, introspection.
- **Context (`unison-context`)**: profile + KV store.
- **Storage (`unison-storage`)**: encrypted long-term artifacts/vault.
- **Renderer (`unison-experience-renderer`)**: experience surface + SSE; consumes ROM (or adapted envelopes).
- **VDI (`unison-agent-vdi`)**: desktop surface; tool executor boundary remains orchestrator-controlled.
- **Tools**: deterministic executors behind an interface (`ToolRegistry`, `ToolExecutor`).

## Contracts (v1) and versioning strategy

All contracts are **versioned** (e.g., `v1`) and forward-compatible:
- **Additive changes only** within a major version.
- New fields must be optional or have defaults.
- Contracts are serialized as **JSON** with:
  - Pydantic models (Python) generating JSON schema
  - envelope `schema_version` fields for cross-service negotiation

Contracts introduced by this framework (v1):
- `InputEventEnvelope`
- `IntentSession`
- `Intent`
- `ActionEnvelope` (new “orchestration action” contract; distinct from actuation’s existing action-envelope)
- `ActionResult`
- `ResponseObjectModel` (ROM)
- `TraceSpan` / `TraceEvent`
- `ContextWriteBehindBatch`
- `EventGraphAppend`

Canonical code location (Phase 0/1):
- `unison-common/src/unison_common/contracts/v1/*`

## Trace instrumentation (latency-first)

Tracing is required at each boundary. Minimum metrics:
- **Time-to-first-feedback**: first renderer emit (or first “working…” event) after input received.
- **Total time**: input received → completion.
- Per-span durations for:
  - `input_received`
  - `session_created`
  - `router_started` / `router_ended`
  - `planner_started` / `planner_ended`
  - `policy_checked`
  - `tool_started` / `tool_ended`
  - `rom_built`
  - `renderer_emitted`
  - `context_write_queued`

Phase 0/1 implements a local **trace artifact** writer (JSON) so traces exist even without external collectors.

## Trust boundaries (brain is untrusted)

- Model-facing components (router/planner) may emit:
  - `ActionEnvelope` proposals
  - explanations, UI suggestions
- Only orchestrator-owned components may perform side effects:
  - tool execution
  - VDI tasks
  - storage writes
  - context updates
- Every side-effect requires:
  - authenticated actor context (JWT/baton)
  - explicit policy decision
  - trace events recording what happened and why

