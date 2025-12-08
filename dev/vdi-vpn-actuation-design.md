# VDI + VPN Actuation Design (UnisonOS)

## Overview and Goals
- Provide a hidden, policy-governed VDI surface for Unison agents to browse, transact, and fetch artifacts without exposing the desktop to the person.
- Route all VDI egress through a fail-closed WireGuard VPN sidecar; no traffic may leak to the host network.
- Integrate with actuation/orchestrator so higher layers remain VPN-agnostic and use a single VDI actuator API.
- Persist downloads and audit trails in `unison-storage`; use vault for credentials and sensitive cookies; consult `unison-policy` and `unison-consent` for high-risk actions.
- Leave a clear path to full desktop automation beyond headless browser flows.

### Key Use Cases
- Automated web browsing and form submission for account sign-ups/logins.
- Downloading statements, tickets, invoices, and persisting them to per-person workspaces.
- Executing policy-gated transactions (purchases/reservations) only with explicit consent.
- Future: full desktop automation (windowed apps, spreadsheets) behind the same actuation contract.

### Non-Goals
- Providing a person-facing remote desktop.
- Embedding VPN provider credentials in code; all secrets live in env/config.
- Bypassing policy/consent/auth boundaries for expedience.

## Architecture
### Component Roles
- `unison-actuation`: exposes high-level `/vdi/*` actuation endpoints to orchestrator; enforces policy/consent/auth and routes to VDI driver.
- `unison-agent-vdi`: executes browser/desktop tasks; owns session lifecycle, downloads, and telemetry to storage.
- `unison-network-vpn`: WireGuard VPN sidecar; provides `/healthz`, `/readyz`, `/status`, `/ip`; hosts the network namespace shared by the VDI.
- `unison-orchestrator`: selects VDI actuator via intent/graph; unaware of VPN plumbing.
- `unison-policy` / `unison-consent`: authorize high-risk actions; provide consent references.
- `unison-auth`: validates service tokens/JWTs used between orchestrator → actuation → VDI.
- `unison-storage`: canonical store for files, vault secrets, and audit logs.
- `unison-context` / `unison-context-graph` / `unison-intent-graph`: receive telemetry; provide person/session context.

### Container Topology (devstack)
- `unison-network-vpn` attaches to `internal` and `data` networks; publishes port `8083` for VDI API and `8084` for VPN health/status.
- `unison-agent-vdi` uses `network_mode: "service:unison-network-vpn"` so all traffic shares the VPN namespace. It does **not** join other networks directly.
- `unison-actuation`, `orchestrator`, renderer, graphs live on `internal`; storage/postgres/redis on `data`; auth/consent on `auth` net (per `docker-compose.security.yml` segmentation).
- DNS alias `agent-vdi` is provided on the VPN service so downstreams call `http://agent-vdi:8083` without knowing the network sharing.
- Fail-closed: VPN container sets default route via `wg0` and installs iptables drop rules for non-VPN egress when `WIREGUARD_REQUIRED=true`.

## Data Flow and Control Flow
### Automated web browsing + download
1) Person intent enters orchestrator → routed to actuation with an Action Envelope referencing `device_class=desktop` and `intent.name=vdi.browse`.
2) Actuation validates auth, scopes, policy `/evaluate`, and consent reference (or fetches via `consent`).
3) Actuation calls `agent-vdi /tasks/browse` with task+person context. If VPN not ready, call fails with `503 vpn_unavailable`.
4) Agent spins a headless browser session, opens URL, performs scripted steps, and streams telemetry to context/graph/renderer (via actuation’s telemetry channel or direct best-effort hooks).
5) Downloads saved to per-person workspace (`/workspace/{person_id}/{session_id}/`) and uploaded to `unison-storage /files` (or `/memory` for ephemeral). Storage returns file_id; agent returns it in response.
6) Agent writes audit events to `unison-storage /audit` (action, URL/domain, person_id, timestamps, VPN exit IP, policy_decision_id).

### Automated form submission / transaction
1) Orchestrator emits Action Envelope `intent.name=vdi.form_submit` with fields, target domain, risk_level determined by orchestrator.
2) Actuation applies policy/consent; high-risk triggers consent reference lookup; may return 202 awaiting_confirmation.
3) If permitted, actuation calls agent task; agent enforces VPN ready + auth token; executes scripted Playwright steps (fill, click, wait_for_navigation).
4) On success/failure, agent records audit + telemetry; actuation returns ActionResult to orchestrator; orchestrator updates renderer/context graph.

## API Specifications
### unison-actuation (new/updated)
- `POST /vdi/tasks/browse` → proxy to agent-vdi browse; request `{person_id, session_id?, url, headers?, wait_for?, telemetry_channel?, risk_level}`; response `{status, action_id, result, file_ids?, exit_ip?, audit_ref}`.
- `POST /vdi/tasks/form-submit` → `{person_id, url, form: [{selector, value, type?}], submit_selector?, wait_for?}`.
- `POST /vdi/tasks/download` → `{person_id, url, cookies_ref?, headers?, target_path?}` returns storage `file_id`.
- `GET /vdi/sessions/{id}` → status/telemetry (optional future).

### unison-agent-vdi (internal)
- `POST /tasks/browse` — executes navigation, optional clicks/waits, returns `{status, exit_ip, artifacts:[file_id], telemetry}`.
- `POST /tasks/form-submit` — fill+submit flows.
- `POST /tasks/download` — fetch/download and persist via storage; supports `workspace_prefix` and `content_type`.
- `GET /healthz`, `GET /readyz` — ready only when VPN healthy and Playwright dependency check passes.
- Auth: service token/JWT from actuation; optional `X-Person-Id` for audit correlation.

