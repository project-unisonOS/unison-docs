# UnisonOS Repository Roles

Use this guide to choose the right repository for your task and to understand how the repos fit together.

## Top-Level Entry Points
- **unison-workspace** – Meta “front door” for developers. Holds git submodules for core services, `unison-devstack`, `unison-docs`, renderer/VDI, and optional services. Start here to clone and bootstrap everything at once.
- **unison-devstack** – Canonical Docker Compose for development and local integration tests. Provides smoke and multimodal tests; used by workspace scripts.
- **unison-platform** – Productized platform distribution. Hosts deployment wiring (Compose for prod), native/installer scripts, and image builders (WSL, VM, ISO). Release tags and compatibility matrices anchor here.
- **unison-os** – Base Ubuntu LTS container image used by service Dockerfiles (non-root, minimal packages).
- **unison-docs** – Canonical architecture, specs, compatibility matrix, developer and hardware guides.
- **project-unisonos.github.io** – MkDocs site for unisonos.ai; built from `docs/` content plus overrides.

## Service Repos (examples)
- **Control plane**: `unison-orchestrator`, `unison-intent-graph`, `unison-context`, `unison-context-graph`, `unison-policy`, `unison-auth`, `unison-consent`.
- **Inference**: `unison-inference`.
- **Experience & shell**: `unison-experience-renderer`, `unison-agent-vdi`, `unison-shell`.
- **I/O services**: `unison-io-core`, `unison-io-speech`, `unison-io-vision`, plus modality adapters (BCI, Braille, Sign).
- **Comms/actuation**: `unison-comms`, `unison-actuation`.
- **Shared**: `unison-common`.

## Start Here Based on Your Goal
- **“I want to test Unison locally.”** Clone `unison-workspace`, initialize submodules, and run `unison-devstack` via workspace scripts (`./scripts/up.sh`, `./scripts/smoke.sh`). Docs: `unison-docs/dev/developer-guide.md`.
- **“I want to tweak the experience renderer or UI.”** Work in `unison-experience-renderer` (or `unison-shell`/`unison-agent-vdi`), then validate through `unison-devstack`.
- **“I want to modify inference logic/models.”** Work in `unison-inference` (provider logic, model selection), then run through `unison-devstack`; update platform manifests when tagging releases.
- **“I want to work on deployment/images/installers.”** Use `unison-platform`:
  - `installer/` for curl|bash/native/WSL installers,
  - `images/` for WSL/VM/ISO builders,
  - `qa/` for end-to-end/hardware smoke tests.

## Docs and Cross-Links
- Compatibility matrix: `unison-docs/dev/compatibility-matrix.md`.
- Architecture overview: `unison-docs/dev/unison-architecture-overview.md`.
- Repo map: `unison-docs/dev/unison-repo-map.md`.
- Hardware deployment guidance: `unison-docs/dev/hardware-deployment-guide.md`.

## Branching, Releases, and Images (summary)
- Trunk on `main`; release branches `release/x.y`; semver tags `vX.Y.Z` anchored in `unison-platform`.
- Service repos align tags with platform releases and publish GHCR images (`ghcr.io/project-unisonos/<service>:<tag>`).
- Installers and images (WSL/VM/ISO) are built and released from `unison-platform`.
