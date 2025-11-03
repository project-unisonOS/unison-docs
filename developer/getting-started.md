# Getting Started with the Unison Platform

> **Start the entire Unison Platform with a single command and experience the power of unified intent orchestration.**

## 🚀 One-Command Platform Setup

### Prerequisites

- **Docker Desktop** (or Docker Engine with Compose)
- **Git** (for cloning repositories)
- **Make** (optional, for command shortcuts)

### Quick Start

```bash
# 1. Clone the platform repository
git clone https://github.com/project-unisonos/unison-platform.git
cd unison-platform

# 2. Configure environment
cp .env.template .env
# Edit .env with your configuration

# 3. Start the entire platform
make up

# 4. Verify everything is working
make health
```

**That's it! 🎉 The entire Unison platform with 15+ services is now running.**

---

## 🏗️ What You Just Started

The Unison Platform includes all these services, automatically interconnected:

### **Core Services**
- **Orchestrator** (8090): Central coordination and workflow management
- **Context Service** (8081): User context and session management
- **Policy Service** (8083): Business rules and compliance enforcement
- **Auth Service** (8083): Authentication, authorization, and identity management

### **Intent Orchestration**
- **Intent Graph** (8080): Intent processing and decomposition
- **Context Graph** (8091): Context fusion and management
- **Experience Renderer** (8092): Adaptive interface generation
- **Agent VDI** (8093): Virtual display interface

### **I/O Services**
- **I/O Speech** (8084): Voice processing and synthesis
- **I/O Vision** (8086): Image and video analysis
- **I/O Core** (8085): I/O coordination and protocol management

### **Skills & Inference**
- **Inference Service** (8087): ML model inference gateway

### **Infrastructure**
- **Storage Service** (8082): Data persistence and retrieval
- **Redis** (6379): Caching and session storage
- **PostgreSQL** (5432): Primary data storage
- **NATS** (4222): Event streaming and messaging

---

## 📋 Essential Commands

### Platform Management

```bash
# Start development environment
make dev

# Start with observability stack
make observability

# View logs from all services
make logs

# Check service health
make health

# Stop everything
make down

# Clean up resources
make clean
```

### Service-Specific Operations

```bash
# Restart specific service
make restart-service SERVICE=orchestrator

# View logs for specific service
make logs-service SERVICE=intent-graph

# Get shell in service container
make shell SERVICE=context-graph

# Execute command in service
make exec SERVICE=auth CMD="env | grep SERVICE"
```

### Development Workflow

```bash
# Run integration tests
make test-int

# Run unit tests
make test-unit

# Validate service contracts
make validate

# Pin exact image versions
make pin

# Run security scans
make security-scan
```

---

## 🎯 Verify Your Installation

### Health Check

```bash
make health
```

Expected output:
```
🏥 Unison Platform - Health Check
================================

✅ Intent Graph: Healthy
✅ Context Graph: Healthy  
✅ Experience Renderer: Healthy
✅ Orchestrator: Healthy
✅ All 15+ services operational
🎉 All systems are healthy!
```

### Test Service Endpoints

```bash
# Test orchestrator
curl http://localhost:8090/health

# Test intent graph
curl http://localhost:8080/health

# Test context graph
curl http://localhost:8091/health

# Test experience renderer
curl http://localhost:8092/health
```

### Access Web Interfaces

- **Jaeger Tracing**: http://localhost:16686 (if observability enabled)
- **Prometheus Metrics**: http://localhost:9090 (if observability enabled)
- **Grafana Dashboards**: http://localhost:3000 (if observability enabled)

---

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# Platform Configuration
UNISON_ENV=development
LOG_LEVEL=info

# Database
POSTGRES_HOST=postgres
POSTGRES_DB=unison
POSTGRES_USER=unison
POSTGRES_PASSWORD=unison_password

# Cache & Messaging
REDIS_HOST=redis
NATS_HOST=nats

