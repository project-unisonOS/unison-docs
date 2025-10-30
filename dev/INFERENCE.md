# External Inference Integration - Phase 9

## Overview

Phase 9 adds external LLM inference capabilities to Unison, enabling generative AI features while maintaining the platform's safety and governance model.

## Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ Orchestrator│───▶│  Inference   │───▶│   Ollama    │
│             │    │   Service    │    │  (Local)    │
└─────────────┘    └──────────────┘    └─────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Policy    │    │   OpenAI     │    │ Azure OpenAI│
│             │    │   (Cloud)    │    │  (Cloud)    │
└─────────────┘    └──────────────┘    └─────────────┘
```

## Supported Inference Intents

### 1. `summarize.doc`
Summarize documents or text content.

**Example Request:**
```json
{
  "intent": "summarize.doc",
  "source": "user-app",
  "payload": {
    "prompt": "Summarize this research paper about quantum computing...",
    "max_tokens": 500,
    "temperature": 0.3
  },
  "safety_context": {
    "data_classification": "public"
  }
}
```

### 2. `analyze.code`
Analyze or explain code snippets.

**Example Request:**
```json
{
  "intent": "analyze.code",
  "source": "ide-plugin",
  "payload": {
    "prompt": "Explain this Python function and suggest improvements...",
    "provider": "ollama",
    "model": "codellama"
  }
}
```

### 3. `translate.text`
Translate text between languages.

**Example Request:**
```json
{
  "intent": "translate.text",
  "source": "chat-ui",
  "payload": {
    "prompt": "Translate to Spanish: 'Hello, how are you today?'"
  }
}
```

### 4. `generate.idea`
Brainstorm ideas or suggestions.

**Example Request:**
```json
{
  "intent": "generate.idea",
  "source": "planning-tool",
  "payload": {
    "prompt": "Generate ideas for a team building activity",
    "temperature": 0.8
  }
}
```

## Provider Configuration

### Ollama (Local - Default)
- No API keys required
- Runs locally in Docker
- Default model: `llama3.2`
- Privacy-first: data never leaves your infrastructure

**Environment Variables:**
```bash
UNISON_INFERENCE_PROVIDER=ollama
UNISON_INFERENCE_MODEL=llama3.2
OLLAMA_BASE_URL=http://ollama:11434
```

### OpenAI (Cloud)
- Requires API key
- Access to GPT models
- Fast inference, higher cost

**Environment Variables:**
```bash
UNISON_INFERENCE_PROVIDER=openai
UNISON_INFERENCE_MODEL=gpt-4
OPENAI_API_KEY=your-api-key-here
OPENAI_BASE_URL=https://api.openai.com/v1
```

### Azure OpenAI (Enterprise)
- Enterprise-grade
- Regional deployment
- Compliance features

**Environment Variables:**
```bash
UNISON_INFERENCE_PROVIDER=azure
UNISON_INFERENCE_MODEL=your-deployment-name
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_API_VERSION=2024-02-15-preview
```

## Policy & Safety

### Data Classification Rules
- **Public**: Allowed for all inference intents
- **Internal**: Requires confirmation for summarization and code analysis
- **Confidential**: Blocked for summarization and code analysis, allowed for translation/idea generation

### Cost Controls
Policy service can enforce:
- Rate limiting per user/intent
- Token quotas
- Provider restrictions (e.g., force local for sensitive data)

### Example Policy Rules
```yaml
- match:
    intent_prefix: "summarize.doc"
    safety_context:
      data_classification: "confidential"
  decision:
    action: "deny"
    reason: "confidential-data-summarization-denied"
```

## Development Setup

### 1. Start Services
```bash
# Start core services
docker compose up -d

# Start Ollama (optional profile)
docker compose --profile tools up -d ollama

# Pull the default model
python scripts/setup_ollama.py
```

### 2. Test Integration
```bash
# Run end-to-end tests
python scripts/test_inference.py
```

### 3. Test Individual Intents
```bash
# Test summarization
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "summarize.doc",
    "payload": {"prompt": "Summarize: AI is transforming..."},
    "safety_context": {"data_classification": "public"}
  }'
```

## Monitoring & Observability

### Metrics
All services expose Prometheus metrics at `/metrics`:
- Request counts per intent
- Provider usage statistics
- Error rates
- Response times

### Logging
Structured JSON logs include:
- Inference requests and responses
- Provider selection
- Cost/risk evaluation results
- Performance metrics

### Example Log Entry
```json
{
  "ts": "2024-10-30T18:30:00Z",
  "service": "unison-inference",
  "message": "inference_success",
  "event_id": "12345678-1234-1234-1234-123456789012",
  "intent": "summarize.doc",
  "provider": "ollama",
  "model": "llama3.2",
  "result_length": 245
}
```

## Troubleshooting

### Common Issues

1. **Ollama model not found**
   ```bash
   # Pull the model manually
   docker exec ollama ollama pull llama3.2
   ```

2. **Inference service unavailable**
   ```bash
   # Check service health
   curl http://localhost:8087/health
   
   # Check readiness
   curl http://localhost:8087/ready
   ```

3. **Policy blocks inference**
   - Check data classification in request
   - Review policy rules in `unison-policy/rules.yaml`
   - Verify `safety_context` is included

### Debug Commands
```bash
# Check Orchestrator dependencies
curl http://localhost:8080/ready

# List available models
curl http://localhost:11434/api/tags

# Test inference service directly
curl -X POST http://localhost:8087/inference/request \
  -H "Content-Type: application/json" \
  -d '{"intent": "test", "prompt": "Hello"}'
```

## Next Steps

### Phase 10 Preparation
- Package inference service in installer
- Add CLI commands for model management
- Document deployment patterns

### Future Enhancements
- Streaming inference responses
- Custom model fine-tuning
- Vector database integration
- Multi-modal inference (images, audio)

## Security Considerations

- API keys stored in environment variables only
- Local inference for sensitive data
- Policy enforcement before external calls
- Audit trail for all inference requests
- Rate limiting and quota enforcement
