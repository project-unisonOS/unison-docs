# Deployment & Platform Roadmap

This roadmap turns the UnisonOS distribution plan into executable phases. Status uses checkboxes for quick tracking.

## Phase 0 – Validation & Alignment
- [ ] Confirm local workspace layout (unison-workspace + submodules) and repo cleanliness.
- [ ] Verify current docs and READMEs reflect repo roles and deployment entrypoints.
- [ ] Identify gaps in compatibility matrix, release tags, and GHCR usage.

## Phase 1 – Structure & Documentation
- [ ] Publish repo role mapping (workspace, devstack, platform, docs, services).
- [ ] Add platform distribution scaffolding in `unison-platform` (`images/`, `installer/`, `qa/`) with README stubs.
- [ ] Align READMEs with common sections (role, run, test, docs links) across core repos and representative services.
- [ ] Document branching/versioning strategy (trunk + release/x.y, semver, service tagging).

## Phase 2 – Build & Image Infrastructure
- [ ] Implement `unison-platform/images/` build scripts for WSL rootfs/script, VM images (QCOW2/VMDK), and autoinstall ISO.
- [ ] Add installer scripts in `unison-platform/installer/` (native, docker, WSL) with shared config/env handling.
- [ ] Seed `unison-platform/qa/` with smoke/e2e entrypoints and environment harness.
- [ ] Wire `make` targets (e.g., `image-wsl`, `image-vm`, `image-iso`) to the scaffolding.

## Phase 3 – Release & GHCR Standardization
- [ ] Define GHCR naming/tagging (ghcr.io/project-unisonos/<service>:edge-main, vX.Y.Z) across repos.
- [ ] Introduce semver-driven tagging in unison-platform and propagate service tags per release.
- [ ] Update CI workflows to push GHCR images and attach artifacts on tags (installers + images).
- [ ] Model nightly/beta/stable channels via branches/tags and document the policy.

## Phase 4 – Real-World Testing & Refinement
- [ ] Produce first testable artifacts (WSL script/rootfs, VM images, ISO) with local model preload options.
- [ ] Add install/boot docs and default model validation (Ollama) for first boot.
- [ ] Extend QA and optional telemetry hooks (local, privacy-preserving) plus `unisonctl diag` packaging.
- [ ] Capture pilot feedback, update compatibility matrix, and iterate on installer/image defaults.

## References
- Plan source: organization-wide deployment strategy (UnisonOS distribution, GHCR usage, release channels).
- Canonical docs: `unison-docs/dev/compatibility-matrix.md`, `unison-docs/dev/developer-guide.md`, `unison-docs/dev/hardware-deployment-guide.md`.
