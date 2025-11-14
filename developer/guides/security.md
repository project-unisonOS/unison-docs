# Security Operations Guide

## Overview

This guide covers the security architecture, implementation, and operational procedures for the Unison platform. Unison implements defense-in-depth security with multiple layers of protection including authentication, authorization, network segmentation, input validation, and comprehensive monitoring.

## Security Architecture

### Authentication System

#### JWT-Based Authentication
- **Access Tokens**: 30-minute expiration with refresh capability
- **Refresh Tokens**: 24-hour expiration with secure storage
- **Service Tokens**: Client credentials for service-to-service auth
- **Token Blacklisting**: Redis-based revocation system

#### Role-Based Access Control (RBAC)
- **Admin**: Full system access and user management
- **Operator**: Operational tasks and monitoring
- **Developer**: Development and debugging access
- **User**: Standard user interactions
- **Service**: Service-to-service communication

#### User Management
- **Password Hashing**: bcrypt with salt rounds
- **Default Users**: Pre-configured for initial setup (change in production)
- **Account Lockout**: Protection against brute force attacks
- **Session Management**: Secure session handling with timeout

### Network Security

#### Network Segmentation
```
Public Network (172.20.0.0/24)
├── Kong API Gateway
└── Load Balancer

Internal Network (172.21.0.0/24)
├── Orchestrator
├── Context
├── Policy
└── Auth

Data Network (172.22.0.0/24)
├── Storage
├── Redis
└── Databases

Auth Network (172.23.0.0/24)
├── Auth Service
└── Redis (auth-specific)

Inference Network (172.24.0.0/24)
├── Inference Service
└── AI Model Containers
```

#### API Gateway Security (Kong)
- **JWT Plugin**: Token validation and signature verification
- **ACL Plugin**: Role-based access enforcement
- **Rate Limiting**: Configurable limits per service/user
- **CORS Plugin**: Cross-origin request handling
- **Security Headers**: CSP, HSTS, X-Frame-Options
- **Request Size Limits**: Protection against large payloads

### Data Protection

#### Encryption
- **In Transit**: TLS 1.2+ for all network communication
- **At Rest**: AES-256 for storage volumes and databases
- **Environment Variables**: Encrypted secrets management
- **Backup Data**: Encrypted backup archives

#### Input Validation and Sanitization
- **Event Envelope Validation**: Schema validation with JSON Schema
- **XSS Protection**: HTML sanitization with bleach library
- **SQL Injection Prevention**: Parameterized queries and ORMs
- **File Upload Security**: Type validation and size limits
- **Command Injection Prevention**: Input sanitization and escaping

### Security Headers

All HTTP responses include comprehensive security headers:

```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

## Security Configuration

### Environment Variables

#### Authentication
```bash
# JWT Configuration
UNISON_JWT_SECRET=your-256-bit-secret-key
UNISON_ACCESS_TOKEN_EXPIRE_MINUTES=30
UNISON_REFRESH_TOKEN_EXPIRE_MINUTES=1440

# Service Authentication
UNISON_ORCHESTRATOR_SERVICE_SECRET=orchestrator-secret
UNISON_INFERENCE_SERVICE_SECRET=inference-secret
UNISON_POLICY_SERVICE_SECRET=policy-secret
```

#### Network Security
```bash
# HTTPS Enforcement
UNISON_FORCE_HTTPS=true

# Allowed Hosts
UNISON_ALLOWED_HOSTS=localhost,unison.local,your-domain.com

# CORS Configuration
UNISON_CORS_ORIGINS=https://your-domain.com,https://app.your-domain.com
```

#### Rate Limiting
```bash
# Global Limits
UNISON_GLOBAL_RATE_LIMIT=100  # requests/minute

# Per-User Limits
UNISON_USER_RATE_LIMIT=200
UNISON_INFERENCE_RATE_LIMIT=50
UNISON_STORAGE_RATE_LIMIT=200
```

### Docker Security Configuration

```yaml
services:
  orchestrator:
    image: unison-orchestrator:latest
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
    user: "1000:1000"
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: '1G'
    networks:
      - internal
