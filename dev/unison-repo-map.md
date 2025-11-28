# Unison Repository Map

Single view of the Unison workspace. Repos live side-by-side in this directory; clone/fork individually from the `project-unisonos` GitHub org. Python services share a common setup: `python3 -m venv .venv && . .venv/bin/activate && pip install -c ../constraints.txt -r requirements.txt` and run tests with `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 OTEL_SDK_DISABLED=true python -m pytest`.

| Repo | Purpose | Status | Language / Framework | Entrypoints / Docs / Tests |
| ---- | ------- | ------ | -------------------- | -------------------------- |
| `unison-orchestrator` | Central intent router and policy-aware coordinator for all modules. | Core (active) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-context` | Profile + KV context store with consent-aware access. | Core (active) | Python / FastAPI | `src/context_service.py`; README; tests via `python -m pytest`. |
| `unison-storage` | Encrypted working/long-term storage and vault. | Core (active) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-policy` | Safety/consent policy engine and audit log. | Core (active) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-auth` | Authentication + RBAC + token issuance for services. | Core (active) | Python / FastAPI | `src/auth_service.py`; README; tests via `python -m pytest`. |
| `unison-consent` | Dedicated consent grant issuance/introspection service. | Core (active) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-inference` | LLM/inference gateway supporting OpenAI/Ollama/Azure. | Core (active) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-intent-graph` | New intent graph front-end for orchestrator routing. | Core (active, early) | Python / FastAPI | `src/main.py`; README; tests via `python -m pytest`. |
| `unison-context-graph` | Graph-based context fusion and preference modeling. | Core (active, early) | Python / FastAPI | `src/main.py`; README; tests via `python -m pytest`. |
| `unison-experience-renderer` | Experience/UI generator that mediates capabilities and wake-word UX. | Core (active) | Python / FastAPI + small JS wakeword helper | `src/main.py`; README; tests via `python -m pytest`. |
| `unison-agent-vdi` | Thin VDI/desktop agent that fronts renderer + intent graph. | Optional (active) | Python / FastAPI | `src/main.py`; README; tests via `python -m pytest`. |
| `unison-io-core` | On-device multimodal runtime stub forwarding envelopes. | Optional (dev-mode) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-io-speech` | Speech I/O stub (STT/TTS) emitting envelopes. | Optional (dev-mode) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-io-vision` | Vision I/O stub emitting envelopes. | Optional (dev-mode) | Python / FastAPI | `src/server.py`; README; tests via `python -m pytest`. |
| `unison-shell` | Electron developer shell for quick onboarding + echo flows. | Optional (dev-mode) | Node / Electron | `npm start`; smoke test `npm test`. |
| `unison-devstack` | Docker Compose stack + helper scripts for local e2e. | Core DX | Docker Compose + Python helper scripts | `docker-compose.yml`; README/SETUP; smoke test `python scripts/e2e_smoke.py`. |
| `unison-platform` | Narrative/platform-level docs + installer entrypoints. | Core docs | Markdown | README; keep architecture notes co-located with code. |
| `unison-docs` | Canonical cross-cutting docs and specs (schemas live in `dev/specs/`). | Core docs | Markdown/JSON | `dev/` for developer docs, `dev/specs/` for schemas. |
| `unison-common` | Shared Python library (auth/tracing/http/idempotency). | Core library | Python | README; tests via `python -m pytest`. |
| `unison-os` | Base container image definitions for services. | Supporting infra | Docker | README; build via Dockerfile. |

See `developer-guide.md` for the end-to-end workflow and `../../docs/dx-hygiene-plan.md` for open DX issues and follow-ups.
For interaction flows between services, see `unison-architecture-overview.md` and `unison-architecture-deep-dive.md`.

## How the Pieces Interact (high level)

- **Intent path**: UI (experience-renderer) and agents (shell, agent-vdi, io-core/speech/vision) send intents → `unison-intent-graph` → `unison-orchestrator` for routing.
- **Context loop**: Orchestrator queries `unison-context-graph` for fused context; context-graph pulls/stores state via `unison-context` (profile/KV) and `unison-storage` (vault/long-term memory).
- **Policy/safety**: Orchestrator calls `unison-policy` (and `unison-consent`) to enforce rules/consent before executing actions.
- **Identity/auth**: Services validate JWTs via `unison-auth`; consent grants come from `unison-consent`.
- **Inference**: Orchestrator (or intent-graph) calls `unison-inference` for LLM/model requests; inference may use local Ollama or cloud providers.
- **I/O layer**: `unison-io-speech`, `unison-io-vision`, `unison-io-core` generate EventEnvelopes to the orchestrator; `unison-experience-renderer` returns responses to users via shell/VDI.
- **Devstack wiring**: `unison-devstack` Docker Compose connects all services with Redis/Postgres and optional tools; `unison-os` provides the base image used by service Dockerfiles.
- **Contracts/docs**: `unison-docs/dev/specs/` provides schemas consumed by services and `unison-common`; `unison-platform` holds platform notes. `unison-common` is imported by Python services for shared middleware.
