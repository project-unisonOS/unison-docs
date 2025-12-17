# Install UnisonOS Alpha as a Linux VM

Target: a local VM using the `v0.5.0-alpha.N` VM disk image artifact (bootable Ubuntu + UnisonOS preinstalled).

## Prereqs

- A hypervisor: QEMU/virt-manager (Linux), VMware, or equivalent
- Disk space for the VM + snapshots + model pack(s)
- 4–8 vCPU and 8–16GB RAM recommended for local inference evaluation

## Download

From the GitHub Release `v0.5.0-alpha.N`:
- `unisonos-linux-vm-v0.5.0-alpha.N.qcow2` (and/or `.vmdk`)
- `SHA256SUMS-v0.5.0-alpha.N.txt` (verify download)

## Install / run (QEMU example)

```bash
qemu-system-x86_64 \
  -m 8192 -smp 4 \
  -drive file=unisonos-linux-vm-v0.5.0-alpha.N.qcow2,format=qcow2 \
  -nic user,model=virtio-net-pci,hostfwd=tcp::8092-:8092,hostfwd=tcp::8087-:8087 \
  -display none -serial mon:stdio
```

Adjust networking as needed; if you use bridged networking, access services via the VM IP.

## Login

- Default user: `unison`
- Default password: `unison` (alpha evaluator default; change immediately for real installs)

## Start / stop

Inside the VM:

```bash
sudo unisonctl status
sudo unisonctl start
sudo unisonctl health
sudo unisonctl logs
```

If `unisonctl` is not present in your build, manage the stack via `systemctl` and/or the shipped `docker compose` bundle (see the release notes for the target).

## Access the renderer

- Bridged networking: `http://<vm-ip>:8092`
- With hostfwd (example above): `http://localhost:8092`

## Config location

- System config: `/etc/unison/` (when installed via native installer)
- Environment: `/etc/unison/platform.env` (or the `.env` file shipped with the bundle)

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
