# Threat Model – Orchestrator

## Assets
- Intent payloads, skills routing decisions, session tokens, service secrets, model/tool API keys.

## Trust boundaries
- Ingress from renderer/shell/IO services.
- Service-to-service calls (context, storage, policy, auth, actuation).
- External model/tool integrations.

## Threats
- Injection via tool/skill payloads -> SSRF/remote calls.
- AuthZ bypass if service identity is weak/flat network.
- Supply chain: deps/actions/image tampering.
- Secrets leakage in logs or traces.
- DoS via unbounded concurrent skill/tool calls.

## Mitigations
- SPIFFE/mTLS between services; Envoy+OPA ext_authz enforcing consent/policy.
- Input validation and allowlists for tool endpoints; rate limiting.
- Signed images + SBOM + cosign verification; pinned actions/deps.
- Redacted logging; minimal PII in traces; alert on auth failures/policy denies.
- Resource limits; circuit breakers on external calls.
