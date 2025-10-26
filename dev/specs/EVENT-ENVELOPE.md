# EventEnvelope Technical Specification

## 1. Purpose

EventEnvelope is the standard message format inside Unison.

All major services — Orchestrator, Context, Storage, Policy, I/O agents, and external integrations — communicate using EventEnvelope objects instead of ad hoc request bodies.

Why this matters:

- It gives us one contract for routing, logging, and policy enforcement.
- It lets the Orchestrator treat every request the same way, regardless of origin.
- It creates a stable interface for future modules (speech I/O, vision I/O, etc.) without rewriting core services.

EventEnvelope is the boundary object of the platform.

---

## 2. Schema Definition

### 2.1 Machine-readable JSON Schema

This is the canonical schema. It aligns with `unison-spec/specs/event-envelope.schema.json`.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "EventEnvelope",
  "type": "object",
  "required": ["timestamp", "source", "intent", "payload"],
  "properties": {
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 UTC timestamp when the event was created"
    },
    "source": {
      "type": "string",
      "description": "Logical module or agent that produced this event. Example: 'io-speech', 'io-vision', 'orchestrator', 'policy', 'context'"
    },
    "intent": {
      "type": "string",
      "description": "High-level requested action. Examples: 'summarize.document', 'context.get', 'policy.evaluate', 'message.dispatch'"
    },
    "payload": {
      "type": "object",
      "description": "Structured arguments for the intent",
      "additionalProperties": true
    },
    "auth_scope": {
      "type": "string",
      "description": "Optional: permission scope asserted by caller. Example: 'person.local.explicit', 'background.passive', 'org.restricted'"
    },
    "safety_context": {
      "type": "object",
      "description": "Optional: info for policy, such as data classification, target audience, or external recipients",
      "additionalProperties": true
    }
  },
  "additionalProperties": false
}
```

### 2.2 Human-readable field reference

| Field             | Required | Type     | Description |
|------------------|----------|----------|-------------|
| `timestamp`      | yes      | string   | ISO 8601 timestamp in UTC (e.g. `2025-10-25T19:22:04Z`). Represents when the event was created. |
| `source`         | yes      | string   | Logical origin of the event. Examples: `io-speech`, `io-vision`, `orchestrator`, `context`, `policy`, `storage`. Used for auditing and trust decisions. |
| `intent`         | yes      | string   | The requested action or capability. Examples: `summarize.document`, `context.get`, `policy.evaluate`, `message.dispatch`, `generate.secure_link`. |
| `payload`        | yes      | object   | Input parameters for the intent. Shape depends on the intent. For example for `context.get` it may include `{ "key": "workspace.activeProject" }`. |
| `auth_scope`     | no       | string   | Declared trust scope. Describes how strongly the person authorized this action. Examples: `person.local.explicit` (explicit spoken or typed command), `background.passive` (implicit trigger), `org.policy` (org-level automation). Policy uses this to decide whether to allow, block, or require confirmation. |
| `safety_context` | no       | object   | Security and compliance metadata. This can include classification (`"confidential"`), recipient domains, or cost implications. Policy uses this to enforce rules. |

All other fields are rejected at this layer. `additionalProperties` is `false` to prevent silent drift.

---

## 3. Example EventEnvelope messages

These examples are realistic to current architecture and near-term roadmap.

### 3.1 Summarize a document

Scenario  
A person says: “Summarize this document for me.”

Envelope sent from speech I/O to Orchestrator:

```json
{
  "timestamp": "2025-10-25T19:22:04Z",
  "source": "io-speech",
  "intent": "summarize.document",
  "payload": {
    "document_ref": "active_window",
    "summary_length": "short"
  },
  "auth_scope": "person.local.explicit",
  "safety_context": {
    "data_classification": "internal",
    "allows_cloud": false
  }
}
```

Notes:

- `document_ref` allows the orchestrator to retrieve content through the appropriate I/O adapter.
- `allows_cloud: false` tells Policy and Orchestrator to keep inference local only.

### 3.2 Policy check for restricted action

Scenario  
The person says: “Send this confidential file to my personal email.”

Orchestrator asks Policy if it’s allowed:

```json
{
  "timestamp": "2025-10-25T19:25:10Z",
  "source": "orchestrator",
  "intent": "policy.evaluate",
  "payload": {
    "action": "file.send_external",
    "target": "personal-email",
    "file_label": "confidential"
  },
  "auth_scope": "person.local.explicit",
  "safety_context": {
    "recipient_domain": "gmail.com",
    "org_policy_zone": "restricted"
  }
}
```

Policy responds separately (not an EventEnvelope in the current design, just HTTP response JSON) with allow / deny / require_confirmation. The orchestrator will not perform the action unless Policy approves.

### 3.3 Context recall

Scenario  
Unison needs to answer “Send that summary to my project team.”  
It first has to recall which summary and which team.

Envelope sent from Orchestrator to Context:

```json
{
  "timestamp": "2025-10-25T19:30:02Z",
  "source": "orchestrator",
  "intent": "context.get",
  "payload": {
    "keys": [
      "latest.summary.document",
      "active.project.team"
    ]
  },
  "auth_scope": "person.local.explicit",
  "safety_context": {
    "scope": "workspace",
    "retention_policy_days": 30
  }
}
```

Context returns data scoped to those keys. This enables follow-up automation without re-asking the person for details.

### 3.4 Generated output routing

Scenario  
After generating a summary, Unison needs to deliver it by voice and on-screen.

Envelope sent from Orchestrator to the I/O layer:

```json
{
  "timestamp": "2025-10-25T19:31:44Z",
  "source": "orchestrator",
  "intent": "respond.summary",
  "payload": {
    "text": "Here's a three-paragraph summary of your document highlighting revenue trends and open risks.",
    "channels": ["speech", "display"],
    "accessibility": {
      "reading_speed": "slow",
      "text_contrast": "high"
    }
  },
  "auth_scope": "person.local.explicit"
}
```

This is how Unison supports multimodal, adaptive output without hardcoding UI per feature.

---

## 4. Validation Rules

The orchestrator enforces basic validation of incoming envelopes before doing anything else. This prevents garbage from propagating through the system.

Validation logic is implemented in the `unison-common` package (`unison-common/src/unison_common/envelope.py`).

Rules enforced today:

1. Envelope must be an object.
2. `timestamp`, `source`, `intent`, and `payload` must exist.
3. `timestamp`, `source`, `intent` must be strings.
4. `payload` must be an object (dictionary).
5. `auth_scope`, if present, must be a string.
6. `safety_context`, if present, must be an object.
7. Unknown top-level fields are rejected.

If validation fails:

- Orchestrator returns HTTP 400 with a reason.
- The event is never routed to Policy, Context, Storage, etc.

Example failure response from `/event`:

```json
{
  "detail": "Missing required field 'payload'"
}
```

Note: This protects downstream services from malformed or adversarial envelopes.

---

## 5. Versioning and Forward Compatibility

### 5.1 Stability policy

- The set of required fields (`timestamp`, `source`, `intent`, `payload`) is considered stable.  
- Optional fields (`auth_scope`, `safety_context`) may evolve.

### 5.2 Adding new intents

- New capabilities are expressed as new `intent` values.  
- You do not add new top-level keys to the envelope to express capability. You add new payload structures.

Example:

- `respond.summary` and `message.dispatch` are two different intents.
- They both remain valid envelopes because the intent string changes, not the schema.

### 5.3 Deprecation

- If an intent is deprecated, we keep the old string in docs and mark it deprecated in `unison-spec`.
- We do not silently repurpose an old intent name with new meaning.

### 5.4 Service discovery

In the future we will expose a registry endpoint so a service can advertise:

- Which intents it handles
- Expected payload shape
- Whether it requires Policy sign-off before execution

That registry will allow new skills to plug into Unison without modifying the orchestrator codebase.

---

## 6. Implementation Notes

### 6.1 Python
In orchestrator code (FastAPI), envelopes arrive as raw JSON in `/event`.  
The flow is:

1. Receive body as dict.  
2. Pass to `validate_event_envelope()` from `unison-common`.  
3. On success, route by `intent`.  
4. On failure, respond with HTTP 400.

Relevant fragment (simplified):

```python
from fastapi import HTTPException
from unison_common import validate_event_envelope, EnvelopeValidationError

