# Dashboard Card Types and Flow

Goal: The renderer shows a full-screen priorities canvas using flexible cards. Cards may display model-generated content (guides, summaries, tool results) or embedded media (e.g., YouTube video) sourced via tools. Each card type includes enough metadata for policy/consent, layout, and per-person preferences.

## Card Types
- `media.embed`: external media embedded inline (video/audio/image/stream). Fields: `title`, `body`, `video_url` (embed-safe), `image_url`, `audio_url`, `source` (e.g., youtube), `actions`.
- `guide`: model-generated step-by-step instructions. Fields: `title`, `body`, `steps` (array), `diagram_url` (optional image), `actions`.
- `tool_result`: distilled output of a tool call (e.g., search results). Fields: `title`, `body`, `items` (list of {title,url,summary}), `actions`.
- `summary`: brief recap/briefing. Fields: `title`, `body`.
- `comms` / `tasks`: prioritized responses/actions. Fields: `title`, `body`, `actions` (e.g., suggested replies or run buttons).

## Flow Example (“replace my sink faucet”)
1) User asks orchestrator → companion/inference suggests a tool call `video.search`.
2) Tool returns a YouTube URL; orchestrator builds:
   - `media.embed` card with `video_url` (embed-safe), title/description.
   - `guide` card with steps and optional diagram (model-generated).
3) Orchestrator persists cards to context `/dashboard/{person_id}` and emits to renderer `/experiences`.
4) Renderer renders cards inline: embedded video in one card; step-by-step guide in another.

## APIs and Persistence
- Context: `GET/POST /dashboard/{person_id}` stores cards + preferences; encryptable; consent/role gated.
- Renderer: loads dashboard from context; listens to `/experiences/stream` for new cards; can persist experiences to context when a person_id is present.
- Orchestrator: `dashboard.refresh` builds cards, merges with existing dashboard, persists to context, and emits to renderer.

## Policy and Safety
- External media: allowlist/sanitize embed URLs (e.g., YouTube embed URL only), respect policy on allowed sources.
- All cards: include `person_id`, `ts`, and `tool_activity` when applicable; avoid PII in logs; apply consent/policy on source/tool use.
