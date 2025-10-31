# Unison Scenarios

This directory contains practical examples and scenarios showing how Unison behaves in real-world interactions, from basic productivity to complex workflows and adaptive experiences.

## Available Scenarios

| Scenario | Description | Complexity |
|----------|-------------|------------|
| [Basic Request](01-basic-request.md) | Simple question-answer interaction | Beginner |
| [Context-Aware Flow](02-context-aware-flow.md) | Demonstrate memory and personalization | Intermediate |
| [Policy Block Example](03-policy-block-example.md) | Safety and consent enforcement | Intermediate |
| [Onboarding and Self-Awareness](04-onboarding-and-self-awareness.md) | First-time setup and system learning | Advanced |

## How to Use These Scenarios

Each scenario includes:
- **Context**: The situation and goals
- **Interaction**: Step-by-step conversation flow
- **Technical Details**: Underlying system behavior
- **Variations**: Different ways the scenario can unfold
- **Learning Points**: Key concepts demonstrated

## Running Scenarios

### Local Development
```bash
# Start Unison locally
cd ../unison-devstack
docker-compose up -d

# Get authentication token
TOKEN=$(curl -s -X POST http://localhost:8088/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&username=admin&password=admin123" | \
  jq -r '.access_token')

# Use the token in scenario examples
export UNISON_TOKEN=$TOKEN
```

### API Testing
```bash
# Example from Basic Request scenario
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer $UNISON_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "query",
    "payload": {"text": "What can you help me with?"}
  }'
```

## Contributing Scenarios

We welcome contributions of new scenarios that demonstrate:

1. **Real-world use cases** from different domains
2. **Advanced features** and capabilities
3. **Edge cases** and error handling
4. **Accessibility** and inclusion examples
5. **Multi-modal** interactions (voice, vision, etc.)

### Scenario Template

```markdown
# Scenario Title

## Context
Describe the situation and environment

## Goals
What the person is trying to accomplish

## Interaction
Step-by-step conversation with Unison

## Technical Details
System behavior and internal processes

## Variations
Alternative paths and outcomes

## Learning Points
Key concepts and features demonstrated
```

## Related Documentation

- [Getting Started](../people/getting-started.md)
- [Architecture](../developer/architecture.md)
- [API Reference](../developer/api-reference/README.md)
- [Security Guide](../operations/security.md)

---

*These scenarios help illustrate Unison's capabilities and provide practical examples for both learning and development.*
