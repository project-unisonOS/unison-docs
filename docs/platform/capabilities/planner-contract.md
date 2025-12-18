# Planner ↔ Capability Resolver Contract (Normative)

## Responsibility Split
- Interaction Model:
  - Produces structured intent
  - Never installs or executes capabilities

- Planner Model:
  - MUST query Capability Resolver before proposing execution steps
  - MUST resolve capabilities before any execution
  - MAY request discovery and installation per policy

## Required Resolver Calls
- `capability.search(intent, constraints)`
- `capability.resolve(step)`
- `capability.install(candidate)`
- `capability.run(capability_id, args)`
- `capability.list()`, `capability.get()`, `capability.remove()`

## Transport and Authentication (normative)
- The planner calls the resolver over an authenticated channel.
- Preferred deployment: resolver binds to loopback and is fronted by an Envoy sidecar enforcing SPIFFE mTLS + optional `ext_authz` (see `unison-security`).
- Minimum requirement: resolver MUST reject unauthenticated `install` and `run` requests.
- Resolver MUST apply authorization gates so `install/remove` are more privileged than `run`.

## Multi-Agent Orchestration (normative)
- Planner selects and resolves capabilities for all workers/validators.
- Delegation to A2A peers MUST be mediated by the resolver (capability type `a2a_peer`), not direct ad-hoc calls.

## Execution Channels
- Programmatic Egress (default):
  - MCP servers, APIs, registries, A2A RPC
- VDI/VPN (conditional):
  - Interactive web flows, SSO, visual verification

Planner MUST select channel based on capability declaration (`execution.channel`) and policy.

## Compliance
Any execution path bypassing this contract is non-compliant.
