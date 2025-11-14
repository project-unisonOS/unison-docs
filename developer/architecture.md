# Unison System Architecture

> Last reviewed: February 2025

This document is the canonical "how it works" reference for builders. It mirrors
`people/quick-start.md` and `developer/platform-overview.md` so it can drop into
the planned GitHub Pages site without edits. Use it when you need subsystem
responsibilities, sequencing, or deployment guidance beyond the high-level
service map.

---

## 1. System Overview

- **Goal:** Convert natural expressions of intent into trustworthy outcomes
  while keeping policy, consent, and context aligned.
- **Contract:** Every interaction flows through an `EventEnvelope` defined in
  `unison-common/schemas/event-envelope.json` and enforced by the
  contract-testing workflows.
- **People-first lens:** Hosted and local experiences (see
  `people/quick-start.md`) talk to the same orchestration spine. Builders extend
  the spine via services, skills, or policy bundles.

![Architecture Diagram](../assets/architecture-diagram.png)

_Alt text: capture interfaces feed the orchestrator and graphs, which fan out to
skills, inference, storage, and rendering surfaces._

---

## 2. Layered Architecture

- **Experience & Capture**
  - Collect voice/vision/text input, render canvases, manage device bridges.
  - Repos: `unison-experience-renderer`, `unison-io-speech`, `unison-io-vision`,
    `unison-io-core`.
  - Notes: Renderer DSL mirrors `people/reference/experience-guide.md`.
- **Intent Orchestration**
  - Normalize events, coordinate intent + context graphs, fan out to policy.
  - Repos: `unison-orchestrator`, `unison-intent-graph`, `unison-context-graph`.
  - Notes: Graph services scale independently while orchestrator brokers traffic.
- **Policy & Consent**
  - Evaluate bundles, enforce grants, issue tokens, capture audits.
  - Repos: `unison-policy`, `unison-consent`, `unison-auth`.
  - Notes: `unison-auth` publishes JWKS that policy + consent consume.
- **State & Storage**
  - Persist context, replay history, store artifacts, maintain WAL.
  - Repos: `unison-context`, `unison-storage`.
  - Notes: Replay tooling (`unison-context-graph/validate_replay.py`) depends on
    WAL health.
- **Skills & Inference**
  - Execute capabilities and model backends.
  - Repos: `unison-devstack/scripts/register_skills.py`, `unison-inference`,
    skill repos.
  - Notes: Skills register via Devstack CLI or CI; inference wraps hosted models.

Each layer exposes `/ready` and `/healthz` endpoints surfaced through the
Devstack dashboard (`http://localhost:3000`) and the hosted monitoring stack.

---

## 3. Core Domains in Detail

### 3.1 Orchestrator

- **Ingress:** `/event`, `/ingest`, and `/ready` endpoints in
  `unison-orchestrator/src/server.py`.
- **Routing:** Validates envelopes, fetches policy/context, emits trace spans
  (`unison-common/src/unison_common/tracing.py`), and dispatches to skills via
  routing rules.
- **State:** Stateless aside from tracing + correlation IDs; Kubernetes
  deployment specs live in `unison-devstack`.

### 3.2 Context Graph + Service

- **Context Service (`unison-context`):** Stores durable context, replay
  pointers, and consent-aware partitions.
- **Context Graph (`unison-context-graph`):** Builds derived relationships for
  personalization/replay (`docs/DURABILITY.md`, `P2.4_DURABILITY_PLAN.md`).
- **APIs:** `/graph`, `/replay`, `/kv`; `test_kv_put_validation.py` enforces
  schema rules.

### 3.3 Policy + Consent

- **Policy Service:** Evaluates bundles (`unison-policy/docs/BUNDLE_FORMAT.md`)
  and exposes `/evaluate`, `/rules/summary`.
- **Consent Service (`unison-consent`):** Issues grants rooted in cryptographic
  material managed by `unison-auth`.
- **Shared contracts:** `unison-common/src/unison_common/consent.py` and
  `consent_rs256.py`.

### 3.4 Experience Renderer

- **Renderer engine:** Consumes the renderer DSL
  (`unison-experience-renderer/src/renderer_dsl.py`) to craft adaptive canvases.
- **Devstack UI:** Bundled with renderer; surfaces health, logs, and scenario
  shortcuts.
