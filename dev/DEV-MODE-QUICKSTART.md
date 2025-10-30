# Developer Mode Quickstart

This guide helps you run Unison in Developer Mode: the devstack services, the io-core stub, and the full-screen Shell. It also shows the E2E smoke script.

---

## Prerequisites

- Docker Desktop
- Node.js 20+ (for Shell)
- Python 3.12+ (for E2E script)

---

## Start the devstack

From `unison-devstack`:

```powershell
# Build and start services (orchestrator, context, storage, policy, io-core)
docker compose up -d --build

# Check status
docker compose ps
```

Health checks:

```powershell
Invoke-RestMethod http://localhost:8080/health   # orchestrator
Invoke-RestMethod http://localhost:8081/health   # context
Invoke-RestMethod http://localhost:8083/health   # policy
Invoke-RestMethod http://localhost:8085/health   # io-core
```

---

## Run the Shell (host)

From `unison-shell`:

```powershell
npm install
npm start
```

- Echo panel sends an `echo` EventEnvelope to the orchestrator.
- Onboarding save posts Tier B keys to context via `POST /kv/put`.

---

## E2E smoke script

From `unison-devstack`:

```powershell
python scripts/e2e_smoke.py
```

The script will:

- Save onboarding keys via `POST /kv/put` (Tier B)
- Export Tier B bundle via `POST /profile.export`
- Send an `echo` via io-core → orchestrator
- Exercise a Policy `require_confirmation` path and confirm

---

## Troubleshooting

- Rebuild a single service:
```powershell
docker compose build orchestrator
docker compose up -d orchestrator
```

- Tail logs:
```powershell
docker compose logs -f orchestrator
```

- PowerShell curl vs curl.exe:
  - Use `Invoke-RestMethod`/`Invoke-WebRequest` or call `curl.exe` explicitly.
