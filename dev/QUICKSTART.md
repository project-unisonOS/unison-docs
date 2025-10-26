# Unison Devstack Quickstart

This guide gets you running the local devstack and exercising the core API in a few minutes.

## Prerequisites

- Docker Desktop (Windows/macOS) or Docker Engine (Linux)
- Python 3.10+
- PowerShell (Windows) or a shell on macOS/Linux

## Clone and open

Place all repos in a common folder (example shown uses `C:\git\unison`). This repo is already laid out as a monorepo for local devstack.

## Set up local Python environment

```powershell
# From repo root
py -m venv .venv
.\.venv\Scripts\python -m pip install -U pip
.\.venv\Scripts\python -m pip install -e .\unison-common
.\.venv\Scripts\python -m pip install -r .\unison-orchestrator\requirements.txt -r .\unison-context\requirements.txt -r .\unison-storage\requirements.txt -r .\unison-policy\requirements.txt
```

## Start the devstack

```powershell
# Using helper script
.\scripts\devstack-up.ps1

# Or directly
# docker compose -f "C:\git\unison\unison-devstack\docker-compose.yml" up --build -d
```

Verify containers:

```powershell
docker compose -f "C:\git\unison\unison-devstack\docker-compose.yml" ps
```

## Health and readiness checks

```powershell
Invoke-RestMethod -Uri http://localhost:8080/health
Invoke-RestMethod -Uri http://localhost:8080/ready | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri http://localhost:8081/health
Invoke-RestMethod -Uri http://localhost:8082/health
Invoke-RestMethod -Uri http://localhost:8083/health
```

## Send a test EventEnvelope

```powershell
$json = [pscustomobject]@{
  timestamp = "2025-10-25T19:22:04Z"
  source = "io-speech"
  intent = "summarize.document"
  payload = @{ document_ref = "active_window"; summary_length = "short" }
  auth_scope = "person.local.explicit"
  safety_context = @{ data_classification = "internal"; allows_cloud = $false }
} | ConvertTo-Json -Depth 6

Invoke-RestMethod -Uri http://localhost:8080/event -Method Post -Body $json -ContentType 'application/json' | ConvertTo-Json -Depth 6
```

The response includes `event_id`. Logs across services use the `X-Event-ID` header to correlate entries.

## View logs

```powershell
# All services
.\scripts\devstack-logs.ps1

# Single service
.\scripts\devstack-logs.ps1 -Service orchestrator
```

## Run tests

```powershell
.\scripts\test-all.ps1
```

Unit tests live under each service's `tests/` folder. Integration tests live under `unison-devstack/tests/integration/`.

## Tear down

```powershell
.\scripts\devstack-down.ps1
```

## Notes

- API reference: `unison-docs/dev/api/orchestrator.md`
- EventEnvelope spec: `unison-docs/dev/specs/EVENT-ENVELOPE.md`
- Architecture: `unison-docs/architecture.md`