```

## Security Monitoring

### Authentication Events

All authentication events are logged with structured JSON:

```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "event_type": "authentication",
  "service": "unison-auth",
  "user_id": "user-123",
  "action": "login_success",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0...",
  "session_id": "session-456"
}
```

### Authorization Events

```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "event_type": "authorization",
  "service": "unison-orchestrator",
  "user_id": "user-123",
  "action": "access_denied",
  "resource": "/api/sensitive",
  "required_role": "admin",
  "user_roles": ["user"],
  "reason": "insufficient_privileges"
}
```

### Security Metrics

Monitor these key security metrics:
- Authentication success/failure rates
- Token issuance and revocation counts
- Rate limit violations
- Policy decision statistics
- Input validation failures
- Network anomaly detection

## Security Procedures

### Initial Setup

1. **Generate Strong Secrets**
   ```bash
   # JWT Secret (256+ bits)
   openssl rand -hex 32
   
   # Service Secrets
   openssl rand -base64 32  # for each service
   
   # Redis Password
   openssl rand -base64 32
   ```

2. **Configure SSL/TLS**
   ```bash
   # Generate certificates (production should use CA-signed)
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
     -keyout ssl/kong.key -out ssl/kong.crt
   ```

3. **Deploy Security Configuration**
   ```bash
   docker-compose -f docker-compose.security.yml up -d
   ```

### Daily Operations

#### Security Health Checks
```bash
# Run security validation
./scripts/security-check.sh

# Check authentication service
curl http://localhost:8088/health

# Verify JWT tokens
curl -X POST http://localhost:8088/verify \
  -H "Content-Type: application/json" \
  -d '{"token": "your-token"}'
