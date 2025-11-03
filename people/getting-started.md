# Getting Started with Unison

Welcome to Project Unison! This guide will help you get up and running with the Unison platform, whether you're someone looking to experience the system or a developer looking to build on it.

## What is Unison?

Unison is a **real-time, context-aware intent orchestration environment** that replaces traditional software interfaces with adaptive experiences. Instead of navigating conventional workflows and screens, you engage in natural exchanges where the system understands your intent, context, and preferences to generate personalized outcomes.

### Key Features

- **Natural Interaction**: Conversational, multimodal interface
- **Context Awareness**: Remembers your preferences and current situation
- **Privacy-First**: Local-first architecture with consent controls
- **Adaptive Experiences**: Learns and adapts to your needs
- **Open Platform**: Extensible with skills and integrations

## Quick Start Options

Choose the option that best fits your needs:

### 🚀 Option 1: Try the Demo (Fastest)
Experience Unison immediately without installation.

[Live Demo](https://demo.unisonos.org) - Opens in a new tab

### 🏠 Option 2: Local Development Setup
Run Unison locally on your machine for development and testing.

### 🏢 Option 3: Production Deployment
Deploy a secure, production-ready instance.

---

## Local Development Setup

### Prerequisites

- **Docker** 20.10+ and Docker Compose
- **Git** for cloning repositories
- **4GB+ RAM** and **10GB+ disk space**
- **Python 3.9+** (for local development)

### Step 1: Clone the Repository

```bash
# Clone the main development stack
git clone https://github.com/project-unisonOS/unison-devstack
cd unison-devstack

# Clone the core services (optional, for local development)
git clone https://github.com/project-unisonOS/unison-orchestrator ../unison-orchestrator
git clone https://github.com/project-unisonOS/unison-context ../unison-context
git clone https://github.com/project-unisonOS/unison-storage ../unison-storage
git clone https://github.com/project-unisonOS/unison-policy ../unison-policy
git clone https://github.com/project-unisonOS/unison-auth ../unison-auth
```

### Step 2: Configure Environment

```bash
# Copy the environment template
cp .env.example .env

# Edit with your configuration
nano .env
```

**Key Configuration Options:**
```bash
# JWT Secret (generate with: openssl rand -hex 32)
UNISON_JWT_SECRET=your-secret-key-here

# Development Settings
LOG_LEVEL=INFO
UNISON_DEBUG_MODE=false

# External Service Keys (optional)
OPENAI_API_KEY=your-openai-key
AZURE_OPENAI_API_KEY=your-azure-key
```

### Step 3: Start the Services

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### Step 4: Verify Installation

```bash
# Check health of all services
curl http://localhost:8080/health  # Orchestrator
curl http://localhost:8081/health  # Context
curl http://localhost:8082/health  # Storage
curl http://localhost:8083/health  # Policy
curl http://localhost:8087/health  # Inference
curl http://localhost:8088/health  # Auth
```

### Step 5: Create Your First Account

```bash
# Get an authentication token
curl -X POST http://localhost:8088/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&username=admin&password=admin123"

# Save the access_token for later use
```

### Step 6: Try Your First Request

```bash
# Send a test event
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "echo",
    "payload": {"message": "Hello Unison!"}
  }'
```

## Production Deployment

For production use, we recommend the security-hardened configuration.

### Security Hardening

```bash
# Use the security configuration
docker-compose -f docker-compose.security.yml up -d

# Run security validation
./scripts/security-check.sh
```

### Production Checklist

- [ ] Change all default passwords and secrets
- [ ] Configure valid SSL certificates
- [ ] Set up proper firewall rules
- [ ] Enable backup and monitoring
- [ ] Review security configuration
- [ ] Test disaster recovery procedures

[Security Deployment Guide](../operations/security.md)

## Interface Options

### Web Interface

Access the Unison web interface:
```
http://localhost:3000
```

### Command Line Interface

```bash
# Install the Unison CLI
pip install unison-cli

# Configure CLI
unison config set --url http://localhost:8080
unison config set --token YOUR_ACCESS_TOKEN

# Send commands
unison ask "What's the weather like?"
unison echo "Hello World"
```

### API Access

```bash
# API Documentation
http://localhost:8080/docs

# Interactive API console
http://localhost:8080/redoc
```

## Basic Usage

### Natural Language Interaction

```bash
# Ask questions
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "query",
    "payload": {"text": "What can you help me with?"}
  }'
```

### Context-Aware Responses

Unison remembers your preferences and context:

```bash
# Set preferences
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "preferences.set",
    "payload": {"theme": "dark", "language": "en"}
  }'

# Get personalized response
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "greeting",
    "payload": {}
  }'
```

### Multimodal Interaction

```bash
# Process images
curl -X POST http://localhost:8080/event \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "vision.analyze",
    "payload": {"image_url": "https://example.com/image.jpg"}
  }'
```

## Development

### Adding Custom Skills

Create your own skills to extend Unison's capabilities:

```python
# my_skill.py
from unison_common import register_skill

@register_skill("my.custom_skill")
def my_custom_skill(envelope):
    """Process custom intent"""
    payload = envelope.get("payload", {})
    
    # Your logic here
    result = process_data(payload)
    
    return {
        "status": "success",
        "result": result
    }
```

### Local Development

```bash
# Run services locally for development
cd ../unison-orchestrator
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python src/server.py
```

### Testing

```bash
# Run tests
cd ../unison-orchestrator
pytest tests/

# Run integration tests
cd ../unison-devstack
./scripts/test-integration.sh
```

[Development Guide](../developer/contributing.md)

## Troubleshooting

### Common Issues

**Services Won't Start**
```bash
# Check Docker status
docker --version
docker-compose --version

# Check port conflicts
netstat -tulpn | grep :8080

# View error logs
docker-compose logs orchestrator
```

**Authentication Failures**
```bash
# Check auth service
curl http://localhost:8088/health

# Verify JWT secret
grep UNISON_JWT_SECRET .env

# Reset admin account
docker-compose exec auth python scripts/reset_admin.py
```

**Connection Issues**
```bash
# Check network connectivity
docker network ls
docker network inspect unison-devstack_default

# Restart services
docker-compose restart
```

### Getting Help

- **Documentation**: [Full Documentation](../README.md)
- **Issues**: [GitHub Issues](https://github.com/project-unisonOS/unison-devstack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/project-unisonOS/unison-devstack/discussions)
- **Community**: [Discord Server](https://discord.gg/unisonos)

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
# Set debug environment
export LOG_LEVEL=DEBUG
export UNISON_DEBUG_MODE=true

# Restart with debug
docker-compose down
docker-compose up -d

# Follow logs
docker-compose logs -f orchestrator
```

## Next Steps

### For People Using Unison

- [ ] Explore the [People Guide](people-guide.md)
- [ ] Try example workflows in [Scenarios](../scenarios/README.md)
- [ ] Customize your preferences
- [ ] Install mobile apps (when available)

### For Developers

- [ ] Read the [Architecture Guide](../developer/architecture.md)
- [ ] Explore [API Documentation](../developer/api-reference/README.md)
- [ ] Build your first skill
- [ ] Contribute to the project

### For Operators

- [ ] Review [Security Guide](../operations/security.md)
- [ ] Set up [Monitoring](../operations/monitoring.md)
- [ ] Configure [Backup and Recovery](../operations/backup-recovery.md)
- [ ] Plan [Production Deployment](../deployment/production.md)

## Resources

### Documentation
- [Complete Documentation](../README.md)
- [API Reference](../developer/api-reference/README.md)
- [Security Guide](../operations/security.md)
- [Troubleshooting](troubleshooting.md)

### Community
- [GitHub Project](https://github.com/project-unisonOS)
- [Discord Community](https://discord.gg/unisonos)
- [Community Forum](https://community.unisonos.org)
- [Blog and Updates](https://blog.unisonos.org)

### Tools and Utilities
- [Unison CLI](https://github.com/project-unisonOS/unison-cli)
- [Mobile Apps](https://github.com/project-unisonOS/unison-mobile)
- [Development Tools](https://github.com/project-unisonOS/unison-tools)

---

## Need Help?

If you run into any issues or have questions:

1. **Check the troubleshooting guide** above
2. **Search existing issues** on GitHub
3. **Ask the community** on Discord or forums
4. **Create a new issue** with detailed information

Welcome to the Unison community! We're excited to see what you'll build. 🚀
