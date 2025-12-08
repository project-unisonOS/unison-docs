# Storage Architecture Unification (Postgres + Neo4j + Redis)

## 1. Overview & Goals
- Unify persistence across UnisonOS: Postgres as the relational backbone, Neo4j for graph, Redis for ephemeral/cache, and `unison-storage` as the canonical persistence gateway (memory, vault, audit, objects).
- Remove SQLite from production paths; normalize service access through storage/graph APIs instead of ad-hoc DB usage.
- Production posture: HA-ready configs, migrations, backups, observability, and clear data classification/retention.

## 2. Current State (as observed)
- Devstack: single Postgres (`postgres`), single Redis (`redis`). Storage service depends on both; others largely ignore Postgres.
- `unison-storage`: uses SQLite file (`/data/store.db`) despite README mentioning `STORAGE_DATABASE_URL`. Provides `/memory`, `/vault`, `/audit`, `/kv`, `/telemetry`.
- `unison-context`: uses SQLite (`/tmp/unison-context-conversation.db`) for profiles, dashboard, and conversation sessions; encrypts profiles with Fernet key; uses `unison-storage` KV for some context.
- `unison-context-graph`: uses SQLite replay store; no Neo4j; no Postgres.
- `unison-intent-graph`: stub FastAPI; no DB; caches are in-memory only (README mentions Redis but not wired in code).
- `unison-auth`: uses Redis for tokens/blacklists (per README); no direct Postgres observed.
- `unison-orchestrator`, `unison-policy`, `unison-consent`, `unison-inference`, `unison-payments`: assume storage/context APIs; no direct DB bindings in devstack compose.
- Devstack networking: single default network (non-segmented) in `docker-compose.yml`; segmented version exists in `docker-compose.security.yml` but not wired for new graph DB.

## 3. Target Architecture
- Postgres: single cluster (HA in prod) as relational backbone. Clients: `unison-storage` (memory/vault/audit/objects metadata), `unison-context` (profiles/kv/dashboard, or via storage), transitional auth/policy tables if needed.
- Neo4j: graph backend for `unison-context-graph` and `unison-intent-graph`; stores relationships only (no secrets/large blobs). References storage IDs for content.
- Redis: ephemeral/cache layer (tokens/blacklists in auth; routing caches in intent/context graph; UI/session).
- `unison-storage`: canonical API for memory (TTL), vault (encrypted), audit, objects. Other services use HTTP APIs, not direct DB, except transitional context/auth tables.
- API boundaries preserved: orchestrator talks to context/context-graph/intent-graph/storage/policy; graph services expose graph queries over HTTP; storage remains gateway for sensitive/long-term data.

## 4. Data Classification & Security
- Secrets (creds, tokens, API keys): stored only in storage vault (Postgres encrypted-at-rest + app-layer encryption); never in Neo4j/Redis; referenced by vault IDs.
- PII (names, emails, preferences): stored in Postgres (context/storage); encryption-at-rest + optional field-level encryption; access via service auth + policy/consent.
- Behavioral/log/audit: audit in storage Postgres; graph edges (non-sensitive IDs + timestamps) in Neo4j; avoid PII in graph properties (use IDs).
- Content/files (prompts, transcripts, downloads): objects via storage; metadata in Postgres; graph references by storage IDs only.
- Ephemeral: Redis (tokens, caches) + storage `/memory` with TTL; default TTLs enforced per keyspace.

## 5. Schema & Model Design (to-be)
- Postgres (storage schema):
  - `memory_entries(session_id, person_id, payload, ttl, expires_at, created_at, updated_at, idx)` with indexes on `person_id`, `expires_at`.
  - `vault_entries(key_id, cipher_text, metadata, created_at, updated_at, version)`.
  - `audit_events(id, person_id, actor, action, target, decision_id, status, created_at, payload_json)`.
  - `objects(id, person_id, content_type, size_bytes, storage_backend, path, created_at, checksum)`.
  - Context tables (if direct): `person_profiles`, `dashboard_state`, `conversation_sessions` (aligned schema) behind ORM/migrations.
