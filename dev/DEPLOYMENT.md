# Deployment Guide

This guide covers different deployment modes for Unison, from single-machine setups to headless configurations.

## Table of Contents

- [Quick Start](#quick-start)
- [Single-Machine Deployment](#single-machine-deployment)
- [Headless Deployment](#headless-deployment)
- [Production Considerations](#production-considerations)
- [Troubleshooting](#troubleshooting)

## Quick Start

### One-Click Installation

**Linux/macOS:**
```bash
curl -fsSL https://raw.githubusercontent.com/project-unisonos/unison/main/unison-devstack/install.sh | bash
```

**Windows PowerShell:**
```powershell
iwr -useb https://raw.githubusercontent.com/project-unisonos/unison/main/unison-devstack/install.ps1 | iex
```

### With Local LLM Support
```bash
curl -fsSL https://raw.githubusercontent.com/project-unisonos/unison/main/unison-devstack/install.sh | bash -s -- --with-ollama
```

## Single-Machine Deployment

Single-machine deployment is ideal for:
- Development environments
- Small team deployments
- Edge computing scenarios
- Privacy-focused installations

### System Requirements

**Minimum:**
- CPU: 4 cores
- RAM: 8GB
- Storage: 20GB available
- OS: Linux, macOS, or Windows with Docker Desktop

**Recommended (with Ollama):**
- CPU: 8 cores
- RAM: 16GB
- Storage: 50GB available
- GPU: NVIDIA GPU with CUDA support (for faster inference)

### Installation Steps

1. **Install Docker and Docker Compose**
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install docker.io docker-compose
   
   # macOS
   brew install docker docker-compose
   
   # Windows
   # Download and install Docker Desktop
   ```

2. **Run the Installer**
   ```bash
   # Basic installation
   ./install.sh
   
   # With Ollama for local LLM
   ./install.sh --with-ollama --single-machine
   ```

3. **Verify Installation**
   ```bash
   cd ~/unison
   ./unison status
   ```

### Configuration

For single-machine deployment, you may want to adjust these settings:

**Resource Limits** (in `docker-compose.yml`):
```yaml
services:
  orchestrator:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
```

**Local Network Access** (optional):
```yaml
services:
  orchestrator:
    ports:
      - "0.0.0.0:8080:8080"  # Access from other devices
```

### Performance Optimization

1. **Enable Docker BuildKit**
   ```bash
   export DOCKER_BUILDKIT=1
   export COMPOSE_DOCKER_CLI_BUILD=1
   ```

2. **Use Local Registry**
   ```bash
   # Set up local registry for faster pulls
   docker run -d -p 5000:5000 --name registry registry:2
   ```

3. **Optimize Ollama Settings**
   ```bash
   # Use GPU acceleration if available
   docker exec ollama ollama run llama3.2
   ```

## Headless Deployment

Headless deployment is designed for:
- Server environments
- Remote deployments
- CI/CD pipelines
- Automated setups

### Prerequisites

- Docker Engine (not Docker Desktop)
- Docker Compose V2
- SSH access (for remote management)
- At least 2GB RAM per service

### Automated Installation

1. **Download and Run Installer**
   ```bash
   # SSH into your server
   ssh user@your-server
   
   # Install Unison
   curl -fsSL https://raw.githubusercontent.com/project-unisonos/unison/main/unison-devstack/install.sh | bash -s -- --single-machine
   ```

2. **Configure for Headless Operation**
   ```bash
   cd ~/unison
   
   # Create headless configuration
   cat > docker-compose.override.yml << 'EOF'
   version: '3.8'
   services:
     orchestrator:
       ports:
         - "127.0.0.1:8080:8080"  # Local access only
     
     inference:
       environment:
         UNISON_INFERENCE_PROVIDER: "openai"  # Use cloud provider
         OPENAI_API_KEY: "${OPENAI_API_KEY}"
     
     ollama:
       profiles: []  # Disable Ollama in headless mode
   EOF
   ```

3. **Set Up Environment Variables**
   ```bash
   # Add API keys for cloud services
   cat >> .env << 'EOF'
   # Cloud inference
   OPENAI_API_KEY=your-api-key-here
   
   # External services (optional)
   UNISON_EXTERNAL_API=true
   EOF
   ```

4. **Start Services**
   ```bash
   ./unison start
   ```

### Remote Access Setup

1. **SSH Tunneling**
   ```bash
   # Forward orchestrator port
   ssh -L 8080:localhost:8080 user@your-server
   
   # Access via http://localhost:8080
   ```

2. **Nginx Reverse Proxy**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       
       location / {
           proxy_pass http://localhost:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

3. **SSL/TLS Configuration**
   ```bash
   # Use Let's Encrypt for SSL
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

### Monitoring Headless Deployment

1. **Health Check Script**
   ```bash
   #!/bin/bash
   # health-check.sh
   
   SERVICES=("orchestrator:8080" "context:8081" "storage:8082" "policy:8083")
   
   for service in "${SERVICES[@]}"; do
       name=$(echo $service | cut -d: -f1)
       port=$(echo $service | cut -d: -f2)
       
       if curl -f "http://localhost:$port/health" > /dev/null 2>&1; then
           echo "✅ $name is healthy"
       else
           echo "❌ $name is unhealthy"
           # Send alert or restart service
           ~/unison/unison restart $name
       fi
   done
   ```

2. **Systemd Service**
   ```ini
   # /etc/systemd/system/unison-health.service
   [Unit]
   Description=Unison Health Check
   After=docker.service
   
   [Service]
   Type=oneshot
   ExecStart=/home/user/unison/health-check.sh
   User=user
   
   [Install]
   WantedBy=multi-user.target
   ```

3. **Cron Job for Monitoring**
   ```bash
   # Add to crontab
   */5 * * * * /home/user/unison/health-check.sh >> /var/log/unison-health.log 2>&1
   ```

## Production Considerations

### Security

1. **Network Security**
   ```yaml
   # docker-compose.prod.yml
   networks:
     unison-internal:
       driver: bridge
       internal: true  # No external access
     
     unison-external:
       driver: bridge
   
   services:
     orchestrator:
       networks:
         - unison-internal
         - unison-external
       ports:
         - "127.0.0.1:8080:8080"  # Local only
   ```

2. **API Keys Management**
   ```bash
   # Use Docker secrets for sensitive data
   echo "your-api-key" | docker secret create openai_api_key -
   ```

3. **Rate Limiting**
   ```yaml
   services:
     orchestrator:
       deploy:
         resources:
           limits:
             cpus: '4.0'
             memory: 4G
       environment:
         UNISON_RATE_LIMIT: "100/minute"
   ```

### Performance

1. **Database Optimization**
   ```yaml
   storage:
     environment:
       SQLITE_CACHE_SIZE: "2000"
       SQLITE_JOURNAL_MODE: "WAL"
   ```

2. **Caching Layer**
   ```yaml
   redis:
     image: redis:alpine
     networks:
       - unison-internal
     volumes:
       - redis_data:/data
   ```

3. **Load Balancing**
   ```yaml
   orchestrator:
     deploy:
       replicas: 3
   ```

### Backup and Recovery

1. **Data Backup Script**
   ```bash
   #!/bin/bash
   # backup.sh
   
   BACKUP_DIR="/backup/unison"
   DATE=$(date +%Y%m%d_%H%M%S)
   
   # Backup volumes
   docker run --rm -v unison_data:/data -v $BACKUP_DIR:/backup \
     alpine tar czf /backup/unison_data_$DATE.tar.gz -C /data .
   
   # Backup configuration
   cp ~/unison/.env $BACKUP_DIR/env_$DATE
   cp ~/unison/docker-compose.yml $BACKUP_DIR/compose_$DATE.yml
   ```

2. **Automated Backups**
   ```bash
   # Add to crontab
   0 2 * * * /home/user/unison/backup.sh
   ```

### Scaling

1. **Horizontal Scaling**
   ```yaml
   # docker-compose.scale.yml
   services:
     orchestrator:
       deploy:
         replicas: 3
     
     context:
       deploy:
         replicas: 2
   ```

2. **Resource Monitoring**
   ```bash
   # Monitor resource usage
   docker stats --no-stream
   
   # Check disk usage
   docker system df
   ```

## Troubleshooting

### Common Issues

1. **Services Won't Start**
   ```bash
   # Check port conflicts
   netstat -tulpn | grep :8080
   
   # Check Docker logs
   docker-compose logs orchestrator
   
   # Verify configuration
   docker-compose config
   ```

2. **High Memory Usage**
   ```bash
   # Check container memory
   docker stats
   
   # Limit memory usage
   docker-compose up -d --scale orchestrator=1
   ```

3. **Network Issues**
   ```bash
   # Check network connectivity
   docker network ls
   docker network inspect unison_default
   
   # Reset networks
   docker network prune
   docker-compose down && docker-compose up -d
   ```

4. **Ollama Issues**
   ```bash
   # Check Ollama status
   docker exec ollama ollama list
   
   # Reinstall model
   docker exec ollama ollama rm llama3.2
   docker exec ollama ollama pull llama3.2
   ```

### Debug Mode

Enable debug logging:
```bash
# Set debug environment
export UNISON_LOG_LEVEL=debug

# Or add to .env
echo "UNISON_LOG_LEVEL=debug" >> ~/unison/.env

# Restart services
~/unison/unison restart
```

### Performance Debugging

1. **Profile Services**
   ```bash
   # Enable profiling
   docker-compose exec orchestrator curl -X POST http://localhost:8080/debug/pprof/profile
   ```

2. **Monitor Resources**
   ```bash
   # Real-time monitoring
   watch -n 1 'docker stats --no-stream'
   
   # Disk usage
   du -sh ~/unison/
   docker system df
   ```

### Getting Help

1. **Check Logs**
   ```bash
   # All services
   unison logs
   
   # Specific service
   unison logs orchestrator
   ```

2. **Community Support**
   - GitHub Discussions: https://github.com/project-unisonos/unison/discussions
   - Issues: https://github.com/project-unisonos/unison/issues

3. **Diagnostic Information**
   ```bash
   # Generate diagnostic report
   unison status > diagnostic.txt
   docker version >> diagnostic.txt
   docker-compose version >> diagnostic.txt
   uname -a >> diagnostic.txt
   ```

## Migration Guide

### From Development to Production

1. **Export Configuration**
   ```bash
   docker-compose config > prod-compose.yml
   ```

2. **Update Production Settings**
   ```bash
   # Remove development overrides
   rm docker-compose.override.yml
   
   # Set production environment
   cp .env .env.prod
   # Edit .env.prod with production values
   ```

3. **Migrate Data**
   ```bash
   # Export data
   docker run --rm -v unison_data:/data -v $(pwd):/backup \
     alpine tar czf /backup/data-migration.tar.gz -C /data .
   
   # Import on production server
   docker run --rm -v unison_data:/data -v $(pwd):/backup \
     alpine tar xzf /backup/data-migration.tar.gz -C /data
   ```

### Version Upgrades

1. **Backup Before Upgrade**
   ```bash
   ./backup.sh
   ```

2. **Upgrade Process**
   ```bash
   # Pull new images
   unison update v1.1.0
   
   # Verify services
   unison status
   
   # Test functionality
   curl http://localhost:8080/health
   ```

3. **Rollback if Needed**
   ```bash
   # Restore previous version
   unison update v1.0.0
   
   # Restore data if necessary
   docker run --rm -v unison_data:/data -v $(pwd):/backup \
     alpine tar xzf /backup/data-migration.tar.gz -C /data
   ```
