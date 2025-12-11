# Threat Model – Actuation / VDI

## Assets
- Actuation commands, device state, VDI session tokens, VPN config.

## Trust boundaries
- Ingress from orchestrator/policy; VPN/VDI exposed ports.
- Device control channels (USB/serial/IO); network path to actuators.

## Threats
- Unauthorized actuation leading to physical/VDI impact.
- Compromise via VPN/VDI endpoints (weak auth, exposed ports).
- Untrusted devices sending spoofed status.
- Supply chain: unsigned images/configs.

## Mitigations
- mTLS with SPIFFE; OPA policy requiring step-up, trusted device attestation.
- NetworkPolicies restricting ingress to orchestrator/policy; firewall on exposed ports.
- Read-only root FS, drop caps; seccomp; non-root.
- Signed images + cosign verify; SBOMs; pinned base.
- Health/readiness probes; audit logs for actuation command/deny; alerts on deny bursts or untrusted device.
