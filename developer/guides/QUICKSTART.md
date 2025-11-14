# Quick Start Guide

Get Unison running in minutes with this step-by-step guide.

## 🚀 One-Click Installation

### Linux/macOS
```bash
curl -fsSL https://raw.githubusercontent.com/project-unisonos/unison/main/unison-devstack/install.sh | bash
```

### Windows PowerShell
```powershell
iwr -useb https://raw.githubusercontent.com/project-unisonos/unison/main/unison-devstack/install.ps1 | iex
```

### With Local LLM (Recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/project-unisonos/unison/main/unison-devstack/install.sh | bash -s -- --with-ollama
```

## ✅ Verify Installation

Once installation completes, check that everything is working:

```bash
cd ~/unison          # or cd %USERPROFILE%\unison on Windows
./unison status      # or .\unison.ps1 status on Windows
```

You should see all services marked as "Healthy".

## 🎯 Try It Out

### 1. Health Check
```bash
curl http://localhost:8080/health
```
Expected response:
```json
{"status": "ok", "service": "unison-orchestrator"}
```

### 2. Test Inference (if Ollama installed)
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "summarize.doc",
    "payload": {
      "prompt": "Summarize this: Unison is a modular AI platform that enables natural interaction through multiple services."
    },
    "safety_context": {"data_classification": "public"}
  }'
```

### 3. Explore Services
Open these URLs in your browser:

- **Orchestrator**: http://localhost:8080/health
- **Context**: http://localhost:8081/health  
- **Storage**: http://localhost:8082/health
- **Policy**: http://localhost:8083/health
- **Inference**: http://localhost:8087/health
- **Ollama** (if installed): http://localhost:11434

## 🛠 Basic Commands

### Service Management
```bash
./unison start          # Start all services
./unison stop           # Stop all services
./unison restart        # Restart all services
./unison status         # Check service health
./unison logs           # View all logs
./unison logs orchestrator  # View specific service logs
```

### Updates
```bash
./unison update         # Update to latest version
./unison update v1.0.0  # Update to specific version
```

### Cleanup
```bash
./unison clean          # Remove containers (keeps data)
./unison clean --volumes  # Remove everything (data loss!)
```

## 🤖 Using AI Features

### Document Summarization
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "summarize.doc",
    "payload": {
      "prompt": "Your long document text here..."
    }
  }'
```

### Code Analysis
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "analyze.code",
    "payload": {
      "prompt": "def fibonacci(n): return n if n <= 1 else fibonacci(n-1) + fibonacci(n-2)"
    }
  }'
```

### Translation
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "translate.text",
    "payload": {
      "prompt": "Translate to French: Hello, how are you?"
    }
  }'
```

### Idea Generation
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "generate.idea",
    "payload": {
      "prompt": "Generate ideas for a sustainable home garden"
    }
  }'
```

## 🔧 Configuration

### Environment Variables
Edit `~/unison/.env` to configure:

```bash
# Cloud API keys (optional)
OPENAI_API_KEY=your-openai-key
AZURE_OPENAI_ENDPOINT=your-azure-endpoint
AZURE_OPENAI_API_KEY=your-azure-key

# Inference settings
UNISON_INFERENCE_PROVIDER=ollama  # or openai, azure
UNISON_INFERENCE_MODEL=llama3.2   # model name
```

### Changing Providers
```bash
# Switch to OpenAI
export UNISON_INFERENCE_PROVIDER=openai
export UNISON_INFERENCE_MODEL=gpt-4
export OPENAI_API_KEY=your-key
./unison restart inference

# Switch back to local Ollama
export UNISON_INFERENCE_PROVIDER=ollama
./unison restart inference
```

## 📊 Monitoring

### Check Metrics
All services expose metrics at `/metrics`:
```bash
curl http://localhost:8080/metrics  # Orchestrator metrics
curl http://localhost:8087/metrics  # Inference metrics
```

### View Logs
```bash
# Follow logs in real-time
./unison logs -f

# Specific service logs
./unison logs orchestrator -f
./unison logs inference -f
```

## 🎨 Custom Examples

### Smart Home Controller
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "generate.idea",
    "source": "smart-home",
    "payload": {
      "prompt": "Suggest energy-saving automations for a 3-bedroom house"
    }
  }'
```

### Code Review Assistant
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "analyze.code",
    "source": "code-review",
    "payload": {
      "prompt": "Review this Python code for security issues and suggest improvements:\n\nimport os\n\ndef load_config(filename):\n    with open(filename, 'r') as f:\n        return eval(f.read())"
    }
  }'
```

### Meeting Summarizer
```bash
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "summarize.doc",
    "source": "meeting-notes",
    "payload": {
      "prompt": "Summarize this meeting transcript and extract action items:\n\n[Your meeting transcript here...]"
    }
  }'
```

## 🔍 Troubleshooting

### Service Won't Start
```bash
# Check what's wrong
./unison logs orchestrator

# Check port conflicts
netstat -tulpn | grep :8080

# Restart everything
./unison stop && ./unison start
```

### Ollama Issues
```bash
# Check Ollama status
curl http://localhost:11434/api/tags

# Reinstall model
docker exec ollama ollama rm llama3.2
docker exec ollama ollama pull llama3.2
```

### Memory Issues
```bash
# Check resource usage
docker stats

# Free up space
docker system prune -f
```

## 📚 Next Steps

1. **Read the Architecture Guide**
   - Understand how services work together
   - Learn about intents and events

2. **Explore Advanced Features**
   - Custom policy rules
   - External integrations
   - Multi-modal I/O

3. **Join the Community**
   - GitHub Discussions: https://github.com/project-unisonos/unison/discussions
   - Report issues: https://github.com/project-unisonos/unison/issues

4. **Build Something**
   - Create a custom skill
   - Integrate with your application
   - Deploy to production

## 🆘 Get Help

### Command Help
```bash
./unison help  # Show all available commands
```

### Health Check
```bash
curl http://localhost:8080/ready  # Detailed readiness status
```

### Diagnostic Information
```bash
./unison status > diagnostic.txt
docker version >> diagnostic.txt
docker-compose version >> diagnostic.txt
```

### Common Solutions

| Problem | Solution |
|---------|----------|
| Port already in use | Change ports in `docker-compose.yml` |
| Out of memory | Increase RAM or use cloud inference |
| Slow responses | Check `./unison status` and resource usage |
| Can't reach services | Verify Docker is running: `docker info` |

## 🎉 Congratulations!

You now have Unison running with:
- ✅ All core services operational
- ✅ Local LLM inference (if installed)
- ✅ Management CLI tools
- ✅ Monitoring and logging
- ✅ Ready for development and experimentation

**What's next?**
- Try the examples above
- Read the [Architecture Guide](ARCHITECTURE.md)
- Explore [Inference Features](INFERENCE.md)
- Check [Deployment Options](DEPLOYMENT.md)

Happy building! 🚀
