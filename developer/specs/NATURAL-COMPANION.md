# Natural Multimodal Companion (On-Device First-Use Experience)

Goal: power-on yields a natural, multimodal companion experience that runs locally when possible, greets the person conversationally, and proactively calls tools (via MCP or internal skills) to assist. When a display is connected, visuals are shown through the renderer; otherwise speech-only responses are used. Cloud inference is a policy-gated fallback.

## Scope (Phase 1)
- On-device default inference (vision-capable + small text model) with readiness gating and cloud fallback when allowed; default to a Qwen-based local model (via Ollama) but keep plug-and-play replacements via env vars/presets.
- Conversational session manager in `unison-orchestrator` that drives the loop: ingest audio/vision inputs, call inference with tool schema, execute model-emitted tool calls, persist context, and emit text+image responses.
- Tool/MCP bridge: register tool capabilities, persist them in `unison-context-graph`, and route tool calls with `unison-policy` cost/safety checks.
- Always-on renderer view showing chat, tool activity, and images; speech-only fallback when no display is attached.
- Devstack E2E: boot → greeting → one proactive tool call (e.g., system info/calendar) → rendered response; tracing/baton continuity validated.

## Actors and Responsibilities
- `unison-io-speech`: stream mic audio, perform STT (stub or provider), emit EventEnvelopes with trace/baton to orchestrator; accept TTS intents to speak replies.
- `unison-io-vision`: stream frame captures/descriptors with trace/baton; optional wake-on-presence signal.
- `unison-orchestrator`: Companion Session Manager (CSM) owns dialog state, calls `unison-inference`, executes tool calls (MCP/in-process skills), persists memory to `unison-context`, publishes capabilities to `unison-context-graph`, emits replies to renderer and IO-speech, enforces policy.
- `unison-inference`: hosts on-device multimodal model (Ollama vision/text; default Qwen) with policy-aware cloud fallback; supports tool-call JSON outputs and structured responses.
- `unison-context`: short- and long-term memory (turn transcripts, summaries, tool outcomes).
- `unison-context-graph`: stores capabilities/tool manifests and multimodal manifests for renderer fallback/readiness.
- `unison-experience-renderer`: always-on chat/visual companion view; consumes capabilities API and renderer manifest fallback; shows tool activity.
- `unison-shell` (Dev Mode): provides MCP host with local tools (filesystem/system info) surfaced into the registry.
- `unison-policy`: approves tool calls and cloud inference usage.
- Observability: `unison-common` tracing headers/baggage + batons; spans cover IO → inference → tool calls → renderer/TTS.
- Emission endpoints (optional env-driven): set `UNISON_RENDERER_URL=http://renderer:8085` and `UNISON_IO_SPEECH_URL=http://io-speech:8084` for direct display/TTS emits from the companion loop; otherwise responses are returned to the caller.

## Session Flow (Happy Path)
1) Presence/speech/vision input arrives (EventEnvelope with trace/baton) → orchestrator CSM.
2) CSM loads person profile and recent context from `unison-context` (short-term turns + summary) and capabilities from `unison-context-graph`.
3) CSM calls `unison-inference` with:
   - Messages (dialog history/situation)
   - Tools (from MCP registry + internal skills) and tool-choice hints based on context
   - Images/frames as attachments
   - Response preference (text, images allowed, function/tool call mode)
4) Inference returns either direct reply or tool_calls:
   - If tool_calls: CSM runs them (MCP or internal skill), respecting `unison-policy` for cost/risk; feeds observations back to inference for final answer.
5) CSM emits responses:
   - `display` intent to renderer (text, images, tool activity metadata)
   - `speak` intent to IO-speech (TTS text)
6) CSM persists turn, tool outcomes, and updated summary to `unison-context`; updates capability freshness in `unison-context-graph`.

## API Contracts

### Inference (`unison-inference`)
- `POST /inference/request`
  - Request (representative):
    ```json
    {
      "intent": "companion.turn",
      "person_id": "local-user",
      "session_id": "uuid",
      "messages": [
        {"role": "system", "content": "You are the Unison companion..."},
        {"role": "user", "content": "What's on my calendar today?"},
        {"role": "assistant", "content": "Let me check that.", "name": "companion"}
      ],
      "attachments": [
        {"type": "image", "format": "png", "data": "base64...", "label": "live_frame"}
      ],
      "tools": [
        {
          "type": "function",
          "name": "calendar.list_today",
          "description": "List today's events",
          "parameters": {"type": "object", "properties": {}, "required": []}
        }
      ],
      "tool_choice": "auto",
      "response_format": "text-and-tools",
      "provider": "ollama",
      "model": "llama3.2-vision",
      "max_tokens": 512,
      "temperature": 0.4
    }
    ```
  - Response (representative):
    ```json
    {
      "ok": true,
      "provider": "ollama",
      "model": "llama3.2-vision",
      "messages": [
        {"role": "assistant", "content": "I can check your calendar now.", "tool_calls": [
          {
            "id": "toolcall-1",
            "type": "function",
            "function": {"name": "calendar.list_today", "arguments": "{}"}
          }
        ]}
      ],
      "usage": {"prompt_tokens": 1200, "completion_tokens": 80}
    }
    ```
