# Golden Path Validation

This document defines the current renderer-led golden path for local Project UnisonOS development.

It is intentionally narrower than full platform install acceptance. It exists to make the current product-path contract explicit inside the workspace repos that developers use day to day.

## Purpose

The current golden path should prove that UnisonOS is behaving like an operating surface, not only like a service mesh.

For the current local development path, the minimum meaningful golden path is:

1. orchestrator startup converges into a meaningful first-run state
2. renderer aggregates onboarding readiness from startup, speech, inference, and profile state
3. a personal briefing can be produced through `dashboard.refresh`
4. voice input can drive a companion turn through `/voice/ingest`

## Canonical Golden-Path Anchors

### 1. Orchestrator startup status
Endpoint:
- `GET /startup/status`

Current contract:
- exposes first-run state rather than generic health alone
- reports fields including:
  - `state`
  - `onboarding_required`
  - `bootstrap_required`
  - `renderer_ready`
  - `core_ready`
  - `speech_ready`

Meaning:
- this is the main machine-readable statement of whether the stack is merely alive or actually ready for the first user experience

## 2. Renderer onboarding aggregation
Endpoint:
- `GET /onboarding-status`

Current contract:
- aggregates orchestrator startup state, profile state, speech readiness, and inference readiness
- exposes fields including:
  - `startup`
  - `steps`
  - `blocked_steps`
  - `remediation`
  - `ready_to_finish`

Meaning:
- this is the renderer-led first-run contract
- it is closer to product truth than raw per-service readiness checks

## 3. Briefing path
Entry point:
- orchestrator event with intent `dashboard.refresh`

Current contract:
- returns cards for a per-person dashboard/briefing experience
- persists dashboard state in `unison-context`
- emits renderer-visible experience payloads when configured

Meaning:
- this is the clearest current path for a renderer-led briefing experience

## 4. Voice path
Entry point:
- `POST /voice/ingest`

Current contract:
- accepts `transcript`, `person_id`, and `session_id`
- routes through the companion manager
- can emit downstream speech and renderer experience artifacts

Meaning:
- this is the clearest current voice-first interaction path in the workspace repos

## Validation Layers

### Repo-local regression anchors

The current golden path is also backed by focused repo-local tests:

- `unison-orchestrator/tests/test_startup_status.py`
- `unison-orchestrator/tests/test_startup_status_ready.py`
- `unison-orchestrator/tests/test_dashboard_refresh.py`
- `unison-orchestrator/tests/test_voice_ingest.py`
- `unison-experience-renderer/tests/test_startup_status_endpoint.py`
- `unison-experience-renderer/tests/test_onboarding_endpoint.py`
- `unison-experience-renderer/tests/test_onboarding_ready.py`
- `unison-context/tests/test_dashboard.py`

These do not replace integration or platform validation, but they lock the current golden-path contract at the service boundary level.

These checks are complementary and should not be conflated.

### Devstack smoke
Script:
- `unison-devstack/scripts/e2e_smoke.py`

Purpose:
- service wiring and integration plumbing

### Multimodal validation
Script:
- `unison-devstack/scripts/test_multimodal.py`

Purpose:
- speech and vision path validation

### Golden-path validation
Script:
- `unison-devstack/scripts/validate_golden_path.py`

Purpose:
- validate the current renderer-led product-path contract
- specifically:
  - startup status shape
  - onboarding status shape
  - briefing path via `dashboard.refresh`
  - voice path via `/voice/ingest`

## What This Does Not Prove

This local golden-path validation does not by itself prove:
- fresh-machine installability
- full platform packaging or release readiness
- reboot/update/recovery coverage
- connector completeness
- full renderer doctrine fidelity

## Journey 6 Boundary Note

The current workspace golden path still does not directly execute the new `unison-comms` Gmail onboarding path.

That pushed bounded path now includes:
- `GET /comms/onboarding/email`
- `POST /comms/onboarding/email/bootstrap`
- `POST /comms/onboarding/email/verify`
- `POST /comms/onboarding/email/reset`
- `GET /comms/onboarding/email/oauth`
- draft-first compose behavior
- adapter-backed summarize behavior
- provider-aware empty/message state shaping

These are useful repo-local and service-surface anchors, but they are not yet part of the canonical workspace golden-path validator sequence.

Those remain broader Milestone 1 and platform-level concerns.

## Auth-Aware Validation

Some runtime paths enforce orchestrator authentication even when the workspace devstack examples do not.

When validating against an auth-enforcing runtime, provide a bearer token:

```bash
export UNISON_BEARER_TOKEN=<access-token>
```

Both of these validators honor that variable:
- `unison-devstack/scripts/test_multimodal.py`
- `unison-devstack/scripts/validate_golden_path.py`

This allows the same validation scripts to work in both:
- permissive local devstack mode
- stricter authenticated runtime mode

## Recommended Local Validation Sequence

With the local stack running:

```bash
python unison-devstack/scripts/e2e_smoke.py
python unison-devstack/scripts/test_multimodal.py
python unison-devstack/scripts/validate_golden_path.py
```

If the runtime enforces auth on orchestrator event paths:

```bash
export UNISON_BEARER_TOKEN=<access-token>
python unison-devstack/scripts/test_multimodal.py
python unison-devstack/scripts/validate_golden_path.py
```

Use this sequence when assessing whether the workspace currently supports the intended development golden path.
