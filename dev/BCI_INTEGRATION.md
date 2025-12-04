# UnisonOS BCI Integration Design

BCI is a first-class input modality alongside keyboard, pointer, voice, gaze, and touch. This design anchors on current UnisonOS services (FastAPI microservices, EventEnvelope contracts, consent/policy/auth guards, and the intent-graph -> orchestrator pipeline).

## Current Baseline
- Inputs: `unison-io-speech`, `unison-io-vision`, `unison-io-core`, `unison-io-bci` emit EventEnvelopes to `unison-orchestrator` (or via `unison-intent-graph`); capability reports already carry a `bci_adapter` flag.
- Routing: `unison-intent-graph` normalizes/forwards; `unison-orchestrator` enforces auth/consent/policy, calls inference/context/storage, and returns responses via renderer/VDI.
- Security/identity: JWT + RBAC (`unison-auth`); consent grants (`unison-consent`); policy/audit (`unison-policy`); profiles/KV (`unison-context`, encrypted at rest when key set); vault/working memory (`unison-storage`).
- Contracts: EventEnvelope v2 (`dev/specs/schemas/event-envelope.md`), `caps.report` (`dev/startup-modality.md`); shared logging/tracing via `unison-common`.

## Goals
- Device-agnostic, privacy-first; raw neural data stays local unless explicitly opted in.
- Separate raw streaming from decoded intents; typical apps consume intents, not raw EEG.
- Pluggable decoders and device adapters; stable upstream interface to intent-graph/orchestrator.
- Fusion-first: combine BCI with gaze/voice/touch; confidence/latency-aware.
- Per-user profiles/calibration stored securely; multi-user device sharing supported.

## Architecture (mapped to repos)

```
[BCI HW] --(BLE/USB/LSL/SDK)--> [Device Interface Layer]
                                   |
                             [Neural Input Subsystem]
                                   |
                             [BCI Service Daemon]
             +---------------------+----------------------+
             |                     |                      |
      [Raw Stream API]      [Decoder Plugins]     [HID Mapper]
                                                        |
                                          [Fusion & Intent Engine]
                                          (in unison-intent-graph)
                                                        |
                                  [System Actions / Orchestrator / Apps]
             |            |             |                |
   [Profiles & Calib] [Secure Storage] [Policy/Consent] [Adaptive UI Controller]
```

### Components
- **Device Interface Layer (new, `unison-io-bci`)**: LSL discovery/subscription, BLE GATT, USB/serial, vendor SDK adapters; normalize samples into typed channels with timestamps and clock info; BrainFlow-like drivers; diagnostics.
- **Neural Input Subsystem**: shared-memory ring buffers, zero-copy readers, optional mmap recording; LSL clock sync or NTP drift compensation; optional RT priority for latency-sensitive decoders.
- **BCI Service Daemon (`unison-io-bci`)**: runs decoder plugins; APIs `POST /bci/devices/attach`, `GET /bci/devices`, `WS /bci/raw` (scoped), `WS /bci/intents`, `POST /bci/hid-map`; emits `caps.report` with `bci_adapter` metadata.
- **Decoder plugins**: subscribe to channel sets/sampling rates; emit `BciIntent` with confidence/latency. Built-ins: mock SSVEP/SMR -> discrete intents, continuous pointer delta, attention/fatigue metrics. Vendor bridges: Emotiv/Neuralink adapters emitting normalized outputs.
- **Fusion & Intent Engine (`unison-intent-graph`)**: fuses BCI with gaze/voice/touch; continuous fusion (pointer smoothing) and discrete fusion (first-wins or BCI confirm); routes `bci.intent` or `input.fused` envelopes to orchestrator; conflict resolution via confidence/freshness/context/profile.
- **Profiles and calibration**: per-user BCI profile in `unison-context` (`/profile/{person_id}`) with devices, control scheme, thresholds, decoder params, mode, fatigue prompts; calibration/model artifacts stored in `unison-storage` vault (encrypted) with pointers from profile; device pairing secrets stay in vault.
- **Security/privacy**: consent scopes `bci.raw.read`, `bci.intent.subscribe`, `bci.device.pair`, `bci.profile.manage`, `bci.export`, `bci.hid.map`; enforced via auth/consent/policy; raw data local-first; TLS and encrypted vault storage; cloud sync opt-in only.
- **Adaptive UI Controller (`unison-experience-renderer`/VDI)**: BCI Control Mode (larger targets, scanning), mode indicators, confidence-driven highlights, undo; uses fusion confidence + fatigue metrics to adjust pacing.

