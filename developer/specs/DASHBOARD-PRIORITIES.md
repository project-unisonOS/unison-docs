# Context-Aware Dashboard (Display-First Experience)

Goal: when a display is attached, render a full-screen “Priorities” dashboard that adapts to the person (preferences, accessibility, policy) and shows distilled, actionable cards (schedule prep, comms triage, tasks, media) instead of traditional app views. State should persist to context so items can be resurfaced; live updates come from orchestrator/companion/VDI.

## Data Model
- `dashboard_state` (context): per-person cards + metadata; e.g.:
  - `cards`: list of `{ id, type, title, body, actions, image_url, video_url, audio_url, stream_url, tool_activity, created_at }`
  - `persona`: `{ person_id, session_id, preferences }`
  - `preferences`: `{ layout: "comms-first" | "tasks-first" | "balanced", weights: { comms, calendar, tasks }, theme, accessibility }`
  - `last_updated`
- Persisted via `GET/POST /dashboard/{person_id}` in `unison-context`; encryptable; consent/policy-enforced.

## Flows
1) Renderer loads `/dashboard/{person_id}` from context; applies `preferences` to layout (e.g., comms emphasis) and renders cards on the full-screen canvas.
2) Orchestrator/companion runs `dashboard.refresh` intent:
   - Pulls person profile (time zone, preferences) and optionally agent VDI summaries (email/calendar/web).
   - Filters sources via policy; creates priority cards; posts to renderer `/experiences` (live) and context `/dashboard/{person_id}` (persist).
3) Live updates: renderer listens to `/experiences/stream` for new cards and applies them; also writes any locally-rendered cards back to context.
4) Preference changes: verbal commands (“emphasize comms”) result in profile update (`dashboard.preferences`) in context; renderer reflows layout accordingly.

## APIs
- Context:
  - `GET /dashboard/{person_id}` → `{ dashboard_state }` (consent + role guard + optional encryption)
  - `POST /dashboard/{person_id}` → `{ ok }` to store state
- Renderer:
  - `/` full-screen canvas; pulls dashboard state; applies persona/layout; supports media (image/video/audio/stream)
  - `/experiences`/`/experiences/stream` already present; extend to write to context (future)
- Orchestrator:
  - `dashboard.refresh` intent: produce cards, post to renderer `/experiences`, persist to context `/dashboard/{person_id}`; enforce policy on sources/tools/providers.
- Agent VDI (system-only):
  - Optional connectors to email/calendar/web; output distilled cards, never raw app UI; obey policy/consent.

## Security/PII
- Require consent and role guard on `/dashboard` context endpoints; encrypt at rest (profile key).
- Redact PII in logs/traces; use mTLS/UDS where possible.
- Policy gating on data sources (e.g., VDI/email) and cloud use; enforce content/retention rules.
