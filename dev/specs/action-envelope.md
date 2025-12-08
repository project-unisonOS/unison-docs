# Action Envelope Specification (Actuation)

Stable cross-service schema for deterministic actuation requests. Emitted by `unison-orchestrator` (via the `proposed_action` tool) and consumed by `unison-actuation`.

## JSON Schema
Canonical schema lives in `action-envelope.schema.json` and mirrors the implementation in `unison-actuation/schemas/action-envelope.schema.json`.

Key fields:
- `schema_version`: `"1.0"`
- `action_id`: UUID
- `person_id`: actor/principal
- `target`: `{device_id, device_class, location?, endpoint?}`
- `intent`: `{name, parameters, human_readable?}`
- `risk_level`: `low|medium|high`
- `constraints`: `{max_duration_ms?, required_confirmations?, quiet_hours?, allowed_risk_levels?}`
- `policy_context`: `{scopes?, consent_reference?, justification?, risk_level?}`
- `telemetry_channel`: `{topic, delivery?, include_parameters?}`
- `provenance`: `{source_intent, orchestrator_task_id?, model_version?, generated_at?}`
- `correlation_id`, `created_at`

Validation rules:
- `risk_level` must be within `constraints.allowed_risk_levels` when present.
- `quiet_hours` use `HH:MM-HH:MM` 24h format.
- `target.device_id` and `target.device_class` are required.
- `intent.name` and `intent.parameters` are required; parameters are free-form JSON.

## Typings
- TypeScript: `schemas/action-envelope.ts`
- Python: Pydantic models in `unison-actuation/src/unison_actuation/schemas.py`

## Routing Guidance
- **Use actuation** when an action changes physical state or high-impact digital state (IoT devices, robots, system automation, avatars/embodiments, browser or OS automation that clicks/types).
- **Use renderer** for expressive/perceptual outputs (UI cards, speech/vision/sign/braille outputs); IO services (`unison-io-*`) should continue to emit EventEnvelopes for expression.
- **Policy scopes**: actuation flows should request scopes such as `actuation.*`, `actuation.home.*`, `actuation.robot.*`, `actuation.desktop.*` and include `policy_context.consent_reference` when available.

## Confirmation and Telemetry
- High-risk actions may return `requires_confirmation` and should surface a confirmation UX via renderer/context.
- Telemetry is published to context/context-graph/renderer using `telemetry_channel.topic` for routing; lifecycle events include `awaiting_confirmation`, `completed`, `failed`.
