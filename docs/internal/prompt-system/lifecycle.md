# Prompt Lifecycle

## Startup / First Use
1. Resolve prompt root (defaults to `~/.unison/prompt`).
2. Ensure directory layout exists.
3. If missing, write default:
   - `base/unison_base.md`
   - `user/identity.json`
   - `user/priorities.json`
   - `user/schema/*.schema.json`
4. Validate JSON configs against schemas.
5. Compile and write `compiled/active_system_prompt.md`.

## Runtime Injection
The orchestrator prepends the compiled prompt as the first `system` message for each inference request.

## Hot Reload
Hot reload is “next turn by default”:
- Each compilation compares a stable fingerprint of the filesystem layers.
- If files changed (including direct user edits), the prompt is recompiled and written.
- A user-requested “apply now” corresponds to forcing recompile on the next tool call, or restarting a model runner if needed.