@app.post("/event")
def handle_event(envelope: dict):
    try:
        envelope = validate_event_envelope(envelope)
    except EnvelopeValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))

    capability_id = envelope["intent"]
    # orchestrator routes based on that capability_id
```

This keeps validation logic centralized and prevents drift.

### 6.2 Logging
All envelopes should be logged by Orchestrator with:

- `timestamp`
- `source`
- `intent`

Payloads that include sensitive data may be redacted or summarized in logs. The redaction policy will live in the Policy service once it exists as its own repo.

### 6.3 Policy integration
Before performing anything with side effects (network transmission, hardware control, external calls), the orchestrator must:

- Create a `policy.evaluate` envelope  
- Send it to the Policy service  
- Honor the response (`allowed`, `require_confirmation`, `reason`)

This is mandatory for safety and auditability.

---

## 6.4 Correlation and Event IDs

- The Orchestrator assigns a unique `event_id` (UUID) for each `/event` request and for `/ready` checks.
- It propagates this ID to downstream services via the `X-Event-ID` HTTP header.
- Core services (Policy, Context, Storage) include the received `X-Event-ID` in structured logs for cross-service correlation.
- The Orchestrator also returns `event_id` in JSON responses for `/event` and `/ready` to help clients correlate requests with logs.

Example response fragment:

```json
{
  "accepted": true,
  "routed_intent": "summarize.document",
  "event_id": "e3e7d3f7-0f6a-4ac2-8246-6ce0b0e2a1bf"
}
```

Clients do not need to send `X-Event-ID`; it is generated by the Orchestrator.

## 7. Summary

EventEnvelope is the universal request/response wrapper inside Unison.  
It:

- Defines how every service talks.  
- Allows the Orchestrator to reason about all actions the same way.  
- Enables Policy to audit and gate behavior.  
- Supports adaptive output and multimodal interaction.  
- Provides a stable interface for future capabilities and external contributors.

This spec is required reading for anyone adding new capabilities, new I/O channels, or new services to Unison.
