# UnisonOS Dynamic Dashboard and Companion Surface (Design Draft)

This document describes how the UnisonOS Operating Surface should use the existing renderer, context, and orchestrator capabilities to provide a dynamic, generated-in-real-time dashboard that can be recalled later through natural language (e.g., “remind me about that workflow we were designing a couple weeks ago”).

Status: design draft; core pieces are now implemented in `unison-context`, `unison-orchestrator`, and `unison-experience-renderer` (including a first version of the `workflow.recall` skill and companion tool wiring).

---

## 1. Roles: Renderer vs Shell

### Renderer (unison-experience-renderer)

- Primary **Operating Surface** for UnisonOS.
- Responsibilities:
  - Stream and render experiences in real time via `/experiences/stream`.
  - Show a living dashboard region of cards derived from experiences and planning skills.
  - Persist recent experiences as dashboard cards in `unison-context` so the state survives restarts and can be recalled later.
- The renderer should feel:
  - **Generated**, not navigated: experiences and cards appear as a result of interaction and planning, not as static app tiles.
  - **Evolving**: what you see on the surface changes as the conversation and context evolve.

### Developer workflows

Developer-only flows (onboarding/profile edits, sending test envelopes, confirmation exercises) should be exercised via documented API recipes and scripts rather than a separate UI surface.

---

## 2. Data Model: Experiences, Cards, and Dashboard State

### 2.1 Experience payload

Experiences are generic payloads written into `unison-experience-renderer` via `POST /experiences` (from orchestrator, companion, or other services). They update the live UI and may also persist to context.

Recommended fields (all optional except `person_id` when persisting):

- `person_id` (string) — the person the experience is for.
- `session_id` (string) — session identifier for grouping.
- `text` (string) — conversational text or summary.
- `tool_activity` (array of strings) — tool names or identifiers involved in this turn.
- `image_url`, `video_url`, `audio_url`, `stream_url` (strings) — media resources.
- `cards` (array of card objects) — structured UI elements representing state or outputs.
- `origin_intent` (string) — semantic intent that produced the experience (e.g., `workflow.design`, `dashboard.refresh`, `companion.turn`).
- `tags` (array of strings) — light-weight labels (e.g., `["workflow", "onboarding", "design"]`).
- `created_at` (number) — timestamp when the experience was created.

Examples of `origin_intent` values:

- `workflow.design` — companion-assisted workflow editing.
- `dashboard.refresh` — planner-driven dashboard updates.
- `workflow.recall` — future recall skill (see below).
- `companion.turn` — generic companion responses.

### 2.2 Cards

Cards are UI elements that appear in the dashboard region. They are shipped as part of experiences (`cards`) and persisted in the dashboard state.

Suggested card fields:

- `id` (string) — unique per card.
- `type` (string) — e.g., `summary`, `comms`, `workflow.step`, `workflow.recap`, `media.embed`.
- `title` (string) — short title.
- `body` (string) — descriptive text.
- `tool_activity` (string or array) — tool(s) that produced or relate to this card.
- `origin_intent` (string) — semantic source intent (e.g., `workflow.design`, `workflow.recall`).
- `tags` (array of strings) — labels for recall and filtering.
- `created_at` (number) — when the card was created.
- Optional media fields (`image_url`, `video_url`, `audio_url`, etc.).

Cards should be treated as **snapshots** of state or outputs; they can be regenerated or pruned by planner skills.

### 2.3 Dashboard state in context

`unison-context` already has a `dashboard_state` table and endpoints:

- `GET /dashboard/{person_id}` → `{"ok": True, "dashboard": {...}, "updated_at": ...}`
- `POST /dashboard/{person_id}` → `{"ok": True, "person_id": person_id}`

Dashboard state should include:

- `cards` (array of card objects) — as described above.
- `preferences` (object) — per-person hints (layout, density, pinned cards).
- `person_id` (string).
- `updated_at` (number).

Renderer:

- Uses `GET /dashboard/{person_id}` (proxied via its own `/dashboard` endpoint) to pre-populate cards on page load.
- Writes back recent cards from `_experience_log` to `/dashboard/{person_id}` so the state is durable across restarts.

---

## 3. Context Graph Logging for Recall

`CompanionSessionManager` already logs conversation state into `unison-context-graph` via a “conversation” dimension. To support recall (“remind me about that workflow…”), these logs should also carry:

- `tags` — from experiences/cards.
- `origin_intent` — which skill/mode produced the turn.
- `created_at` — for time-based filtering.

Example context-graph update (simplified):

```json
{
  "user_id": "dev-person",
  "session_id": "workflow-session-1",
  "dimensions": [
    {
      "name": "conversation",
      "value": {
        "transcript": "We updated the onboarding workflow…",
        "tool_activity": ["workflow.design"],
        "cards": [ /* cards shown at that time */ ],
        "tags": ["workflow", "onboarding", "design"],
        "origin_intent": "workflow.design",
        "created_at": 1733097600
      }
    }
  ]
}
```

