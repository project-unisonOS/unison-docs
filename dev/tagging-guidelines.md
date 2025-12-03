# UnisonOS Tagging Guidelines (Draft)

This document defines a starter tag schema for UnisonOS. Tags are attached to:

- **Cards** rendered in the dashboard (via orchestrator skills and companion responses).
- **Experiences** sent to the renderer (`/experiences`).
- **Context-graph traces** and state dimensions (via the companion session manager).

The goal is to make recall (“remind me about that workflow…”) predictable and privacy‑preserving without overfitting to any one model provider.

Status: internal draft; aligned with current implementations in:

- `unison-orchestrator` (skills, companion, workflow.recall).
- `unison-experience-renderer` (cards + experiences).
- `unison-context` (dashboard state).
- `unison-context-graph` (context + trace replay/search).

---

## 1. General Rules

- Tags are short, lowercase strings.
  - Prefer `kebab-case` (for simple labels) or `namespace:value` (for scoped concepts).
  - Examples: `workflow`, `trip:planning`, `project:unisonos-docs`.
- Assign **3–7 tags** per card/experience in normal cases.
- No raw PII in tags:
  - Avoid full names, emails, street addresses, phone numbers, exact GPS coordinates.
  - Use coarse or abstracted forms instead (for example `city:lisbon`, `contact:alice` with a separate private mapping).
- Tags should be:
  - **Useful for recall** (“that workflow”, “that Lisbon trip”, “the onboarding docs”).
  - **Stable** over time (avoid frequent renames).
  - **Composable** (multiple tags can describe the same item).

---

## 2. Categories

Tags fall into a small set of categories. A single tag may serve more than one purpose, but the categories help keep the vocabulary small and predictable.

### 2.1 Domain / Topic

Used on nearly every card/experience.

- `workflow` – workflows, playbooks, multi‑step processes.
- `planning` – day/week planning, trip planning, project planning.
- `comms` – messages, email, chat, notifications.
- `calendar` – events, meetings, schedules, reminders.
- `docs` – documents, notes, specs, reference material.
- `learning` – tutorials, courses, reading lists, research.
- `finance` – payments, budgets, expenses, invoices.
- `health` – wellness, sleep, exercise, health tracking.
- `travel` – trips, itineraries, flights, hotels, transit.
- `system` – platform, settings, capabilities, diagnostics.

### 2.2 Activity Type

Describes *what* is happening.

- `search` – searching or exploring (web, docs, files).
- `draft` – initial content generation (emails, docs, workflows).
- `review` – reviewing or critiquing something.
- `decision` – summarizing options, making choices.
- `task` – single actionable items to do.
- `meeting` – scheduling, notes, or follow‑ups for meetings.
- `note` – free‑form notes, reflections, scratchpad entries.
- `setup` – installation, configuration, onboarding steps.

### 2.3 Importance / Status

For prioritization and follow‑up.

- `p0` – critical / urgent.
- `p1` – high priority.
- `p2` – normal priority.
- `blocked` – currently blocked.
- `in-progress` – being worked on.
- `done` – completed.
- `snoozed` – deferred until later.

### 2.4 Surface / Modality

Helps filter by interaction mode.

- `voice` – voice‑driven interaction.
- `display` – primarily visual interaction.
- `multimodal` – mixed voice + display.
- `mobile` – phone or tablet surface.
- `desktop` – laptop/desktop/shell/VDI surface.

### 2.5 Origin / Intent

Usually mirrors `origin_intent` but encoded as tags for quick filtering.

Examples (non‑exhaustive):

- `companion.turn` – generic companion responses.
- `dashboard.refresh` – planner‑ or skill‑driven dashboard updates.
- `workflow.recall` – recall of prior workflows / sessions.
- `calendar.refresh` – calendar‑derived summaries.
- `comms.triage` – communications triage.
- `startup.prompt.plan` – initial startup / modality planning.
- `system.health` – health, diagnostics, or telemetry summaries.

Implementation note:

- `origin_intent` remains a dedicated field on cards/experiences; the corresponding tag is optional but recommended where it helps recall.

### 2.6 Location & Travel

Coarse, consent‑based location context. These tags are **optional** and should only be used when the person has allowed location‑aware behavior.

Place / context (user‑defined or inferred):

- `home`
- `work`
- `gym`
- `store`
- `airport`

Travel lifecycle:

- `trip:planning` – pre‑trip research and setup.
- `trip:in-progress` – during the trip itself.
- `commute` – regular routes between known places.
- `transit` – trains, buses, rideshares.
- `flight` – flights, boarding, delays.
- `hotel` – lodging, check‑in/out, reservations.

Region (optional):

- `city:lisbon`, `city:seattle`
- `country:us`, `country:pt`

Raw coordinates, full addresses, or venue IDs belong in encrypted profile/context data, not in tags.

