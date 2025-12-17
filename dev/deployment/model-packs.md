# Model Packs (Alpha 0.5.0)

UnisonOS alpha releases keep base artifacts lean and distribute large model weights separately as **Model Packs**.

## What models are expected by default?

For `v0.5.0-alpha.N`, the default evaluation profile is:

- **Interaction model (LLM)**: **Qwen** (via Ollama; default is `qwen2.5:1.5b`)
- **Planner model**: **Qwen** (often the same family; default is `qwen2.5:1.5b`)
- **Speech models**:
  - ASR: faster-whisper (via a model pack installed into `UNISON_MODEL_DIR`)
  - TTS: Piper (via a model pack installed into `UNISON_MODEL_DIR`)

Some alpha profiles may also add optional models (larger LLMs, multimodal models) depending on hardware.

## Bundled vs downloaded

Alpha uses a hybrid approach:

- **Ollama models (Qwen)** are typically **pulled on demand** (online) unless you pre-load them offline.
- **ASR/TTS weights** are distributed as **versioned model packs** (`.tgz` + `models.manifest.json`) that can be installed offline.

## Where models live

- Default model directory: `/var/lib/unison/models`
- Override: `UNISON_MODEL_DIR`

## How to switch model packs

Model pack selection is an explicit profile plus required packs:

- Profile selector: `UNISON_MODEL_PACK_PROFILE` (default: `alpha/default`)
- Required pack gate: `UNISON_MODEL_PACK_REQUIRED=pack_id@version` (enforced by the orchestrator Phase 1 runtime)

Profiles are documented in `unison-platform/model-packs/alpha/`:
- `alpha/default` — recommended evaluator profile (Qwen + speech pack required)
- `alpha/light` — smaller footprint (text-first)
- `alpha/full` — larger footprint (bigger models where supported)

## Install model packs (offline/online)

The model pack manager is `unison-models` (from `unison-common`):

- Offline: `unison-models install --path <path/to/model-pack.tgz>`
- Online: `unison-models install --fetch <url-or-alias>`

If a required pack is missing, the system must surface a clear recovery prompt with these commands.

## Troubleshooting

- **“Required models are not installed”**: install the required pack, then restart the stack/inference path.
- **Ollama not available**: install Ollama (or configure an accessible `OLLAMA_BASE_URL`) and pull the requested Qwen model(s).
- **Disk pressure**: switch to `alpha/light` and remove unused packs/models from `UNISON_MODEL_DIR`.

