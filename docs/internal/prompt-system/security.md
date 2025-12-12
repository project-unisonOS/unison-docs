# Security & Trust Boundaries

## Trust Boundaries
- The filesystem prompt directory is **user-owned** and **outside** the model.
- The model is treated as untrusted with respect to persistence.
- Only UnisonOS code writes prompt files, and only via validated tools.

## Threats
- **Self-persistence**: model tries to change its own rules.
- **Prompt injection**: content attempts to override base policy.
- **Privilege escalation**: changes that relax privacy/tool boundaries.

## Mitigations
- Immutable base policy layer; update tools only target `identity.json` and `priorities.json`.
- Schema validation + patch validation for every update.
- High-risk approval gating.
- Append-only audit logging + snapshot rollback.

