---
title: Update From Conversation
nav_order: 4
---

# Updating UnisonOS from conversation

UnisonOS updates are initiated through conversation and executed by the local **Update Service**.
The assistant never “updates” directly; it uses the `updates.*` tools and waits for explicit approval where required.

## Common phrases

- “Are updates available?”
- “Install security updates.”
- “Install everything.”
- “Schedule updates tonight at 10.”
- “How’s it going?”
- “What changed?”
- “Roll back the last update.”

## What you will see (high level)

1. **Discovery**: the assistant calls `updates.check()` and summarizes available updates by plane (`os`, `unison`, `models`).
2. **Planning**: the assistant calls `updates.plan(selection, constraints)` and shows the ordered steps, impacts, and rollback info.
3. **Approval**: if the plan requires approval, the assistant asks you explicitly before continuing.
4. **Execution**: the assistant calls `updates.apply(plan_id)` and you receive progress updates.
5. **Completion**: you get “what changed” highlights and a pointer to full release notes.

## Policy changes (via conversation)

The assistant can read and patch your local update policy:

- Read: `updates.get_policy()`
- Patch: `updates.set_policy(policy_patch)`

Examples:

- “Only install security updates automatically.” → `updates.set_policy({auto_apply:'security_only'})`
- “Ask me before model updates.” → `updates.set_policy({approval_required_for:['unison','models']})`
- “Only update on Wi‑Fi.” → `updates.set_policy({wifi_only:true})`

## Rollback behavior

- If a health check fails, rollback is automatic and you are notified.
- You can also request rollback explicitly with `updates.rollback(target='last_known_good')`.

## Troubleshooting

- If the assistant says `update service unavailable`, verify the Update Service is running and reachable from the orchestrator.
- If model updates fail with a signature error, verify model pack public keys are installed and the pack includes `models.manifest.sig.json`.
- If OS updates show “no snapd”, you are not on Ubuntu Core (or snapd is not available). Unison and model planes can still update.

