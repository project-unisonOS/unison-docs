# UnisonOS Prompt System (Internal)

UnisonOS owns the assistant’s system prompt and injects a compiled prompt at runtime. Models are treated as stateless with respect to values, personality, and priorities.

This directory is the internal, developer-facing source of truth for:
- The prompt layer model and filesystem layout
- The compiler/validator/update pipeline
- Trust boundaries and security constraints
- Hot reload behavior

## Quick Links
- Default system prompt: `unison-docs/docs/internal/prompt-system/default-system-prompt.md`
- Architecture: `unison-docs/docs/internal/prompt-system/architecture.md`
- Lifecycle: `unison-docs/docs/internal/prompt-system/lifecycle.md`
- Update flow: `unison-docs/docs/internal/prompt-system/update-flow.md`
- Schemas: `unison-docs/docs/internal/prompt-system/schemas.md`
- Threats & mitigations: `unison-docs/docs/internal/prompt-system/security.md`
