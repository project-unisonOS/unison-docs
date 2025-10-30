# Unison Context Service

## Purpose

Per-person, tiered memory for personalization and continuity.

## Tiers (A/B/C)

- **A – Private**
  - Sealed, encrypted; never exported.
- **B – Profile**
  - Portable, exportable, sharable across devices.
- **C – Session**
  - Ephemeral working memory.

## Namespacing

- All keys are scoped by `person_id` and must start with `{person_id}:`.
- Tier B profile keys must include the segment `:profile:`.

Non‑Negotiable:

- Tier A is never exported.
- Cross‑person access must be routed through Policy.

---

## HTTP API (MVP)

### POST /kv/put

- Stores multiple key/value pairs with tier enforcement.
- Body:

```json
{
  "person_id": "local-user",
  "tier": "B",
  "items": {
    "local-user:profile:language": "en",
    "local-user:profile:onboarding_complete": true
  }
}
```

- Validation:
  - `person_id` non-empty.
  - `tier` ∈ {"A","B","C"}.
  - Keys start with `{person_id}:`.
  - If `tier` = "B", keys must contain `:profile:`.

### POST /kv/get

- Fetches a set of keys.
- Body:

```json
{ "keys": ["local-user:profile:language"] }
```

- Response:

```json
{ "ok": true, "values": {"local-user:profile:language": "en"} }
```

### POST /profile.export

- Exports Tier B (profile) bundle for a person.
- Body:

```json
{ "person_id": "local-user" }
```

- Response:

```json
{
  "ok": true,
  "person_id": "local-user",
  "exported_at": 1730130000.123,
  "items": {
    "local-user:profile:language": "en",
    "local-user:profile:onboarding_complete": true
  }
}
```

---

## Developer Notes

- Implementations should persist to Storage in production; this MVP is in-memory.
- All requests should include/propagate `X-Event-ID` for correlation.
