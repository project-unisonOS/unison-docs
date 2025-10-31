# Scenario 02 – Context-Aware Flow: "Continue working on my project"

## Scenario Summary

A person returns to their workspace after a break and asks Unison to continue their previous work. Unison leverages its context awareness to understand the project state, recall preferences, and provide relevant suggestions based on previous interactions and current environment.

---

## Step-by-Step Experience

1. **Intent expression**
   The person sits down and says:  
   > "Continue working on my project."  

   Unison responds with context awareness:  
   > "Welcome back! I see you were working on the Q4 marketing presentation. You had 3 slides completed and were researching competitor analysis. Would you like to pick up where you left off?"

2. **Context retrieval**
   - Unison accesses the context service to retrieve recent activity
   - Identifies the active project from workspace state
   - Recalls the person's working patterns and preferences
   - Checks for any updates or changes since last session

3. **State assessment**
   - Reviews progress on the presentation (3/12 slides complete)
   - Notes the research phase (competitor analysis in progress)
   - Checks calendar for upcoming deadlines (presentation in 5 days)
   - Identifies any new emails or messages related to the project

4. **Intelligent suggestions**
   - Provides relevant options based on context:  
     > "I can help you in several ways:
     > 1. Continue with competitor research (you were looking at TechCorp's latest product)
     > 2. Start drafting the remaining slides based on your outline
     > 3. Review and refine the completed slides
     > 4. Check for any new market data that might impact your analysis"

5. **Adaptive assistance**
   - Based on the person's choice, Unison adapts its assistance
   - Maintains context throughout the interaction
   - Updates preferences based on current needs

---

## System Flow (EventEnvelope Trace)

| Stage | Intent | Source → Destination | Payload Summary | Notes |
|--------|---------|----------------------|-----------------|-------|
| 1 | `work.continue` | Speech I/O → Orchestrator | "Continue working on my project" | Context-aware request |
| 2 | `context.retrieve` | Orchestrator → Context | Recent activity, project state | Retrieves work context |
| 3 | `environment.assess` | Orchestrator → I/O agents | Workspace state, calendar, emails | Checks environment changes |
| 4 | `preferences.recall` | Orchestrator → Context | Working patterns, habits | Personalizes response |
| 5 | `suggestions.generate` | Orchestrator → Inference | Context + options | Creates relevant suggestions |
| 6 | `response.contextual` | Orchestrator → I/O renderer | Personalized options | Delivers contextual response |
| 7 | `context.update` | Orchestrator → Context | New interaction, choices | Updates working memory |

---

## Technical Implementation

### Context Service Data Structure

```json
{
  "person_id": "person-123",
  "session_id": "session-456",
  "active_project": {
    "id": "project-q4-marketing",
    "name": "Q4 Marketing Presentation",
    "type": "presentation",
    "progress": {
      "completed_slides": 3,
      "total_slides": 12,
      "last_activity": "2024-01-01T10:30:00Z"
    },
    "current_phase": "competitor_analysis",
    "deadline": "2024-01-06T14:00:00Z"
  },
  "preferences": {
    "work_style": "structured",
    "break_reminder": true,
    "focus_time": "morning",
    "output_format": "visual"
  },
  "environment": {
    "workspace": "office",
    "devices": ["desktop", "phone"],
    "time_of_day": "morning",
    "calendar_events": ["team meeting at 2PM"]
  }
}
```

### Intelligent Suggestion Algorithm

```python
def generate_suggestions(context):
    suggestions = []
    
    # Based on project progress
    if context["active_project"]["progress"]["completed_slides"] < 5:
        suggestions.append({
            "type": "continue_research",
            "description": "Continue competitor analysis",
            "priority": "high"
        })
    
    # Based on deadline proximity
    days_until_deadline = (deadline - today).days
    if days_until_deadline <= 7:
        suggestions.append({
            "type": "accelerate_work",
            "description": "Focus on completing remaining slides",
            "priority": "high"
        })
    
    # Based on work patterns
    if context["preferences"]["work_style"] == "structured":
        suggestions.append({
            "type": "follow_outline",
            "description": "Work from your existing outline",
            "priority": "medium"
        })
    
    return suggestions
```

---

## Variations and Extensions

### Different Context Types
- **Creative Work**: "Continue writing my story" - recalls plot, characters, tone
- **Coding Project**: "Continue programming" - remembers functions, bugs, tests
- **Research Task**: "Continue my research" - tracks sources, notes, citations
- **Learning Activity**: "Continue studying" - knows progress, difficult topics

### Environmental Adaptations
- **Location Change**: Different suggestions for office vs. home
- **Time of Day**: Morning focus vs. evening review preferences
- **Device Context**: Mobile vs. desktop capabilities
- **Collaboration**: Team projects vs. individual work

### Proactive Assistance
- **Deadline Alerts**: "Your presentation is in 2 days, shall we prioritize?"
- **Break Reminders**: "You've been working for 2 hours, time for a break?"
- **Resource Updates**: "New market data released, relevant to your analysis"
- **Collaboration Opportunities**: "Sarah is working on similar research, connect?"

---

## Learning Points

This scenario demonstrates:

1. **Persistent Context**: Maintains state across sessions
2. **Environmental Awareness**: Understands workspace and conditions
3. **Personalization**: Adapts to individual preferences and patterns
4. **Intelligent Suggestions**: Provides relevant options based on context
5. **Proactive Assistance**: Anticipates needs and offers help
6. **Multi-Project Support**: Manages multiple concurrent activities

---

## Privacy and Ethics Considerations

### Data Handling
- **Local Storage**: Context data stored locally by default
- **Consent Management**: Explicit consent for environmental monitoring
- **Data Minimization**: Only stores relevant contextual information
- **Retention Policies**: Automatic cleanup of old context data

### Ethical Guidelines
- **No Manipulation**: Suggestions based on preferences, not persuasion
- **Transparency**: Clear about how context is used
- **Control**: Person can override or ignore suggestions
- **Accessibility**: Adapts to different abilities and needs

---

## Related Documentation

- [Context Service Architecture](../developer/architecture.md#context-service)
- [Privacy Controls](../operations/security.md#data-protection)
- [Personalization Features](../features/personalization.md)
- [Environmental Sensors](../developer/api-reference/io.md)

---

## Try It Yourself

```bash
# Set up context data
curl -X POST http://localhost:8081/context \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "person_id": "person-123",
    "active_project": {
      "name": "Q4 Marketing Presentation",
      "progress": {"completed": 3, "total": 12}
    },
    "preferences": {
      "work_style": "structured"
    }
  }'

# Test context-aware request
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "work.continue",
    "payload": {"text": "Continue working on my project"}
  }'
```

---

*This scenario showcases Unison's ability to maintain context, personalize interactions, and provide intelligent assistance that adapts to individual needs and circumstances.*
