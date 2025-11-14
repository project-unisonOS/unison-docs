# Project Unison Documentation Hub

## Overview

Project Unison is an **enterprise-grade intent orchestration platform** that replaces traditional interfaces with real-time, context-aware experience generation. The platform unifies more than fifteen microservices behind hard contracts, shared tooling, and a single deployment workflow so teams can ship safely while retaining service autonomy.

**Key Platform Features**

- **One-command setup**: `make up` brings the entire platform online.
- **Universal CI/CD**: Reusable workflows with security, provenance, and SBOM enforcement.
- **Hard interfaces**: Shared schemas via `unison-spec` remove ad hoc contracts.
- **Enterprise security**: Policy, consent, and tracing guard every request.
- **Full observability**: Distributed tracing, metrics, and structured logging everywhere.
- **Clear domain boundaries**: Core services, I/O gateways, skills + inference, and infrastructure layers.

---

## Documentation Structure

### People Experiences
Guides for everyone interacting with Unison—explorers, facilitators, and everyday collaborators.

| Section | Description |
|---------|-------------|
| [Hello Unison](people/hello-unison.md) | **Start here** – guided first interaction and narrative walkthrough. |
| [Quick Start](people/quick-start.md) | Launch the hosted or local experience in minutes. |
| [Onboarding Checklist](people/onboarding-checklist.md) | Repeatable ramp plan for teammates and partners. |
| [People Guide](people/people-guide.md) | Feature-by-feature reference for everyday use. |
| [Scenarios](scenarios/README.md) | Real-world patterns (basic request, context-aware flow, etc.). |
| [Troubleshooting](people/troubleshooting.md) | Common issues and fast fixes. |
| [Experience Guide](people/reference/experience-guide.md) | Deep reference for surfaces, controls, and cues. |

### Developer Documentation
Everything builders need—from local setup to hard contracts. Start with the orienting docs, then dive into guides and references.

| Section | Description |
|---------|-------------|
| [Developer Getting Started](developer/getting-started.md) | Local environment prep, verification, and tooling. |
| [Platform Overview](developer/platform-overview.md) | Domains, dataflow, and cross-service boundaries. |
| [Development Workflow](developer/development-workflow.md) | Branching strategy, testing expectations, and release cadence. |
| [Migration Guide](developer/migration-guide.md) | Moving legacy services toward shared contracts. |
| [Guides](developer/guides) | Deployment, dev-mode quickstart, inference, setup, and security hardening references. |
| [Security Notes](developer/guides/security.md) | Architecture + configuration details for securing deployments. |

### Specifications & API
The source of truth for interfaces and automation.

