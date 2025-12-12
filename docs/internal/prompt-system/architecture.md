# Architecture Overview

## Goals
- **User-owned**: identity and priorities live on the user’s filesystem, not inside the model.
- **Model-agnostic**: any LLM backend can be swapped without losing personality/priorities.
- **Deterministic**: prompt assembly is stable and reproducible given the same inputs.
- **Controlled updates**: the model can only *propose* changes; a validator applies them.
- **Anti-sycophancy**: disagreement, tradeoffs, and factual correction are explicit requirements.
- **Hot reload**: config edits take effect on the next turn by default.

## Components

### `unison-common` (library)
Primary implementation lives in `unison-common/src/unison_common/prompt/`:
- Reads prompt layers from a configured root (defaults to `~/.unison/prompt`)
- Validates `identity.json` and `priorities.json` against JSON Schemas
- Compiles a single `active_system_prompt.md`
- Maintains snapshots and an append-only audit log
- Provides JSON Patch validation/apply helpers

### `unison-orchestrator` (runtime injection + tools)
`unison-orchestrator/src/orchestrator/companion.py`:
- Injects the compiled prompt as the first `system` message for each turn
- Exposes controlled tools:
  - `propose_prompt_update`
  - `apply_prompt_update`
  - `rollback_prompt_update`

## Prompt Layers
1. **Unison Base Policy (immutable)**: safety, privacy, tool boundaries, non-overrideable constraints.
2. **User Identity & Values (persistent)**: stable preferences, accessibility, anti-sycophancy config.
3. **User Priorities & Directives (mutable)**: current goals, risk tolerance, verbosity, do/don’t rules.
4. **Session Context (ephemeral)**: current task, environment hints, time-bounded intent.

## Deterministic Assembly
The compiler outputs a single Markdown document with sections for each layer plus explicit anti-sycophancy requirements. Given identical layer inputs and session context, output is identical.

