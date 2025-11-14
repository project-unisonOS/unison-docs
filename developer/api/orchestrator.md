# Unison Orchestrator API Reference

## Overview

The Unison Orchestrator API provides a set of endpoints for managing events, skills, and introspection.

## Confirmation Flow

- When `policy` returns `require_confirmation: true`, `/event` responds with `confirmation_token` and `confirmation_ttl_seconds`.
- Confirm the pending action via:

### POST /event/confirm

- Request:

```json
{ "confirmation_token": "<uuid>" }
```

- Response (accepted):

```json
{
  "accepted": true,
  "routed_intent": "...",
  "handled_by": "echo",
  "outputs": { ... },
  "event_id": "...",
  "steps": [ {"step":"confirm"}, {"step":"handler"} ]
}
```

- TTL is configured via env `UNISON_CONFIRM_TTL` (seconds). Pending confirmations are persisted under `storage:/kv/confirm/<token>`.

## Base URL

- Local devstack: `http://localhost:8080`

## Endpoints

### GET /health

- Purpose: Liveness probe
- Response:

```json
{ "status": "ok", "service": "unison-orchestrator" }
```

### GET /ready

- Purpose: Readiness probe. Checks context/storage health and performs a policy evaluation.
- Response fields:
  - `ready` (bool)
  - `deps.context` (bool)
  - `deps.storage` (bool)
  - `deps.policy_allowed_action` (bool)
  - `event_id` (string, UUID)
- Example:

```json
{
  "ready": true,
  "deps": { "context": true, "storage": true, "policy_allowed_action": true },
  "event_id": "c9a8f7a2-7f61-4c2c-9e3e-3b5c1f6d9a21"
}
```

### POST /event

- Purpose: Accept an EventEnvelope (see dev/specs/EVENT-ENVELOPE.md) and gate it through Policy.
- Request headers:
  - None required. Orchestrator will generate and propagate `X-Event-ID` internally for downstream calls.
- Request body:
  - EventEnvelope object with required fields: `timestamp`, `source`, `intent`, `payload`.
- Validation:
  - Unknown top-level fields are rejected.
- Response (allowed):

```json
{
  "accepted": true,
  "routed_intent": "summarize.document",
  "payload": { "document_ref": "active_window", "summary_length": "short" },
  "policy_status": 200,
  "policy_require_confirmation": false,
  "explanation": "stub handler executed",
  "handled_by": "echo",
  "outputs": { "echo": { "document_ref": "active_window", "summary_length": "short" }, "context": {"greeting": "hello"}},
  "event_id": "e3e7d3f7-0f6a-4ac2-8246-6ce0b0e2a1bf",
  "steps": [
    {"step":"validate","ok":true},
    {"step":"policy","ok":true,"status":200,"reason":"internal-summary-allowed"},
    {"step":"context_get","ok":true,"keys":1},
    {"step":"handler","ok":true,"name":"echo"}
  ]
}
```

- Response (blocked):

```json
{
  "accepted": false,
  "reason": "policy-deny",
  "require_confirmation": true,
  "confirmation_token": "<uuid>",
  "confirmation_ttl_seconds": 300,
  "policy_status": 200,
  "policy_raw": { "decision": { "allowed": false, "require_confirmation": true, "reason": "policy-deny" } },
  "event_id": "...",
  "steps": [ { "step": "validate" }, { "step": "policy", "ok": false } ]
}
```

### Skills

- `GET /skills` — list registered skills
- `POST /skills` — body `{ intent_prefix, handler, context_keys? }`
  - `context_keys` (optional): array of keys to fetch from Context via `/kv/get` before invoking the handler

## GET /introspect

- Purpose: Operational snapshot for debugging/ops.
- Response fields:
  - `event_id` (UUID)
  - `services` — health summaries of context/storage/policy
  - `skills` — registered skill entries
  - `policy_rules` — `{ ok, status, summary: { count, path } }`

## Correlation

- The orchestrator generates a unique `event_id` per `/ready` and `/event` request.
- It propagates `X-Event-ID: <event_id>` to downstream services (Policy, Context, Storage).
- All core services log structured JSON including `event_id` when available, enabling cross-service log correlation.

## Notes

- Current implementation performs a policy check and returns an accepted/blocked response. Dispatch to generators/I/O is stubbed and will be extended in future iterations.