This ensures context-graph can later answer questions like “recent workflow design interactions” for a given person.

---

## 4. Behavior: Dynamic Dashboard as Generated Surface

The dashboard should be treated as a **generated surface**, not a static homepage:

- **Source of truth**:
  - Experiences emitted by companion turns, planner skills, and tools.
  - Cards built or updated by skills such as `dashboard.refresh`, `workflow.design`, and `workflow.recall`.
- **Renderer behavior**:
  - On load:
    - Fetches dashboard state and recent experiences.
    - Renders cards dynamically (no fixed layout beyond a simple grid or list).
  - On new experiences (SSE stream):
    - Updates the main view (chat, tools, media).
    - Updates cards when experiences include a `cards` array.
  - Renderer does not hardcode card types; it renders what is present and styles based on `type`/`tags`.

This keeps the Operating Surface open-ended: new skills and tools can introduce new card types and layouts without changing the renderer’s core code.

---

## 5. `workflow.recall` Skill (Design + Implementation)

This skill provides the ability to handle intents such as “remind me about that workflow we were designing a couple weeks ago”. A first implementation is wired into `unison-orchestrator` as both a skill handler (`workflow_recall`) and a companion tool (`workflow.recall`) that currently operates over dashboard state.

### 5.1 Intent and payload

Skill name:

- Internal skill: `workflow_recall` (handler).
- Intent name: `"workflow.recall"` (used in EventEnvelope `intent` field).

Payload shape:

```json
{
  "person_id": "dev-person",
  "query": "that workflow we were designing a couple weeks ago",
  "time_hint_days": 14,
  "tags_hint": ["workflow"]
}
```

- `time_hint_days` is optional and defaults to a window (e.g., 30 days).
- `tags_hint` is optional; if absent, tags can be inferred from the query (simple keyword mapping).

### 5.2 Retrieval logic (conceptual)

1. **Resolve time window**:
   - Compute a `since` timestamp based on `time_hint_days` (e.g., now minus 14 days).

2. **Derive tags**:
   - Start with `tags_hint` if present.
   - Else map query tokens like “workflow”, “design”, “onboarding” to tags.

3. **Query data sources**:
   - **Dashboard state** via `unison-context`:
     - `GET /dashboard/{person_id}` and filter cards where:
       - `tags` intersect the derived tags, and
       - `created_at` is newer than `since`.
   - **Context graph** (future or existing search endpoint):
     - Ideal shape: `POST /traces/search` with criteria:
       - `person_id`, `tags`, `since`.
     - Response: relevant conversation entries with `transcript`, `tool_activity`, `tags`, `cards`.

4. **Rank and summarize** (current implementation: dashboard-only):
   - Prefer:
     - Recent entries within the window.
     - Entries whose `origin_intent` is `workflow.design`, `workflow.update`, or similar.
   - Build a small set of recap cards, for example:

   ```json
   {
     "cards": [
       {
         "id": "workflow-recap-1",
         "type": "workflow.recap",
         "title": "Onboarding workflow – last edited 2 weeks ago",
         "body": "We updated step 3 to combine email and phone verification.",
         "tags": ["workflow", "onboarding", "design"],
         "origin_intent": "workflow.recall"
       }
     ]
   }
   ```

### 5.3 Skill effects

The `workflow.recall` handler should:

1. Use the steps above to produce a `cards` array and an optional `summary_text`.
2. Persist these recap cards by calling `dashboard_put(service_clients, person_id, dashboard_state)`:
   - Either replace the dashboard’s cards, or merge and flag recap cards (TBD based on UX).
3. Emit each recap card as an experience to renderer `/experiences`:
   - So they appear immediately on the person’s surface.
4. Return a structured result:

```json
{
  "ok": true,
  "person_id": "dev-person",
  "cards": [ /* recap cards */ ],
  "summary_text": "We last worked on your onboarding workflow two weeks ago. I’ve brought that view back to your dashboard."
}
```

The companion can then respond in natural language using `summary_text`, while the dashboard reflects the recalled workflow.

---

## 6. Companion Integration

With this design:

- Natural language in the companion loop (“remind me about that workflow…”) can be mapped by the model to a tool call:
  - Tool: `workflow.recall`
  - Arguments: `{ person_id, time_hint_days, tags_hint, query }`
- The companion:
  - Executes the tool via the orchestrator’s native tool path, which calls the same `workflow_recall` logic used by the skill handler.
  - Uses `summary_text` as chat response when appropriate.
  - Leaves the UI update to the emitted recap cards and updated dashboard state.

This keeps the boundary clean:

- Companion handles language and tool orchestration.
- The dashboard is updated via standard experience and context APIs.
- Renderer simply renders what it receives—keeping the surface flexible and extensible.

---

As implementation proceeds, update this document with:

- Actual search endpoint shapes in `unison-context-graph`.
- Any additional metadata fields used for recall (e.g., project IDs).
- UX refinements for how recap cards are displayed and pruned over time.
