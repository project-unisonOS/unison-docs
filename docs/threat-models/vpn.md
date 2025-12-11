# Threat Model – VPN

## Assets
- WireGuard config/keys, tunnel traffic metadata, VDI/VPN health endpoints.

## Trust boundaries
- VPN ingress from clients; egress to internal network; control plane from orchestrator.

## Threats
- Key leakage or weak config leading to unauthorized tunnel access.
- Exposed health/status endpoints without auth.
- DoS on VPN port; rogue client draining resources.
- Supply chain: unsigned images.

## Mitigations
- Strong key mgmt; rotate WG keys; store in Vault/Secret Manager.
- AuthN on status APIs; restrict ingress via firewall/NetworkPolicies; rate limit.
- Non-root, drop caps where possible (NET_ADMIN kept minimal); read-only FS; seccomp.
- Signed images + cosign verify; pinned base.
- Alerts on handshake failures, repeated auth failures, and VPN readyz failing.
