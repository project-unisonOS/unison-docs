# Unison Developer Guide

Opinionated path from clone to a running local stack (devstack + renderer) plus testing notes. This assumes Ubuntu 22.04/24.04 on WSL2 with Docker Desktop.

## Prerequisites

- Ubuntu on WSL2 (or native Linux) with at least 4 CPUs / 8 GB RAM (increase to 6–8 CPUs + 12–16 GB RAM for smooth Docker builds).
- Docker Desktop with WSL2 backend and Compose v2 enabled.
- Python 3.12, Node.js 18+, and `make`/`git`.
- Recommended: `direnv` or a `.env` file to manage secrets locally.

## Clone / Workspace Layout

Clone the repos side-by-side under a common parent:

```bash
mkdir -p ~/src/unison && cd ~/src/unison
for repo in \
  unison-devstack unison-orchestrator unison-context unison-storage unison-policy \
  unison-auth unison-consent unison-inference unison-intent-graph unison-context-graph \
  unison-experience-renderer unison-agent-vdi \
  unison-io-core unison-io-speech unison-io-vision \
  unison-common unison-platform unison-shell unison-os unison-docs unison-payments; do
  git clone git@github.com:project-unisonos/$repo.git
done
```

Keep `constraints.txt` from this workspace at the root so Python services can pin dependencies consistently. `unison-docs`
provides the canonical cross-cutting docs and specs that services reference.

## Python Services – Common Setup

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -c ../constraints.txt -r requirements.txt
cp .env.example .env  # most services now ship a sample env file
```

Environment variables: copy any `.env.example` files when present; otherwise set the values listed in each service README (e.g., `UNISON_JWT_SECRET`, Redis/Postgres endpoints).

## Start the Devstack (recommended)

```bash
cd unison-devstack
cp .env.security .env   # baseline dev env; adjust secrets as needed
docker compose up -d --build
# Optional tools profile for local models and skill registration:
# docker compose --profile tools up -d ollama skill-register
```

Services come up on:

- Orchestrator `http://localhost:8090`
- Context `http://localhost:8081`
- Storage `http://localhost:8082`
- Policy `http://localhost:8083`
- Auth `http://localhost:8088`
- Inference `http://localhost:8087`
- Experience Renderer `http://localhost:8092`
- Intent Graph `http://localhost:8080` (devstack mapping)
- Context Graph `http://localhost:8091`
- Agent VDI `http://localhost:8093`
- Jaeger UI `http://localhost:16686`

Stop with `docker compose down` (add `-v` to clear volumes).

## Running Services Directly (without compose)

For targeted debugging you can run a single service after installing deps:

```bash
cd unison-orchestrator
UNISON_JWT_SECRET=dev-secret python src/server.py
```

Adjust env vars per README (e.g., context/storage hosts).

Renderer:

```bash
cd unison-experience-renderer
python src/main.py
```

Shell (Electron):

```bash
cd unison-shell
npm install
npm start
```

## Testing

- Python services: `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 OTEL_SDK_DISABLED=true python -m pytest`
- Devstack smoke (requires compose running): `python scripts/e2e_smoke.py`
- Docs lint: `npx --yes markdownlint-cli2` (uses workspace config at `.markdownlint-cli2.jsonc`)

## Running Unison via Docker

- Primary path is `docker compose up -d --build` in `unison-devstack`.
- To rebuild a single service: `docker compose build orchestrator` then `docker compose up orchestrator`.
- To include optional tools (Ollama, skill registration): `docker compose --profile tools up -d`.
- Health checks are baked into compose; use `docker compose ps` to confirm.
- Renderer is exposed at `http://localhost:8092`; Jaeger at `http://localhost:16686`.
- Secrets come from `.env` (copy from `.env.security`) and per-service environment variables in the compose file.

## Troubleshooting

- WSL2: increase memory/CPU in `.wslconfig` if builds are slow; ensure Docker Desktop is running.
- Port collisions: adjust published ports in `unison-devstack/docker-compose.yml`.
- Missing Python deps: re-run the shared install command with the workspace `constraints.txt`.
- Renderer wakeword tests may need `DISABLE_AUTH_FOR_TESTS=true` to bypass Baton middleware.

## Where to Go Next

- Repository map: `unison-repo-map.md`
- Architecture overview: `unison-architecture-overview.md` and `unison-architecture-deep-dive.md`
- Hardware guide: `hardware-deployment-guide.md`
- DX hygiene plan (tracking): workspace `docs/dx-hygiene-plan.md`
