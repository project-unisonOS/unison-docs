---
title: Update Provider Interface
nav_order: 2
---

# Update Provider Interface (design spec)

The Update Service coordinates multiple update planes (OS, Unison, Models) via providers that implement a common contract.
Providers are responsible for availability checks, plan contribution, and execution of plan steps with health checks and rollback.

This document defines the provider interface and the plan/job state model.

## Concepts

### Plane
A logical update domain: `os`, `unison`, or `models`.

### Artifact
A versioned, signed installable unit (snap, container image, model pack).

### Plan
An ordered sequence of steps with prerequisites and rollback points.

### Job
An execution instance of a plan.

## Data model

### InventoryItem
- `plane`: `os|unison|models`
- `name`: string (e.g., `unison-orchestrator`, `planner-pack`)
- `installed_version`: semver/string
- `channel`: string (e.g., `stable`, `candidate`)
- `source`: string (registry URL, snap store origin, local repo)
- `health`: `healthy|degraded|unknown`
- `metadata`: provider-specific map

### AvailableUpdate
- `plane`
- `name`
- `from_version`
- `to_version`
- `channel`
- `priority`: `security|recommended|optional`
- `requires_reboot`: bool
- `size_bytes`: integer (optional)
- `release_notes_ref`: string (local cache key or URL)
- `compat`: constraints (optional)

### PreflightResult
- `ok`: bool
- `blocking_reasons`: string[]
- `warnings`: string[]
- `disk_free_bytes`: integer
- `power`: `{ on_ac: bool, battery_percent: int|null }`
- `network`: `{ metered: bool, wifi: bool, ok: bool }`

### PlanStep
- `id`: string
- `plane`
- `title`: string
- `action`: string (provider-defined verb)
- `args`: map
- `rollback`: `{ supported: bool, hint: string|null }`
- `health_check`: `{ type: string, args: map }`
- `estimated_seconds`: int|null
- `requires_approval`: bool
- `requires_reboot`: bool

### UpdatePlan
- `plan_id`: string
- `created_at`: ISO8601
- `steps`: PlanStep[]
- `preflight`: PreflightResult
- `impact_summary`: string
- `approval_required`: bool
- `recommended_schedule`: `{ window_start: ISO8601|null, window_end: ISO8601|null }`

### JobStatus
- `job_id`: string
- `plan_id`: string
- `state`: `queued|running|paused|failed|rolled_back|completed`
- `current_step_id`: string|null
- `progress`: `{ completed_steps: int, total_steps: int }`
- `events`: `{ ts: ISO8601, level: info|warn|error, msg: string, step_id: string|null }[]`

## Provider contract

Providers should be implemented as local modules invoked by the Update Service (not directly by conversation).

### Interface (language-agnostic)

- `get_inventory() -> InventoryItem[]`
- `check_updates(policy) -> AvailableUpdate[]`
- `preflight(selection, policy) -> PreflightResult`
- `build_steps(selection, policy, inventory) -> PlanStep[]`
- `execute_step(step, context) -> void` (must emit progress events)
- `health_check(step, context) -> { ok: bool, details: string }`
- `rollback(step_or_target, context) -> void`
- `fetch_release_notes(update) -> { highlights: string[], details: string }`

### Execution rules

- Providers must be **idempotent**: re-running a step should not corrupt state.
- Providers must persist enough state to resume after restart.
- Providers must verify signatures/hashes before install.
- Providers must report accurate reboot requirements.

## Reference provider behaviors

### OS Provider (Ubuntu Core / snapd)

Responsibilities:

- Enumerate snaps relevant to the OS plane (base, kernel, gadget, core, security updates).
- Check for updates via snap channels.
- Respect refresh holds and schedule windows.
- Apply updates via snapd in a way that preserves rollback.

Typical steps:

- `os.snap.refresh`: refresh selected snaps (or all security-critical)
- `os.reboot`: if required

Health checks:

- snapd state ok
- required services reachable after refresh
- reboot completed and system returned healthy

### Unison Provider (snap-first, container alternative)

Preferred approach on Ubuntu Core:

- Package major Unison components as snaps or snap bundles.
- Keep person state outside snap install paths.
- Use snap revisions as rollback targets.

Container alternative:

- Pull versioned images by digest.
- Deploy to “green” slot, run health checks, then cut over.
- Roll back to “blue” slot if health checks fail.

Typical steps:

- `unison.artifact.download`
- `unison.deploy.stage`
- `unison.deploy.cutover`
- `unison.migrations.run`
- `unison.services.restart`

Health checks:

- orchestrator responds
- event bus connected
- renderer reachable
- critical endpoints pass smoke tests

### Model Provider (model packs)

Responsibilities:

- Check for model pack updates by channel.
- Download pack + manifest.
- Verify signature + hashes.
- Install side-by-side (versioned).
- Validate (load test + smoke prompt).
- Switch active model via config pointer.
- Retain last-known-good pack for rollback.

Typical steps:

- `models.pack.download`
- `models.pack.verify`
- `models.pack.install`
- `models.pack.validate`
- `models.pack.activate`

Health checks:

- model runtime loads within threshold
- test inference completes
- ASR/TTS basic pass (if applicable)

## Plan coordination

The Update Service owns sequencing and cross-plane compatibility:

- OS -> Unison -> Models (default)
- Providers can declare hard requirements in `AvailableUpdate.compat`
- The planner must reorder or block with an explanation

## Diagnostics

Providers should support:

- `provider.dump_state()` (safe summary)
- Step logs with redaction
- A diagnostic bundle exporter (optional), controlled by policy
