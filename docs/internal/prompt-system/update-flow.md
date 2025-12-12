# Controlled Update Flow (No Self-Edit)

## Tools
The model is never allowed to directly edit the prompt files. It can only call tools that UnisonOS implements and controls:

1. `propose_prompt_update`
   - Inputs: target (`identity|priorities`), JSON Patch ops, rationale, risk classification
   - Output: proposal id, engine risk, “requires approval” flag

2. `apply_prompt_update`
   - Inputs: proposal id, approved flag
   - Responsibilities:
     - Re-validate patch + schema
     - Snapshot current prompt directory
     - Apply changes atomically
     - Append audit log entry
     - Trigger prompt recompile (hot reload)

3. `rollback_prompt_update`
   - Inputs: snapshot tar path
   - Responsibilities:
     - Restore snapshot
     - Append audit log entry
     - Trigger prompt recompile

## Approval Gating
High-risk changes (e.g., privacy stance or tool boundary edits) require explicit approval.

## Versioning & Audit
- Snapshots are written to `snapshots/<timestamp>.tar`.
- Audit log is append-only at `history/changes.log` (JSONL).

