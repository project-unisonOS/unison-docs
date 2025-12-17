# Install UnisonOS Alpha on WSL2

Target: Windows + WSL2 using the `v0.5.0-alpha.N` WSL2 release artifact.

## Prereqs

- Windows 11 (recommended) or Windows 10 19044+
- WSL2 enabled
- Docker Desktop (recommended) with WSL integration enabled
- Disk space for a Linux distro + Docker images + model pack(s)

## Download

From the GitHub Release `v0.5.0-alpha.N`:
- `unisonos-wsl2-v0.5.0-alpha.N.zip` (or `.tar.gz`)
- `SHA256SUMS-v0.5.0-alpha.N.txt` (verify download)

## Install

```powershell
# One-time: enable WSL
wsl --install

# Import the UnisonOS distro (adjust paths)
wsl --import UnisonOS `
  C:\\wsl\\unisonos `
  .\\unisonos-wsl2-v0.5.0-alpha.N.tar.gz `
  --version 2

# Launch
wsl -d UnisonOS
```

## Start / stop

Inside WSL:

```bash
# Start platform stack
docker compose -f /opt/unisonos/bundle/docker-compose.prod.yml up -d --wait

# Stop platform stack
docker compose -f /opt/unisonos/bundle/docker-compose.prod.yml down
```

From Windows (optional):

```powershell
wsl --terminate UnisonOS
```

## Access the renderer

- Renderer UI: `http://localhost:8092`

## Config location

- Bundle: `/opt/unisonos/bundle/`
- Environment: `/opt/unisonos/bundle/.env` (copied from `.env.example`)

## Model packs

- Default interaction model is **Qwen** (via the default alpha model pack).
- If the UI/inference reports missing models, follow `dev/deployment/model-packs.md`.

## Smoke test

Use the one-command smoke test shipped in the artifact (preferred). If unavailable, run:

```bash
curl -f http://localhost:8092/readyz
curl -f http://localhost:8087/health
```

## Diagnostics

```bash
docker compose -f /opt/unisonos/bundle/docker-compose.prod.yml ps
docker compose -f /opt/unisonos/bundle/docker-compose.prod.yml logs --tail=200
```
