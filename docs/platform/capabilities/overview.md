# UnisonOS Capability System Overview (AAIF-aligned)

## Purpose
Define a unified, extensible capability system for UnisonOS that enables intent-driven discovery, installation, and execution of tools, MCP servers, skill packs, and agent-to-agent (A2A) peers.

This system is normative for all execution pathways in UnisonOS.

## Non-Goals
- Replacing MCP or competing with AAIF standards
- Allowing models to bypass policy, manifests, or planners
- Encoding secrets directly in manifests

## Core Concepts
- **Capability**: Any executable or callable resource that fulfills an intent.
- **Tool**: Local function or service.
- **MCP Server**: Tool surface exposed via Model Context Protocol.
- **Skill Pack**: Procedural bundle (SKILL.md-style) that orchestrates tools/MCP.
- **A2A Peer**: External agent capable of delegated work.
- **Agent Workflow**: A composed, multi-agent execution plan.

## AAIF Directional Alignment
UnisonOS aligns with the Linux Foundation Agentic AI Foundation (AAIF):
- MCP is the primary tool-transport protocol
- AGENTS.md is a first-class developer guidance artifact
- Capability packaging remains portable and vendor-neutral

UnisonOS may extend these concepts but must not diverge incompatibly.

## Authority Model (normative)
- **Interaction Model**: Converts conversation to structured intent only.
- **Planner Model**: Sole authority for capability resolution and execution.
- **Capability Resolver**: Enforces manifest, policy, and lifecycle.

## Lifecycle (normative)
1. Planner calls `capability.search()`/`capability.resolve()` to identify candidates.
2. Planner calls `capability.install()` for a selected candidate (if not already installed).
3. Planner calls `capability.run()` for the installed capability.
4. Resolver persists manifest changes and exposes `capability.list()`/`capability.get()`/`capability.remove()`.

Any execution path that bypasses resolver enforcement is non-compliant.

## Operational endpoints (recommended)
- `GET /healthz` (process up)
- `GET /readyz` (store/schema/policy readiness)
- `GET /version` (service + schema versions)
- `GET /metrics` (Prometheus text format)

## Related docs
- `seeded-capabilities.md` (base/local layering, onboarding, registries)