```

#### Log Monitoring
```bash
# Monitor authentication failures
grep "authentication_failure" /var/log/unison/*.log

# Check rate limiting
grep "rate_limit_exceeded" /var/log/unison/*.log

# Policy violations
grep "policy_denied" /var/log/unison/*.log
```

### Incident Response

#### Security Incident Checklist

1. **Initial Assessment**
   - [ ] Identify affected systems and users
   - [ ] Determine incident scope and impact
   - [ ] Preserve evidence and logs

2. **Containment**
   - [ ] Isolate affected services
   - [ ] Block malicious IP addresses
   - [ ] Revoke compromised tokens

3. **Investigation**
   - [ ] Analyze logs and audit trails
   - [ ] Identify root cause
   - [ ] Document timeline and findings

4. **Recovery**
   - [ ] Patch vulnerabilities
   - [ ] Restore services from clean backups
   - [ ] Rotate all secrets and certificates

5. **Post-Incident**
   - [ ] Update security procedures
   - [ ] Implement additional controls
   - [ ] Conduct security review

#### Common Security Incidents

**Brute Force Attack**
```bash
# Identify source IPs
grep "authentication_failure" /var/log/unison/auth.log | \
  jq -r '.ip_address' | sort | uniq -c | sort -nr

# Block malicious IPs
iptables -A INPUT -s 192.168.1.100 -j DROP
```

**Token Compromise**
```bash
# Revoke specific token
curl -X POST http://localhost:8088/revoke \
  -H "Authorization: Bearer admin-token" \
  -H "Content-Type: application/json" \
  -d '{"token": "compromised-token"}'

# Rotate JWT secret
export UNISON_JWT_SECRET=$(openssl rand -hex 32)
docker-compose restart auth orchestrator
```

## Security Hardening

### Production Hardening Checklist

#### Authentication
- [ ] Change all default passwords
- [ ] Use strong, randomly generated secrets
- [ ] Implement password policies
- [ ] Enable multi-factor authentication
- [ ] Set appropriate token lifetimes

#### Network Security
- [ ] Deploy behind proper firewall
- [ ] Use VPN for administrative access
- [ ] Disable unused ports and services
- [ ] Implement proper DNS security
- [ ] Monitor network traffic

#### SSL/TLS
- [ ] Use valid certificates from trusted CA
- [ ] Enable HTTPS only
- [ ] Implement certificate rotation
- [ ] Use TLS 1.2+ only
- [ ] Disable weak ciphers

#### Container Security
- [ ] Use minimal base images
- [ ] Run as non-root user
- [ ] Enable read-only filesystems
- [ ] Implement resource limits
- [ ] Scan images for vulnerabilities

#### Monitoring
- [ ] Enable comprehensive logging
- [ ] Set up log aggregation
- [ ] Configure security alerts
- [ ] Monitor for anomalous behavior
- [ ] Regular security audits

### Security Testing

#### Automated Security Tests
```bash
# Run security validation
./scripts/security-check.sh

# OWASP ZAP Baseline Scan
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t http://localhost:8000

# Dependency vulnerability scan
safety check
```

#### Penetration Testing
- Test authentication bypass attempts
- Verify input validation effectiveness
- Test rate limiting bypass
- Check for privilege escalation
- Validate network segmentation

## Compliance and Auditing

### Audit Trail

All security-relevant actions are logged with:
- Timestamp and user identity
- Action performed and resource accessed
- Source IP and user agent
- Success/failure status
- Policy decisions and reasoning

### Compliance Requirements

#### GDPR Compliance
- [ ] Data minimization principles
- [ ] User consent management
- [ ] Right to be forgotten implementation
- [ ] Data breach notification procedures
- [ ] Privacy by design implementation

#### SOC 2 Controls
- [ ] Security incident response procedures
- [ ] Access control and review processes
- [ ] Data encryption and protection
- [ ] Monitoring and alerting systems
- [ ] Regular security assessments

### Security Reporting

#### Daily Reports
- Authentication success/failure rates
- Blocked requests and rate limiting
- System access patterns
- Anomaly detection alerts

#### Weekly Reports
- Security patch status
- Vulnerability scan results
- User access review
- Configuration drift analysis

#### Monthly Reports
- Security metrics and trends
- Incident summary and lessons learned
- Compliance status updates
- Risk assessment results

## Security Best Practices

### Development Security

#### Secure Coding Practices
- Input validation and sanitization
- Parameterized queries for database access
- Proper error handling without information leakage
- Secure session management
- Regular security code reviews

#### Dependency Management
- Regular dependency updates
- Vulnerability scanning
- Supply chain security
- License compliance checking
- Minimal dependency usage

### Operational Security

#### Access Control
- Principle of least privilege
- Regular access reviews
- Separation of duties
- Temporary elevated access
- Audit of privileged accounts

#### Backup and Recovery
- Encrypted backup storage
- Regular backup testing
- Off-site backup storage
- Disaster recovery procedures
- Recovery time objectives

## Troubleshooting

### Common Security Issues

#### Authentication Failures
```bash
# Check auth service health
curl http://localhost:8088/health

# Verify JWT secret consistency
grep UNISON_JWT_SECRET .env
docker-compose exec auth env | grep JWT_SECRET

# Check Redis connectivity
docker-compose exec auth redis-cli ping
```

#### Authorization Problems
```bash
# Verify user roles
curl -X GET http://localhost:8088/me \
  -H "Authorization: Bearer user-token"

# Check policy service
curl http://localhost:8083/health
curl http://localhost:8083/rules/summary
```

#### Network Security Issues
```bash
# Check firewall rules
iptables -L -n

# Verify network isolation
docker network ls
docker network inspect unison-devstack_internal

# Test TLS configuration
openssl s_client -connect your-domain.com:443
```

### Debug Mode

Enable verbose security logging for troubleshooting:
```bash
# Enable debug logging
export LOG_LEVEL=DEBUG
export UNISON_DEBUG_AUTH=true

# Monitor authentication flow
docker-compose logs -f auth | jq '.'

# Check policy decisions
docker-compose logs -f orchestrator | grep policy
```

---

*This security guide should be reviewed regularly and updated as new threats and controls are identified.*