# Inference
UNISON_INFERENCE_PROVIDER=ollama
UNISON_INFERENCE_MODEL=llama3.2
```

### Service Ports

All services are accessible on localhost:

| Service | Port | Description |
|---------|------|-------------|
| Orchestrator | 8090 | Main intent orchestration |
| Intent Graph | 8080 | Intent processing |
| Context Graph | 8091 | Context management |
| Experience Renderer | 8092 | UI generation |
| Agent VDI | 8093 | Virtual display |
| Auth Service | 8083 | Authentication |
| Context Service | 8081 | Context management |
| I/O Speech | 8084 | Speech processing |
| I/O Vision | 8086 | Vision processing |
| I/O Core | 8085 | I/O coordination |
| Inference | 8087 | ML inference |
| Storage | 8082 | Data persistence |

---

## 🧪 Testing Your Setup

### Basic Intent Processing

```bash
curl -X POST http://localhost:8090/intent/process \
  -H "Content-Type: application/json" \
  -d '{
    "person_id": "test-user-001",
    "expression": "Schedule a team meeting for tomorrow at 2pm",
    "context": {
      "timezone": "UTC"
    }
  }'
```

### Context Management

```bash
curl -X POST http://localhost:8091/context/update/test-user-001 \
  -H "Content-Type: application/json" \
  -d '{
    "context_type": "user",
    "context_data": {
      "preferences": {
        "meeting_duration": "30min",
        "notification_level": "normal"
      }
    }
  }'
```

### Experience Generation

```bash
curl -X POST http://localhost:8092/experience/generate \
  -H "Content-Type: application/json" \
  -d '{
    "person_id": "test-user-001",
    "intent_data": {
      "type": "schedule_meeting",
      "parameters": {
        "time": "2pm tomorrow",
        "attendees": "team"
      }
    },
    "context_data": {
      "device": "desktop"
    },
    "experience_type": "ui"
  }'
```

---

## 🔍 Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check service status
make status

# View logs for problematic service
make logs-service SERVICE=orchestrator

# Check for port conflicts
netstat -tulpn | grep :8080

# Restart everything
make down && make up
```

#### Docker Issues
```bash
# Check Docker is running
docker info

# Check resource usage
docker stats

# Clean up if needed
make clean
```

#### Health Check Failures
```bash
# Detailed health check
make health

# Check individual service
curl http://localhost:8080/health

# View service logs
make logs-service SERVICE=intent-graph
```

### Getting Help

```bash
# Show all available commands
make help

# Get diagnostic information
make status > diagnostic.txt
docker version >> diagnostic.txt
docker-compose version >> diagnostic.txt
```

---

## 🎚️ Development Profiles

### Development Profile
```bash
make dev
```
- Enables hot reload
- Shows debug logs
- Includes development tools

### Production Profile
```bash
make prod
```
- Optimized for performance
- Production logging levels
- Security hardening

### Observability Profile
```bash
make observability
```
- Includes monitoring stack
- Jaeger tracing enabled
- Prometheus + Grafana dashboards

---

## 📚 Next Steps

### 1. **Explore the Architecture**
- Read [Platform Overview](platform-overview.md)
- Understand [Domain Organization](platform-overview.md#domain-organization)
- Learn about [Service Contracts](../specs/unison-spec/)

### 2. **Development Workflow**
- Read [Development Workflow](development-workflow.md)
- Set up [Local Development](development-workflow.md#local-development)
- Learn about [Testing](development-workflow.md#testing)

### 3. **Build Something**
- Create a [Custom Skill](../tutorials/creating-skills.md)
- Integrate with [External APIs](../tutorials/external-integrations.md)
- Deploy to [Production](deployment/README.md)

### 4. **Join the Community**
- GitHub Discussions: https://github.com/project-unisonos/unison-platform/discussions
- Report Issues: https://github.com/project-unisonos/unison-platform/issues
- Contributing Guide: [CONTRIBUTING.md](../CONTRIBUTING.md)

---

## 🎉 Congratulations!

You now have the **complete Unison Platform** running with:

- ✅ **15+ interconnected services** operational
- ✅ **One-command management** via Makefile
- ✅ **Health monitoring** and logging
- ✅ **Development tools** and testing
- ✅ **Enterprise-grade security** and observability
- ✅ **Ready for development** and production

**What's next?**
- Try the examples above
- Read the [Platform Overview](platform-overview.md)
- Explore [Development Workflow](development-workflow.md)
- Check [Deployment Options](deployment/README.md)

Happy building! 🚀

---

**🔗 Quick Links**
- [Platform Overview](platform-overview.md)
- [Development Workflow](development-workflow.md)
- [API Reference](api-reference/README.md)
- [Deployment Guide](deployment/README.md)
- [Troubleshooting](troubleshooting.md)