### VPN service (`unison-network-vpn`)
- `GET /healthz` — process up.
- `GET /readyz` — WireGuard interface up + handshake within `VPN_HANDSHAKE_TTL`.
- `GET /status` — `{interface_up, handshake_time, exit_ip?, config_source}`.
- `GET /ip` — best-effort egress IP check via configurable echo endpoint.

## Storage Integration
- Downloads written to `/workspace/{person_id}/{session_id}/` inside agent container; directory is a volume mounted to storage sync or uploaded immediately via `unison-storage /files`.
- Naming: `vdi/{person_id}/{session_id}/{timestamp}_{slugified_domain}.{ext}`.
- Vault: credentials/tokens pulled from `unison-storage /vault` using references in Action Envelope (never inline secrets).
- Audit: `POST /audit` with fields `{action_id, person_id, agent=vdi, intent, target_url, domain, vpn_exit_ip, decision_id, status, timestamp}`.

## Security & Privacy
- VPN fail-closed: iptables drop non-VPN default route when `WIREGUARD_REQUIRED=true`; readiness blocks VDI when VPN down.
- Per-person isolation: session-scoped browser contexts; clear cookies/cache after task; workspace path includes person_id/session_id; option to destroy after upload.
- Auth: actuation → VDI uses service token/JWT; VDI enforces policy scope hints from envelope; no direct public access.
- Consent/policy: high-risk intents (transactions, credential use) require policy permit + consent reference; VDI refuses without `policy_decision_id`.
- Logging: PII minimized; URLs/domains hashed where possible in audit; sensitive payloads stored in vault, not logs.

## Deployment & Configuration
- Devstack additions:
  - New service `unison-network-vpn` (WireGuard client) with volumes for `/etc/wireguard/wg0.conf`.
  - `agent-vdi` uses `network_mode: service:unison-network-vpn`; VPN service exposes port `8083` (VDI API) and `8084` (VPN status).
  - Health dependencies: agent `readyz` waits for VPN `/readyz`; orchestrator uses actuation; compose healthchecks enforced.
- Env vars:
  - VPN: `WIREGUARD_CONFIG_PATH`, `WIREGUARD_CONFIG_B64`, `VPN_IP_ECHO_URL`, `WIREGUARD_REQUIRED`, `VPN_HEALTH_PORT`.
  - VDI: `VDI_SERVICE_PORT`, `VDI_SERVICE_HOST`, `VPN_HEALTH_URL`, `STORAGE_URL`, `STORAGE_TOKEN`, `POLICY_URL`, `CONSENT_URL`, `AUTH_URL`, `VDI_WORKSPACE_PATH`.
  - Actuation: `ACTUATION_VDI_URL`, `ACTUATION_SERVICE_TOKEN`, `ACTUATION_ALLOWED_RISK_LEVELS`.
- Edge vs cloud: headless Chromium requires ~1 vCPU/1.5GB; ensure GPU passthrough or disable; VPN MTU configurable for host networks.
- VPN provider: support mounting full `wg0.conf`; local test endpoint supported by bringing your own WireGuard server; prod uses provider-issued endpoints/secrets via vault.

## Future Extensions
- Full desktop support: add lightweight X11/Wayland + VNC/RDP inside agent container; extend driver for windowed app automation.
- Additional actuators: reuse actuation driver pattern for IoT/robotics; VPN sidecar reusable for other egress-sensitive actuators.
- Graph integration: persist VDI sessions and resource edges into context-graph/intent-graph when Neo4j backend lands.
- Session pooling: pre-warm browser contexts per person with policy-based TTLs; attach to orchestrator intents for faster workflows.
- Telemetry/metrics: expose VPN bytes transferred, reconnect counts; per-task timings; OTEL spans for browser actions.

## Phased Implementation Plan
### Phase 1 – VPN Service + VDI Network Wiring
- Repos: `unison-network-vpn` (new), `unison-devstack`, `unison-agent-vdi`.
- Changes: add WireGuard client container with health endpoints; set agent network_mode to VPN; add readiness chain; basic VPN logging; integration smoke to confirm VPN egress.
- Tests: devstack integration test hitting `/ip` through VDI to confirm VPN IP (or assert VPN readiness gating).

### Phase 2 – Headless Browser + Basic Actuation API
- Repos: `unison-agent-vdi`, `unison-actuation`, `unison-devstack`, `unison-docs`.
- Changes: add Playwright/Chromium; implement `/tasks/browse|form-submit|download`; wire to storage uploads + audit; actuation exposes `/vdi/tasks/*` proxy with policy enforcement and service token auth.
- Tests: FastAPI unit tests for models/routes; integration flow to browse a test page and persist a sample download via storage.

### Phase 3 – Policy, Consent, Auth Hardening
- Enforce scopes + consent references on VDI tasks; verify JWTs via `unison-auth`; enrich audit logs with decision IDs.
- Add rejection paths when VPN missing, consent absent, or storage unavailable.

### Phase 4 – Extended Desktop Support (future)
- Add full desktop session manager (Xvfb/Wayland + VNC); add actuation driver capabilities `desktop.command`, `desktop.stream`.
- Tests for GUI automation and multi-session isolation.

### Migration/Config Notes
- Compose: add VPN service + aliases; add volumes for WireGuard config; ensure `SYS_MODULE`/`NET_ADMIN` caps on VPN only.
- CI: add docker build for VPN image; add integration job running devstack subset (vpn + agent + storage) to exercise `/ip` + download.
- Secrets: all WireGuard keys/peers pulled from env or mounted secrets; never committed to repo.
