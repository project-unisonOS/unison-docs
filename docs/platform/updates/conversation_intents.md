---
title: Conversational Update Intents
nav_order: 3
---

# Conversational update intents and canonical flows

UnisonOS updates must be operable entirely via conversation.
This doc defines canonical utterances, tool calls, and expected system behaviors.

## Tool surface (summary)

- `updates.check()`
- `updates.plan(selection, constraints)`
- `updates.apply(plan_id)`
- `updates.status(job_id)`
- `updates.pause(job_id)` / `updates.resume(job_id)` / `updates.cancel(job_id)`
- `updates.rollback(target)`
- `updates.whats_new(from_version, to_version)`
- `updates.get_policy()` / `updates.set_policy(policy_patch)`

## Intent groups

1. **Discover**
   - “Are updates available?”
   - “What’s new since last week?”
   - “Do I have security updates?”

2. **Decide**
   - “Show me what would change.”
   - “Only install security updates.”
   - “Skip model updates.”

3. **Schedule**
   - “Install tonight at 10.”
   - “Do it when I’m not using the system.”
   - “Only update on Wi‑Fi.”

4. **Execute**
   - “Install now.”
   - “Start the update.”
   - “Pause it.”
   - “Cancel.”

5. **Recover**
   - “Roll back the last update.”
   - “Go back to the previous model.”
   - “What happened? Why did it fail?”

6. **Learn**
   - “What changed?”
   - “Tell me the highlights.”
   - “List new capabilities.”

## Canonical flow: proactive notification

Trigger: Update Service emits `update.available`.

System (spoken):
- “An update is available: OS security patches and a UnisonOS feature update. Want to review and install now, schedule it, or ignore for now?”

If person says: “Review it.”
- Tool: `updates.check()`
- Response: grouped list by plane with priority, reboot requirement, and estimated time.

System:
- “Security patches are recommended and may require a reboot. UnisonOS 0.6.2 adds <highlights>. Do you want to install everything or security only?”

## Canonical flow: person-initiated check

Person:
- “Are updates available?”

Tools:
1) `updates.check()`

System response pattern:
- “Yes. Security updates for the device are available, and UnisonOS has a recommended update. Models are up to date. Want me to create an install plan?”

If person says: “Yes, install everything.”
Tools:
1) `updates.plan(selection={os:'security', unison:'recommended', models:'channel:stable'}, constraints={require_ac:true})`
2) System asks for approval if required.
3) `updates.apply(plan_id)`

## Canonical flow: schedule

Person:
- “Install updates tonight at 10.”

Tools:
1) `updates.plan(..., constraints={schedule:'2025-12-17T22:00:00-08:00'})`

System:
- “I’ll start at 10 PM. It should take about 8 minutes and may restart services. I’ll let you know when it’s done.”

Notes:
- Scheduling is policy-gated (quiet hours, AC power, Wi‑Fi-only).

## Canonical flow: OS security-only

Person:
- “Just do the security updates.”

Tools:
1) `updates.plan(selection={os:'security'}, constraints={})`
2) `updates.apply(plan_id)`

System completion:
- “Security updates are complete. A reboot was required and has finished successfully. Want the technical details?”

## Canonical flow: model-only update

Person:
- “Update my speech models.”

Tools:
1) `updates.plan(selection={models:['asr','tts']}, constraints={channel:'stable'})`

System approval prompt:
- “This will download about 1.2 GB and keep the current models as a fallback. Proceed?”

Completion:
- “ASR and TTS model packs are updated and validated. You can say ‘switch back’ if anything feels worse.”

## Canonical flow: progress and interruption

Person:
- “How’s it going?”

Tool:
- `updates.status(job_id)`

System:
- “Step 3 of 7: installing Unison runtime. About 2 minutes remaining.”

Person:
- “Pause.”
Tool:
- `updates.pause(job_id)`

System:
- “Paused. Say ‘resume’ to continue.”

## Canonical flow: failure + rollback

Trigger: Update Service emits `update.failed`.

System:
- “The update failed during model validation. I rolled back to the previous model pack automatically. Want details or to try again later?”

If person says: “Roll back everything.”
Tool:
- `updates.rollback(target='last_known_good')`

## “What changed?” behavior

Person:
- “What changed?”

Tools:
1) Determine last update boundary from inventory
2) `updates.whats_new(from_version, to_version)`

System:
- “Highlights: (1) … (2) … (3) … Want the full details?”

## Policy editing via conversation

Person:
- “Only install security updates automatically. Ask me before feature updates.”

Tool:
- `updates.set_policy({auto_apply:'security_only', approval_required_for:['unison','models']})`

System:
- “Done. I’ll apply security updates automatically and ask before feature or model updates.”

## Safety constraints (must always apply)

- Never apply disruptive updates while the person is actively using time-critical IO (e.g., in a call) unless explicitly overridden.
- Always disclose reboot/service restart implications before approval.
- Always keep a rollback path and communicate it clearly.
- Always verify artifact signatures before install.
