# UnisonOS Google Calendar Connector (Design Draft)

This document describes a safe pattern for integrating Google Calendar with UnisonOS without committing personal data or secrets to source control. It uses Google Calendar as a concrete example of a **calendar adapter** feeding the Operating Surface (dashboard + workflows).

Status: design draft; implementation should keep secrets and personal data local to the developer’s machine.

---

## 1. Goals

- Let a person use their real Google Calendar to:
  - See upcoming events as cards in the UnisonOS dashboard.
  - Generate “day plan” workflows.
  - Prepare and debrief meetings via UnisonOS.
- Keep all credentials and event data **outside** of the GitHub repo:
  - Tokens in local files or secure OS keychain.
  - Config in local `.env` / override files (gitignored).
- Treat Google Calendar as one **adapter** behind higher-level intents and cards:
  - No Google-specific assumptions in public contracts.

---

## 2. Architecture Overview

At a high level:

- A **local connector script/service** runs on the same machine as devstack (or inside a devstack container).
- The connector:
  - Handles Google OAuth and calendar API calls.
  - Maps events into Unison concepts (cards, workflows).
  - Talks to Unison via HTTP (orchestrator + context).
- Unison services:
  - Orchestrator:
    - Provides `workflow.design`, `dashboard.refresh`, and future `comms.prepare_meeting` intents.
  - Context:
    - Stores per-person dashboard state and workflows.
  - Renderer:
    - Renders cards and workflows in the dashboard.

This keeps Google-specific logic in the connector and Unison core focused on generic intents and cards.

---

## 3. Local Connector Setup (Developer Machine)

### 3.1 Directory and gitignore

Recommended layout (example):

- `local/`
  - `google_calendar_sync.py`
  - `.env` (contains Google credentials, Unison URLs, person_id)
  - `tokens/` (OAuth tokens, if not using OS keychain)

Ensure `local/` is **gitignored**, for example:

```gitignore
local/
```

This keeps secrets and event data out of the repo and GitHub.

### 3.2 Environment variables (local only)

The connector script reads configuration from the environment or `local/.env`:

