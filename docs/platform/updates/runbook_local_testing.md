---
title: Local Testing Runbook
nav_order: 5
---

# Local testing runbook (dev + CI)

This runbook verifies the end-to-end conversational update flow using the dev stack.

## 1) Start the stack (includes Update Service)

From `unison-platform/`:

```bash
make up
```

Verify:

- Orchestrator: `http://localhost:8090/health`
- Renderer: `http://localhost:8092/health`
- Update Service: `http://localhost:8094/health`

## 2) Ensure orchestrator can reach the Update Service

In the orchestrator container/env, `UNISON_UPDATES_URL` must be set (compose does this):

```bash
UNISON_UPDATES_URL=http://updates:8089
```

## 3) Run unit tests (Update Service + signature verification)

From the workspace root:

```bash
PYTHONPATH=unison-updates/src .venv/bin/pytest -q unison-updates/tests
```

## 4) Exercise the conversational flow

In the client (renderer surface), say:

- “Are updates available?”
- “Show me an update plan.”
- “Install it.”
- “How’s it going?”

Expected tool calls:

1. `updates.check()`
2. `updates.plan(...)`
3. `updates.apply(plan_id)`
4. `updates.status(job_id)` (as needed)

Progress notifications:

- Renderer receives `update.progress`, `update.complete`, `update.failed`.

## 5) Enable signature enforcement (recommended)

The production default is `UNISON_UPDATES_REQUIRE_SIGNATURES=true`.

When enabled, you must provide public keys:

- Unison release keys: `/etc/unison/keys/updates/unison/*.pub`
- Model pack keys: `/etc/unison/keys/updates/models/*.pub`

For local development, you can generate keys and sign artifacts using:

- `unison-updates/scripts/ed25519_keygen.py`
- `unison-updates/scripts/sign_json.py`

