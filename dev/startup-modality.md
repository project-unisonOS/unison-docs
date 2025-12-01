# Startup Modality and Language Plan

Objective: provide a consistent startup experience that detects available modalities (audio/display/camera/Adapters), picks the right prompting path (conversation-only vs display + conversation), and defaults to a local multimodal model. The design must stay extensible for sign language and brain-computer interface (BCI) inputs at first contact.

## Existing Capabilities
- IO stubs: `unison-io-speech` (STT/TTS stub), `unison-io-vision` (vision stub), `unison-io-core` (event emitter).
- Surfaces: `unison-experience-renderer` (display), `unison-agent-vdi` (desktop surface), wake-word defaults in renderer.
- Routing: `unison-intent-graph` + `unison-orchestrator` for intent flow.
- Models: `unison-inference` supports local providers (Ollama) and defaults to an on-device model in devstack.

## State Machine (startup)
- `BOOT`: start core services; inference loads the default local multimodal model and reports readiness.
- `DISCOVER_CAPS`: IO layer enumerates peripherals (audio in/out, display, camera, optional sign/bci adapters) and emits `caps.report` to intent-graph/orchestrator.
- `LANG_PREF`: resolve language in order: stored profile locale (context/storage) → OS/device locale hint → multilingual greeting request.
- `PROMPT`: deliver initial prompt according to detected mode:
  - Conversation-only: play/stream TTS greeting and listen; no UI.
  - Display + conversation: render a minimal language card plus simultaneous voice prompt; keep mic open.
- `SESSION_READY`: set ASR/TTS locale, wake-word, and proceed to normal intent flow.
- Failure/timeouts: fall back to “I can hear you; tell me your language” and log missing device/locale.

## Capability Report (proposal)
Emit once at startup (and on device changes) from IO layer to intent-graph/orchestrator:
```json
{
  "event": "caps.report",
  "source": "io-core",
  "person_id": "local-user",
  "caps": {
    "audio_in": {"present": true, "confidence": 0.9},
    "audio_out": {"present": true, "confidence": 0.9},
    "display": {"present": true, "confidence": 0.8},
    "camera": {"present": false},
    "sign_adapter": {"present": false},   // placeholder for future sign service
    "bci_adapter": {"present": false},    // placeholder for future BCI adapter
    "wakeword": {"present": true},
    "locale_hint": "en-US"
  },
  "timestamp": "2025-01-01T00:00:00Z"
}
```
Store this in context (KV) for downstream services and renderer to branch UI/voice paths.

## Language Selection
- Prefer stored `profile.locale`; else OS/device locale; else multilingual greeting (short hello set).
- On mic-only: concise bilingual greeting; on display: tap-to-select card plus voice.
- Propagate locale to `unison-io-speech` (ASR/TTS hints), wake-word config, and orchestrator intent metadata.

## Local Model Usage
- Inference preloads a lightweight on-device model (e.g., Ollama qwen2.5) at `BOOT`.
- Reports readiness via health + `model.ready` event; renderer shows “Starting local model…” only if display is present.
- Cloud fallback stays policy-gated (`UNISON_ALLOW_CLOUD_FALLBACK` default false).

## Extensibility
- Sign language: treat sign recognition as another adapter surfaced in `caps.report`; when present, renderer/vision can offer a visual card and accept gesture input. Sign synthesis can be added as an output path later.
- BCI: treat as another input channel publishing intents; `caps.report` flags presence so prompts avoid unavailable channels.

## First Implementation Slice (to avoid duplication)
1. Define `caps.report` contract in docs (this file) and align with `dev/specs/event-envelope` before adding code.
2. Add capability emit in IO layer (io-core/io-vision/renderer/VDI) and intake in intent-graph/orchestrator with context cache.
3. Add language selection path (profile/locale → greeting) and mode-appropriate prompt variants.
4. Ensure inference loads a default local model and reports readiness; only add if not already present in service boot.

Status: caps.report is emitted from IO-core and IO-vision at startup, cached in intent-graph, and stored in context via orchestrator skill `caps.report`. Prompt planning skill `startup.prompt.plan` picks locale/mode and checks inference readiness.
