# UnisonOS Alpha Evaluation

This page is the fastest path to evaluating UnisonOS `v0.5.0-alpha.N` as a developer.

## What “Alpha” means

- Expect rough edges: defaults and packaging may change between alpha drops.
- We prioritize “installable + boots + end-to-end interaction works” over completeness.
- File issues aggressively; alpha is for learning quickly.

## Which artifact should you choose?

- **WSL2**: fastest start for Windows developers (recommended if you already use Docker Desktop + WSL2).
- **Linux VM**: isolated environment; good for demos and evaluation without touching host OS.
- **Bare metal ISO**: closest to “real device”; use if you’re testing hardware/driver/network assumptions.

## Downloads

All artifacts live on the GitHub Release for `v0.5.0-alpha.N`:
`https://github.com/project-unisonOS/unison-platform/releases/tag/v0.5.0-alpha.N`

Required assets:
- `unisonos-wsl2-v0.5.0-alpha.N.zip` (or `.tar.gz`)
- `unisonos-linux-vm-v0.5.0-alpha.N.qcow2` (and/or `.vmdk`)
- `unisonos-baremetal-v0.5.0-alpha.N.iso`
- `unisonos-manifest-v0.5.0-alpha.N.json`
- `SHA256SUMS-v0.5.0-alpha.N.txt`

## 10-minute “first interaction” walkthrough

1. Install one target (pick one):
   - WSL2: `dev/deployment/install-wsl2.md`
   - Linux VM: `dev/deployment/install-linux-vm.md`
   - Bare metal: `dev/deployment/install-bare-metal.md`
2. Confirm the system reaches “ready”:
   - `sudo unisonctl status` (or `docker compose ps` for WSL2 bundles)
   - `sudo unisonctl health` (or curl the `/health` endpoints)
3. Open the renderer:
   - `http://localhost:8092` (WSL2 / dev machines) or `http://<host-or-vm-ip>:8092`
4. Run the smoke test (one command; included with the artifact):
   - `unisonctl smoke` (or the documented `make qa-smoke` / `python -m pytest qa` equivalent)
5. Confirm inference works end-to-end:
   - Default interaction model is **Qwen** via the default model pack.
   - If models are missing, follow the prompt to fetch/import the selected model pack.

## Troubleshooting

- **Ports in use**: stop other stacks; verify `8092` (renderer) and `8087` (inference) are free.
- **Not “ready”**: check logs: `sudo unisonctl logs` (or `docker compose logs -n 200`).
- **Model missing**: install/fetch the default model pack, then restart inference.
- **Where are logs?**: `sudo unisonctl logs` and system journal; containers: `docker compose logs`.

## How to file issues

- Install/image/release packaging issues: `https://github.com/project-unisonOS/unison-platform/issues`
- Devstack/test harness issues: `https://github.com/project-unisonOS/unison-devstack/issues`
- Renderer UX issues: `https://github.com/project-unisonOS/unison-experience-renderer/issues`

Include:
- Release tag (`v0.5.0-alpha.N`) + target (WSL2/VM/bare-metal)
- Host specs (CPU/RAM/disk) and OS details
- `unisonos-manifest-*.json` + relevant logs