- **Extensions:** Refer to `people/reference/experience-guide.md` for custom
  surfaces.

### 3.5 Skills & Inference

- **Skills:** Registered via `unison-devstack/scripts/register_skills.py` or the
  hosted skill register; metadata stored in storage/context.
- **Inference:** `unison-inference` exposes a FastAPI service that wraps model
  runners (`INFERENCE.md`).
- **Security:** Skills inherit policy gating through orchestrator-signed
  requests; inference endpoints enforce token scopes from `unison-auth`.

---

## 4. Data Flow & Contracts

1. Capture services normalize input and emit `EventEnvelope` payloads.
2. Orchestrator validates the envelope schema
   (`unison-common/tests/test_envelope_validation.py`).
3. Orchestrator queries context and policy in parallel; tracing spans correlate
   requests.
4. Intent + context graphs decompose goals while skills/inference execute the
   steps.
5. Experience renderer assembles the final surface and replies to people
   interfaces.
6. Storage and context persist state so replay and auditing remain possible.

Key contracts:

- `event-envelope.json`
- Policy bundle schema (`unison-policy/docs/BUNDLE_FORMAT.md`)
- Renderer DSL (`unison-experience-renderer/src/renderer_dsl.py`)

Any change to these contracts requires updates per
`DOCUMENTATION_UPDATE_PLAN.md`.

---

## 5. Deployment Topologies

- **Local Devstack**
  - `make up` boots the compose bundle (`unison-devstack/compose/compose.yaml`).
  - Entry points: Devstack UI (`:3000`) plus the individual service ports
    (`:8080+`).
  - Mirrors People quick start Step 1B; ideal for feature work.
- **Hosted Preview**
  - Shared stack driven by `docker-compose.prod.yml` and `compose.edge.yml`.
  - Entry points: Hosted URL with SSO.
  - Adds Kong gateway, scaled orchestrator, and managed Postgres.
- **CI Pipelines**
  - GitHub Actions (`tests.yml`, `service-tests.yml`, `contract-testing*.yml`).
  - Entry points: workflow dispatch.
  - Contract tests guard schemas; docs-lint guards markdown.
- **Production (planned)**
  - Kubernetes + service mesh (`PHASED_DEPLOYMENT_STRATEGY.md`).
  - Entry points: public ingress via Kong.
  - Aligns with security hardening docs in `unison-docs/dev/SECURITY_*`.

Secrets and config live in `.env.template`, `.env.prod.template`, and
Vault/Terraform files under `unison-platform/config`.

---

## 6. Observability, Reliability, and Compliance

- **Tracing:** `unison-common/src/unison_common/tracing.py` wires OTEL; collector
  config in `otel-collector-config.yaml`. Tests live in
  `unison-common/tests/test_tracing_*.py`.
- **Metrics:** `unison-common/src/unison_common/monitoring.py` plus Prometheus
  config (`unison-devstack/config/prometheus.yml`).
- **Logging:** Structured JSON via `unison-common/src/unison_common/logging.py`;
  redaction tests keep sensitive data out of logs.
- **Health:** `make health` and `http://localhost:3000/health` aggregate probes.
  Every service exposes `/ready` + `/healthz`.
- **Reliability:** Replay tooling (`replay_store.py`, `validate_replay.py`) plus
  the storage WAL support disaster recovery (`HEALTH_CHECK_SYSTEM.md`).
- **Compliance:** Policy/consent enforcement relies on JWT/JWKS from
  `unison-auth`; see `SECURITY_IMPLEMENTATION.md` and `PRIVACY.md`.

---

## 7. Reference & Next Steps

- Experience docs: `people/quick-start.md`, `people-guide.md`,
  `scenarios/README.md`.
- Builder guides: `developer/platform-overview.md`,
  `developer/getting-started.md`, `developer/development-workflow.md`.
- Specs: `unison-docs/dev/specs/*` (policy, context, event envelope) and
  `unison-spec/`.
- Maintenance loop: follow `DOCUMENTATION_UPDATE_PLAN.md` and log refreshes in
  `DOCUMENTATION_UPDATE_SUMMARY.md`.

Keep this file updated whenever you touch architecture diagrams, service
boundaries, or core contracts so published docs stay aligned with the platform.***
