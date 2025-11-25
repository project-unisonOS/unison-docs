# Person Profile, Enrollment, and Secure Personalization

Goal: Unison should recognize multiple people, tailor interactions to each person’s needs and preferences, and enforce safety/accessibility/privacy constraints at all times. Enrollment captures identity, consent, and accessibility; returning sessions verify identity (biometric/PIN), load the persona, and apply constraints across all outputs and tool calls.

## Data Model (person_profile)
- Identity/auth: `person_id`, auth methods (passphrase/PIN), biometric references (voiceprint_id, faceprint_id) with version/expiry/confidence thresholds, last_seen_device, enrollment timestamps.
- Safety/consent: consent scopes/tiers, parental/guardian flags, retention preferences, “never store” flags, policy group mapping.
- Content/access controls: content rating, disallowed topics, sensory limits (no flashing visuals, volume caps, haptics allowed?), privacy zones.
- Modality/accessibility: preferred input/output (speech/text/visual), language/locale/voice, captions on, TTS speed/pitch, high-contrast/large text, screen reader, “no visuals” flag.
- Interaction constraints: turn pacing, max response length, stop phrases, hands-free/gaze-only, physical interaction constraints.
- Tool/provider/cost: allowed providers, cloud/offline preference, cost caps, disallowed tools/apps.
- Profile context: name/pronouns, household role, time zone, device list, notification rules.
- Audit/provenance: created_at/updated_at, updated_by (self/admin), enrollment source, transport hints (mTLS/UDS required?).

## Storage and Security
- `unison-context`: stores `person_profile` (PII) and conversation summaries; scoped by `person_id`. Tag PII and avoid logging sensitive fields.
- `unison-storage`: stores biometric embeddings and consent artifacts (encrypted at rest); references stored in context profile, not raw data.
- `unison-policy`: stores policy group membership and evaluates content/cost/cloud rules per person.
- `unison-context-graph`: stores capabilities/tool manifests; filtered per person via policy/context.
- Transport: mTLS/UDS where possible; always propagate batons/traces. Avoid PII in traces/logs; redact in structured logging.
- Retention/rotation: biometric refs include expiry; rotate embeddings on schedule; respect “never store” flags by keeping interactions ephemeral.

## APIs (Context)
- `GET /profile/{person_id}` / `POST /profile/{person_id}`: read/update profile (auth + consent enforced). Body includes structured `person_profile` schema sections as above.
- `GET /conversation/{person_id}/{session_id}` / `POST /conversation/{person_id}/{session_id}`: already present; backed by SQLite; can be extended with persona summary linkage.
- PII handling: reject cross-person access; require consent scopes; avoid returning biometric material (only refs/metadata).

## Enrollment Flow (First-Time)
1) Presence detected → tentative session (trace/baton).
2) Collect name/pronouns + modality prefs + language/voice.
3) Accessibility/sensory: captions on, volume limits, no flashing/haptics as needed.
4) Safety/consent: content rating, disallowed topics, retention/“never store”, offline-only vs cloud allowed; set policy group.
5) Biometrics (optional but recommended): voiceprint + faceprint with liveness; store embeddings in storage (encrypted) and refs in profile; set thresholds/expiry; PIN/passphrase fallback.
6) Tool/provider/cost: allowed providers, cloud/offline preference, cost caps.
7) Confirmation: read back key settings; store profile; bind to policy group; issue baton.

## Returning Flow
- Verify identity (voice/face with liveness; fallback PIN). If low confidence, prompt disambiguation.
- Load profile + constraints; apply to renderer/IO (captions, volume caps, no visuals if set).
- Filter capabilities/tools via context-graph and policy group; honor cloud/offline and cost caps.
- Use conversation summaries for continuity; enforce stop phrases and interaction constraints.

## Orchestrator/Companion Changes
- Add enrollment/verification intents: `person.enroll`, `person.verify`, `person.update_prefs`.
- Companion loop: pull profile, filter tools/capabilities, enforce constraints on outputs (e.g., no images if no-visuals; volume cap for TTS).
- Policy: attach person’s policy group; block disallowed providers/tools; cap costs; enforce content rating.

## IO/Renderer Changes
- `unison-io-speech`/`unison-io-vision`: capture/verify biometrics with liveness; respect accessibility on output (volume caps, captions, no flashing); pass person_id when verified.
- Renderer: adjust UI (contrast, text size, captions) per person; support “no visuals” mode.

## Privacy & Audit Guardrails
- mTLS/UDS between services where supported; sign/encrypt batons.
- Redact PII in logs/traces; never log biometric blobs or auth secrets.
- Audit log on profile reads/writes and biometric verification attempts (person_id, reason, success/fail, actor).
- Enforce consent/policy checks on profile APIs and tool calls.
