# Install UnisonOS Alpha on Bare Metal

Target: dedicated hardware using the `v0.5.0-alpha.N` **bootable installer ISO** (full Ubuntu installer with embedded autoinstall).

## Prereqs

- A target machine you can boot from USB
- 8GB+ USB drive
- A flashing tool (Rufus/balenaEtcher) or `dd`
- 4–8 cores and 8–16GB RAM recommended for local inference evaluation
- Wired networking recommended for first boot (especially if model packs are fetched)

## Download

From the GitHub Release `v0.5.0-alpha.N`:
- `unisonos-baremetal-v0.5.0-alpha.N.iso.part00` (and subsequent `part*`)
- `unisonos-baremetal-v0.5.0-alpha.N.iso.REASSEMBLE.txt`
- `SHA256SUMS-v0.5.0-alpha.N.txt` (verify download)

## Install

1. Reassemble the ISO:
   - `cat unisonos-baremetal-v0.5.0-alpha.N.iso.part* > unisonos-baremetal-v0.5.0-alpha.N.iso`
2. Flash the ISO to USB.
2. Boot the target machine from USB.
3. Autoinstall runs unattended; wait for install + reboot.
4. After reboot, UnisonOS stack should auto-start (may take a few minutes on first boot).

## Login

- Default user: `unison`
- Default password: `unison` (alpha evaluator default; change immediately for real installs)

## Start / stop

On the installed system:

```bash
sudo unisonctl status
sudo unisonctl start
sudo unisonctl health
sudo unisonctl logs
```

## Access the renderer

- Renderer UI: `http://<device-ip>:8092`

## Config location

- System config: `/etc/unison/`
- Environment: `/etc/unison/platform.env`

## Model packs

- Default interaction model is **Qwen** (via the default alpha model pack).
- Alpha model packs may include separate **planner** and **ASR/TTS** models; if missing, the system must prompt with recovery steps (fetch/import).
- Details: `dev/deployment/model-packs.md`.

## Smoke test

Use the one-command smoke test shipped with the release; otherwise:

```bash
sudo unisonctl health
curl -f http://localhost:8092/readyz
curl -f http://localhost:8087/health
```

## Diagnostics

```bash
sudo unisonctl status
sudo unisonctl logs
sudo journalctl -u unison-platform --no-pager | tail -n 200
```
