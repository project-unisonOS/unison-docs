# User Journey 01 – Basic Request: “Summarize this document for me”

## Scenario Summary

A person wants a concise summary of a document they are viewing. They simply ask Unison, “Summarize this document for me.”  
Unison understands context, retrieves the content through the appropriate input channel, generates the summary, and delivers it in the person’s preferred format—spoken, visual, or both.

---

## Step-by-Step Experience

1. **Intent expression**
   The person says or types:  
   > “Summarize this document for me.”  

   Unison acknowledges immediately:  
   > “Got it. I’ll read the content and give you a summary.”  

2. **Content capture**
   - If a file or window is active, Unison retrieves its text through the connected I/O agent.  
   - If no document is available, Unison asks for clarification:  
     > “Would you like to paste text or open a file?”  

3. **Generation**
   - Unison routes the request through its Orchestrator.  
   - Context service notes that this is a work-related productivity task and recalls prior preferences (e.g., summary length).  
   - Policy service verifies that no restricted data will leave the device unless the person consents.  
   - Depending on configuration, Unison chooses **local inference** or **cloud model** for summarization.  

4. **Response delivery**
   - The summary is presented on-screen and spoken aloud if voice output is active.  
   - Example:  
     > “Here’s a three-paragraph summary of your document. Would you like me to highlight key action items?”  

5. **Context update**
   - Context service records that the person requested a summary for this project, improving future response accuracy.

---

## System Flow (EventEnvelope Trace)

| Stage | Intent | Source → Destination | Payload Summary | Notes |
|--------|---------|----------------------|-----------------|-------|
| 1 | `summarize.document` | Speech or Keyboard I/O → Orchestrator | Transcribed text: “Summarize this document for me.” | Trigger event |
| 2 | `document.retrieve` | Orchestrator → I/O agent | Request for current active document | May access file system or window context |
| 3 | `policy.evaluate` | Orchestrator → Policy | Data sensitivity evaluation | Checks local/cloud policy before model call |
| 4 | `generate.summary` | Orchestrator → Inference (local or cloud) | Text content + summary parameters | Executes summarization |
| 5 | `respond.summary` | Orchestrator → I/O renderer | Summary output + modality preferences | Adapts to voice or display |
| 6 | `context.update` | Orchestrator → Context | Interaction metadata, preferences | Updates memory for personalization |

---

## Design Notes

- **Natural interaction:** The person speaks conversationally; no menus or app launches.  
- **Transparency:** Unison explains what it’s doing and asks before sending data externally.  
- **Adaptivity:** Output mode changes automatically based on available I/O.  
- **Learning over time:** Context updates reinforce future task performance.  
- **Privacy preservation:** Policy gate ensures summaries of private content remain local when possible.
