# UnisonOS Communications Design (Draft)

This document captures a high-level design for UnisonOS communications. It treats “communication” as a first-class concept, abstracts over specific channels (email, Unison-to-Unison, meeting apps), and explains how communication surfaces in the Operating Surface (dashboard + companion) without hard-coding an “inbox view”.

Status: internal design draft; guides future skills, tools, and adapters.

---

## 1. Goals

- Provide **intent-centric** communication flows instead of inbox-centric UIs.
- Support multiple channels behind a common abstraction:
  - Email (Gmail/IMAP/Graph).
  - Unison-to-Unison messaging.
  - Meeting apps (Teams, Zoom, etc.) via adapters.
- Surface prioritized communications in the Operating Surface:
  - Cards in the dashboard.
  - Companion responses and follow-ups.
  - Recall/search via context-graph.
- Preserve privacy:
  - Connectors and tokens live on the edge.
  - Core contracts are channel-agnostic and avoid leaking raw provider details.

---

## 2. Communication Model (Intent-Centric)

Communication is modeled via **intents** and channel adapters, not by exposing raw inboxes.

### 2.1 Core intents

Initial set (names are illustrative and may be refined):

- `comms.check` – check for new/unread communications.
- `comms.summarize` – summarize communications for a period or topic.
- `comms.reply` – reply to a specific thread/message.
- `comms.compose` – send a new message to one or more recipients.

Future candidates:

- `comms.schedule` – propose times / coordinate meetings.
- `comms.escalate` – mark critical, adjust priority.
- `comms.snooze` – defer messages until a later time window.

### 2.2 Channel-agnostic message shape

All channels (email, Unison, etc.) are normalized into a generic message model before reaching the orchestrator:

- `channel` – e.g. `"email"`, `"unison"`, `"sms"` (future).
- `participants` – list of participant descriptors:
  - Emails, Unison IDs, or other addresses.
- `subject` – short text label.
- `body` – main text content (optionally structured; attachments handled separately).
- `thread_id` – logical thread identifier (provider-specific mapping).
- `message_id` – unique ID for a specific message.
- `context_tags` – tags such as `["comms", "meeting", "project:unisonos"]`.
- `metadata` – channel-specific fields (kept inside adapters where possible).

The orchestrator and companion primarily see intents + normalized message metadata, not raw provider payloads.

### 2.3 Adapters

Each channel is implemented by a dedicated adapter:

- **Email adapter** – Gmail/IMAP/Graph integration:
  - Fetches messages, maps to the abstract message shape.
  - Sends replies/new messages via provider APIs.
- **Unison adapter** – Unison-to-Unison messaging:
  - Delivers messages directly between Unison instances.
  - Stores content encrypted on each edge device.
- **Meeting adapter** – Teams, Zoom, etc.:
  - Maps calendar/links into join actions and presence hooks.

Adapters are responsible for:

- Provider-specific authentication and token management (edge-only).
- Mapping between provider IDs and Unison concepts.
- Hiding provider-specific details behind generic intents.

---

## 3. Email Integration (One Channel Implementation)

Email is treated as one channel behind `comms.*` intents, not as a UI.

### 3.1 Email connector

- Runs locally (as a service or script).
- Stores tokens and cached state in encrypted storage/profile (not in the repo).
- Provides a small HTTP surface for orchestrator/skills, or uses direct client libraries from a background worker.

### 3.2 Mapping to intents

Examples:

- `comms.check`
  - Fetches new/unread messages for the configured inbox(es).
  - Applies simple triage (e.g., priority vs bulk).
  - Produces cards for the dashboard, such as “Messages to respond to”.
- `comms.summarize`
  - Summarizes inbox for a time window or filter:
    - “Today’s important messages”.
    - “Unanswered messages since yesterday”.
  - Emits summary cards plus conversational text.
- `comms.reply`
  - Given `thread_id` / `message_id` and reply text, calls the email adapter to send a reply.
  - Updates dashboard cards and trace logs.
- `comms.compose`
  - Companion helps draft the message body and subject.
  - Email adapter sends via Gmail/IMAP/Graph.
  - Produces a “sent” card with appropriate tags.

### 3.3 Dashboard and tags

Dashboard cards derived from email should be tagged so they are easy to recall:

- Domain: `["comms"]`.
- Channel: `["email"]`.
- Status: `["p0" | "p1" | "p2"]` for priority.
- Concepts: `["project:<id>"]`, `["topic:<concept>"]` as needed.

Example tags:

- Important email from a teammate about UnisonOS:
  - `["comms", "email", "p1", "project:unisonos"]`.

---

## 4. Unison-to-Unison Communication

This channel does not depend on email infrastructure. It uses UnisonOS itself as the primary communication medium.

### 4.1 Identity and addressing

- Each person has a Unison identity (e.g. a `unison_id` tied to their edge profile).
- `comms.compose` with `channel: "unison"` routes to a Unison messaging adapter instead of email.
- Addressing may be:
  - Direct (`unison_id`).
  - By relationship (`contact:alice`) resolved via a local address book mapped to Unison IDs.

### 4.2 Transport and storage