- Neo4j:
  - Nodes: `Person`, `Device`, `Agent`, `Service`, `Skill`, `Resource`, `Workspace`, `Session`, `IntentInstance`, `PolicyGroup`.
  - Relationships: `OWNS`, `MEMBER_OF`, `HAS_RESOURCE`, `HANDLES`, `PRODUCED`, `ON_DEVICE`, `FOR_PERSON`, `ABOUT`, `ALLOWED_BY`, `REQUESTED_BY`, `TRIGGERED`.
  - Properties: IDs (`person_id`, `resource_id`, `agent_id`, `intent_id`, `storage_id`), timestamps, types, confidence scores; no secrets/PII strings.
- Redis:
  - Keyspaces: `auth:tokens:*` (TTL), `intent:cache:*` (short TTL), `context:cache:*`, `graph:hot:*` for recent traversals; consistent TTLs per use case.

## 6. Service-Level Integration (to-be)
- `unison-storage`: moves to Postgres-backed schemas; optional object backend (local FS vs S3-compatible) via `STORAGE_OBJECT_BACKEND`. Exposes `/healthz`, `/readyz`, metrics.
- `unison-context`: use Postgres via `UNISON_CONTEXT_DATABASE_URL`; migrate data from SQLite; long-term aim to route persistence via storage APIs for KV/profile blobs; keep encryption for profiles.
- `unison-context-graph`: connect to Neo4j via `GRAPH_DB_URI`, `GRAPH_DB_USER`, `GRAPH_DB_PASSWORD`; maintain Redis cache; expose graph CRUD/query endpoints.
- `unison-intent-graph`: similarly connect to Neo4j; store intent instances and routing edges; Redis cache for hot paths.
- `unison-auth/policy/consent`: continue Redis for tokens/blacklists; audit/consent logs via storage audit; any relational tables move to Postgres through storage where feasible.

## 7. Migration & Compatibility
- Context: add Postgres migrations (Alembic) and migration script from SQLite → Postgres (export/import); set devstack to Postgres by default; keep SQLite only for local dev override.
- Storage: migrate from SQLite to Postgres; provide migration path (export/import) and default `STORAGE_DATABASE_URL` in devstack.
- Graph: introduce Neo4j alongside existing Redis caches; no breaking API initially—add health gating and optional use, then switch queries to Neo4j once implemented.
- Backwards compatibility: keep current HTTP APIs; add new graph endpoints alongside existing stubs; phase-in Postgres/Neo4j configs via env defaults.

## 8. Observability & Operations
- Metrics: DB query latency/error rates; Redis hit/miss; Neo4j query timings/node/relationship counts; cache eviction metrics.
- Logging: structured JSON, avoid sensitive payloads; include request IDs and person_id only when needed.
- Backup/Restore: Postgres dumps or PITR; Neo4j backup (volume snapshots or `neo4j-admin`); object store backups; secrets in vault with KMS-managed keys.

## 9. Phased Implementation Plan
### Phase 0 – Discovery (done here)
- Confirmed: storage/context/context-graph use SQLite; intent-graph is stub; Redis/Postgres exist but mostly unused by these services.

### Phase 1 – Neo4j Intro (devstack)
- Add Neo4j service to devstack (internal network only, volume for data); env vars `GRAPH_DB_URI`, `GRAPH_DB_USER`, `GRAPH_DB_PASSWORD`.
- Add driver config + health/ready checks in context-graph and intent-graph; leave logic stubbed but connected.

### Phase 2 – Postgres for unison-context
- Add Postgres support (`UNISON_CONTEXT_DATABASE_URL`), ORM models, Alembic migrations.
- Migration script from SQLite to Postgres for existing data; enforce Postgres in non-dev.
- Update devstack to point context at Postgres (shared cluster).

### Phase 3 – Neo4j graph modeling
- Implement Neo4j-backed node/edge operations in context-graph; expose traversal/query endpoints.
- Implement intent-instance graph in intent-graph; use Redis as cache; reference storage IDs, not blobs.
- Add unit/integration tests for graph CRUD/traversals.

### Phase 4 – Harden unison-storage
- Move to Postgres storage backend with migrations; finalize schemas for memory/vault/audit/objects.
- Optional object backend config; enforce encryption and TTLs; add metrics.

### Phase 5 – Cleanup/Enforcement
- Remove SQLite from prod configs; CI guard rails (no SQLite URLs in prod builds).
- Update docs/diagrams; verify services only access DBs through storage/graph as designed.
