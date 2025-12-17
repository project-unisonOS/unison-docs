# UnisonOS Alpha 0.5.0 Release Contract

This document defines the contract for publishing UnisonOS `0.5.0` alpha release packages (starting at `v0.5.0-alpha.1`).

## 2.1 Channels and versioning

- Source branch (alpha): `main`
- Tag format (alpha): `v0.5.0-alpha.N` (N starts at `1` and increments)

Brief channel definitions:
- **Alpha**: evaluator/dev preview; installer/boot flows must work, but features and defaults may change quickly; known issues expected.
- **Beta**: feature-complete for the release line; upgrade/rollback path exists; reliability and performance hardening; fewer known issues.
- **Stable**: production-intent; documented support matrix; release process and artifacts are repeatable and signed/verified.

## 2.2 Alpha acceptance checklist (MVP)

Each `v0.5.0-alpha.N` release MUST satisfy:

- [ ] **Install success** on all targets: WSL2, Linux VM, bare-metal ISO installer.
- [ ] **Boot/Start to “ready” automatically** (no manual service poking required after install).
- [ ] **Inference path works end-to-end**:
  - [ ] Default provider is local/offline-capable (`ollama` today).
  - [ ] Default *interaction* model is **Qwen** (exact model pinned by the default model pack).
  - [ ] Model pack accounts for **planner** and **ASR/TTS** models (present or retrievable via the model pack mechanism).
- [ ] **Renderer reachable and usable** (documented URL/port per target; basic interaction works).
- [ ] **One-command smoke test passes** (documented and shipped as part of the artifact).
- [ ] **Model-missing behavior is friendly**: clear recovery message + either automatic pull (if allowed) or explicit offline import instructions.

## 2.3 Release artifact set (GitHub Release assets)

Each alpha GitHub Release MUST include:

- WSL2 package: `unisonos-wsl2-v0.5.0-alpha.N.zip` (or `.tar.gz`)
- Linux VM image: `unisonos-linux-vm-v0.5.0-alpha.N.qcow2` (and/or `.vmdk` if produced)
- Bare-metal ISO: `unisonos-baremetal-v0.5.0-alpha.N.iso.part00` (and subsequent `part*`, plus `...REASSEMBLE.txt`)
- Bill of materials: `unisonos-manifest-v0.5.0-alpha.N.json`
- Checksums: `SHA256SUMS-v0.5.0-alpha.N.txt`
- (Optional but recommended) Signature file(s) for the checksum file (e.g., `*.sig`)

## 2.4 Documentation set required in the release

Each alpha MUST ship docs that make evaluation straightforward:

- [ ] Per-target quickstarts: WSL2, Linux VM, bare metal.
- [ ] “What’s included” overview, including **model pack** defaults and how to switch packs.
- [ ] “Known issues” section for the release.