- Additions needed:
  - Model presets for on-device multimodal and small text-only models.
  - Readiness endpoint already present; extend to report on-device model availability.
  - Tool-call fidelity: ensure arguments are valid JSON, align with OpenAI tool-call schema for MCP compatibility.
  - Cloud fallback: when policy-approved, allow provider/model override; include `policy_decision_id` in response when fallback taken.

### Orchestrator (`unison-orchestrator`)
- Event intents (using existing `/event` endpoint with baton/tracing):
  - `speech.input`: `{ "audio_ref": "...", "text": "transcript", "person_id": "...", "session_id": "...", "latency_ms": ... }`
  - `vision.frame`: `{ "image_ref"|"image_b64": "...", "person_id": "...", "session_id": "...", "metadata": {"ts": ...} }`
  - `companion.reply` (outbound to IO/renderer): `{ "text": "...", "images": [...], "tool_activity": [...], "person_id": "...", "session_id": "..." }`
- Companion Session Manager responsibilities:
  - Maintain per-person session store (active dialog, summary) backed by `unison-context`.
  - Pull capabilities/tools from `unison-context-graph` (including MCP-hosted tools and orchestrator skills).
  - Construct inference payload (messages, attachments, tools, tool-choice hints).
  - Execute tool calls:
    - MCP: call MCP client with descriptor `name`, `arguments`; map responses into inference follow-ups.
    - Internal skills: invoke existing skill registry functions.
    - Policy: call `unison-policy` before high-cost or cloud inference/tool calls.
  - Emit intents:
    - To renderer: `display` with text, images, tool activity; respect manifest fallback already in renderer.
    - To IO-speech: `speak` with TTS text; include `voice` options when available.
  - Persist: turns + tool results → `unison-context` (short-term rolling window + periodic summary); capability freshness → `unison-context-graph`.
- Tool Registry (shared component):
  - Sources: MCP servers (e.g., `unison-shell` host tools), orchestrator skill registry, static system tools (time, system info).
  - Format: align with context-graph capabilities schema; store `name`, `description`, JSON schema, scope, cost/risk hints, last-seen MCP server.
  - Publication: POST to `unison-context-graph` `/capabilities`; CSM consumes from there.

## Data and Storage
- `unison-context`: KV for turn transcripts and summaries (`person_id:session_id:turns`), plus embeddings/hooks later.
- `unison-context-graph`: capabilities table already exists; add companion capability type and optionally link to manifest entries.
- Renderer manifest fallback remains as documented; companion publishes current display manifest (chat + gallery layout) when available.

## Observability and Safety
- Reuse `unison-common` tracing and baton middleware end-to-end (IO → orchestrator → inference → tools → renderer/TTS).
- Log tool-call decisions, policy verdicts, and model fallback decisions.
- Metrics: counts for on-device vs cloud inference, tool-call success/failure, proactive tool usage.

## Devstack Validation Scenario
1) Start devstack with `DISABLE_AUTH_FOR_TESTS=true` and local Ollama model pulled.
2) On boot, CSM issues greeting via inference; renderer shows chat bubble; IO-speech speaks it.
3) User says “What’s on my calendar?” → model emits `calendar.list_today` tool call (MCP from `unison-shell`); orchestrator executes, returns observation, model replies with summary and maybe image (calendar card).
4) Verify: traces show baton continuity; context-graph has capability entries; renderer ready even without a display (fallback manifest); cloud fallback blocked unless policy allows. For direct emits, set `UNISON_RENDERER_URL=http://renderer:8085` and `UNISON_IO_SPEECH_URL=http://io-speech:8084` in orchestrator env.

### Devstack env hints
- Orchestrator: `UNISON_MCP_REGISTRY_URL=http://shell:3000/mcp/registry`, `UNISON_RENDERER_URL=http://renderer:8085`, `UNISON_IO_SPEECH_URL=http://io-speech:8084`.
- Inference: pull Qwen via Ollama: `ollama pull qwen2.5` (and vision variant if needed), set `UNISON_INFERENCE_MODEL=qwen2.5`, `UNISON_INFERENCE_MODEL_MULTIMODAL=qwen2.5`.
- Context: conversation endpoints now available at `/conversation/{person_id}/{session_id}` and `/conversation/health` (in-memory for now).

## Implementation Notes and Priorities
1) `unison-inference`: add on-device multimodal preset, readiness, tool-call schema fidelity, policy-aware cloud fallback.
2) `unison-orchestrator`: implement Companion Session Manager + Tool Registry, MCP bridge, policy hooks, response emission to renderer/IO-speech.
3) `unison-context-graph`: ensure capability API supports MCP tool descriptors; expose per-person queries if needed.
4) `unison-io-speech` / `unison-io-vision`: stream inputs with trace/baton headers; enrich payloads for CSM.
5) `unison-experience-renderer`: companion UI (chat + tool activity + images) aligned with manifest fallback behavior.
