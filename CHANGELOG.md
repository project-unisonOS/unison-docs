# Changelog

## 2025-02-XX
- Multimodal capability manifest flow implemented:
  - Orchestrator publishes its manifest to context-graph at startup.
  - Context-graph persists capabilities in SQLite and serves `/capabilities`.
  - Experience-renderer falls back to a default display manifest when none is available to stay ready.
- Baton propagation and tracing fixes across services (unison-common updates applied).
- Durability shutdown and manifest docs updated for context-graph.
