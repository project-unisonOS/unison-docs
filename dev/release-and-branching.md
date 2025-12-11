# Release, Branching, and Tagging

This describes how UnisonOS repos align around a trunk-based workflow, semver, and GHCR publishing.

## Branching Model
- `main`: always green integration branch; nightly channel builds from here.
- `release/x.y`: cut from `main` to stabilize a minor release (beta channel). Only critical fixes merge here.
- `hotfix/x.y.z` (optional): short-lived branches for urgent stable fixes.
- Feature branches: `feature/<short-desc>` → PR → `main`.

## Versioning (Platform-Centric Semver)
- Platform version defined in `unison-platform` drives releases: `vX.Y.Z`.
- Service repos tag the same version when included in a platform release (e.g., `unison-orchestrator` `v0.4.0`).
- Service-side patches within a release cycle should bump the platform patch (preferred) or document service-specific patch in the compatibility matrix.

## Tags and Releases
- Tags: `vX.Y.Z` on `unison-platform` and participating services.
- GitHub Releases (in `unison-platform`):
  - Release notes,
  - Compose bundles,
  - Installer scripts (installer/),
  - Images (WSL/VM/ISO) from `images/`,
  - Checksums and signatures (where available).
- Channels:
  - Nightly: `main` → GHCR tags `edge-main-YYYYMMDD`.
  - Beta: `release/x.y` → `vX.Y.0-beta.N`.
  - Stable: `vX.Y.Z` tags.

## GHCR Naming
- `ghcr.io/project-unisonos/<repo-name>:<tag>`, e.g.:
  - `ghcr.io/project-unisonos/unison-orchestrator:v0.4.0`
  - `ghcr.io/project-unisonos/unison-platform:v0.4.0`
  - `ghcr.io/project-unisonos/unison-common-wheel:v0.4.0`
- On push to `main`: push `:edge-main` (or date-stamped) images.
- On tag `vX.Y.Z`: push `:vX.Y.Z` and, for platform, `:latest`.

## Contributor Workflow
- External contributions:
  - Fork, branch from `main`, submit PR to `main`.
  - Include tests; for core services run pytest; for platform/devstack run smoke/integration where applicable.
  - Label PRs with area (service/platform/docs) and impact (breaking/minor/docs).
- Cross-repo changes:
  1. File a coordination issue (e.g., in `unison-platform`).
  2. Update `unison-devstack` compose to pin new image tags.
  3. Merge service PRs → build/push images → update devstack/platform refs.
  4. Run E2E/smoke before merging platform or workspace changes.

## Compatibility Matrix
- Canonical source: `unison-docs/dev/compatibility-matrix.md`; rendered at `/reference/compatibility/`.
- Each platform release adds a row with the service tags that are guaranteed to interoperate.