### MVP status (current)
- Service: `unison-io-bci` with LSL ingest, BLE/serial detection + streaming stubs, per-device decoder selection (window/RMS), raw snapshots, XDF/EDF export, HID mapping, auth/consent middleware, and capability reports.
- Scopes: `bci.intent.subscribe`, `bci.raw.read`, `bci.export`, `bci.hid.map`, `bci.device.pair`, `bci.profile.manage`.
- Endpoints: health/ready/metrics, `/bci/devices{attach,get}`, `/bci/decoders`, `/bci/intents` (WS), `/bci/raw` (WS, stream/limit params), `/bci/export` (XDF/EDF), `/bci/hid-map`.
- Device profiles: seeded Muse-S/Muse-2/OpenBCI profiles with notify UUIDs/parsers/channel labels/sample rates and decoder defaults; CSV/notify parsers feed samples into the decoder pipeline.

## Protocols and SDK Paths
- **LSL**: discovery + subscribe; prompt to attach when EEG stream appears; use LSL time sync.
- **BLE GATT**: EEG profile with battery/sample/channel map; known device presets.
- **USB/Serial**: CSV/binary via BrainFlow-like drivers.
- **Vendor adapters**: “Neural Control API” wrappers for proprietary SDKs.
- **HID emulation**: optional userspace virtual HID; default devstack path is EventEnvelopes only.
- **Recording/export**: XDF/EDF export gated by policy/consent.

## Data Models
- **BCI intent EventEnvelope payload**
  ```json
  {
    "event_type": "bci.intent",
    "intent": {
      "type": "input.command",
      "command": "click",
      "axes": {"dx": 0.0, "dy": 0.0},
      "mode": "discrete",
      "confidence": 0.83,
      "latency_ms": 45,
      "decoder": {"name": "ssvep_v1", "version": "1.0.0"}
    },
    "person": {"id": "person-123", "session_id": "sess-abc"},
    "context": {"interaction": "navigation", "fusion_state": {"gaze_target": "btn-1"}},
    "auth_scope": "bci.intent.subscribe",
    "metadata": {"source_stream": "lsl:device-123"}
  }
  ```
- **BCI profile (stored in `unison-context`)**
  ```json
  {
    "person_id": "person-123",
    "bci": {
      "devices": [{"id": "lsl:device-123", "type": "eeg", "paired_at": "..."}],
      "control_scheme": "gaze_plus_bci_click",
      "intents": {"confirm": "ssvep_A", "cancel": "ssvep_B"},
      "thresholds": {"attention_min": 0.4, "click_confidence": 0.7},
      "decoder_params": {"model": "ssvep_v1", "calibration_id": "cal-789"},
      "hid_maps": {"confirm": "KEY_ENTER", "cancel": "KEY_ESC"},
      "fatigue_prompts": true,
      "privacy": {"allow_raw_export": false, "cloud_sync": false}
    }
  }
  ```

## Key Flows
- Hybrid gaze + BCI click: `unison-io-bci` ingests EEG -> decoder emits `bci.intent:click` -> fusion combines with gaze target -> orchestrator receives `input.fused`; renderer highlights/executes on confidence threshold.
- Text entry: on-screen keyboard; voice generates candidates; BCI selects/advances; undo via BCI gesture.
- Assistant invoke: profile maps BCI command to assistant; intent-graph routes; renderer shows mode indicator.
- Raw access: `WS /bci/raw` with `bci.raw.read` scope; export requires `bci.export` and policy confirmation.

## Privacy, Security, Safety
- Local-first processing; cloud sync opt-in only.
- Encryption: vault storage for calibration/models; TLS between services; profile encryption key via `UNISON_CONTEXT_PROFILE_KEY`.
- Permissions: scopes enforced in auth/consent/policy; clear user prompts (“Allow this app to use BCI input?”); audit all BCI access.
- Device pairing: authenticated, bonded connections; vendor tokens in vault; block unsolicited attachments.
- Safety: renderer guard against high-frequency flicker when BCI active; validate BCI intents to prevent spoofing.
- Transparency: renderer indicator + access log (“App X received BCI intents at 10:03”); easy pause toggle.

## MVP Plan (Phase 1)
1) `unison-io-bci`: FastAPI skeleton; LSL ingest; mock decoder to emit `bci.intent`; HID mapping stub; caps.report with `bci_adapter`.
2) `unison-intent-graph`: `/bci/intent` intake + fusion module combining BCI/gaze/voice/touch; emit `input.fused`; tests.
3) `unison-context`/`unison-storage`: BCI profile block; calibration/model pointers in vault.
4) `unison-experience-renderer`: BCI Control Mode, indicator, confidence-driven highlights, undo.
5) Devstack: add `unison-io-bci`; sample LSL config; quickstart doc updates.
6) Permissions/policy: scopes in auth/consent; policy templates to gate raw/export/device-pair/HID map.
7) Diagnostics: latency/jitter counters; replay harness for regression tests.
