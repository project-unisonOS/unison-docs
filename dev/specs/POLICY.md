# Unison Policy Service

## Purpose

Governs high-impact actions by returning allow/deny/require_confirmation decisions with clear reasons and optional alternatives.

---

## Rules schema (MVP)

- Evaluated top-to-bottom; first match wins.
- Match fields (any may be omitted):
  - `intent_prefix`
  - `auth_scope`
  - `safety_context.data_classification`
- Decision fields:
  - `action`: `allow` | `deny` | `require_confirmation`
  - `reason`: short machine-friendly string
  - `suggested_alternative` (optional): human-readable guidance for Shell UX

Example:

```yaml
- match:
    intent_prefix: "summarize."
    safety_context:
      data_classification: "confidential"
  decision:
    action: "require_confirmation"
    reason: "needs-confirmation-for-confidential"
    suggested_alternative: "Use internal summary mode or downgrade data classification."

- match:
    intent_prefix: "delete."
  decision:
    action: "deny"
    reason: "destructive-actions-denied"
    suggested_alternative: "Archive instead of delete, or require admin approval."
```

---

## HTTP API (MVP)

### POST /evaluate

Request:

```json
{
  "capability_id": "summarize.doc",
  "context": {
    "actor": "local-user",
    "safety_context": { "data_classification": "confidential" }
  }
}
```

Response:

```json
{
  "capability_id": "summarize.doc",
  "decision": {
    "allowed": false,
    "require_confirmation": true,
    "reason": "needs-confirmation-for-confidential",
    "suggested_alternative": "Use internal summary mode or downgrade data classification."
  }
}
```

---

## Orchestrator expectations

- Orchestrator must call Policy before any external/sensitive action.
- Orchestrator surfaces `suggested_alternative` in `/event` responses and logs.
- If `require_confirmation` is true, Orchestrator issues a token and awaits `/event/confirm`.

---

## Developer Notes

- Rules are YAML for readability in MVP; consider signed sources in production.
- Keep reasons terse; alternatives should be person-friendly sentences for Shell.
