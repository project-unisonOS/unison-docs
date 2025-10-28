# Project Unison – Core Architectural Directives (Developer Reference)

## 0. Scope
This document defines the current architectural directives for Project Unison. It captures required design constraints, module relationships, and development guidelines. All items under “Non-Negotiable” are mandatory.

---

## 1. System Goal
Unison is a modular, containerized computing environment that boots into an intelligent interactive surface, enabling natural multimodal interaction. It adapts to the person in front of it, enforces policy and privacy, and operates without traditional “apps.”

Two execution modes:
1. **Developer Mode** – runs via Docker Compose on a desktop host with a full-screen shell.
2. **Device Mode** – boots Ubuntu, auto-starts the Unison environment, and presents only the Unison shell.

Non-Negotiable:
- Build Developer Mode first.
- APIs and services must be portable to Device Mode.

---

## 2. Core Services Overview

| Service | Purpose | Status |
|----------|----------|---------|
| **unison-orchestrator** | Central router. Manages EventEnvelopes and calls other services. | Exists |
| **unison-context** | Handles personalization, memory, and tiered data. | Exists |
| **unison-storage** | Secure persistence for context and system state. | Exists |
| **unison-policy** | Evaluates privacy and authorization. | Exists |
| **unison-io-core** | On-device multimodal runtime, emits EventEnvelopes. | New |
| **unison-shell** | Full-screen conversational UI (Electron + React). | New |
| **unison-os** | Ubuntu-based base image for all containers. | Exists |
| **unison-devstack** | Docker Compose integration environment. | Exists |
| **unison-docs** | Documentation and design specs. | Exists |
| **unison-spec** | JSON schemas and contracts. | Exists |

Non-Negotiable:
- All inter-service communication uses the EventEnvelope contract.
- No direct database or file access between services.

---

## 3. EventEnvelope
Every service-to-service message must conform to `EVENT-ENVELOPE.md` in `unison-docs/dev/specs/`.

Required fields: `timestamp`, `source`, `intent`, `payload`  
Optional: `auth_scope`, `safety_context`

Non-Negotiable:
- No ad hoc payloads between services.
- Unknown fields are rejected.

---

## 4. Context Design – Per-Person, Tiered, Portable
### Requirements:
1. **Multi-person partitions:** Each `person_id` has isolated data.
2. **Three-tier memory model:**
   - **Private:** Sealed, encrypted, never exported.
   - **Profile:** Portable, sharable across devices.
   - **Session:** Short-term working memory.
3. **Exportable context:** Tier B can be exported via `/profile.export`.
4. **Policy enforcement:** Cross-person data access always routed through Policy.

Non-Negotiable:
- `unison-context` must implement tiered storage and enforce `person_id` namespaces.
- Tier A (“private”) never leaves the device.
- Policy must approve any cross-person or external data exchange.

---

## 5. Policy Enforcement
Policy controls all high-impact actions (network, sharing, finance, or personal data).  
It returns: `allowed`, `require_confirmation`, `reason`, `suggested_alternative`.

Non-Negotiable:
- Orchestrator must call Policy before performing external or sensitive actions.
- Shell must display clear feedback for denied or confirmation-required actions.

---

## 6. Model Architecture
### unison-io-core (on-device multimodal runtime)
- Handles speech, vision, and local inference.
- Emits EventEnvelopes to the Orchestrator.
- Does not persist identity or secrets.

Non-Negotiable:
- Model must be swappable.
- Models cannot access Context or Storage directly.
- No local model may transmit data off-device without Policy clearance.

---

## 7. Onboarding Experience
At first startup, Unison must:
1. Greet the person (text + audio).
2. Detect and set language preference.
3. Report detected hardware (mic, camera, etc.).
4. Explain privacy stance (local-first, cloud optional).
5. Ask for consent on cloud use.
6. Save onboarding details in `unison-context` (Tier B, per `person_id`).

Non-Negotiable:
- Must describe itself clearly to the person (“I don’t detect a camera yet…”).
- Must record explicit consent for any networked feature.

---

## 8. Repository Actions

New repositories to create:
```bash
git clone git@github.com:project-unisonOS/unison-shell.git
git clone git@github.com:project-unisonOS/unison-io-core.git
```
Existing repositories remain in use (`unison-policy`, `unison-os`, etc.).

`unison-devstack` continues to define integration and container orchestration.

Non-Negotiable:
- Each service repo stays independent (no monorepo).
- All Docker images inherit from `unison-os` base.

---

## 9. Security and Trust Model
- Context, Storage, and Policy enforce least privilege by default.  
- Secrets (Tier A) are never exported or shared automatically.  
- Context partitions are bound to a verified `person_id`.  
- Policy is always consulted for data transfer, multi-user interaction, or external execution.

---

## 10. Developer Directives for Cascade
- Treat models as pluggable. Context and Policy are always external.  
- Implement `person_id` and `tier` support in Context now.  
- Extend Orchestrator to validate EventEnvelopes and call Policy for risk.  
- Build `unison-shell` onboarding sequence aligned to “Journey 04.”  
- Respect the local-first architecture at all times.  
- No model or service may silently reach the internet without Policy authorization.

---

## 11. unison-os Repository Reminder
`unison-os` defines the **base Ubuntu LTS image** for all Unison containers.  
It standardizes packages, runtime user, and security baseline.

Non-Negotiable:
- Keep the name “Unison OS.” It is the brand for the experiential layer, not a kernel fork.
- Document clearly that it runs *on* Ubuntu.

---

## 12. Summary
**Unison’s core invariants:**  
1. Modular services, not a monolith.  
2. EventEnvelope for all communication.  
3. Policy governs all high-impact actions.  
4. Context is person-scoped, tiered, and portable.  
5. Models are swappable.  
6. Onboarding defines trust and consent.  
7. Local-first, privacy-forward by design.

This document is binding for all contributors and AI development agents.
