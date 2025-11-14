# People Quick Start

> Last reviewed: February 2025

This guide gets people experiencing Unison fast, whether through the hosted
environment or a local stack. The structure mirrors what we plan to publish on
GitHub Pages, so each section can stand on its own.

---

## Step 1 · Pick Your Starting Point

### 1A · Hosted Experience (fastest path)

- **Prerequisites:** Hosted invite, modern Chromium or Safari browser, microphone
  enabled for voice.
- **Launch:** Follow your invite link (or `https://demo.unisonos.org` when open
  access returns) and sign in.
- **Verify:** The canvas should greet you with “Hello from Unison.” Send
  “What can you help me with this afternoon?” and watch the Skills panel update.
- **Tips:** Keep DevTools closed to avoid extra latency. For blockers, jump to
  the [People Guide](./people-guide.md#need-help).

### 1B · Local Stack (full control)

- **Prerequisites:** macOS, Linux, or WSL2; Docker Desktop 4.25+ (8 GB RAM, 4
  CPUs); `make`; `git`; optional `uv`/Python 3.11 for custom skills.
- **Clone + start:**

  ```bash
  git clone https://github.com/unison-platform/unison.git
  cd unison
  make up
  ```

- **Watch readiness:** Run `make health` or open `http://localhost:3000/health`
  until every service shows `healthy`.
- **Sign in locally:** Visit `http://localhost:3000`, open the Experience tab,
  and ask “Show me what’s new in my workspace.”
- **Troubleshooting:** Restart a noisy service with
  `make restart service=context`. Clean up everything with
  `make down && docker system prune -f`. More fixes live in
  [`people-guide.md`](./people-guide.md#faq).

---

## Step 2 · Sample Scenarios

Choose a scenario that matches what you want to explore and follow along in the
interface.

- **Start simple:** [Basic Request](../scenarios/01-basic-request.md) shows the
  envelope, orchestration path, and how Unison explains its plan.
- **See context awareness:** [Scenario 02](../scenarios/02-context-aware-flow.md)
  walks through how personal context changes responses in real time.
- **Go deeper:** Browse the catalog in
  [scenarios/README.md](../scenarios/README.md) for collaboration, automation,
  and multi-hop consent flows.

Keep the Devstack dashboard open while you run a scenario so you can watch which
services respond.

---

## Step 3 · Make It Yours

1. **Personalize the experience.** Use the gear icon to set your preferred name,
   voice, notification cadence, and privacy boundaries. The
   [Hello Unison walkthrough](./hello-unison.md) highlights the quickest wins.
2. **Connect data sources.** Calendar, files, and presence connectors keep
   experiences grounded. Configure them in Settings → Integrations, then cross
   reference `people-guide.md#bring-your-data`.
3. **Shape behaviors.** Load or tweak renderer templates from the “Customize
   Surface” dialog, and use the
   [Experience Reference](./reference/experience-guide.md) for DSL details.

---

## Service Map Snapshot

- **Experience surfaces:** Experience Renderer (`:8092`) and Devstack UI
  (`:3000`) provide the canvases and health dashboards.
- **Orchestration spine:** Orchestrator (`:8080`), Intent Graph (`:8084`), and
  Context Graph (`:8085`) ingest envelopes and plan execution.
- **Policy + consent:** Policy (`:8083`), Auth (`:8086`), and Consent (`:8087`)
  evaluate bundles, mint tokens, and enforce grants.
- **Data stores:** Context (`:8081`) and Storage (`:8082`) keep graph state,
  replay data, and artifacts durable.
- **Skills + I/O:** Speech, Vision, Core I/O, and the skills registry
  (`:8095+`) capture multimodal inputs and fan out to capabilities.

Need the full dependency graph? Jump to the
[Developer Platform Overview](../developer/platform-overview.md) or the
[Architecture Guide](../developer/architecture.md).

---

## Health & Support

- **Check status:** Use `make health`, `make logs`, or
  `http://localhost:3000/status`.
- **Self-serve fixes:** `people-guide.md#need-help` covers the top interrupts and
  how to collect diagnostics.
- **Contact the team:** File issues in the monorepo, visit the community
  Discord, or email support—links stay updated in the People Guide.

---

## What’s Next?

- **Experience track:** Continue with the [People Guide](./people-guide.md) for
  accessibility, collaboration, and rollout planning. Pair it with the
  [experience reference](./reference/experience-guide.md) when designing new
  surfaces.
- **Builder track:** Move into
  [Developer Getting Started](../developer/getting-started.md) or the
  [Platform Overview](../developer/platform-overview.md) to set up your
  environment, learn repo make targets, and plan contributions.

Log what felt great (or rough) as you explore. Feeding those insights into the
architecture + onboarding refresh keeps the documentation evolving with the
product.
