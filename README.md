# Unison Docs

Canonical workspace documentation. This repo now hosts:

- Workspace-wide guides and DX notes.
- Policies and contributor info (CoC, contributing, maintainers, security, setup).
- Protocol specs and schemas (see `specs/`).

## Quick pointers
- Specs & schemas: `specs/` (e.g., `unified-messaging-protocol.md`, `event-envelope.schema.json`, `schemas/`).
- Architecture & safety: `architecture.md`, `safety.md`, `accessibility.md`, `compatibility-matrix.md`.
- Contributor/Policy docs: `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `MAINTAINERS.md`, `SECURITY.md`, `SETUP.md`.
- Constraints: `constraints.txt` for consistent installs.

## Layout
- Root: workspace-level guides, policies, and primary specs.
- `specs/`: protocol spec docs and schemas (only `schemas/` subfolder plus spec files).

Per-service details remain in their respective repos; use this repo for cross-cutting docs and specs.