### 2.7 Search & Concept Tags

Lightweight concept capture derived from queries, documents, or workflows.

Patterns:

- `workflow:<name>` – specific flows.
  - Examples: `workflow:onboarding`, `workflow:billing`, `workflow:support`.
- `project:<id>` – projects or areas.
  - Examples: `project:unisonos`, `project:unisonos-docs`, `project:personal-finance`.
- `topic:<concept>` – optional high‑level themes.
  - Examples: `topic:privacy`, `topic:accessibility`, `topic:productivity`.

Heuristics:

- When the primary activity is search, always include `search`.
- Extract candidate concepts from:
  - Query text (after stopword removal and basic normalization).
  - Document titles or workflow names.
  - Tool/skill names (for example, `calendar.refresh` ⇒ `["calendar"]`).
- Map free‑form tokens into the canonical vocabulary above where possible instead of introducing new tags.

---

## 3. How to Tag in Practice

For each **card** or **experience**, aim to set:

- 1–2 **domain/topic** tags (for example `["workflow", "travel"]`).
- 1–2 **activity** tags (for example `["planning", "search"]`).
- 0–2 **importance/status** tags (for example `["p1"]` when applicable).
- 0–2 **surface/modality** tags if relevant (for example `["voice", "multimodal"]`).
- 0–2 **location/travel** tags when location is in play (for example `["trip:planning", "city:lisbon"]`).
- 1 **origin/intent** tag that generally mirrors `origin_intent`.
- 0–3 **concept** tags (`workflow:<name>`, `project:<id>`, `topic:<concept>`).

Examples for three flows are detailed in the next section.

---

## 4. Flow-Specific Tag Sets

This section defines concrete tag sets for three important flows. These are descriptive contracts; services should follow them when emitting cards/experiences for the given intents.

### 4.1 Daily Dashboard / Morning Brief (`dashboard.refresh`)

**Intent / origin**

- `origin_intent`: `"dashboard.refresh"`.
- Applies to cards produced by the `dashboard_refresh` skill (morning briefing, communications, system summaries).

**Baseline tags for any `dashboard.refresh` card**

- Domain: `["planning"]`
- Origin: `["dashboard.refresh"]`
- Surface: `["display"]` (add `["multimodal"]` if also voiced).
- Status (optional): `["p1"]` for high‑value cards, `["p2"]` otherwise.

**Card‑type specific tags**

- Morning briefing:
  - Add: `["dashboard", "calendar"]`
  - Example:

    ```json
    ["planning", "dashboard", "dashboard.refresh", "calendar", "p1"]
    ```

- Priority communications:
  - Add: `["dashboard", "comms"]`
  - Example:

    ```json
    ["planning", "dashboard", "dashboard.refresh", "comms", "p1"]
    ```

- System / health summary:
  - Add: `["dashboard", "system"]`
  - Example:

    ```json
    ["system", "dashboard", "dashboard.refresh", "p2"]
    ```

### 4.2 Workflow Design / Editing (`workflow.design`)

**Intent / origin**

- Planned skill handler: `workflow_design`.
- `origin_intent`: `"workflow.design"` for design/edit sessions.
- Cards: steps, diagrams, summaries, “next actions” for a workflow.

**Baseline tags for workflow design cards**

- Domain: `["workflow", "planning"]`
- Activity:
  - `["draft"]` while designing.
  - `["review"]` when reviewing.
- Origin: `["workflow.design"]`
- Surface: `["display"]` or `["multimodal"]`.

**Workflow‑specific concept tags**

- Always add a workflow concept tag:
  - Examples: `workflow:onboarding`, `workflow:billing`, `workflow:support`.
- Optionally add a project tag:
  - Examples: `project:unisonos`, `project:unisonos-docs`, `project:trip-lisbon`.

**Examples**

- Onboarding workflow design card:

  ```json
  ["workflow", "planning", "draft", "workflow.design", "workflow:onboarding", "project:unisonos-docs"]
  ```

- Billing workflow review card:

  ```json
  ["workflow", "planning", "review", "workflow.design", "workflow:billing", "project:unisonos"]
  ```

### 4.3 Travel Planning (`travel.plan.*`)

**Intent / origin**

- Planned intents (examples):
  - `"travel.plan.trip"`
  - `"travel.find.flights"`
  - `"travel.find.hotels"`
- `origin_intent`: one of the above (or `"companion.turn"` plus travel tags when purely companion‑driven).
- Cards: itinerary summaries, flight options, hotel options, packing/workflow cards.

**Baseline tags for travel planning cards**

- Domain: `["travel", "planning"]`
- Activity:
  - `["search"]` when exploring options.
  - `["decision"]` when summarizing choices.
- Travel lifecycle:
  - `["trip:planning"]` for pre‑trip planning.
  - `["trip:in-progress"]` while traveling.