| Repository / Doc | Purpose |
|------------------|---------|
| [`project-unisonOS/unison-spec`](https://github.com/project-unisonOS/unison-spec) | Canonical schemas and requirements. |
| [API Reference](developer/api/README.md) | Endpoint walkthroughs and payload expectations. |
| [Schema Specs](developer/specs/README.md) | Shared contracts (event envelope, policy rules, etc.). |
| [Event Envelope](../unison-spec/specs/event-envelope.md) | Standard message format for every service boundary. |

---

## Platform Quick Start

```bash
# Clone the platform repository
git clone https://github.com/project-unisonOS/unison-platform.git
cd unison-platform

# Configure and start everything
cp .env.template .env
make up

# Verify all services are healthy
make health
```

**What you get**

- Intent orchestration and event routing.
- Context management and long-term memory.
- Experience rendering (cards, text, speech).
- I/O agents for speech, vision, and desktop control.
- Inference, skills, and policy enforcement.
- Full observability stack (Prometheus, Grafana, Jaeger).

See [Developer Getting Started](developer/getting-started.md) for environment requirements and troubleshooting.

---

## Quick Links

### For New People
- [Try the demo](https://demo.unisonos.org) – experience the agent.
- [Hello Unison](people/hello-unison.md) – guided first session.
- [People Guide](people/people-guide.md) – feature reference.
- [Troubleshooting](people/troubleshooting.md) – unblock yourself fast.

### For Developers
- [Architecture Overview](developer/architecture.md) – understand the system.
- [Dev Environment Setup](developer/getting-started.md) – local stack instructions.
- [API Reference](developer/api-reference/README.md) – schemas and endpoints.
- [Examples](developer/examples/README.md) – reusable patterns.

### For Operators
- [Security Guide](operations/security.md) – controls and policies.
- [Production Deployment](developer/deployment/production.md) – rollout steps.
- [Monitoring](operations/monitoring.md) – dashboards and alerts.
- [Maintenance](operations/maintenance.md) – routine + emergency playbooks.

### For Maintainers
- [Documentation Plan](DOCUMENTATION_UPDATE_PLAN.md) – roadmap and priorities.
- [Implementation Plans](../) – milestone status across services.
- [docs-lint CI](.github/workflows/docs-lint.yml) – checks run on every PR.

---

## Layered Architecture Overview

1. **User Interface Layer** – Web, mobile, CLI, and API gateway clients.
2. **Core Services Layer** – Orchestrator (decision engine), Context (memory), Storage (data durability), Policy (safety), Auth, Skills, and Inference services.
3. **Infrastructure Layer** – Docker/Kubernetes, Kong gateway, Redis, TLS termination, secrets, and observability tooling.

See [unison-docs/developer/architecture.md](developer/architecture.md) for diagrams and detailed narratives.

---

## Feature Highlights

### Natural Interaction
- Conversational interface with multimodal inputs.
- Context fusion keeps preferences, goals, and history.
- Adaptive responses tuned by policy and consent signals.

### Privacy & Security
- Local-first computation whenever possible.
- End-to-end encryption between services.
- Explicit consent scopes embedded in every EventEnvelope.
- Entire stack is open source and auditable.

### Performance & Reliability
- Microservices with contract enforcement and retries.
- Sub-second orchestration targeting real-time experiences.
- Replay, idempotency, and durability layers for recovery.
- Deployable on laptops, edge clusters, or cloud providers.

### Extensibility
- Skill system for new capabilities.
- Plugin architecture and open APIs for integrations.
- Developer tools, SDKs, and CI templates for every repo.

---

## Navigation Guide

### By Role

- **New to Unison**: [Getting Started](people/getting-started.md) → [People Guide](people/people-guide.md) → [Scenarios](scenarios/README.md) → [Troubleshooting](people/troubleshooting.md).
- **Developers**: [Architecture](developer/architecture.md) → [Dev Setup](developer/getting-started.md) → [API Reference](developer/api-reference/README.md) → [Contributing](developer/contributing.md).
- **Operators**: [Security](operations/security.md) → [Production Deployment](developer/deployment/production.md) → [Monitoring](operations/monitoring.md) → [Maintenance](operations/maintenance.md).

### By Topic

- **Learn the Platform**: [Vision](vision.md), [Architecture](developer/architecture.md), [Feature Matrix](feature-matrix.md).
- **Build with Unison**: [API Reference](developer/api-reference/README.md), [Skill Development](developer/skills/README.md), [Integration Examples](developer/examples/README.md).
- **Deploy Unison**: [Local Development](developer/deployment/local-development.md), [Production Deployment](developer/deployment/production.md), [Security Hardening](operations/security.md).
- **Operate Unison**: [Security Operations](operations/security.md), [Monitoring](operations/monitoring.md), [Backup & Recovery](operations/backup-recovery.md).

---

## Contributing

Documentation is fully open to contributions.

1. **Improve existing content** – fix typos, add examples, refresh diagrams.
2. **Add new documentation** – tutorials, walkthroughs, API samples.
3. **Improve accessibility** – translations, WCAG compliance, alt text.

**Guidelines**
- Follow the [markdown style guide](.markdownlint.json).
- Keep language clear, inclusive, and actionable.
- Test every instruction you publish.
- Provide context and examples for new concepts.

**Review Process**
1. Open a PR with a descriptive summary.
2. Docs maintainers review structure and voice.
3. Relevant engineers review technical accuracy.
4. Once approved, changes merge and publish automatically.

---

## Documentation Metrics

- **User documentation**: ~95% complete.
- **Developer documentation**: ~90% complete.
- **Operations documentation**: ~85% complete.
- **API documentation**: 100% covered via `unison-spec`.
- **Accessibility**: WCAG 2.1 AA.
- **Linting**: markdownlint + remark enforced in CI.
- **Examples**: All inline code tested during docs CI.

---

## Related Resources

### Official Channels
- **Website**: [unisonos.org](https://unisonos.org)
- **GitHub**: [project-unisonOS](https://github.com/project-unisonOS)
- **Community Forum**: [community.unisonos.org](https://community.unisonos.org)
- **Discord**: [discord.gg/unisonos](https://discord.gg/unisonos)

### Core Repositories

| Repository | Purpose | Language |
|------------|---------|----------|
| [`unison-orchestrator`](https://github.com/project-unisonOS/unison-orchestrator) | Central coordination service | Python |
| [`unison-context`](https://github.com/project-unisonOS/unison-context) | Context and memory management | Python |
| [`unison-storage`](https://github.com/project-unisonOS/unison-storage) | Persistence and encryption | Python |
| [`unison-policy`](https://github.com/project-unisonOS/unison-policy) | Safety and consent enforcement | Python |
| [`unison-auth`](https://github.com/project-unisonOS/unison-auth) | Authentication and authorization | Python |
| [`unison-inference`](https://github.com/project-unisonOS/unison-inference) | AI/ML generation services | Python |
| [`unison-common`](https://github.com/project-unisonOS/unison-common) | Shared libraries and utilities | Python |
| [`unison-devstack`](https://github.com/project-unisonOS/unison-devstack) | Dev + deployment tooling | Docker |

---

## License

All documentation is published under the **Creative Commons Attribution 4.0 International** license. Share and adapt it with attribution to Project Unison.

---

## Getting Help

1. **Documentation issues**: [open an issue](https://github.com/project-unisonOS/unison-docs/issues).
2. **Technical support**: Ask in [Discord](https://discord.gg/unisonos) or the community forum.
3. **Feature requests**: File issues in the relevant service repository.
4. **Direct contact**: docs@unisonos.org or [@unisonos](https://twitter.com/unisonos).

---

*Last updated: November 2025 · Version 1.1.0*
