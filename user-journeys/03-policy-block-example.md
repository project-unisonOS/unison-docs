# User Journey 03 – Policy Block Example: “Send this confidential file to my personal email”

## Scenario Summary
A person working on a company-managed device says:  
> “Send this confidential file to my personal email.”  

Unison recognizes that the requested action involves restricted data leaving the organization.  
It explains why the request is blocked, offers safer alternatives, and reinforces trust through clarity rather than silent refusal.

---

## Step-by-Step Experience

1. **Intent expression**
   The person says:  
   > “Send this confidential file to my personal email.”  

   Unison immediately checks applicable policies and responds:  
   > “This document is classified as confidential. Company policy doesn’t allow it to be sent to external addresses. Would you like me to prepare a secure share link instead?”  

2. **Policy evaluation**
   - Orchestrator sends the intent to the Policy service with metadata from the file’s classification.  
   - Policy engine returns `allow = false` and recommends an alternate capability: `generate.secure_link`.  

3. **Explanation and alternative offer**
   - Unison clearly describes the reason for the block and what options remain:  
     > “I can generate a secure, time-limited link you can share with approved collaborators.”  

4. **Action substitution**
   - If the person agrees, Unison calls the secure-link generator service and confirms completion:  
     > “Here’s your secure share link. It expires in seven days.”  

5. **Context update**
   - Context records that this person prefers secure links for restricted data in future tasks.

---

## System Flow (EventEnvelope Trace)

| Stage | Intent | Source → Destination | Payload Summary | Notes |
|--------|---------|----------------------|-----------------|-------|
| 1 | `file.send_external` | Speech I/O → Orchestrator | “Send this confidential file to my personal email.” | Trigger |
| 2 | `policy.evaluate` | Orchestrator → Policy | File metadata + target email domain | Block evaluation |
| 3 | `policy.decision` | Policy → Orchestrator | allow=false, suggested=`generate.secure_link` | Alternate route |
| 4 | `generate.secure_link` | Orchestrator → Storage / Security API | File reference | Safe substitution |
| 5 | `context.update` | Orchestrator → Context | Policy decision outcome | Improves future handling |

---

## Design Notes

- **Explicit reasoning:** Unison explains what rule is being applied and why, never silently discarding a command.  
- **Transparency builds trust:** People understand limits as protective, not arbitrary.  
- **Graceful fallback:** Instead of “no,” Unison offers compliant alternatives.  
- **Policy extensibility:** Rules can evolve without retraining models or altering Orchestrator logic.  
- **Adaptive learning:** Context retains user preference for future safe workflows.
