# Event Graph vs Context Graph (Target)

This document defines two related but distinct stores:

- **Event Graph**: append-only timeline of what happened (for replay, audit, debugging, latency).
- **Context Graph**: evolving representation of what the system *believes* (preferences, state, pointers, summaries).

Both exist to serve different queries and retention models.

## Definitions

### Event Graph (append-only)

**Purpose**
- Capture a complete, ordered timeline of interaction events and system decisions.
- Support replay, debugging, audit trails, and performance analysis.

**Stores**
- input envelopes (sanitized)
- routing/classifier outputs
- planner outputs (proposals)
- policy decisions (allow/deny/confirm)
- tool calls + results
- ROM builds + renderer emissions
- context write-behind queue + flush results
- trace spans/events (timings, status)

**Properties**
- Append-only (no mutation; redaction creates a new redaction event)
- Partitionable by `trace_id`, `session_id`, `person_id`
- Designed for replay and “why did this happen?” analysis

### Context Graph (stateful)

**Purpose**
- Model stable preferences, evolving goals, task focus pointers, and summaries.
- Support “what should we do next?” and personalization queries.

**Stores**
- user preferences and accessibility settings
- per-person and per-session focus pointers (active task, active workflow)
- summarized memory and salient entities (bounded)
- policy-related state references (consent references, risk tolerances)

**Properties**
- Mutable state with explicit versioning/ETags
- Derived (in part) from Event Graph events via write-behind

## Required now vs later

### Required now (Phase 0–1)

- **Trace artifacts** written locally (JSON) per interaction.
- **Event Graph “shape”** defined (contract) even if stored only as local JSONL.
- **Context write-behind contract** defined; may be no-op initially.

### Later (Phase 2+)

- Context read integration (context snapshot feeding router/planner).
- Event Graph persistence beyond local dev (SQLite index, later JetStream/DB).
- Replay tooling and privacy-preserving redaction pipeline.

## Initial storage choices

### Event Graph (initial)

- Storage: local append-only `JSONL` file OR `SQLite` table.
- Default location: `traces/` (or env-configured path).
- Encryption hook: interface for encrypt-at-rest, initially no-op.

Current Phase 3 implementation:
- The Event Graph is implemented as an append-only JSONL store in `unison-orchestrator` (config: `UNISON_EVENT_GRAPH_DIR`, `UNISON_EVENT_GRAPH_FILE`).
- Thin-slice interactions append structured `EventGraphEvent` records; replay tooling is provided via `unison-orchestrator/scripts/event_graph_replay.py`.

### Context Graph (current workspace reality)

The repo already has a `unison-context-graph` service with a replay store (SQLite-backed) that records “traces” for search and replay. This is *not yet* the framework’s Event Graph as defined here (it stores a subset of events and does not serve as the canonical append-only interaction ledger).

## Retention, privacy, and redaction

Baseline policies (target):
- **Minimize sensitive payloads**: store hashes or references where possible.
- **Redaction events**: do not mutate old events; append a redaction instruction event.
- **Retention windows**:
  - Event Graph: short default (e.g., 7–30 days) with opt-in longer retention per user/consent.
  - Context Graph: bounded to necessary stable state and summaries.
- **PII boundaries**: strict tagging (`data_classification`, `sensitivity_level`) to gate export and sharing.

## Data model (high-level)

- Event Graph is a sequence of `EventGraphNode` items:
  - each node has `event_id`, `event_type`, `ts`, `trace_id`, `session_id`, `actor`, `payload_ref|payload`
  - nodes can reference others via `parent_event_id` / `causation_id`
- Context Graph is a set of named dimensions:
  - `profile`, `preferences`, `task_focus`, `summaries`, `capabilities`
