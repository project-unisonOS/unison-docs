# User Journey 02 – Context-Aware Flow: “Send that summary to my project team”

## Scenario Summary

After generating a document summary, a person tells Unison:  
> “Send that summary to my project team.”  

Unison remembers the previous interaction, identifies which summary and team are referenced, and completes the task safely and naturally.

---

## Step-by-Step Experience

1. **Intent expression**
   The person says:  
   > “Send that summary to my project team.”  

   Unison replies:  
   > “I’ll send your latest document summary to the team from your current project. Do you want it sent by email or chat?”  

2. **Context retrieval**
   - Context service recalls that the last request involved summarizing a document titled *Quarterly Report Q2*.  
   - It also recalls the person’s active workspace and preferred communication channels.  
   - If multiple projects exist, Unison clarifies:  
     > “You have summaries for Marketing and Engineering projects. Which team should receive this one?”  

3. **Policy validation**
   - Policy service confirms that Unison has permission to send messages to the selected team.  
   - If external delivery is restricted, Unison explains why and offers alternatives:  
     > “I can’t send messages outside your organization, but I can prepare an internal note or export a file.”  

4. **Action execution**
   - Orchestrator calls the appropriate integration (email, chat API, or file upload).  
   - Context logs the action and success status.  
   - Example confirmation:  
     > “Message sent to the Engineering team in Slack, including your summary of the Q2 report.”  

5. **Context update**
   - Unison updates memory with what was sent, when, and to whom, enabling future commands like:  
     > “Resend that summary to the new team members.”

---

## System Flow (EventEnvelope Trace)

| Stage | Intent | Source → Destination | Payload Summary | Notes |
|--------|---------|----------------------|-----------------|-------|
| 1 | `message.send_summary` | Speech I/O → Orchestrator | Text: “Send that summary to my project team.” | Trigger event |
| 2 | `context.retrieve` | Orchestrator → Context | Query: most recent “summary” artifact and “project team” reference | Recall |
| 3 | `policy.evaluate` | Orchestrator → Policy | Validate outbound communication permissions | Consent and scope |
| 4 | `message.dispatch` | Orchestrator → External API (email/chat) | Message body + recipients | Action execution |
| 5 | `context.update` | Orchestrator → Context | Record transmission event | Enables continuity |

---

## Design Notes

- **Memory continuity:** Unison links follow-up requests to previous actions without re-prompting for detail.  
- **Transparency:** Before transmitting, Unison confirms destination and method.  
- **Adaptivity:** If network access is limited, Unison can queue or export the message for later delivery.  
- **Context evolution:** Each action enriches the shared state, improving future automation accuracy.  
- **Trust through explanation:** When an action is blocked, Unison explains policy boundaries clearly and conversationally.
