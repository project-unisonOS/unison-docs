# Threat Model – Context Service

## Assets
- Context graphs/profiles, telemetry, consent state.

## Trust boundaries
- Ingress from orchestrator/renderer/shell; storage backend.
- Service-to-service calls with policy/auth.

## Threats
- Unauthorized reads/writes of sensitive/highly-sensitive context.
- Inference of private data through logs/telemetry.
- Supply chain tampering; unpinned deps/images.
- DoS via large/complex context queries.

## Mitigations
- SPIFFE/mTLS; OPA consent/policy checks on every read/write; classification checks.
- Redaction middleware and PII minimization; capped logging.
- Signed images/SBOM; pinned actions/deps; cosign verify on deploy.
- Rate limits/pagination; resource limits; audit logs on access.
