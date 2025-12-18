# UnisonOS Alpha 2 — Release Notes (Draft)

This document is a living draft for the next **Alpha 2** release. It is intended to accumulate changes as development continues. Before cutting the next alpha release tag, the “Changes in this cycle” section should be curated and copied into the GitHub Release notes.

## Summary

Alpha 2 focuses on making **system capabilities** real, safe, and operationally usable:

- A production-oriented **Capability Resolver** service (`unison-capability`) implements the normative planner ↔ resolver contract.
- Capabilities are **manifest-declared**, schema-validated, policy-enforced, and **audited**.
- Images can ship a **seeded baseline** catalog (safe-by-default local tools, disabled connectors, and skill packs).
- A pluggable **registry discovery** model allows optional catalogs without hardcoding trust.
- **OAuth onboarding** is supported for connectors with secrets stored outside manifests (references only).
- `unison-comms` is refactored to execute comms actions via the resolver, aligning comms with capability governance.
- Devstack now includes an end-to-end comms test proving: orchestrator → resolver → comms tool surface.

## Changes in this cycle (running list)

### Capability system (core)

- Implemented `unison-capability` as the platform Capability Resolver:
  - API implements the required contract: `capability.search`, `capability.resolve`, `capability.install`, `capability.run`, plus `list/get/remove`.
  - Manifest schema validation and policy gates enforced on install and run.
  - Transactional installs (stage → validate → promote) with rollback safety.
  - Concurrency-safe store operations (file locks) and tests.
  - Operational endpoints: `/healthz`, `/readyz`, `/version`, `/metrics`.
  - Structured audit events with token/secrets redaction aligned with `unison-security` logging guidance.
  - Central egress gate: deny-by-default non-loopback egress unless allowlisted; per-capability network allowlists enforced at runtime.

### Seeded capabilities (baseline experience)

- Added layered manifest support:
  - `manifest.base.json` is shipped read-only in the image.
  - `manifest.local.json` is mutable; installs/overrides/enablement state are written only to local.
  - Resolver view merges base + local with local overriding by `id`.
  - Factory reset removes local state while keeping the base catalog.
- Seeded a curated baseline manifest including:
  - Local host/system inspection tools enabled by default.
  - Connector placeholders disabled by default and gated by OAuth.
  - Skill packs for common workflows.

### Registry adapters (discovery without hardcoded trust)

- Added a pluggable registry adapter system:
  - Static catalog adapter for deterministic “known-good” entries.
  - HTTP catalog adapter (HTTPS-only) with egress/policy gates; treated as untrusted unless policy/config marks verified.
  - Candidate ranking favors local catalog hits; registry candidates are lower-ranked by default.

### OAuth onboarding and secrets (no secrets in manifests)

- Added OAuth device authorization flow support for Google and Microsoft providers (headless-friendly).
- Implemented a secrets backend abstraction with encrypted file backend for development.
- Enforced that manifests contain only secret references/handles (never secret values).

### Comms integration (capability-governed comms)

- Refactored `unison-comms` to expose a tool surface for comms operations and to support a resolver-mediated execution path.
- Updated `unison-orchestrator` comms skills to resolve and run `comms.*` capabilities via the resolver (planner-contract compliant), rather than calling comms endpoints directly.
- Added a devstack end-to-end comms smoke step verifying:
  - `comms.compose` (unison) through orchestrator → resolver → comms tool surface
  - `comms.check` returns the composed message

### Documentation

- Capability docs were expanded to cover:
  - manifest schema and extensions
  - seeded base/local layering
  - registry adapters and trust defaults
  - OAuth enablement and secret reference rules
- GH Pages documentation updated to:
  - explain the capability system in the Architecture Deep Dive
  - add an Experience page describing “System Capabilities” from a person’s perspective

## Compatibility and migration notes

- Planner/orchestrator flows should not execute tools/connectors directly; they must resolve capabilities first and run via the resolver.
- Connectors are disabled by default. Enabling requires onboarding; secret material must be stored outside manifests and referenced by handles.
- Devstack includes a permissive local configuration for resolver auth/egress to support local integration testing. Production deployments should front internal services with the standard identity and policy sidecars.

## Known issues / follow-ups (draft)

- Tighten and standardize service-to-service auth and identity (SPIFFE mTLS + ext_authz) across devstack and production compose.
- Expand connector implementations beyond placeholders; keep policy/egress and secret handling consistent with resolver/security primitives.
- Add CI coverage for capability-governed comms flows outside of devstack smoke (unit/integration tests at service boundaries).