Design target:

- Edge-first, end-to-end encrypted.
- Messages stored encrypted on each participant’s device.
- Optional **cloud relay/sync**:
  - Only used if the person opts in.
  - Controlled via policy and consent.
  - Ideally stores envelopes, not raw plaintext content.

The Unison adapter is responsible for:

- Routing messages between participants (directly when possible, via relay when needed).
- Handling offline delivery and reconnection.

### 4.3 Shared renderer sessions

Unison-to-Unison communications enable **shared spaces**:

- A shared renderer context where:
  - Cards, experiences, and workflows are visible to all participants.
  - Changes (e.g. new steps in a workflow, embedded diagrams) are propagated to each participant’s instance.
- Optional **personal layer**:
  - Each participant can maintain private notes or prompts in their own renderer view.
  - Shared actions remain synchronized; private notes do not.

State persistence:

- Shared actions are written back into each participant’s:
  - Context (for dashboard state).
  - Context-graph (as trace events).

### 4.4 Dashboard integration

Unison-to-Unison messages and shared spaces show up as:

- Priority communications cards:
  - Tags such as `["comms", "unison", "p0"]`.
- Shared workflow cards:
  - Tags like `["workflow", "unison", "project:<id>"]`.

This realizes the “communicating in unison” metaphor: communicating via Unison’s Operating Surface instead of traditional email threads.

---

## 5. Meeting and App Integration

Meeting-related communication should be abstracted similarly, regardless of underlying apps.

### 5.1 Connectors

Meeting connectors integrate with external providers:

- Teams, Zoom, etc.

Responsibilities:

- Discover upcoming meetings from calendar/email.
- Map provider-specific links into join actions and presence information.

### 5.2 Intents

Examples:

- `comms.join_meeting`
  - Given a meeting id/link, launches the appropriate client or deep link.
- `comms.prepare_meeting`
  - Builds cards ahead of a meeting:
    - Relevant comms.
    - Docs and workflows.
    - Participants and agendas.
- `comms.debrief_meeting`
  - Summarizes outcomes:
    - Action items.
    - Decisions.
    - Follow-ups.

### 5.3 Shared spaces for meetings

For participants using UnisonOS:

- A shared renderer space acts as a collaborative canvas during the meeting.
- All changes are written back into each participant’s context + context-graph as:
  - Cards (for dashboard).
  - Traces (for recall).

This works alongside external meeting tools (Teams, Zoom), allowing UnisonOS to be the shared “Operating Surface” even when audio/video is provided by another app.

---

## 6. Data, Privacy, and Implementation Boundaries

### 6.1 Personal connectors

- Email, calendar, and other connectors run locally or within the person’s controlled environment.
- Secrets and tokens live in:
  - `.env` files (gitignored).
  - Encrypted storage/profile fields in `unison-context`.
- Repos and public docs:
  - Contain only connector interfaces and examples, never real tokens or personal endpoints.

### 6.2 Abstraction boundary

- Orchestrator and companion see:
  - Intents (`comms.*`, `workflow.*`).
  - Normalized messages and card payloads.
  - Tags and summaries.
- Channel adapters encapsulate:
  - Provider-specific identifiers and protocols (IMAP IDs, SMTP headers, Zoom meeting IDs).
  - Their details should not leak into the core intent contracts.

### 6.3 Audit and recall

- All comms-related skills and tools log into context-graph:
  - `origin_intent` (e.g. `comms.check`, `comms.reply`).
  - `tags` (channel, project, topic, priority).
  - `created_at` timestamps.
  - Cards representing what was shown or changed at that time.
- Dashboard cards mirror important communications for:
  - Forward-looking views (e.g. “messages to respond to”).
  - Backwards-looking recall (“summarize important messages from last week”).

The combination of dashboard state, trace logging, and tagging should enable natural-language recall such as:

- “Summarize my important messages from last week.”
- “Show me the workflow we sketched in our last Unison session about onboarding.”

without depending on opaque model memory or central logs.

---

## 7. Next Steps (Implementation-Oriented)

Recommended sequencing:

1. **Tagging alignment**
   - Finalize comms-related tag usage in `unison-docs/dev/tagging-guidelines.md` (for example: `["comms", "email"]`, `["comms", "unison"]`, `["meeting"]`).
2. **Email adapter (Google first)**
   - Design a minimal local Gmail/IMAP integration that:
     - Runs as a connector service or script.
     - Talks to orchestrator via HTTP (no direct SDK coupling in the core services).
   - Map adapter outputs into `comms.check` / `comms.summarize` flows and dashboard cards.
3. **Unison-to-Unison messaging prototype**
   - Define a simple `unison_id` scheme and addressing rules.
   - Implement a local “direct message” channel:
     - Minimal: same machine multi-user or loopback.
     - Future: encrypted relay for cross-device.
4. **Meeting adapter exploration**
   - Start with calendar → meeting join flow (one provider).
   - Prototype `comms.join_meeting` and `comms.prepare_meeting` using synthetic data.

This document should be revisited as the first adapters and skills land, and expanded with concrete API shapes for comms intents and adapters.

