# Scenario 01 – Basic Request: "Summarize this document for me"

## Scenario Summary

A person wants a concise summary of a document they are viewing. They simply ask Unison, "Summarize this document for me."  
Unison understands context, retrieves the content through the appropriate input channel, generates the summary, and delivers it in the person's preferred format—spoken, visual, or both.

---

## Step-by-Step Experience

1. **Intent expression**
   The person says or types:  
   > "Summarize this document for me."  

   Unison acknowledges immediately:  
   > "Got it. I'll read the content and give you a summary."  

2. **Content capture**
   - If a file or window is active, Unison retrieves its text through the connected I/O agent.  
   - If no document is available, Unison asks for clarification:  
     > "Would you like to paste text or open a file?"  

3. **Generation**
   - Unison routes the request through its Orchestrator.  
   - Context service notes that this is a work-related productivity task and recalls prior preferences (e.g., summary length).  
   - Policy service verifies that no restricted data will leave the device unless the person consents.  
   - Depending on configuration, Unison chooses **local inference** or **cloud model** for summarization.  

4. **Response delivery**
   - The summary is presented on-screen and spoken aloud if voice output is active.  
   - Example:  
     > "Here's a three-paragraph summary of your document. Would you like me to highlight key action items?"  

5. **Context update**
   - Context service records that the person requested a summary for this project, improving future response accuracy.

---

## System Flow (EventEnvelope Trace)

| Stage | Intent | Source → Destination | Payload Summary | Notes |
|--------|---------|----------------------|-----------------|-------|
| 1 | `summarize.document` | Speech or Keyboard I/O → Orchestrator | Transcribed text: "Summarize this document for me." | Trigger event |
| 2 | `document.retrieve` | Orchestrator → I/O agent | Request for current active document | May access file system or window context |
| 3 | `policy.evaluate` | Orchestrator → Policy | Data sensitivity evaluation | Checks local/cloud policy before model call |
| 4 | `generate.summary` | Orchestrator → Inference (local or cloud) | Text content + summary parameters | Executes summarization |
| 5 | `respond.summary` | Orchestrator → I/O renderer | Summary output + modality preferences | Adapts to voice or display |
| 6 | `context.update` | Orchestrator → Context | Interaction metadata, preferences | Updates memory for personalization |

---

## Technical Implementation

### EventEnvelope Example

```json
{
  "id": "uuid-v4",
  "timestamp": "2024-01-01T12:00:00Z",
  "source": "unison-speech",
  "intent": "summarize.document",
  "payload": {
    "text": "Summarize this document for me",
    "modality": "voice"
  },
  "context": {
    "person_id": "person-123",
    "session_id": "session-456",
    "active_document": "/path/to/document.pdf"
  },
  "auth_scope": "read",
  "safety_context": {
    "content_type": "document",
    "data_sensitivity": "personal"
  }
}
```

### Policy Evaluation

The policy service evaluates:
- **Data sensitivity**: Is the document private or confidential?
- **Consent requirements**: Does the person consent to cloud processing?
- **Output format**: Preferred response modality based on context
- **Accessibility**: Any accommodation requirements

### Context Service Updates

After processing, the context service stores:
```json
{
  "person_id": "person-123",
  "preferences": {
    "summary_length": "medium",
    "output_modality": ["visual", "voice"],
    "last_document_type": "pdf"
  },
  "interaction_history": [
    {
      "timestamp": "2024-01-01T12:00:00Z",
      "intent": "summarize.document",
      "success": true,
      "satisfaction": "high"
    }
  ]
}
```

---

## Variations and Extensions

### Alternative Input Methods
- **Voice**: "Hey Unison, can you summarize this?"
- **Keyboard**: Type command in interface
- **Gesture**: Point to document and use gesture command
- **Context**: Automatic summary when document opens for >30 seconds

### Different Summary Types
- **Executive summary**: High-level key points only
- **Detailed summary**: Comprehensive with sections
- **Action items**: Extract tasks and deadlines
- **Q&A format**: Question and answer style summary

### Accessibility Adaptations
- **Screen reader**: Optimized for audio consumption
- **Visual impairment**: Enhanced contrast and larger text
- **Cognitive load**: Simplified language and shorter sentences
- **Language preferences**: Translate to preferred language

---

## Learning Points

This scenario demonstrates:

1. **Natural Language Understanding**: Unison correctly interprets the request
2. **Context Awareness**: Recognizes the active document and environment
3. **Multi-modal Output**: Adapts response to voice and visual preferences
4. **Privacy Controls**: Respects data sensitivity and consent
5. **Personalization**: Learns preferences for future interactions
6. **Accessibility**: Adapts to different needs and capabilities

---

## Related Documentation

- [Architecture Overview](../developer/architecture.md)
- [Event Envelope Specification](../../unison-spec/specs/event-envelope.md)
- [Policy Service](../developer/api-reference/policy.md)
- [Context Service](../developer/api-reference/context.md)

---

## Try It Yourself

```bash
# Start Unison locally
cd ../unison-devstack
docker-compose up -d

# Get authentication token
TOKEN=$(curl -s -X POST http://localhost:8088/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&username=admin&password=admin123" | \
  jq -r '.access_token')

# Send a summary request
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "summarize.document",
    "payload": {
      "text": "Summarize this document for me",
      "document_path": "/path/to/your/document.pdf"
    }
  }'
```

---

*This scenario illustrates Unison's ability to understand natural requests and provide helpful, context-aware responses while respecting privacy and accessibility needs.*
