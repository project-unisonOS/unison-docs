# Project Unison – Development Snapshot (as of October 2025)

## Current State
**Goal:** Build a modular, containerized OS-level environment that generates adaptive, context-aware experiences in real time.

**Architecture established:**
- **Core repositories created** under `project-unisonOS`:
  - `unison-spec` – shared schemas and standards.  
  - `unison-orchestrator` – event routing and service coordination.  
  - `unison-context` – short- and long-term memory management.  
  - `unison-storage` – secure persistence and partitioned data stores.  
  - `unison-devstack` – Docker Compose-based local environment.  
  - `unison-docs` – full documentation suite (vision, architecture, feature matrix, user journeys).  
- **Docker Compose environment operational** (orchestrator, context, storage).  
- **EventEnvelope schema defined** and tested across components.  
- **Shared developer governance** in place:  
  - `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SETUP.md`, `MAINTAINERS.md` distributed across all repos.  
- **User Journeys** drafted (basic request, context-aware flow, policy block, onboarding).  
- **Architecture diagram and README files** integrated in `unison-docs`.  

**Tooling baseline:**
- Development using **Ubuntu-based Docker containers** (Python 3.10+).  
- Source managed via **GitHub organization**; all documentation in Markdown.  
- Accessibility and WCAG 2.2 standards embedded from inception.

---

## Immediate Next Steps (0–3 weeks)

| Area | Task | Target |
|------|------|--------|
| **Spec** | Define `event-types.json` and shared interface contracts for Orchestrator ↔ Context ↔ Storage. | week 1 |
| **Orchestrator** | Implement `server.py` routing prototype and local REST test endpoint. | week 2 |
| **Context** | Add persistence and recall API (`/context/get`, `/context/set`). | week 2 |
| **Storage** | Connect to local volume store with secure partitions; integrate with Context. | week 3 |
| **Docs** | Add `dev/` subfolder with build, API, and schema references. | week 3 |
| **CI/CD** | Enable GitHub Actions for build + test on all repos. | week 3 |

---

## Short-Term Roadmap (0–3 months)

1. **Core Runtime**
   - Finalize EventEnvelope spec and message routing.  
   - Implement full Orchestrator REST + WebSocket interface.  
   - Integrate Context caching and policy enforcement hooks.

2. **Developer Tooling**
   - Add logging and tracing for inter-service events.  
   - Define base test harness for orchestration validation.

3. **I/O Layer Prototype**
   - Introduce `unison-io-speech` repo for text-to-speech and ASR bridging.  
   - Begin modular driver model for additional inputs (vision, tactile).

4. **Policy Service MVP**
   - Separate repo handling permissions, audit, and external API authorization.  
   - Support real-time evaluation and override prompts.

5. **Documentation & Community**
   - Add `/dev` documentation section for API references and build guides.  
   - Expand User Journeys for multi-modal and accessibility-first use cases.  
   - Open early contributor onboarding via GitHub Discussions.

---

## Development Principles
- **Modularity first** – all components replaceable without architectural breakage.  
- **Transparency and privacy by design** – explicit data flow and user control.  
- **Accessibility built-in** – all interactions multimodal from inception.  
- **Open collaboration** – clear governance, public documentation, and extensibility.
