# Seeded Capabilities (base + local)

UnisonOS images may ship with a curated baseline of capabilities that are safe by default:
- local-only tools enabled by default
- network connectors present but disabled by default (OAuth required)
- skill packs (SKILL.md-style) to guide planners for common workflows

This page defines the **layered manifest model** and how enablement and onboarding works.

## Layered manifest model (normative)

The resolver maintains two catalogs:

1) `manifest.base.json` (read-only, shipped in the image)
- Curated baseline for common intents.
- Never modified at runtime.

2) `manifest.local.json` (mutable, persisted on disk)
- Local installs, overrides, and enablement state.
- All runtime writes go here.

Resolver view = merge(base + local), where:
- local entries override base entries of the same `id`
- the planner always interacts with the merged view via resolver APIs

## Enablement and connectors

Connectors are shipped **disabled by default**:
- `enabled: false`
- `requires_oauth: true`
- `secrets` holds references only (no values), e.g. `secret://...`

To enable a connector:
1. An operator/admin (or an authorized planner surface) starts OAuth onboarding with the resolver.
2. Resolver stores refresh tokens in an external secrets backend.
3. Resolver updates `manifest.local.json` to set `enabled: true` and bind secret references.

## Secrets (normative)
- Manifests MUST NOT store secret values.
- Manifests MAY store references (handles) such as `vault://...` or `secret://...`.
- Audit logs MUST redact tokens and secret material.

## Capability packs

“Capability packs” are curated sets of related entries shipped together:
- host diagnostics and bounded inspection
- filesystem operations with scoped allowlists
- connectors (email/calendar/etc.) in disabled state
- skill packs that orchestrate the above in a planner-compatible way

The exact shipped set is deployment-specific and may differ by product tier.

## Registry discovery (overview)

The resolver may also discover capabilities from registries via adapters:
- static catalog adapter (curated JSON shipped with the image)
- HTTP catalog adapter (HTTPS JSON index, deny-by-default egress, untrusted by default)

Installed entries from registries are written to `manifest.local.json`.

