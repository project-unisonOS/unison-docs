# Capability Manifest Specification v0.1 (Normative)

## Overview
The capability manifest is the local source of truth for all executable resources.

Canonical JSON Schema:
- `unison-docs/dev/specs/capability/manifest.v0.1.schema.json`

## Capability Types
- tool
- mcp_server
- skill_pack
- a2a_peer
- agent_workflow

## Required Fields
```json
{
  "id": "string",
  "type": "tool | mcp_server | skill_pack | a2a_peer | agent_workflow",
  "version": "semver",
  "description": "string",
  "origin": {
    "source": "url | local",
    "digest": "sha256",
    "signature": "optional"
  },
  "interfaces": {
    "inputs": "json-schema",
    "outputs": "json-schema"
  },
  "permissions": {
    "network": "deny | allowlist",
    "filesystem": "read | write | none",
    "devices": []
  },
  "runtime": {
    "sandbox": "process | container",
    "resources": {
      "cpu": "limit",
      "memory": "limit"
    }
  },
  "trust_level": "local | verified | community | untrusted"
}
```

## Optional Extensions (v0.1)

These fields are optional, but when present MUST validate against the schema above.

### `execution`
- `execution.channel`: `programmatic | vdi_vpn`
  - `programmatic` is the default for MCP/APIs/A2A.
  - `vdi_vpn` indicates interactive/visual/VPN-mediated execution is required or preferred by the capability.

### `secrets` (references only)
- `secrets[]`: list of secret references that the runtime MUST resolve externally (e.g., Vault).
- The manifest MUST NOT embed secret values.

Example:
```json
{
  "secrets": [
    { "name": "GITHUB_TOKEN", "ref": "vault://kv/unison/github#token" }
  ]
}
```

### `implementation`
Execution metadata needed by the resolver for `capability.run()`:
- `implementation.kind`: `command | python | mcp_tool | a2a_rpc`
- `command`: `argv` list (base command)
- `python`: `callable` string `module:function`
- `mcp`: `registry_url`, `tool_name`, optional `server_id`
- `a2a`: `endpoint` URL for RPC-style delegation

These metadata are execution hints; policy and permissions are still enforced via `permissions.*` and platform policy services.

### `enabled` and `requires_oauth`
- `enabled`: boolean flag for operational enablement (default behavior is treated as enabled when absent).
- `requires_oauth`: boolean flag indicating the capability requires OAuth onboarding before use.

If `requires_oauth=true`, the manifest MUST still store secrets as references only (`secrets[].ref`), never values.

## Operational and Security Notes
- `permissions.network` MUST be enforced at runtime for all outbound calls (registries, MCP, A2A).
- Safe default for resolver egress is deny-by-default, with explicit allowlists.
- Resolver installation MUST be transactional (stage → validate → promote) so partial installs never become runnable.

## Manifest layering (base + local)
- Images may ship a read-only baseline catalog (`manifest.base.json`).
- Runtime writes MUST go to a mutable local catalog (`manifest.local.json`).
- Resolver view is the merged catalog (base + local), with local overriding base entries by `id`.

## Registry Adapters

Resolvers may support discovery from registries through adapters. Minimal supported adapter patterns:

- Static catalog adapter:
  - JSON catalog shipped with the image.
  - Deterministic and suitable for “known-good” entries.

- HTTP catalog adapter:
  - HTTPS-only JSON index from configured URLs.
  - Treated as untrusted by default.
  - All fetches MUST pass through resolver egress/policy gates.

Trust defaults:
- Do not treat community/third-party catalogs as trusted unless policy explicitly marks them verified.

## Normative Rules
- Capabilities MUST be declared here before execution.
- Secrets MUST NOT be stored in the manifest (references only).
- Version pinning is REQUIRED (`version` MUST be an exact semver, not a range).