- `UNISON_PERSON_ID` – e.g. `"local-user"`.
- `UNISON_ORCH_URL` – e.g. `"http://localhost:8080"`.
- `UNISON_CONTEXT_URL` – e.g. `"http://localhost:8081"`.
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` – from Google Cloud Console.
- `GOOGLE_CALENDAR_ID` – email or specific calendar ID (optional; defaults to primary).

These values live only on the developer machine.

### 3.3 OAuth tokens

OAuth setup is standard Google Calendar practice (outside Unison scope):

- Use the “installed app” flow or another appropriate flow.
- Store the token and refresh token in:
  - `local/tokens/google_calendar.json`, or
  - The OS keychain (preferred).

The connector uses that token file/keychain entry to authorize calls to the Google Calendar API.

---

## 4. Connector Responsibilities

The connector is responsible for:

1. **Authentication with Google**
   - Handle OAuth flow and token refresh.
2. **Fetching events**
   - For example:
     - Next 24–48 hours (`now` to `now + 2 days`).
     - Past few hours for “recent meetings”.
3. **Mapping events to Unison concepts**
   - Upcoming events → dashboard cards.
   - Daily schedule → workflow for `workflow.design`.
   - Meeting prep → summary cards for specific meetings.
4. **Sending data into Unison**
   - Via orchestrator skills (preferred):
     - `workflow.design` for day-plan workflows.
     - `dashboard.refresh` (or a dedicated calendar skill) for briefing cards.
   - Or via context API (`/dashboard/{person_id}`) when direct card updates are needed.

No Google-specific identifiers should leak into public contracts; they can be stored in card metadata or context KV if needed.

---

## 5. Event → Card Mapping

### 5.1 Example card shape

For each upcoming event, the connector can synthesize a card:

- Fields:
  - `id`: `calendar-{event_id}` (local stable id).
  - `type`: `"calendar.event"`.
  - `title`: event summary (e.g. `"Design review with Alex"`).
  - `body`: derived description (time, location, high-level notes).
  - `start_time`, `end_time`: ISO timestamps.
  - `location`: string (city/room/URL).
  - `tags`: e.g. `["calendar", "meeting", "p1", "project:unisonos"]`.
  - Optional: `meeting_link`, `attendees`, `project_id`.

These cards are written into dashboard state for `UNISON_PERSON_ID` and emitted via `/experiences` so they appear in the dashboard view.

### 5.2 Daily briefing card

The connector can also create a high-level briefing:

- `type`: `"summary"`.
- `title`: `"Today's meetings"`.
- `body`: short textual summary (count, first/last events).
- `tags`: `["calendar", "briefing", "planning"]`.

This card can be merged with other dashboard cards (e.g. comms, tasks).

---

## 6. Event → Workflow Mapping

The connector can use `workflow.design` to create “day plan” workflows for the person.

### 6.1 Example workflow

Workflow id: `"day-plan-{YYYYMMDD}"`, for example `day-plan-20261203`.

For each event:

- Add a step via `workflow.design`:
  - `title`: `"{start_time_short} – {summary}"` (for example, `"09:00 – Design review"`).
  - `position`: position in chronological order.

Example payload (conceptual):

```json
{
  "person_id": "local-user",
  "workflow_id": "day-plan-20261203",
  "project_id": "calendar-day-plan",
  "mode": "design",
  "changes": [
    {
      "op": "add_step",
      "title": "09:00 – Design review with Alex",
      "position": 0
    },
    {
      "op": "add_step",
      "title": "11:00 – Sync with PM team",
      "position": 1
    }
  ]
}
```

The connector calls orchestrator’s `workflow.design` skill endpoint with this payload, generating a summary card and updating the workflow document.

### 6.2 Tagging

Cards from these workflows should be tagged per the tagging guidelines:

- `["workflow", "planning", "workflow.design", "draft", "workflow:day-plan", "project:calendar-day-plan"]`.

---

## 7. Example Sync Flow (Step-by-Step)

This sequence describes a typical sync run with devstack:

1. **Devstack is running**:
   - Orchestrator, context, renderer, context-graph, etc.
2. **Connector starts**:
   - Reads `UNISON_ORCH_URL`, `UNISON_CONTEXT_URL`, `UNISON_PERSON_ID`, Google credentials.
   - Ensures `UNISON_PERSON_ID` profile exists (via `POST /profile/{person_id}`).
3. **Fetch Google Calendar events**:
   - Calls Google Calendar API (primary calendar) for the next 24–48 hours.
4. **Map events to cards & workflow steps**:
   - Build “event cards” and a `day-plan` workflow as described above.
5. **Send to Unison**:
   - Invoke `workflow.design` for the day-plan.
   - Optionally call `dashboard.refresh` or directly `POST /dashboard/{person_id}` with synthesized cards.
6. **Person opens renderer**:
   - Navigates to renderer for `person_id=local-user`.
   - Sees:
     - Day-plan workflow summary card.
     - Individual event cards in the dashboard.

All Google data stays in:

- Local memory of the connector.
- Local context DBs (on the edge).

Nothing is checked into the repo.

---

## 8. Connector Skeleton (Non-Committing Example)

The repository may include an **example skeleton** (no secrets, no Google code) showing:

- How to read `UNISON_*` env vars.
- How to call orchestrator/context.
- Placeholder `fetch_calendar_events()` implementation that is intentionally left blank, to be filled in by each developer locally.

Example path: `unison-devstack/scripts/google_calendar_sync_example.py`.

Developers can copy this file into `local/google_calendar_sync.py`, add Google API calls, and wire up their own `.env` and token handling.

---

## 9. Security and Privacy Notes

- Never commit:
  - Google client IDs/secrets.
  - OAuth token files.
  - Raw event data (JSON exports).
- Treat the connector as a local application:
  - Source can be partly shared (skeleton), but configuration and tokens are strictly local.
- Ensure that:
  - Dashboard cards and workflows derived from the calendar do not expose more personal data than the person expects.
  - Any cloud relay/sync (if added later) for context/trace data is opt-in and policy-controlled.

This pattern should be reused for other “personal data at the edge” integrations (email, task managers, notes) so that UnisonOS can be a rich Operating Surface without owning the underlying data sources.