- Region (optional, if user has enabled location‑aware behavior):
  - `["city:lisbon"]`, `["city:seattle"]`
  - `["country:pt"]`, `["country:us"]`

**Concept tags**

- Workflow-ish travel concept:
  - `workflow:trip-planning`
- Project tag for the trip:
  - `project:trip-lisbon` (or similar stable identifier).

**Examples**

- Trip planning summary card:

  ```json
  ["travel", "planning", "search", "trip:planning", "city:lisbon", "workflow:trip-planning", "project:trip-lisbon"]
  ```

- Flight options card:

  ```json
  ["travel", "planning", "search", "flight", "trip:planning", "city:lisbon", "project:trip-lisbon"]
  ```

- Hotel confirmation card:

  ```json
  ["travel", "planning", "decision", "hotel", "trip:planning", "city:lisbon", "project:trip-lisbon"]
  ```

---

## 5. Example Intents and Skill Shapes (Conceptual)

This section sketches two intents/skills that can later be wired into orchestrator and companion flows. It is descriptive only; implementations should follow existing patterns for envelopes, skills, and tools.

### 5.1 `workflow.design`

**Intent name**

- `"workflow.design"`

**Skill handler**

- Internal handler name: `workflow_design`.
- Responsibilities:
  - Accept a workflow identifier and optional edits or steps.
  - Read/write workflow definitions from storage/context.
  - Produce cards that represent the current workflow state and next steps.

**Example payload shape**

```json
{
  "person_id": "dev-person",
  "workflow_id": "onboarding",
  "project_id": "unisonos-docs",
  "mode": "design", // or "review"
  "changes": [
    {
      "op": "add_step",
      "title": "Verify email and phone together",
      "position": 3
    }
  ]
}
```

Cards emitted by this skill should follow the tag rules in section 4.2 and set `origin_intent: "workflow.design"`.

**Tool exposure**

- Expose as a companion tool named `"workflow.design"` with a schema that matches the payload shape above so the model can:
  - Propose edits (via `changes`).
  - Request a recap (no `changes`, `mode: "review"`).

### 5.2 `travel.plan.trip`

**Intent name**

- `"travel.plan.trip"`

**Skill handler**

- Internal handler name: `travel_plan_trip`.
- Responsibilities:
  - Accept a high‑level trip description.
  - Normalize dates, locations, and preferences.
  - Produce cards that summarize plans and open decisions (flights, hotels, tasks).

**Example payload shape**

```json
{
  "person_id": "dev-person",
  "trip_id": "lisbon-2026-04",
  "destination_city": "Lisbon",
  "destination_country": "PT",
  "date_range": {
    "start": "2026-04-10",
    "end": "2026-04-18"
  },
  "preferences": {
    "budget_level": "mid",
    "hotel_style": "walkable",
    "work_needs": true
  }
}
```

Cards emitted by this skill should follow the tag rules in section 4.3 and set `origin_intent: "travel.plan.trip"` (or a related value for sub‑skills).

**Tool exposure**

- Expose as a companion tool named `"travel.plan.trip"` that:
  - Takes the payload above (or a simplified version) as arguments.
  - Returns a structured summary plus cards for flights, hotels, and tasks.

These intent sketches keep the contract clear for future implementation while aligning with the tagging and recall design in this document.

---

## 6. Service Responsibilities

High‑level guidance on where tags should be set or enriched:

- **Orchestrator / Skills**
  - Skills that produce cards (for example, `dashboard.refresh`, future workflow skills) should assign sensible default tags based on domain and intent.
  - `workflow.recall` must ensure all recap cards include at least `["workflow"]` and `origin_intent: "workflow.recall"`.

- **Companion Session Manager**
  - Derive baseline tags from:
    - `origin_intent` (envelope intent).
    - Tool activity names (`context.get`, `workflow.recall`, etc.).
  - Attach these tags to the experience payload and to the context‑graph trace metadata.

- **Renderer**
  - Preserve tags on incoming experiences and dashboard cards.
  - Never invent tags; only propagate what orchestrator/companion/services provide.

- **Context and Context‑Graph**
  - Store tags as part of dashboard state (`cards[].tags`) and trace metadata.
  - Expose tags in search interfaces (for example, `/traces/search`).

---

## 7. Future Extensions

Areas to evolve once the starter schema has been exercised:

- Introduce a small set of **UX tags** (for example `layout:grid`, `layout:list`) if layout becomes part of recall or filtering.
- Add a **confidence** or **source** field for tags (for example `source:model`, `source:rule`) if model‑derived tags become common.
- Define clearer **lifecycle semantics** for tags that should expire or be downgraded over time (for example, `p0` decays to `p1` after a week).

Any additions should keep the vocabulary small and interpretable; tags are a shared contract between services, not an open string field.
