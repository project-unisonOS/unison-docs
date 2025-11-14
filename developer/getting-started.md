# Developer Getting Started

> Last reviewed: February 2025

This guide is the first stop for builders working inside the Unison workspace. It shows how to prepare your environment,
boot the devstack, iterate on individual services, and stay aligned with the docs that will back the future GitHub Pages
site.

---

## 1. Prepare Your Environment

### Requirements

- macOS Sonoma+, Linux, or Windows 11 with WSL2
- Docker Desktop 4.25+ (8 GB RAM, 4 CPUs)
- `git`, `make`, and a recent shell (bash, zsh, pwsh)
- Python 3.11+ and `uv` or `pipx` for service-specific tooling
- Node.js 20+ if you plan to run documentation linting locally

### Clone the Workspace

```bash
git clone https://github.com/unison-platform/unison.git
cd unison
```

The repository contains all platform services (for example `unison-orchestrator/`, `unison-context/`,
`unison-policy/`), support tooling (`unison-devstack/`, `scripts/`), and documentation (`unison-docs/`). Keep the root
clean—shared make targets expect this layout.

---

## 2. Boot the Devstack

1. **Copy environment defaults**

   ```bash
   cp unison-platform/.env.template unison-platform/.env
   ```

   Update secrets or overrides as needed. Dev defaults avoid any hosted dependencies.

2. **Start services**

   ```bash
   make up
   ```

   This command (defined at the repo root) orchestrates the compose bundle in `unison-platform/compose/compose.yaml`,
   starting the experience renderer, orchestrator, policy, context, storage, skills, and I/O services.

3. **Verify readiness**

   - Run `make health` to aggregate `/ready` probes.
   - Open `http://localhost:3000` for the Devstack dashboard and experience surface.
   - Tail logs with `make logs` or focus on a single service via `make logs SERVICE=orchestrator`.

4. **Shut down / clean up**

   - `make down` stops the stack.
   - `make clean` prunes containers, volumes, and cached images if something becomes corrupted.

---

## 3. Work on a Specific Service

1. **Navigate to the service directory**

   ```bash
   cd unison-orchestrator
   ```

2. **Install dependencies (when needed)**

   ```bash
   uv pip install -r requirements-dev.txt
   ```

   Each service keeps its own `requirements*.txt` or `pyproject.toml`. Use the same Python version listed in
   `constraints.txt`.

3. **Run service-local commands**

   ```bash
   make format
   make test-unit
   make test-int
   ```

4. **Hot reload alongside the platform**

   - Keep the devstack running from the repo root (`make up`).
   - Use `make dev-service` (when available) or `uvicorn src.main:app --reload` per service to iterate quickly.

5. **Sync configuration**

   - Typed settings live in each service’s `settings.py`.
   - When you add or rename env vars, update `.env.template`, `.env.prod.template`, and the service README plus the docs
     listed in `DOCUMENTATION_UPDATE_PLAN.md`.

---

## 4. Everyday Commands Reference

- `make up` — bring up the default compose stack defined in `unison-platform/compose/compose.yaml`.
- `make dev` — start a developer-focused bundle with hot reload and verbose logging enabled.
- `make health` — confirm every service’s `/ready` probe is green (mirrors the Devstack health view).
- `make logs` — tail all logs; pipe through `rg` or `fzf` when hunting for errors.
- `make logs SERVICE=<name>` — follow a single service using the names shown in the Devstack UI.
- `make restart SERVICE=<name>` — recycle one container without taking down the rest of the stack.
- `make test` — run the aggregated unit + integration suites that CI executes by default.
- `make test-contracts` — run schema + envelope validation against `unison-common`.
- `make down` — stop the stack while leaving volumes intact.

Run `make help` from the repo root for a full command list. Service directories often expose their own make targets; check
each README for specifics.

---

## 5. Testing & CI Parity

- **Unit tests:** `make test-unit` inside a service folder. CI runs these through `.github/workflows/tests.yml` for each
  repo.
- **Integration tests:** `make test-int` at the root executes platform-level flows (intent orchestration, consent,
  tracing). Use `pytest -k <pattern>` inside the relevant suite for faster iteration.
- **Contract tests:** `make test-contracts` or `make validate` run the same checks as
  `.github/workflows/contract-testing*.yml`.
- **Docs lint:** `cd unison-docs && npm run lint:docs` mirrors `docs-lint.yml` (markdownlint, remark, misspell).
- **Smoke tests:** `make test-smoke` exercises the Devstack after a fresh boot; the CI equivalent is
  `unison-devstack/.github/workflows/e2e-smoke.yml`.

Match CI as closely as possible before opening a PR to avoid long feedback cycles.

---

## 6. Observability & Troubleshooting

- **Dashboards:** `http://localhost:3000` provides health, logs, and scenario shortcuts. Observability bundles start via
  `make observability`.
- **Tracing:** OTEL collector config lives in `otel-collector-config.yaml`. Use `make up-tracing` (if defined) to start
  Jaeger/Tempo locally.
- **Metrics:** Prometheus + Grafana assets reside in `unison-devstack/config/prometheus.yml` and
  `unison-devstack/grafana/`. Include them when debugging performance regressions.
- **Common fixes:**
  - Ports in use → `make down && make clean`, or free the port manually.
  - Container crash loops → inspect `docker logs <container>` and check environment variables.
  - Dependency drift → re-run `uv pip sync` (per service) or `make bootstrap` if available.
- **Diagnostics:** Capture `make status`, `docker ps`, and relevant log snippets before asking for help in
  `#docs-refresh` or filing an issue.

---

## 7. Next Steps & References

1. **Understand the architecture:** Read [`developer/architecture.md`](./architecture.md) and
   [`developer/platform-overview.md`](./platform-overview.md) for the mental model that matches the service map.
2. **Follow the workflow:** [`developer/development-workflow.md`](./development-workflow.md) dives deeper into lifecycle,
   testing, and deployment practices.
3. **Explore people-facing docs:** Skim [`people/quick-start.md`](../people/quick-start.md) and
   [`people/people-guide.md`](../people/people-guide.md) so the experience you build matches what people see.
4. **Keep docs in sync:** Use `DOCUMENTATION_UPDATE_PLAN.md` and record changes in `DOCUMENTATION_UPDATE_SUMMARY.md` with
   every PR.

By keeping this guide current, anyone joining the project—or revisiting it after a gap—can spin up the platform, develop
confidently, and publish changes directly into the upcoming GitHub Pages site. Thanks for helping keep the loop tight.
