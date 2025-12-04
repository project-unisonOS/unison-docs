# BCI Permissions and Consent Scopes

BCI data is sensitive. These scopes, enforced through `unison-auth`, `unison-consent`, and `unison-policy`, gate access to neural streams, decoded intents, and device control.

## Scopes
- `bci.raw.read` — Subscribe to raw neural data (LSL/buffer mirrors). Rare; research/diagnostics only.
- `bci.intent.subscribe` — Receive decoded BCI intents/events (default for apps using neural control).
- `bci.device.pair` — Pair or attach BCI hardware (BLE/USB/LSL/SDK) and manage drivers.
- `bci.profile.manage` — Read/write per-user BCI profile (control schemes, thresholds, model pointers).
- `bci.export` — Export neural recordings (XDF/EDF) or calibration sessions.
- `bci.hid.map` — Configure virtual HID mappings from BCI intents.

## Consent and policy
- Consent grants must enumerate requested scopes; default TTL should be short for raw/export actions.
- `unison-policy` should log all BCI access decisions and enforce allow-lists for raw/export endpoints.
- Pairing (`bci.device.pair`) should require authenticated person context and, when possible, local approval.
- Raw and export paths are opt-in and off by default; model/profile cloud sync must be explicitly opted in.

## Service expectations
- **BCI service (`unison-io-bci`)**: enforce scopes on `WS /bci/raw`, `WS /bci/intents`, device attach/pair, export, and HID map endpoints; `/bci/decoders` is read-only.
- **Intent graph**: accept `bci.intent` envelopes and propagate `auth_scope` for downstream checks; fuse with other modalities to `input.fused`.
- **Orchestrator/policy**: treat `bci.intent` and `input.fused` like other input, applying policy + consent before acting.
- **Renderer/UX**: display active BCI indicator and access log summary when BCI scopes are in use.
