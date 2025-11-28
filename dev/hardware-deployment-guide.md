# Hardware Deployment Guide

Reference steps for bringing Unison up on physical devices or edge hardware.

## Minimum Recommendations

- CPU: 4 cores (8 preferred) with AVX support.
- RAM: 8 GB minimum (12–16 GB preferred for local inference).
- Storage: 40 GB free SSD.
- Network: Stable broadband; wired preferred for render/agent workloads.
- OS: Ubuntu 22.04 LTS or 24.04 LTS (server or desktop). Enable OpenSSH for remote access.

## Prepare the Device

```bash
sudo apt update
sudo apt install -y curl git build-essential python3 python3-venv docker.io docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # re-login after
```

Optional: install `nvidia-container-toolkit` if GPU inference is required.

## Fetch Repos

Clone the same set listed in `developer-guide.md` (keep side-by-side under `~/unison`). At minimum for a full stack: `unison-devstack`, `unison-orchestrator`, `unison-context`, `unison-storage`, `unison-policy`, `unison-auth`, `unison-consent`, `unison-inference`, `unison-intent-graph`, `unison-context-graph`, `unison-experience-renderer`, `unison-agent-vdi`.

## Configure

- Copy `unison-devstack/.env.security` to `.env` and update secrets for production (JWT secrets, consent secrets, Postgres passwords).
- Set resource flags in Docker (cgroups) to match available CPU/RAM.
- For air-gapped or offline installs, pre-load images built from the workspace using `docker save` / `docker load`.

## Run

```bash
cd ~/unison/unison-devstack
docker compose up -d --build
```

Access points:

- Renderer UI: `http://<device-ip>:8092`
- Orchestrator API: `http://<device-ip>:8090`
- Jaeger: `http://<device-ip>:16686`

## On-Device Upgrades

- Pull latest code in each repo, rebuild images, and `docker compose up -d --build`.
- For blue/green on a fleet, tag images (`ghcr.io/project-unisonos/<service>:<tag>`) and roll out via your orchestrator; keep data volumes to preserve state.

## Secrets and Configuration

- Prefer `.env` + Docker secrets or bind-mounted files for keys.
- Rotate `UNISON_JWT_SECRET`, consent secrets, and database credentials regularly.
- If running the Electron shell locally, avoid storing secrets in user profiles; drive everything via services.

## Monitoring and Health

- Compose healthchecks expose readiness; use `docker compose ps` or a supervisor to restart failed services.
- Export OTEL traces to Jaeger (already configured in devstack) or your collector; adjust `OTEL_EXPORTER_OTLP_ENDPOINT`.

## TODO

- Add automated provisioning scripts for common boards (e.g., Jetson, NUC).
- Publish validated sizing for GPU/CPU inference models per provider.
- Document OTA pattern for remote agents (shell/agent-vdi) once chosen.
