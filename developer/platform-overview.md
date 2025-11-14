# Unison Platform Overview

> Last reviewed: February 2025

This orientation file summarizes the repos, services, and workflows that keep
the Unison experience running. Each section maps to a future GitHub Pages card
so we can publish it without extra formatting.

---

## 1. Platform Boundaries

- **Core promise:** Translate natural intent into orchestrated outcomes while
  keeping consent, policy, and context in sync.
- **Audience split:** People-facing docs live under `people/`; builder docs live
  under `developer/`.
- **Change signal:** When a repo, service contract, or make target changes,
  update this overview first, then cascade to the deeper references.

---

## 2. Repository Map

The platform ships as a polyrepo tree checked out together. Start here when you
need to find where something lives.

- **Experience stack:** `unison-experience-renderer` renders canvases and hosts
  the Devstack dashboard.
- **Orchestration spine:** `unison-orchestrator` handles event ingress,
  policy/context fan-out, and skill routing.
- **Policy and consent:** `unison-policy`, `unison-consent`, and `unison-auth`
  manage bundles, grants, and tokens.
- **Context and graphing:** `unison-context` stores durable state, and
  `unison-context-graph` builds projections for replay/personalization.
- **Storage:** `unison-storage` keeps artifacts, WAL data, and audit logs.
- **Shared contracts:** `unison-common` and `unison-spec` provide schemas and
  client helpers.
- **I/O services:** `unison-io-speech`, `unison-io-vision`, and `unison-io-core`
  capture multimodal input.
- **Dev tooling:** `unison-devstack`, `scripts/`, and `.github/` contain make
  targets, compose bundles, and workflows such as `docs-lint`.

Each repo README links back to this file under “Where does this fit?”—keep that
crosslink intact.

---

## 3. Service Map Snapshot

- **Experience layer:** Experience Renderer (`:8092`) and Devstack UI (`:3000`)
  provide canvases, health dashboards, and scenario launchers.
- **Orchestration layer:** Orchestrator (`:8080`), Intent Graph (`:8084`), and
  Context Graph (`:8085`) ingest envelopes, plan execution, and manage context
  edges.
- **Policy + consent:** Policy (`:8083`), Auth (`:8086`), and Consent (`:8087`)
  evaluate bundles, issue tokens, and enforce grants.
- **Data stores:** Context (`:8081`) and Storage (`:8082`) persist graph state
  and artifacts.
- **I/O + skills:** Speech, Vision, Core I/O, and the skills registry (`:8095+`)
  capture multimodal input and fan out to capabilities.

See [`developer/architecture.md`](./architecture.md) for diagrams and sequence
details.

---

## 4. Run Modes

### Local Devstack

- `make up` boots the default compose bundle defined in `compose/compose.yaml`.
- `make health`, `make logs`, and `make restart service=<name>` are surfaced in
  the Devstack UI.
- Update this section whenever the compose bundle or required env vars change.

### CI / Contract Testing

- `.github/workflows/tests.yml` (per service) runs unit + integration suites.
- `.github/workflows/contract-testing*.yml` guard schema compatibility.
- `.github/workflows/docs-lint.yml` runs markdownlint, remark, and misspell for
  everything under `unison-docs/`.

### Hosted / Preview

- `unison-devstack/docker-compose.prod.yml` and `compose.edge.yml` power the
  hosted preview deployment.
- Release playbooks live in `UNISON_PLATFORM_IMPLEMENTATION_PLAN.md` and
  `PHASED_DEPLOYMENT_STRATEGY.md`.

---

## 5. Observability & Support Surfaces

- **Health endpoints:** `http://localhost:3000/health`, the Devstack status
  page, and service-level `/ready` probes.
- **Tracing + metrics:** `unison-common/tests/test_tracing_*` guard OTEL
  instrumentation; docs live in `docs/observability/README.md`.
- **Log hygiene:** `logging.py` and `monitoring.py` in `unison-common` define
  redaction + metrics helpers.
- **Incident loop:** The People Quick Start sends folks to
  `people-guide.md#need-help`; mirror those escalation paths here when runbooks
  move.

---

## 6. Next Steps for Builders

1. **Set up your environment.** Follow
   [`developer/getting-started.md`](./getting-started.md) for tooling, linting,
   and contribution policies.
2. **Deep dive into architecture.** Use
   [`developer/architecture.md`](./architecture.md) for subsystem sequencing and
   diagrams.
3. **Plan contributions.** Reference `DOCUMENTATION_UPDATE_PLAN.md` so doc
  updates ship alongside code.
4. **Stay aligned with People docs.** If you add or rename services, update this
   file and `people/quick-start.md` in the same PR.

---

## 7. Maintenance Loop (WIP)

- **PR checklist:** “Docs updated?” lives in
  `.github/pull_request_template.md`.
- **Docs changelog:** `DOCUMENTATION_UPDATE_SUMMARY.md` captures every refresh.
- **Quarterly review:** Architecture steward reviews this file, the architecture
  reference, and People quick start together.

Until the automation ships, note doc impacts in your PR description and loop in
the docs maintainers.
