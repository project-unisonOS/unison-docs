---
title: Local Updates Overview
nav_order: 1
---

# Local software updates for UnisonOS

UnisonOS updates are designed to be **conversationally initiated**, **policy-driven**, **transactional**, and **rollbackable**.
Conversation never “does updates” directly. Instead, conversation requests an update goal; the Update Service evaluates policy,
produces a safe plan, asks for approval (as required), executes with health checks, and reports completion with “what changed”.

## Update planes

UnisonOS treats local updates as three coordinated planes:

1. **Device OS plane**: Ubuntu Core (snap base), kernel/base snaps, security patches.
2. **UnisonOS software plane**: Unison services, capabilities, agents, renderer, configs, migrations.
3. **Model plane**: interaction/planner models, ASR, TTS, embeddings, tokenizers, runtimes and related assets.

Each plane is managed by a provider behind a single Update Service.

## Goals

- **Proactive and on-demand**: notify when updates are available; allow “check/install/schedule/rollback” via conversation.
- **No data loss**: runtime updates must not overwrite person data, preferences, or persistent config.
- **Safety and trust**: signed artifacts; compatibility checks; preflight checks; explicit approval when needed.
- **Resilience**: atomic apply, rollback on failure, and resumable downloads.

## System components

### Update Service (daemon)

A privileged local service responsible for:

- Maintaining an **inventory** of installed OS snaps, Unison components, and model packs
- Checking configured sources (channels/registries)
- Building an **update plan** (ordered steps + prerequisites + rollback points)
- Running **preflight checks** (disk, battery/AC, network, idle, “in-call”, thermal constraints, etc.)
- Executing updates with **health checks** and **automatic rollback**
- Emitting events into Unison’s event bus: `update.available`, `update.progress`, `update.complete`, `update.failed`
- Serving a single tool surface to the interaction/planner models (see `conversation_intents.md`)

### Providers

The Update Service delegates to plane-specific providers:

- **OS Provider**: snapd refresh control on Ubuntu Core, security cadence, channel selection, reboot requirements.
- **Unison Provider**: updates Unison runtime/services using a rollback-friendly mechanism:
  - Preferred on Ubuntu Core: Unison components packaged as snaps (transactional + rollback)
  - Alternative: container images with blue/green cutover + health checks + rollback
- **Model Provider**: installs model packs from signed manifests; validates compatibility; keeps last-known-good packs.

## Core invariants

### Transactional + rollbackable

Each update must have:

- A clear **rollback point**
- A **last-known-good** version retained
- A **health check gate** before declaring success

If a health check fails, rollback is automatic and the person is notified.

### Resumable + safe

- Downloads must resume after interruption.
- Power loss must not brick the system.
- Partial updates must be detectable and recoverable.

### Signed and verifiable

- Every artifact must be verified before install:
  - OS: snap assertions / snap signatures (snapd)
  - Unison: signed snap or signed image digest + provenance
  - Models: signed manifest + hashed payloads

## Data persistence and migrations

Separate deployables (runtime) from person state:

- Person state (examples): preferences, policy, credentials (encrypted), conversation history, local knowledge stores.
- Runtime state: binaries, containers/snaps, model packs, ephemeral caches.

Migration rules:

- For schema changes, run forward migrations as part of the Unison plane update.
- Create a pre-migration snapshot (db + config) for major versions.
- Favor backward-compatible schemas when feasible.

## Update policy

Policies are editable via conversation and stored locally in persistent config:

- Auto-check frequency (daily/weekly)
- Auto-download (yes/no; Wi‑Fi only)
- Auto-apply (never / security-only / everything) with explicit approval rules
- Preferred channels per plane (stable/candidate/beta/edge)
- Quiet hours / do-not-disturb
- Preconditions (require AC power; minimum battery; minimum free disk)
- Retention (keep N previous versions per component/model)
- Rollback permissions

## Compatibility and sequencing

Default sequencing:

1. OS plane (if required for runtime or security-critical)
2. Unison plane (services/runtime)
3. Model plane (packs and runtimes)

Compatibility is enforced:

- A model pack can declare `requires.unison_runtime >= X`.
- A Unison release can declare `requires.os_base >= Y`.
- The plan must either reorder steps or block with an explanation.

## Notifications and conversational UX

Updates are initiated from conversation:

- “Are updates available?”
- “Install the security updates now.”
- “Schedule the feature update for tonight at 10.”
- “Roll back to the previous version.”

Completion notifications include:

- What updated (by plane)
- Whether a reboot/restart occurred
- What changed: highlights + link to full release notes
- A quick way to roll back if needed

## Observability and diagnostics

The Update Service must provide:

- Per-job logs (structured)
- Progress events (machine-readable)
- A “create diagnostics bundle” operation suitable for support without leaking sensitive content

## Security posture

- Artifact signature verification is required.
- Secrets are never embedded in artifacts; credentials used for pulling private registries are stored encrypted locally.
- The Update Service exposes only a narrow local API to Unison, enforced by OS-level permissions.

## References

- See `docs/platform/updates/provider_interface.md` for the provider contract and reference provider behaviors.
- See `docs/platform/updates/conversation_intents.md` for canonical conversational flows and examples.
- See `docs/platform/updates/how_to_update_from_conversation.md` for a user-facing guide.
- See `docs/platform/updates/runbook_local_testing.md` for local validation and CI test mode notes.
